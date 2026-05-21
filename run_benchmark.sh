#!/bin/bash
#
# Benchmark: JPEG-1 (libjpeg-turbo) vs HTJ2K (OpenJPH) vs HTJ2K (Kakadu)
#
# Usage: ./run_benchmark.sh [output_dir]
#   output_dir defaults to the directory containing this script.
#
# Configure the paths below before first use.
#
set -e

########################################
# Configuration — edit these paths
########################################
IMG=~/Documents/data/images/ppm/u10_8bit.ppm

CJPEG=/usr/bin/cjpeg
DJPEG=/usr/bin/djpeg

OJPH_C=/home/osamu/Documents/src/OpenJPH/build/src/apps/ojph_compress/ojph_compress
OJPH_E=/home/osamu/Documents/src/OpenJPH/build/src/apps/ojph_expand/ojph_expand

KDU_C=/home/osamu/bin/kdu_compress
KDU_E=/home/osamu/bin/kdu_expand

PYTHON=/home/osamu/.pyenv/versions/3.10.16/bin/python3

ITERS=10
########################################

OUT_DIR="${1:-$(cd "$(dirname "$0")" && pwd)}"
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

PIXELS=$((3840 * 2160))
MPIXELS=$(echo "scale=4; $PIXELS / 1000000" | bc)

QSTEPS=(0.15 0.06 0.038 0.025 0.02 0.011)
JPEG_Q=(10 50 70 80 90 95)

# Verify all tools exist
for tool in "$CJPEG" "$DJPEG" "$OJPH_C" "$OJPH_E" "$KDU_C" "$KDU_E" "$PYTHON"; do
  if [ ! -x "$tool" ]; then
    echo "ERROR: $tool not found or not executable" >&2; exit 1
  fi
done
if [ ! -f "$IMG" ]; then
  echo "ERROR: image $IMG not found" >&2; exit 1
fi

