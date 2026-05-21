#!/bin/bash
# Benchmark encode/decode for wavelet optimization measurement.
# Usage: ./bench_wavelet.sh [label]
# Run from build/tests directory.

set -euo pipefail

LABEL="${1:-baseline}"
COMPRESS="./ojph_compress"
EXPAND="./ojph_expand"
REF_IMAGES="./jp2k_test_codestreams/openjph/references"
EXT_IMAGES="$HOME/Documents/data/images/ppm"
TMPDIR="./bench_tmp"
RUNS=11

mkdir -p "$TMPDIR"

bench_encode() {
  local name="$1" input="$2" opts="$3" runs="$4"
  local times=()
  for ((i=0; i<runs; i++)); do
    local t
    t=$(date +%s%N)
    $COMPRESS -i "$input" -o "$TMPDIR/${name}.j2c" $opts >/dev/null 2>&1
    t=$(( $(date +%s%N) - t ))
    t=$(echo "scale=6; $t / 1000000000" | bc)
    times+=("$t")
  done
  # sort and take median
  IFS=$'\n' sorted=($(sort -g <<<"${times[*]}")); unset IFS
  local mid=$((runs / 2))
  echo "${sorted[$mid]}"
}

bench_decode() {
  local name="$1" runs="$2"
  local times=()
  local ext="ppm"
  for ((i=0; i<runs; i++)); do
    local t
    t=$(date +%s%N)
    $EXPAND -i "$TMPDIR/${name}.j2c" -o "$TMPDIR/${name}_dec.${ext}" >/dev/null 2>&1
    t=$(( $(date +%s%N) - t ))
    t=$(echo "scale=6; $t / 1000000000" | bc)
    times+=("$t")
  done
  IFS=$'\n' sorted=($(sort -g <<<"${times[*]}")); unset IFS
  local mid=$((runs / 2))
  echo "${sorted[$mid]}"
}

echo "=== Benchmark: $LABEL ($RUNS runs, median) ==="
echo ""
printf "%-35s %10s %10s\n" "Test" "Encode(s)" "Decode(s)"
printf "%-35s %10s %10s\n" "---" "---" "---"

# 4K 8-bit lossless
if [[ -f "$EXT_IMAGES/u10_8bit.ppm" ]]; then
  enc=$(bench_encode "4k_8bit_rev" "$EXT_IMAGES/u10_8bit.ppm" "-reversible true" $RUNS)
  dec=$(bench_decode "4k_8bit_rev" $RUNS)
  printf "%-35s %10s %10s\n" "4K 8-bit lossless (3840x2160)" "$enc" "$dec"
fi

# 4K 8-bit lossy
if [[ -f "$EXT_IMAGES/u10_8bit.ppm" ]]; then
  enc=$(bench_encode "4k_8bit_irv" "$EXT_IMAGES/u10_8bit.ppm" "" $RUNS)
  dec=$(bench_decode "4k_8bit_irv" $RUNS)
  printf "%-35s %10s %10s\n" "4K 8-bit lossy (3840x2160)" "$enc" "$dec"
fi

# 16-bit lossless 1280x720
enc=$(bench_encode "dpx16_rev" "$REF_IMAGES/dpx_1280x720_16bit.ppm" "-reversible true" $RUNS)
dec=$(bench_decode "dpx16_rev" $RUNS)
printf "%-35s %10s %10s\n" "16-bit lossless (1280x720)" "$enc" "$dec"

# 16-bit lossy 1280x720
enc=$(bench_encode "dpx16_irv" "$REF_IMAGES/dpx_1280x720_16bit.ppm" "" $RUNS)
dec=$(bench_decode "dpx16_irv" $RUNS)
printf "%-35s %10s %10s\n" "16-bit lossy (1280x720)" "$enc" "$dec"

# 16-bit lossless 499x511
enc=$(bench_encode "mm_rev" "$REF_IMAGES/mm.ppm" "-reversible true" $RUNS)
dec=$(bench_decode "mm_rev" $RUNS)
printf "%-35s %10s %10s\n" "16-bit lossless (499x511)" "$enc" "$dec"

# 8-bit lossless 1616x1080
enc=$(bench_encode "mal_rev" "$REF_IMAGES/Malamute.ppm" "-reversible true" $RUNS)
dec=$(bench_decode "mal_rev" $RUNS)
printf "%-35s %10s %10s\n" "8-bit lossless (1616x1080)" "$enc" "$dec"

# 8-bit lossy 1616x1080
enc=$(bench_encode "mal_irv" "$REF_IMAGES/Malamute.ppm" "" $RUNS)
dec=$(bench_decode "mal_irv" $RUNS)
printf "%-35s %10s %10s\n" "8-bit lossy (1616x1080)" "$enc" "$dec"

echo ""
rm -rf "$TMPDIR"
