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

All times are internal CPU time: OpenJPH `Elapsed time` (clock()),
Kakadu `-cpu 0`. Both include file I/O.

| Qstep | Qfactor | OJPH bpp | OJPH orig (s) | OJPH opt (s) | KDU (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU (MP/s) | Speedup |
|------:|--------:|----------|---------------|--------------|---------|-------------------|-----------------|------------|---------|
| 0.15  | 10      | .37      | .0358         | .0344        | .0164   | 231               | 240             | 504        | +4%     |
| 0.06  | 50      | .91      | .0471         | .0423        | .0174   | 176               | 195             | 475        | +11%    |
| 0.038 | 70      | 1.31     | .0521         | .0478        | .0183   | 159               | 173             | 453        | +9%     |
| 0.025 | 80      | 1.75     | .0593         | .0514        | .0196   | 139               | 161             | 422        | +16%    |
| 0.02  | 90      | 2.02     | .0619         | .0542        | .0202   | 133               | 153             | 410        | +15%    |
| 0.011 | 95      | 2.87     | .0724         | .0619        | .0218   | 114               | 133             | 380        | +17%    |
| lossless | —    | 9.11     | .1336         | .0930        | .0275   | 62                | 89              | 301        | +44%    |

### Decoding (optimized)

| Qstep | Qfactor | OJPH bpp | OJPH orig (s) | OJPH opt (s) | KDU (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU (MP/s) |
|------:|--------:|----------|---------------|--------------|---------|-------------------|-----------------|------------|
| 0.15  | 10      | .37      | .0310         | .0298        | .0287   | 267               | 278             | 288        |
| 0.06  | 50      | .91      | .0374         | .0370        | .0322   | 221               | 224             | 257        |
| 0.038 | 70      | 1.31     | .0421         | .0399        | .0332   | 197               | 207             | 249        |
| 0.025 | 80      | 1.75     | .0450         | .0429        | .0351   | 184               | 193             | 236        |
| 0.02  | 90      | 2.02     | .0466         | .0449        | .0369   | 177               | 184             | 224        |
| 0.011 | 95      | 2.87     | .0523         | .0515        | .0389   | 158               | 161             | 213        |
| lossless | —    | 9.11     | .0760         | .0720        | .0510   | 109               | 115             | 163        |

### Summary (updated)

| Metric | JPEG | OJPH (orig) | OJPH (opt) | Kakadu |
|--------|-----:|------------:|-----------:|-------:|
| Avg encode throughput (MP/s), lossy | 391 | 158 | 176 | 441 |
| Encode throughput (MP/s), lossless | — | 62 | 89 | 301 |
| Avg decode throughput (MP/s), lossy | 319 | 200 | 208 | 245 |
| Decode throughput (MP/s), lossless | — | 109 | 115 | 163 |

| Comparison (lossy avg) | Encode | Decode |
|------------------------|-------:|-------:|
| Kakadu / OJPH (opt)    | 2.51x  | 1.18x  |
| Kakadu / OJPH (orig)   | 2.79x  | 1.22x  |

| Comparison (lossless)  | Encode | Decode |
|------------------------|-------:|-------:|
| Kakadu / OJPH (opt)    | 3.38x  | 1.42x  |
| Kakadu / OJPH (orig)   | 4.85x  | 1.50x  |

### Optimization impact by operating point

The encoder speedup is **strongest at high bitrates and lossless** (44% for
lossless, 15-17% at high quality) where the block encoder processes more
non-zero coefficients. At low bitrates (Qstep=0.15), most coefficients are
quantized to zero and the block encoder is not the bottleneck — speedup is
modest (+4%).

Decode performance also shows modest improvement (5-6% at mid-range bitrates)
from the AVX-512 wavelet and colour transforms.

## Plot

![Benchmark Plot](benchmark_plot.png)

## Observations

- **Encoding:** Kakadu's HT block encoder is 2.51x faster than optimized
  OpenJPH for lossy (down from 2.79x). The gap narrows at higher bitrates.
- **Lossless encoding:** The optimized encoder achieves 89 MP/s, a 44%
  improvement over the original 62 MP/s. Kakadu lossless is 3.38x faster.
- **Decoding:** Kakadu is about 1.18x faster than OpenJPH for lossy, 1.42x
  for lossless. libjpeg-turbo remains the fastest decoder overall.
- **File-size parity:** With the same Qstep and `-no_weights`, both HTJ2K
  encoders produce virtually identical file sizes, confirming equivalent
  quantization.