# Version detection
JPEG_VERSION=$($CJPEG -version 2>&1 | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
OJPH_LIB=$(ldd "$OJPH_C" 2>/dev/null | grep openjph | awk '{print $3}')
OJPH_VERSION=$(strings "$OJPH_LIB" 2>/dev/null | grep -oP 'JPH Ver \K[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
KDU_VERSION=$($KDU_C -version 2>&1 | grep "version" | head -1 | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")

extract_kdu_cpu() {
  echo "$1" | grep "End-to-end CPU time" | sed 's/.*= \([0-9.]*\) seconds.*/\1/'
}
extract_ojph_elapsed() {
  echo "$1" | grep "Elapsed time" | sed 's/.*= //' | tr -d ' '
}

echo "==> Running benchmark ($ITERS iterations per data point)..."

declare -a JPEG_BPP OJPH_BPP KDU_BPP
declare -a JPEG_ENC_T OJPH_ENC_T KDU_ENC_T
declare -a JPEG_DEC_T OJPH_DEC_T KDU_DEC_T

for idx in 0 1 2 3 4 5; do
  q=${JPEG_Q[$idx]}
  qs=${QSTEPS[$idx]}
  echo "    Qstep=$qs ..."

  # JPEG
  jpeg_enc_total=0; jpeg_dec_total=0
  for i in $(seq 1 $ITERS); do
    t=$( { time "$CJPEG" -quality $q -sample 1x1 -outfile "$TMPDIR/bench.jpg" "$IMG" 2>/dev/null ; } 2>&1 | grep real | sed 's/real\t//')
    mins=$(echo $t | sed 's/m.*//'); secs=$(echo $t | sed 's/.*m//' | sed 's/s//')
    jpeg_enc_total=$(echo "$jpeg_enc_total + $mins * 60 + $secs" | bc)
    t=$( { time "$DJPEG" -pnm -outfile "$TMPDIR/bench_dec.ppm" "$TMPDIR/bench.jpg" 2>/dev/null ; } 2>&1 | grep real | sed 's/real\t//')
    mins=$(echo $t | sed 's/m.*//'); secs=$(echo $t | sed 's/.*m//' | sed 's/s//')
    jpeg_dec_total=$(echo "$jpeg_dec_total + $mins * 60 + $secs" | bc)
  done
  JPEG_ENC_T[$idx]=$(echo "scale=4; $jpeg_enc_total / $ITERS" | bc)
  JPEG_DEC_T[$idx]=$(echo "scale=4; $jpeg_dec_total / $ITERS" | bc)
  jpeg_size=$(stat -c%s "$TMPDIR/bench.jpg")
  JPEG_BPP[$idx]=$(echo "scale=2; $jpeg_size * 8 / $PIXELS" | bc)

  # OpenJPH
  ojph_enc_total=0; ojph_dec_total=0
  for i in $(seq 1 $ITERS); do
    out=$("$OJPH_C" -i "$IMG" -o "$TMPDIR/bench_ojph.j2c" -qstep $qs 2>&1)
    t=$(extract_ojph_elapsed "$out"); ojph_enc_total=$(echo "$ojph_enc_total + $t" | bc)
    out=$("$OJPH_E" -i "$TMPDIR/bench_ojph.j2c" -o "$TMPDIR/bench_ojph_dec.ppm" 2>&1)
    t=$(extract_ojph_elapsed "$out"); ojph_dec_total=$(echo "$ojph_dec_total + $t" | bc)
  done
  OJPH_ENC_T[$idx]=$(echo "scale=4; $ojph_enc_total / $ITERS" | bc)
  OJPH_DEC_T[$idx]=$(echo "scale=4; $ojph_dec_total / $ITERS" | bc)
  ojph_size=$(stat -c%s "$TMPDIR/bench_ojph.j2c")
  OJPH_BPP[$idx]=$(echo "scale=2; $ojph_size * 8 / $PIXELS" | bc)

  # Kakadu
  kdu_enc_total=0; kdu_dec_total=0
  for i in $(seq 1 $ITERS); do
    out=$("$KDU_C" -i "$IMG" -o "$TMPDIR/bench_kdu.j2c" 'Cmodes=HT' Qstep=$qs -num_threads 0 -no_weights -cpu 0 2>&1)
    t=$(extract_kdu_cpu "$out"); kdu_enc_total=$(echo "$kdu_enc_total + $t" | bc)
    out=$("$KDU_E" -i "$TMPDIR/bench_kdu.j2c" -o "$TMPDIR/bench_kdu_dec.ppm" -num_threads 0 -cpu 0 2>&1)
    t=$(extract_kdu_cpu "$out"); kdu_dec_total=$(echo "$kdu_dec_total + $t" | bc)
  done
  KDU_ENC_T[$idx]=$(echo "scale=4; $kdu_enc_total / $ITERS" | bc)
  KDU_DEC_T[$idx]=$(echo "scale=4; $kdu_dec_total / $ITERS" | bc)
  kdu_size=$(stat -c%s "$TMPDIR/bench_kdu.j2c")
  KDU_BPP[$idx]=$(echo "scale=2; $kdu_size * 8 / $PIXELS" | bc)
done

## Compute throughputs
declare -a JPEG_ENC_MP OJPH_ENC_MP KDU_ENC_MP
declare -a JPEG_DEC_MP OJPH_DEC_MP KDU_DEC_MP

for i in 0 1 2 3 4 5; do
  JPEG_ENC_MP[$i]=$(echo "scale=0; $MPIXELS / ${JPEG_ENC_T[$i]}" | bc)
  OJPH_ENC_MP[$i]=$(echo "scale=0; $MPIXELS / ${OJPH_ENC_T[$i]}" | bc)
  KDU_ENC_MP[$i]=$(echo "scale=0; $MPIXELS / ${KDU_ENC_T[$i]}" | bc)
  JPEG_DEC_MP[$i]=$(echo "scale=0; $MPIXELS / ${JPEG_DEC_T[$i]}" | bc)
  OJPH_DEC_MP[$i]=$(echo "scale=0; $MPIXELS / ${OJPH_DEC_T[$i]}" | bc)
  KDU_DEC_MP[$i]=$(echo "scale=0; $MPIXELS / ${KDU_DEC_T[$i]}" | bc)
done

# Averages
jpeg_enc_avg=0; ojph_enc_avg=0; kdu_enc_avg=0
jpeg_dec_avg=0; ojph_dec_avg=0; kdu_dec_avg=0
for i in 0 1 2 3 4 5; do
  jpeg_enc_avg=$(echo "$jpeg_enc_avg + ${JPEG_ENC_MP[$i]}" | bc)
  ojph_enc_avg=$(echo "$ojph_enc_avg + ${OJPH_ENC_MP[$i]}" | bc)
  kdu_enc_avg=$(echo "$kdu_enc_avg + ${KDU_ENC_MP[$i]}" | bc)
  jpeg_dec_avg=$(echo "$jpeg_dec_avg + ${JPEG_DEC_MP[$i]}" | bc)
  ojph_dec_avg=$(echo "$ojph_dec_avg + ${OJPH_DEC_MP[$i]}" | bc)
  kdu_dec_avg=$(echo "$kdu_dec_avg + ${KDU_DEC_MP[$i]}" | bc)
done
jpeg_enc_avg=$(echo "scale=0; $jpeg_enc_avg / 6" | bc)
ojph_enc_avg=$(echo "scale=0; $ojph_enc_avg / 6" | bc)
kdu_enc_avg=$(echo "scale=0; $kdu_enc_avg / 6" | bc)
jpeg_dec_avg=$(echo "scale=0; $jpeg_dec_avg / 6" | bc)
ojph_dec_avg=$(echo "scale=0; $ojph_dec_avg / 6" | bc)
kdu_dec_avg=$(echo "scale=0; $kdu_dec_avg / 6" | bc)

kdu_ojph_enc=$(echo "scale=2; $kdu_enc_avg / $ojph_enc_avg" | bc)
kdu_ojph_dec=$(echo "scale=2; $kdu_dec_avg / $ojph_dec_avg" | bc)
jpeg_ojph_enc=$(echo "scale=2; $jpeg_enc_avg / $ojph_enc_avg" | bc)
jpeg_ojph_dec=$(echo "scale=2; $jpeg_dec_avg / $ojph_dec_avg" | bc)
kdu_jpeg_enc=$(echo "scale=2; $kdu_enc_avg / $jpeg_enc_avg" | bc)
kdu_jpeg_dec=$(echo "scale=2; $kdu_dec_avg / $jpeg_dec_avg" | bc)

## Write markdown
echo "==> Writing benchmark_results.md..."
cat > "$OUT_DIR/benchmark_results.md" << MDEOF
# Codec Benchmark: JPEG-1 vs HTJ2K (OpenJPH) vs HTJ2K (Kakadu)

## Setup

| Item | Detail |
|------|--------|
| Image | \`u10_8bit.ppm\` (3840 x 2160, 8-bit RGB) |
| JPEG-1 | libjpeg-turbo ${JPEG_VERSION}, 4:4:4 chroma (\`-sample 1x1\`) |
| OpenJPH | ${OJPH_VERSION}, irreversible 9/7, \`-qstep\` |
| Kakadu | ${KDU_VERSION}, \`Cmodes=HT\`, \`Qstep=\`, \`-no_weights\` |
| Threading | All single-threaded (Kakadu: \`-num_threads 0\`) |
| Timing | JPEG: wall-clock; OpenJPH: internal \`Elapsed time\`; Kakadu: \`End-to-end CPU time\` (\`-cpu 0\`) |
| Iterations | ${ITERS} runs averaged per data point |
| Platform | $(uname -s) $(uname -m) |

Both HTJ2K encoders use the same \`Qstep\` value at each operating point,
producing nearly identical file sizes. JPEG quality is chosen to give
comparable bitrates.

## Encoding

| Qstep | JPEG bpp | OJPH bpp | KDU bpp | JPEG (s) | OJPH (s) | KDU (s) | JPEG (MP/s) | OJPH (MP/s) | KDU (MP/s) |
|------:|----------|----------|---------|----------|----------|---------|-------------|-------------|------------|
$(for i in 0 1 2 3 4 5; do
  printf "| %-5s | %-8s | %-8s | %-7s | %-8s | %-8s | %-7s | %-11s | %-11s | %-10s |\n" \
    "${QSTEPS[$i]}" "${JPEG_BPP[$i]}" "${OJPH_BPP[$i]}" "${KDU_BPP[$i]}" \
    "${JPEG_ENC_T[$i]}" "${OJPH_ENC_T[$i]}" "${KDU_ENC_T[$i]}" \
    "${JPEG_ENC_MP[$i]}" "${OJPH_ENC_MP[$i]}" "${KDU_ENC_MP[$i]}"
done)

## Decoding

| Qstep | JPEG bpp | OJPH bpp | KDU bpp | JPEG (s) | OJPH (s) | KDU (s) | JPEG (MP/s) | OJPH (MP/s) | KDU (MP/s) |
|------:|----------|----------|---------|----------|----------|---------|-------------|-------------|------------|
$(for i in 0 1 2 3 4 5; do
  printf "| %-5s | %-8s | %-8s | %-7s | %-8s | %-8s | %-7s | %-11s | %-11s | %-10s |\n" \
    "${QSTEPS[$i]}" "${JPEG_BPP[$i]}" "${OJPH_BPP[$i]}" "${KDU_BPP[$i]}" \
    "${JPEG_DEC_T[$i]}" "${OJPH_DEC_T[$i]}" "${KDU_DEC_T[$i]}" \
    "${JPEG_DEC_MP[$i]}" "${OJPH_DEC_MP[$i]}" "${KDU_DEC_MP[$i]}"
done)

## Summary

| Metric | JPEG | OpenJPH | Kakadu |
|--------|-----:|--------:|-------:|
| Avg encode throughput (MP/s) | ${jpeg_enc_avg} | ${ojph_enc_avg} | ${kdu_enc_avg} |
| Avg decode throughput (MP/s) | ${jpeg_dec_avg} | ${ojph_dec_avg} | ${kdu_dec_avg} |

| Comparison | Encode | Decode |
|------------|-------:|-------:|
| Kakadu / OpenJPH | ${kdu_ojph_enc}x | ${kdu_ojph_dec}x |
| JPEG / OpenJPH   | ${jpeg_ojph_enc}x | ${jpeg_ojph_dec}x |
| Kakadu / JPEG     | ${kdu_jpeg_enc}x | ${kdu_jpeg_dec}x |

## Plot

![Benchmark Plot](benchmark_plot.png)

## Observations

- **Encoding:** Kakadu's HT block encoder is ${kdu_ojph_enc}x faster than OpenJPH's.
  Kakadu's encode time stays nearly flat across bitrates, whereas OpenJPH
  scales with bitrate.
- **Decoding:** Kakadu is about ${kdu_ojph_dec}x faster than OpenJPH. libjpeg-turbo
  remains the fastest decoder overall.
- **File-size parity:** With the same Qstep and \`-no_weights\`, both HTJ2K
  encoders produce virtually identical file sizes, confirming equivalent
  quantization.
MDEOF

## Generate plot
echo "==> Generating benchmark_plot.png..."
"$PYTHON" << PYEOF
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

htj2k_bpp = [$(for i in 0 1 2 3 4 5; do
  echo -n "$(echo "scale=3; (${OJPH_BPP[$i]} + ${KDU_BPP[$i]}) / 2" | bc), "
done)]
jpeg_bpp  = [$(for i in 0 1 2 3 4 5; do echo -n "${JPEG_BPP[$i]}, "; done)]

jpeg_enc  = [$(for i in 0 1 2 3 4 5; do echo -n "${JPEG_ENC_MP[$i]}, "; done)]
ojph_enc  = [$(for i in 0 1 2 3 4 5; do echo -n "${OJPH_ENC_MP[$i]}, "; done)]
kdu_enc   = [$(for i in 0 1 2 3 4 5; do echo -n "${KDU_ENC_MP[$i]}, "; done)]

jpeg_dec  = [$(for i in 0 1 2 3 4 5; do echo -n "${JPEG_DEC_MP[$i]}, "; done)]
ojph_dec  = [$(for i in 0 1 2 3 4 5; do echo -n "${OJPH_DEC_MP[$i]}, "; done)]
kdu_dec   = [$(for i in 0 1 2 3 4 5; do echo -n "${KDU_DEC_MP[$i]}, "; done)]

jpeg_enc_t = [$(for i in 0 1 2 3 4 5; do echo -n "${JPEG_ENC_T[$i]}, "; done)]
ojph_enc_t = [$(for i in 0 1 2 3 4 5; do echo -n "${OJPH_ENC_T[$i]}, "; done)]
kdu_enc_t  = [$(for i in 0 1 2 3 4 5; do echo -n "${KDU_ENC_T[$i]}, "; done)]

jpeg_dec_t = [$(for i in 0 1 2 3 4 5; do echo -n "${JPEG_DEC_T[$i]}, "; done)]
ojph_dec_t = [$(for i in 0 1 2 3 4 5; do echo -n "${OJPH_DEC_T[$i]}, "; done)]
kdu_dec_t  = [$(for i in 0 1 2 3 4 5; do echo -n "${KDU_DEC_T[$i]}, "; done)]

colors = {'jpeg': '#E74C3C', 'ojph': '#2ECC71', 'kdu': '#3498DB'}

fig, axes = plt.subplots(2, 2, figsize=(14, 10))
fig.suptitle('Codec Benchmark: JPEG-1 vs HTJ2K (OpenJPH) vs HTJ2K (Kakadu)\n'
             'Image: u10_8bit.ppm (3840x2160, 8-bit RGB, 4:4:4) — Single-threaded',
             fontsize=13, fontweight='bold')

ax = axes[0, 0]
ax.plot(jpeg_bpp, jpeg_enc, '-o', color=colors['jpeg'], label='JPEG (libjpeg-turbo)', markersize=7, linewidth=2)
ax.plot(htj2k_bpp, ojph_enc, '-s', color=colors['ojph'], label='HTJ2K (OpenJPH)', markersize=7, linewidth=2)
ax.plot(htj2k_bpp, kdu_enc, '-^', color=colors['kdu'], label='HTJ2K (Kakadu)', markersize=7, linewidth=2)
ax.set_xlabel('Bitrate (bpp)'); ax.set_ylabel('Throughput (MP/s)')
ax.set_title('Encoding Throughput'); ax.legend(fontsize=9); ax.grid(True, alpha=0.3)
ax.set_xlim(0, 4.0)

ax = axes[0, 1]
ax.plot(jpeg_bpp, jpeg_dec, '-o', color=colors['jpeg'], label='JPEG (libjpeg-turbo)', markersize=7, linewidth=2)
ax.plot(htj2k_bpp, ojph_dec, '-s', color=colors['ojph'], label='HTJ2K (OpenJPH)', markersize=7, linewidth=2)
ax.plot(htj2k_bpp, kdu_dec, '-^', color=colors['kdu'], label='HTJ2K (Kakadu)', markersize=7, linewidth=2)
ax.set_xlabel('Bitrate (bpp)'); ax.set_ylabel('Throughput (MP/s)')
ax.set_title('Decoding Throughput'); ax.legend(fontsize=9); ax.grid(True, alpha=0.3)
ax.set_xlim(0, 4.0)

ax = axes[1, 0]
ax.plot(jpeg_bpp, [t*1000 for t in jpeg_enc_t], '-o', color=colors['jpeg'], label='JPEG (libjpeg-turbo)', markersize=7, linewidth=2)
ax.plot(htj2k_bpp, [t*1000 for t in ojph_enc_t], '-s', color=colors['ojph'], label='HTJ2K (OpenJPH)', markersize=7, linewidth=2)
ax.plot(htj2k_bpp, [t*1000 for t in kdu_enc_t], '-^', color=colors['kdu'], label='HTJ2K (Kakadu)', markersize=7, linewidth=2)
ax.set_xlabel('Bitrate (bpp)'); ax.set_ylabel('Time (ms)')
ax.set_title('Encoding Time'); ax.legend(fontsize=9); ax.grid(True, alpha=0.3)
ax.set_xlim(0, 4.0)

ax = axes[1, 1]
ax.plot(jpeg_bpp, [t*1000 for t in jpeg_dec_t], '-o', color=colors['jpeg'], label='JPEG (libjpeg-turbo)', markersize=7, linewidth=2)
ax.plot(htj2k_bpp, [t*1000 for t in ojph_dec_t], '-s', color=colors['ojph'], label='HTJ2K (OpenJPH)', markersize=7, linewidth=2)
ax.plot(htj2k_bpp, [t*1000 for t in kdu_dec_t], '-^', color=colors['kdu'], label='HTJ2K (Kakadu)', markersize=7, linewidth=2)
ax.set_xlabel('Bitrate (bpp)'); ax.set_ylabel('Time (ms)')
ax.set_title('Decoding Time'); ax.legend(fontsize=9); ax.grid(True, alpha=0.3)
ax.set_xlim(0, 4.0)

plt.tight_layout()
plt.savefig('$OUT_DIR/benchmark_plot.png', dpi=150, bbox_inches='tight')
PYEOF

echo "==> Done. Results written to:"
echo "    $OUT_DIR/benchmark_results.md"
echo "    $OUT_DIR/benchmark_plot.png"
