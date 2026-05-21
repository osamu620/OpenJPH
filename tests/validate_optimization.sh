#!/bin/bash
#
# Bitstream identity validation for encoder optimizations.
#
# Usage:
#   ./validate_optimization.sh generate   # Generate reference codestreams (run BEFORE optimization)
#   ./validate_optimization.sh verify     # Compare current output against references (run AFTER optimization)
#   ./validate_optimization.sh roundtrip  # Verify lossless round-trip only (no reference needed)
#
# The script must be run from the build/tests directory (where ojph_compress,
# ojph_expand, compare_files, and mse_pae are located).

set -euo pipefail

REF_IMAGES="./jp2k_test_codestreams/openjph/references"
REF_DIR="./optimization_ref"
OUT_DIR="./optimization_out"

COMPRESS="./ojph_compress"
EXPAND="./ojph_expand"
COMPARE="./compare_files"
MSE_PAE="./mse_pae"

PASS=0
FAIL=0
ERRORS=""

# Test cases: "name|input_image|compress_options|num_components"
# Covers: lossless 8-bit, lossless 16-bit, lossy, various block sizes,
#         tiled, grayscale, color, YUV, tall/narrow edge cases.
TEST_CASES=(
  # Lossless 16-bit (primary optimization target)
  "rev53_16bit_color|mm.ppm|-reversible true|3"
  "rev53_16bit_gray|mm.pgm|-reversible true|1"
  "rev53_16bit_cb32|mm.ppm|-reversible true -block_size {32,32}|3"
  "rev53_16bit_cb4|mm.ppm|-reversible true -block_size {4,4}|3"
  "rev53_16bit_cb1024x4|mm.ppm|-reversible true -block_size {4,1024}|3"
  "rev53_16bit_cb4x1024|mm.ppm|-reversible true -block_size {1024,4}|3"
  "rev53_16bit_tiled|mm.ppm|-reversible true -tile_size {128,128}|3"
  "rev53_16bit_d3|mm.ppm|-reversible true -num_decomps 3|3"
  "rev53_16bit_d6|mm.ppm|-reversible true -num_decomps 6|3"

  # Lossless 16-bit DPX (larger image)
  "rev53_dpx16bit|dpx_1280x720_16bit.ppm|-reversible true|3"
  "rev53_dpx16bit_tiled|dpx_1280x720_16bit.ppm|-reversible true -tile_size {256,256}|3"

  # Lossless 8-bit
  "rev53_8bit_color|Malamute.ppm|-reversible true|3"
  "rev53_8bit_cb32|Malamute.ppm|-reversible true -block_size {32,32}|3"
  "rev53_8bit_cb4|Malamute.ppm|-reversible true -block_size {4,4}|3"
  "rev53_8bit_tiled_d5|Malamute.ppm|-reversible true -tile_size {32,32} -num_decomps 5|3"
  "rev53_8bit_tiled_d6|Malamute.ppm|-reversible true -tile_size {32,32} -num_decomps 6|3"

  # Lossless grayscale 8-bit
  "rev53_8bit_gray|monarch.pgm|-reversible true|1"

  # Lossy 16-bit
  "irv97_16bit_color|mm.ppm||3"
  "irv97_16bit_gray|mm.pgm||1"

  # Lossy 8-bit
  "irv97_8bit_color|Malamute.ppm||3"
  "irv97_8bit_cb32|Malamute.ppm|-block_size {32,32}|3"
  "irv97_8bit_tiled|Malamute.ppm|-tile_size {33,33}|3"

  # Tall/narrow edge cases
  "rev53_tall_narrow|tall_narrow.ppm|-reversible true|3"
  "irv97_tall_narrow|tall_narrow.ppm||3"
)

check_prerequisites() {
  local missing=0
  for tool in "$COMPRESS" "$EXPAND" "$COMPARE" "$MSE_PAE"; do
    if [[ ! -x "$tool" ]]; then
      echo "ERROR: $tool not found. Run from build/tests directory." >&2
      missing=1
    fi
  done
  if [[ ! -d "$REF_IMAGES" ]]; then
    echo "ERROR: $REF_IMAGES not found. Build with -DOJPH_BUILD_TESTS=ON first." >&2
    missing=1
  fi
  if [[ $missing -ne 0 ]]; then
    exit 1
  fi
}

run_encode() {
  local name="$1" input="$2" opts="$3" outdir="$4"
  local outfile="${outdir}/${name}.j2c"
  # shellcheck disable=SC2086
  $COMPRESS -i "${REF_IMAGES}/${input}" -o "$outfile" $opts 2>&1
}

