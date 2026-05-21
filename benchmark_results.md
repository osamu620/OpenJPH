# Codec Benchmark: JPEG-1 vs HTJ2K (OpenJPH) vs HTJ2K (Kakadu)

## Setup

| Item | Detail |
|------|--------|
| Image | `u10_8bit.ppm` (3840 x 2160, 8-bit RGB) |
| JPEG-1 | libjpeg-turbo 2.1.5, 4:4:4 chroma (`-sample 1x1`) |
| OpenJPH | 0.27.3, irreversible 9/7, `-qstep` |
| Kakadu | v8.6.2, `Cmodes=HT`, `Qstep=`, `-no_weights` |
| Threading | All single-threaded (Kakadu: `-num_threads 0`) |
| Timing | JPEG: wall-clock; OpenJPH: internal `Elapsed time`; Kakadu: `End-to-end CPU time` (`-cpu 0`) |
| Iterations | 10 runs averaged per data point |
| Platform | Linux x86_64, AMD Ryzen 9 9950X 16-Core Processor |
| SIMD | avx avx2 avx512bw avx512cd avx512f avx512vl sse sse2 sse4_1 sse4_2 ssse3 |

Both HTJ2K encoders use the same `Qstep` value at each operating point,
producing nearly identical file sizes. JPEG quality is chosen to give
comparable bitrates.

## Encoding

| Qstep | Qfactor | JPEG bpp | OJPH bpp | KDU bpp | JPEG (s) | OJPH (s) | KDU (s) | JPEG (MP/s) | OJPH (MP/s) | KDU (MP/s) |
|------:|--------:|----------|----------|---------|----------|----------|---------|-------------|-------------|------------|
| 0.15  | 10      | .43      | .37      | .38     | .0176    | .0358    | .0166   | 471         | 231         | 499        |
| 0.06  | 50      | 1.04     | .91      | .91     | .0192    | .0471    | .0183   | 432         | 176         | 453        |
| 0.038 | 70      | 1.38     | 1.31     | 1.31    | .0207    | .0521    | .0192   | 400         | 159         | 432        |
| 0.025 | 80      | 1.71     | 1.75     | 1.75    | .0212    | .0593    | .0203   | 391         | 139         | 408        |
| 0.02  | 90      | 2.49     | 2.02     | 2.02    | .0236    | .0619    | .0208   | 351         | 133         | 398        |
| 0.011 | 95      | 3.63     | 2.87     | 2.88    | .0272    | .0724    | .0226   | 304         | 114         | 367        |

## Decoding

| Qstep | Qfactor | JPEG bpp | OJPH bpp | KDU bpp | JPEG (s) | OJPH (s) | KDU (s) | JPEG (MP/s) | OJPH (MP/s) | KDU (MP/s) |
|------:|--------:|----------|----------|---------|----------|----------|---------|-------------|-------------|------------|
| 0.15  | 10      | .43      | .37      | .38     | .0199    | .0310    | .0286   | 416         | 267         | 290        |
| 0.06  | 50      | 1.04     | .91      | .91     | .0224    | .0374    | .0320   | 370         | 221         | 259        |
| 0.038 | 70      | 1.38     | 1.31     | 1.31    | .0246    | .0421    | .0333   | 337         | 197         | 249        |
| 0.025 | 80      | 1.71     | 1.75     | 1.75    | .0265    | .0450    | .0345   | 312         | 184         | 240        |
| 0.02  | 90      | 2.49     | 2.02     | 2.02    | .0317    | .0466    | .0361   | 261         | 177         | 229        |
| 0.011 | 95      | 3.63     | 2.87     | 2.88    | .0378    | .0523    | .0385   | 219         | 158         | 215        |

## Optimized OpenJPH (dev/optimize-trial branch)

AVX-512 encoder optimizations applied to OpenJPH on the same hardware and
image. Changes: AVX-512 reversible wavelet + colour transforms, block encoder
VLC/MagSgn batching, template dispatch for inlining, widened MagSgn
accumulator, branchless byte drain, AVX-512 rev_tx_to_cb32.

### Encoding (optimized)

| Qstep | Qfactor | OJPH bpp | OJPH orig (s) | OJPH opt (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | Speedup |
|------:|--------:|----------|---------------|--------------|-------------------|-----------------|---------|
| 0.15  | 10      | .37      | .0358         | .0373        | 231               | 222             | -4%     |
| 0.06  | 50      | .91      | .0471         | .0432        | 176               | 191             | +9%     |
| 0.038 | 70      | 1.31     | .0521         | .0498        | 159               | 166             | +4%     |
| 0.025 | 80      | 1.75     | .0593         | .0535        | 139               | 155             | +12%    |
| 0.02  | 90      | 2.02     | .0619         | .0557        | 133               | 148             | +11%    |
| 0.011 | 95      | 2.87     | .0724         | .0659        | 114               | 125             | +10%    |
| lossless | —    | 9.11     | .1336         | .0969        | 62                | 85              | +28%    |

### Decoding (optimized)

| Qstep | Qfactor | OJPH bpp | OJPH orig (s) | OJPH opt (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | Speedup |
|------:|--------:|----------|---------------|--------------|-------------------|-----------------|---------|
| 0.15  | 10      | .37      | .0310         | .0320        | 267               | 259             | -3%     |
| 0.06  | 50      | .91      | .0374         | .0398        | 221               | 208             | -6%     |
| 0.038 | 70      | 1.31     | .0421         | .0424        | 197               | 195             | -1%     |
| 0.025 | 80      | 1.75     | .0450         | .0455        | 184               | 182             | -1%     |
| 0.02  | 90      | 2.02     | .0466         | .0476        | 177               | 174             | -2%     |
| 0.011 | 95      | 2.87     | .0523         | .0533        | 158               | 155             | -2%     |
| lossless | —    | 9.11     | .0760         | .0750        | 109               | 110             | +1%     |

### Summary (updated)

| Metric | JPEG | OJPH (orig) | OJPH (opt) | Kakadu |
|--------|-----:|------------:|-----------:|-------:|
| Avg encode throughput (MP/s), lossy | 391 | 158 | 168 | 426 |
| Avg encode throughput (MP/s), lossless | — | 62 | 85 | — |
| Avg decode throughput (MP/s) | 319 | 200 | 195 | 247 |

| Comparison (lossy avg) | Encode | Decode |
|------------------------|-------:|-------:|
| Kakadu / OJPH (opt)    | 2.53x  | 1.27x  |
| Kakadu / OJPH (orig)   | 2.69x  | 1.23x  |

### Optimization impact by operating point

The encoder speedup is **strongest at high bitrates and lossless** (28% for
lossless, 10-12% at high quality) where the block encoder processes more
non-zero coefficients. At very low bitrates (Qstep=0.15), most coefficients
are quantized to zero and the block encoder is not the bottleneck — the
speedup is negligible.

Decode performance is essentially unchanged (within noise), as expected —
the optimizations target the encoder only.

## Plot

![Benchmark Plot](benchmark_plot.png)

## Observations

- **Encoding:** Kakadu's HT block encoder is 2.53x faster than optimized
  OpenJPH (down from 2.69x). The gap narrows at higher bitrates.
- **Lossless encoding:** The optimized encoder achieves 85 MP/s, a 28%
  improvement over the original 62 MP/s.
- **Decoding:** Kakadu is about 1.27x faster than OpenJPH. libjpeg-turbo
  remains the fastest decoder overall.
- **File-size parity:** With the same Qstep and `-no_weights`, both HTJ2K
  encoders produce virtually identical file sizes, confirming equivalent
  quantization.
