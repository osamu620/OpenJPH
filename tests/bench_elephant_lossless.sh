#!/usr/bin/env bash
# Benchmark OpenJPH vs Kakadu HTJ2K on 16-bit lossless ElephantDream_4K.
#
# Usage:
#   tests/bench_elephant_lossless.sh [runs]
#
# Environment overrides:
#   IMG=/path/to/ElephantDream_4K.ppm
#   OJPH_C=/path/to/ojph_compress
#   KDU_C=/path/to/kdu_compress
#   TMPDIR_ROOT=/tmp
#
# Notes:
# - Kakadu is benchmarked in HT mode (Cmodes=HT) for apples-to-apples HTJ2K.
# - Runs OpenJPH single-thread (current CLI behavior) and Kakadu in 1-thread
#   and auto-thread modes.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNS="${1:-8}"
IMG="${IMG:-$HOME/Documents/data/images/ppm/ElephantDream_4K.ppm}"
OJPH_C="${OJPH_C:-$ROOT_DIR/build/src/apps/ojph_compress/ojph_compress}"
KDU_C="${KDU_C:-$(command -v kdu_compress || true)}"
TMPDIR_ROOT="${TMPDIR_ROOT:-/tmp}"
TMPDIR="$(mktemp -d "$TMPDIR_ROOT/ojph-bench-elephant.XXXXXX")"
trap 'rm -rf "$TMPDIR"' EXIT

if [[ ! -x "$OJPH_C" ]]; then
  echo "ERROR: OpenJPH encoder not found/executable: $OJPH_C" >&2
  exit 1
fi
if [[ -z "$KDU_C" || ! -x "$KDU_C" ]]; then
  echo "ERROR: Kakadu encoder not found/executable: ${KDU_C:-<empty>}" >&2
  exit 1
fi
if [[ ! -f "$IMG" ]]; then
  echo "ERROR: input image not found: $IMG" >&2
  exit 1
fi
if ! [[ "$RUNS" =~ ^[0-9]+$ ]] || [[ "$RUNS" -lt 1 ]]; then
  echo "ERROR: runs must be a positive integer (got: $RUNS)" >&2
  exit 1
fi

read -r magic width height maxval < <(
  awk '
    /^#/ { next }
    {
      for (i = 1; i <= NF; ++i) {
        n++
        t[n] = $i
        if (n == 4) {
          print t[1], t[2], t[3], t[4]
          exit
        }
      }
    }' "$IMG"
)
if [[ "$magic" != "P6" || "$maxval" != "65535" ]]; then
  echo "ERROR: expected 16-bit P6 PPM (P6 ... 65535), got: $magic ... $maxval" >&2
  exit 1
fi

pixels=$((width * height))
mpixels="$(awk -v p="$pixels" 'BEGIN { printf "%.4f", p / 1000000.0 }')"

run_openjph() {
  RUNS="$RUNS" OJPH_C="$OJPH_C" IMG="$IMG" OUT="$TMPDIR/openjph.j2c" \
    /usr/bin/time -f "wall=%e user=%U sys=%S" \
    bash -lc 'for i in $(seq 1 "$RUNS"); do "$OJPH_C" -i "$IMG" -o "$OUT" -reversible true >/dev/null; done' 2>&1
}

run_kdu_1thr() {
  RUNS="$RUNS" KDU_C="$KDU_C" IMG="$IMG" OUT="$TMPDIR/kdu_1thr.j2c" \
    /usr/bin/time -f "wall=%e user=%U sys=%S" \
    bash -lc 'for i in $(seq 1 "$RUNS"); do "$KDU_C" -i "$IMG" -o "$OUT" Creversible=yes Clayers=1 Clevels=5 Corder=RPCL "Cblk={64,64}" Cmodes=HT -num_threads 1 -quiet >/dev/null 2>&1; done' 2>&1
}

run_kdu_auto() {
  RUNS="$RUNS" KDU_C="$KDU_C" IMG="$IMG" OUT="$TMPDIR/kdu_auto.j2c" \
    /usr/bin/time -f "wall=%e user=%U sys=%S" \
    bash -lc 'for i in $(seq 1 "$RUNS"); do "$KDU_C" -i "$IMG" -o "$OUT" Creversible=yes Clayers=1 Clevels=5 Corder=RPCL "Cblk={64,64}" Cmodes=HT -quiet >/dev/null 2>&1; done' 2>&1
}

extract_field() {
  sed -n "s/.*$1=\([0-9.]*\).*/\1/p" <<<"$2"
}

calc_throughput() {
  awk -v m="$mpixels" -v w="$1" 'BEGIN { if (w == 0) print "inf"; else printf "%.2f", m / w }'
}

openjph_out="$(run_openjph)"
kdu1_out="$(run_kdu_1thr)"
kdua_out="$(run_kdu_auto)"

ow="$(extract_field wall "$openjph_out")"
ou="$(extract_field user "$openjph_out")"
os="$(extract_field sys "$openjph_out")"
k1w="$(extract_field wall "$kdu1_out")"
k1u="$(extract_field user "$kdu1_out")"
k1s="$(extract_field sys "$kdu1_out")"
kaw="$(extract_field wall "$kdua_out")"
kau="$(extract_field user "$kdua_out")"
kas="$(extract_field sys "$kdua_out")"

openjph_mps="$(calc_throughput "$ow")"
kdu1_mps="$(calc_throughput "$k1w")"
kdua_mps="$(calc_throughput "$kaw")"
ratio_kdu1="$(awk -v o="$ow" -v k="$k1w" 'BEGIN { printf "%.2f", o / k }')"
ratio_kdua="$(awk -v o="$ow" -v k="$kaw" 'BEGIN { printf "%.2f", o / k }')"

printf "\nInput: %s\n" "$IMG"
printf "PPM: %s %sx%s max=%s | Pixels=%d (%.4f MP)\n" "$magic" "$width" "$height" "$maxval" "$pixels" "$mpixels"
printf "Runs: %s\n\n" "$RUNS"

printf "%-18s %-10s %-10s %-10s %-10s\n" "Encoder" "wall(s)" "user(s)" "sys(s)" "MP/s"
printf "%-18s %-10s %-10s %-10s %-10s\n" "------" "-------" "-------" "------" "----"
printf "%-18s %-10s %-10s %-10s %-10s\n" "OpenJPH" "$ow" "$ou" "$os" "$openjph_mps"
printf "%-18s %-10s %-10s %-10s %-10s\n" "Kakadu HT 1thr" "$k1w" "$k1u" "$k1s" "$kdu1_mps"
printf "%-18s %-10s %-10s %-10s %-10s\n" "Kakadu HT auto" "$kaw" "$kau" "$kas" "$kdua_mps"

printf "\nRelative speed (wall):\n"
printf "  Kakadu HT 1thr vs OpenJPH: %sx faster\n" "$ratio_kdu1"
printf "  Kakadu HT auto vs OpenJPH: %sx faster\n" "$ratio_kdua"