record_result() {
  local name="$1" status="$2"
  if [[ "$status" == "PASS" ]]; then
    PASS=$((PASS + 1))
    printf "  %-40s [PASS]\n" "$name"
  else
    FAIL=$((FAIL + 1))
    ERRORS="${ERRORS}  ${name}\n"
    printf "  %-40s [FAIL]\n" "$name"
  fi
}

cmd_generate() {
  echo "=== Generating reference codestreams ==="
  mkdir -p "$REF_DIR"

  for tc in "${TEST_CASES[@]}"; do
    IFS='|' read -r name input opts ncomp <<< "$tc"
    if run_encode "$name" "$input" "$opts" "$REF_DIR" >/dev/null 2>&1; then
      printf "  %-40s [OK]\n" "$name"
    else
      printf "  %-40s [ENCODE FAILED]\n" "$name" >&2
      exit 1
    fi
  done

  echo ""
  echo "Reference codestreams saved to ${REF_DIR}/"
  echo "Total: ${#TEST_CASES[@]} files"
}

cmd_verify() {
  echo "=== Verifying bitstream identity ==="

  if [[ ! -d "$REF_DIR" ]]; then
    echo "ERROR: Reference directory $REF_DIR not found." >&2
    echo "Run '$0 generate' first with the baseline code." >&2
    exit 1
  fi

  mkdir -p "$OUT_DIR"

  for tc in "${TEST_CASES[@]}"; do
    IFS='|' read -r name input opts ncomp <<< "$tc"

    if ! run_encode "$name" "$input" "$opts" "$OUT_DIR" >/dev/null 2>&1; then
      record_result "$name" "FAIL (encode error)"
      continue
    fi

    if $COMPARE "${OUT_DIR}/${name}.j2c" "${REF_DIR}/${name}.j2c" >/dev/null 2>&1; then
      record_result "$name" "PASS"
    else
      record_result "$name" "FAIL"
    fi
  done

  echo ""
  echo "=== Bitstream identity: ${PASS} passed, ${FAIL} failed ==="
  if [[ $FAIL -gt 0 ]]; then
    echo "Failed tests:"
    printf "$ERRORS"
    echo ""
    echo "Run '$0 roundtrip' to check if failures are still lossless-correct."
    exit 1
  fi
}

cmd_roundtrip() {
  echo "=== Verifying lossless round-trip ==="

  mkdir -p "$OUT_DIR"

  for tc in "${TEST_CASES[@]}"; do
    IFS='|' read -r name input opts ncomp <<< "$tc"

    local is_lossless=0
    if [[ "$opts" == *"-reversible true"* ]]; then
      is_lossless=1
    fi

    if ! run_encode "$name" "$input" "$opts" "$OUT_DIR" >/dev/null 2>&1; then
      record_result "${name} (encode)" "FAIL"
      continue
    fi

    local ext="${input##*.}"
    if ! $EXPAND -i "${OUT_DIR}/${name}.j2c" -o "${OUT_DIR}/${name}.${ext}" >/dev/null 2>&1; then
      record_result "${name} (decode)" "FAIL"
      continue
    fi

    local mse_output
    mse_output=$($MSE_PAE "${OUT_DIR}/${name}.${ext}" "${REF_IMAGES}/${input}" 2>&1) || true

    if [[ $is_lossless -eq 1 ]]; then
      local all_zero=1
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local mse pae
        mse=$(echo "$line" | awk '{printf "%.0f", $1}')
        pae=$(echo "$line" | awk '{printf "%d", $2}')
        if [[ "$mse" != "0" ]] || [[ "$pae" != "0" ]]; then
          all_zero=0
        fi
      done <<< "$mse_output"

      if [[ $all_zero -eq 1 ]]; then
        record_result "${name} (lossless)" "PASS"
      else
        record_result "${name} (lossless MSE/PAE!=0)" "FAIL"
      fi
    else
      if [[ -n "$mse_output" ]]; then
        record_result "${name} (lossy roundtrip)" "PASS"
      else
        record_result "${name} (lossy roundtrip)" "FAIL"
      fi
    fi
  done

  echo ""
  echo "=== Round-trip: ${PASS} passed, ${FAIL} failed ==="
  if [[ $FAIL -gt 0 ]]; then
    echo "Failed tests:"
    printf "$ERRORS"
    exit 1
  fi
}

check_prerequisites

case "${1:-}" in
  generate)
    cmd_generate
    ;;
  verify)
    cmd_verify
    ;;
  roundtrip)
    cmd_roundtrip
    ;;
  *)
    echo "Usage: $0 {generate|verify|roundtrip}" >&2
    echo "" >&2
    echo "  generate   Generate reference codestreams (run BEFORE optimization)" >&2
    echo "  verify     Compare current output against references (run AFTER)" >&2
    echo "  roundtrip  Verify lossless round-trip only (no reference needed)" >&2
    exit 1
    ;;
esac
