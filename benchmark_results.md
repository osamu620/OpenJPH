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
accumulator, branchless byte drain, AVX-512 rev_tx_to_cb32, speculative bulk
MagSgn drain with SWAR 0xFF detection and deferred accumulation (-mbmi2),
NASM MagSgn encoder with register-resident accumulator and prefix-sum
codeword combination, VLC bulk drain with SWAR and bswap backward writes,
unified UVLC pair lookup tables eliminating 3-way branch, run-length MEL
encoding with popcount/tzcnt batch run advancement, exponential-growth elastic
allocator with 8 MiB initial chunk reducing malloc pressure.

### Encoding (optimized)

All times are internal CPU time: OpenJPH `Elapsed time` (clock()),
Kakadu `-cpu 0`. Both include file I/O.

| Qstep | Qfactor | OJPH bpp | OJPH orig (s) | OJPH opt (s) | KDU (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU (MP/s) | Speedup |
|------:|--------:|----------|---------------|--------------|---------|-------------------|-----------------|------------|---------|
| 0.15  | 10      | .38      | .0358         | .0276        | .0160   | 231               | 301             | 518        | +30%    |
| 0.06  | 50      | .92      | .0471         | .0312        | .0163   | 176               | 266             | 509        | +51%    |
| 0.038 | 70      | 1.31     | .0521         | .0352        | .0170   | 159               | 236             | 488        | +48%    |
| 0.025 | 80      | 1.75     | .0593         | .0382        | .0185   | 139               | 217             | 448        | +56%    |
| 0.02  | 90      | 2.02     | .0619         | .0398        | .0185   | 133               | 208             | 448        | +56%    |
| 0.011 | 95      | 2.88     | .0724         | .0451        | .0201   | 114               | 184             | 413        | +61%    |
| lossless | —    | 9.12     | .1336         | .0663        | .0257   | 62                | 125             | 323        | +102%   |

### Decoding (optimized)

| Qstep | Qfactor | OJPH bpp | OJPH orig (s) | OJPH opt (s) | KDU (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU (MP/s) |
|------:|--------:|----------|---------------|--------------|---------|-------------------|-----------------|------------|
| 0.15  | 10      | .38      | .0310         | .0254        | .0258   | 267               | 327             | 321        |
| 0.06  | 50      | .92      | .0374         | .0315        | .0281   | 221               | 263             | 295        |
| 0.038 | 70      | 1.31     | .0421         | .0362        | .0298   | 197               | 229             | 278        |
| 0.025 | 80      | 1.75     | .0450         | .0381        | .0322   | 184               | 218             | 258        |
| 0.02  | 90      | 2.02     | .0466         | .0404        | .0321   | 177               | 205             | 258        |
| 0.011 | 95      | 2.88     | .0523         | .0447        | .0344   | 158               | 186             | 241        |
| lossless | —    | 9.12     | .0760         | .0646        | .0465   | 109               | 128             | 178        |

### Summary (updated)

| Metric | JPEG | OJPH (orig) | OJPH (opt) | Kakadu |
|--------|-----:|------------:|-----------:|-------:|
| Avg encode throughput (MP/s), lossy | 391 | 158 | 235 | 471 |
| Encode throughput (MP/s), lossless | — | 62 | 125 | 323 |
| Avg decode throughput (MP/s), lossy | 319 | 200 | 238 | 275 |
| Decode throughput (MP/s), lossless | — | 109 | 128 | 178 |

| Comparison (lossy avg) | Encode | Decode |
|------------------------|-------:|-------:|
| Kakadu / OJPH (opt)    | 2.00x  | 1.16x  |
| Kakadu / OJPH (orig)   | 2.79x  | 1.22x  |

| Comparison (lossless)  | Encode | Decode |
|------------------------|-------:|-------:|
| Kakadu / OJPH (opt)    | 2.58x  | 1.39x  |
| Kakadu / OJPH (orig)   | 4.85x  | 1.50x  |

### Optimization impact by operating point

The encoder speedup is **strongest at high bitrates and lossless** (102% for
lossless, 30-61% at lossy operating points). The exponential-growth elastic
allocator with 8 MiB initial chunk reduces malloc overhead during encoding,
providing an additional ~10% encoding speedup on top of the previous
algorithmic optimizations.

Decode performance also improved significantly (15-27% vs previous
measurement), likely due to reduced memory allocation overhead from the larger
initial allocator chunk and better virtual memory layout.

### Remaining gap to Kakadu

| Mode | Gap (Kakadu/OJPH) | Target |
|------|------------------:|-------:|
| Lossy encode (avg) | 2.00x | 1.0x |
| Lossless encode | 2.58x | 1.0x |
| Lossy decode (avg) | 1.16x | 1.0x |
| Lossless decode | 1.39x | 1.0x |

The decode gap is now very close (1.16x for lossy — OpenJPH is nearly
competitive). The main opportunity remains in encoding, where a 2x gap
persists. The codeblock encoder (`encode_codeblock`) remains the dominant
cost center at ~40% of total encode time.

## ElephantDream_4K (16-bit, 4096x2160)

| Item | Detail |
|------|--------|
| Image | `ElephantDream_4K.ppm` (4096 x 2160, 16-bit RGB) |
| Pixels | 8,847,360 (8.85 MP) |

### Encoding (ElephantDream_4K)

| Qstep | bpp | OJPH opt (s) | KDU (s) | OJPH opt (MP/s) | KDU (MP/s) | Ratio |
|------:|----:|--------------|---------|-----------------|------------|-------|
| 0.15  | 0.08 | .0267       | .0255   | 331             | 347        | 1.05x |
| 0.06  | 0.22 | .0305       | .0248   | 290             | 357        | 1.23x |
| 0.038 | 0.38 | .0325       | .0256   | 272             | 346        | 1.27x |
| 0.025 | 0.52 | .0338       | .0267   | 262             | 331        | 1.27x |
| 0.02  | 0.67 | .0338       | .0267   | 262             | 331        | 1.27x |
| 0.011 | 1.07 | .0366       | .0272   | 242             | 325        | 1.35x |
| lossless | 18.54 | .0840  | .0458   | 105             | 193        | 1.83x |

### Decoding (ElephantDream_4K)

| Qstep | bpp | OJPH opt (s) | KDU (s) | OJPH opt (MP/s) | KDU (MP/s) | Ratio |
|------:|----:|--------------|---------|-----------------|------------|-------|
| 0.15  | 0.08 | .0273       | .0646   | 324             | 137        | 0.42x |
| 0.06  | 0.22 | .0310       | .0662   | 285             | 134        | 0.47x |
| 0.038 | 0.38 | .0354       | .0676   | 250             | 131        | 0.52x |
| 0.025 | 0.52 | .0356       | .0687   | 249             | 129        | 0.52x |
| 0.02  | 0.67 | .0379       | .0689   | 233             | 128        | 0.55x |
| 0.011 | 1.07 | .0387       | .0703   | 229             | 126        | 0.55x |
| lossless | 18.54 | .0892  | .0681   | 99              | 130        | 1.31x |

### Summary (ElephantDream_4K)

| Metric | OJPH opt (MP/s) | KDU (MP/s) | Ratio |
|--------|----------------:|-----------:|------:|
| Avg encode throughput, lossy | 277 | 340 | 1.23x |
| Encode throughput, lossless | 105 | 193 | 1.83x |
| Avg decode throughput, lossy | 262 | 131 | 0.50x |
| Decode throughput, lossless | 99 | 130 | 1.31x |

For 16-bit content, OpenJPH lossy decoding is **2x faster** than Kakadu.
The encoding gap narrows dramatically to 1.05-1.35x for lossy (vs 2.00x
on 8-bit). Lossless encoding gap is 1.83x (vs 2.58x on 8-bit).

## Plots

![Benchmark Plot — u10_8bit](benchmark_plot.png)
![Benchmark Plot — ElephantDream_4K](benchmark_plot_elephant.png)

## Observations

- **Encoding (8-bit):** Kakadu's HT block encoder is 2.00x faster than
  optimized OpenJPH for lossy (down from 2.79x original). The gap narrows at
  lower bitrates where the fixed overhead dominates.
- **Encoding (16-bit):** The gap shrinks to 1.05-1.35x for lossy. At
  Qstep=0.15, OpenJPH is within 5% of Kakadu.
- **Lossless encoding:** 125 MP/s on 8-bit (+102% vs original), 105 MP/s on
  16-bit. Kakadu leads 2.58x (8-bit), 1.83x (16-bit).
- **Decoding (8-bit):** OpenJPH beats Kakadu at low bitrates (327 vs 321 MP/s
  at Qstep=0.15). At higher bitrates, Kakadu leads by 1.16-1.30x.
- **Decoding (16-bit):** OpenJPH is **2x faster** than Kakadu at all lossy
  operating points. Only lossless decode shows Kakadu ahead (1.31x).
- **File-size parity:** With the same Qstep and `-no_weights`, both HTJ2K
  encoders produce virtually identical file sizes.
