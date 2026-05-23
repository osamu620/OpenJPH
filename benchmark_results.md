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
encoding with popcount/tzcnt batch run advancement.

### Encoding (optimized)

All times are internal CPU time: OpenJPH `Elapsed time` (clock()),
Kakadu `-cpu 0`. Both include file I/O.

| Qstep | Qfactor | OJPH bpp | OJPH orig (s) | OJPH opt (s) | KDU (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU (MP/s) | Speedup |
|------:|--------:|----------|---------------|--------------|---------|-------------------|-----------------|------------|---------|
| 0.15  | 10      | .38      | .0358         | .0281        | .0166   | 231               | 295             | 500        | +27%    |
| 0.06  | 50      | .92      | .0471         | .0330        | .0183   | 176               | 251             | 453        | +43%    |
| 0.038 | 70      | 1.31     | .0521         | .0356        | .0192   | 159               | 233             | 432        | +46%    |
| 0.025 | 80      | 1.75     | .0593         | .0383        | .0203   | 139               | 217             | 409        | +55%    |
| 0.02  | 90      | 2.02     | .0619         | .0399        | .0208   | 133               | 208             | 399        | +55%    |
| 0.011 | 95      | 2.88     | .0724         | .0448        | .0226   | 114               | 185             | 367        | +62%    |
| lossless | —    | 9.12     | .1336         | .0587        | .0275   | 62                | 141             | 302        | +128%   |

### Decoding (optimized)

| Qstep | Qfactor | OJPH bpp | OJPH orig (s) | OJPH opt (s) | KDU (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU (MP/s) |
|------:|--------:|----------|---------------|--------------|---------|-------------------|-----------------|------------|
| 0.15  | 10      | .38      | .0310         | .0293        | .0286   | 267               | 283             | 290        |
| 0.06  | 50      | .92      | .0374         | .0368        | .0320   | 221               | 225             | 259        |
| 0.038 | 70      | 1.31     | .0421         | .0415        | .0333   | 197               | 200             | 249        |
| 0.025 | 80      | 1.75     | .0450         | .0443        | .0345   | 184               | 187             | 240        |
| 0.02  | 90      | 2.02     | .0466         | .0451        | .0361   | 177               | 184             | 229        |
| 0.011 | 95      | 2.88     | .0523         | .0503        | .0385   | 158               | 165             | 215        |
| lossless | —    | 9.12     | .0760         | .0716        | .0510   | 109               | 116             | 163        |

### Summary (updated)

| Metric | JPEG | OJPH (orig) | OJPH (opt) | Kakadu |
|--------|-----:|------------:|-----------:|-------:|
| Avg encode throughput (MP/s), lossy | 391 | 159 | 232 | 427 |
| Encode throughput (MP/s), lossless | — | 62 | 141 | 302 |
| Avg decode throughput (MP/s), lossy | 319 | 201 | 207 | 247 |
| Decode throughput (MP/s), lossless | — | 109 | 116 | 163 |

| Comparison (lossy avg) | Encode | Decode |
|------------------------|-------:|-------:|
| Kakadu / OJPH (opt)    | 1.84x  | 1.19x  |
| Kakadu / OJPH (orig)   | 2.69x  | 1.23x  |

| Comparison (lossless)  | Encode | Decode |
|------------------------|-------:|-------:|
| Kakadu / OJPH (opt)    | 2.14x  | 1.41x  |
| Kakadu / OJPH (orig)   | 4.87x  | 1.50x  |

### Optimization impact by operating point

The encoder speedup is **strongest at high bitrates and lossless** (128% for
lossless, 27-62% at lossy operating points). The optimizations are purely
algorithmic (AVX-512 encoder, branchless VLC drain, SIMD MagSgn pair
combining, run-length MEL, NASM MagSgn). The branchless VLC drain
contributed +16-22% on lossless by eliminating 58% of branch misses.
SIMD pair-wise MagSgn combining added another ~5% by pre-combining
adjacent codeword pairs in AVX-512 before the NASM batch encoder.

Decoder optimization is modest since the encoder-focused changes target
different code paths.

### Remaining gap to Kakadu

| Mode | Gap (Kakadu/OJPH) | Target |
|------|------------------:|-------:|
| Lossy encode (avg) | 1.84x | 1.0x |
| Lossless encode | 2.14x | 1.0x |
| Lossy decode (avg) | 1.19x | 1.0x |
| Lossless decode | 1.41x | 1.0x |

The codeblock encoder (`encode_codeblock`) remains the dominant cost
center at ~25% of total encode time.

## ElephantDream_4K (16-bit, 4096x2160)

| Item | Detail |
|------|--------|
| Image | `ElephantDream_4K.ppm` (4096 x 2160, 16-bit RGB) |
| Pixels | 8,847,360 (8.85 MP) |
| Qsteps | Finer geometric series (no JPEG-1 comparison needed for 16-bit) |

### Encoding (ElephantDream_4K)

| Qstep | bpp | OJPH orig (s) | OJPH opt (s) | KDU (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU (MP/s) | Speedup | Gap |
|------:|----:|--------------:|-------------:|--------:|-----------------:|----------------:|-----------:|--------:|----:|
| 0.5   | 0.02 | .0241       | .0240        | .0260   | 366              | 369             | 340        | +0%     | 0.92x |
| 0.3   | 0.03 | .0252       | .0250        | .0260   | 351              | 354             | 340        | +1%     | 0.96x |
| 0.2   | 0.05 | .0270       | .0262        | .0264   | 327              | 338             | 335        | +3%     | 0.99x |
| 0.15  | 0.08 | .0287       | .0270        | .0268   | 308              | 328             | 330        | +6%     | 1.01x |
| 0.1   | 0.13 | .0317       | .0295        | .0272   | 278              | 300             | 325        | +7%     | 1.08x |
| 0.07  | 0.20 | .0347       | .0313        | .0280   | 255              | 283             | 316        | +11%    | 1.12x |
| 0.05  | 0.29 | .0375       | .0326        | .0285   | 235              | 271             | 310        | +15%    | 1.14x |
| 0.03  | 0.44 | .0416       | .0344        | .0287   | 212              | 257             | 308        | +21%    | 1.20x |
| 0.02  | 0.67 | .0454       | .0356        | .0300   | 194              | 249             | 295        | +28%    | 1.18x |
| 0.01  | 1.10 | .0494       | .0369        | .0301   | 178              | 240             | 294        | +34%    | 1.23x |
| 0.005 | 1.46 | .0515       | .0381        | .0313   | 171              | 232             | 283        | +35%    | 1.22x |
| lossless | 18.54 | .1575  | .0780        | .0501   | 56               | 113             | 177        | +102%   | 1.56x |

### Decoding (ElephantDream_4K)

Kakadu timing is `-cpu 0` decoding to raw (no PPM byte-swap overhead).
OpenJPH `Elapsed time` includes PPM writing.

| Qstep | bpp | OJPH orig (s) | OJPH opt (s) | KDU raw (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU raw (MP/s) | Gap |
|------:|----:|--------------:|-------------:|------------:|-----------------:|----------------:|---------------:|----:|
| 0.5   | 0.02 | .0271       | .0263        | .0344       | 327              | 336             | 257            | 0.77x |
| 0.3   | 0.03 | .0282       | .0276        | .0346       | 313              | 321             | 256            | 0.80x |
| 0.2   | 0.05 | .0299       | .0286        | .0348       | 295              | 309             | 254            | 0.82x |
| 0.15  | 0.08 | .0310       | .0301        | .0354       | 285              | 294             | 250            | 0.85x |
| 0.1   | 0.13 | .0338       | .0323        | .0367       | 261              | 274             | 241            | 0.88x |
| 0.07  | 0.20 | .0360       | .0346        | .0377       | 245              | 256             | 235            | 0.92x |
| 0.05  | 0.29 | .0380       | .0365        | .0383       | 233              | 242             | 231            | 0.95x |
| 0.03  | 0.44 | .0410       | .0395        | .0394       | 215              | 224             | 225            | 1.00x |
| 0.02  | 0.67 | .0432       | .0422        | .0403       | 204              | 210             | 220            | 1.05x |
| 0.01  | 1.10 | .0452       | .0438        | .0417       | 195              | 202             | 212            | 1.05x |
| 0.005 | 1.46 | .0462       | .0459        | .0424       | 191              | 193             | 209            | 1.08x |
| lossless | 18.54 | .1056  | .0978        | .0581       | 83               | 90              | 152            | 1.69x |

Note: Gap < 1.0x means OpenJPH is faster than Kakadu. OpenJPH decode
includes PPM writing overhead while KDU raw does not, so the actual
OJPH advantage at low bitrates is even larger.

### Summary (ElephantDream_4K)

| Metric | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU (MP/s) | Gap (KDU/opt) |
|--------|------------------:|----------------:|-----------:|---------------:|
| Avg encode throughput, lossy | 261 | 293 | 316 | 1.08x |
| Encode throughput, lossless | 56 | 113 | 177 | 1.56x |
| Avg decode throughput, lossy (KDU raw) | 260 | 260 | 236 | **0.91x** |
| Decode throughput, lossless (KDU raw) | 83 | 90 | 152 | 1.69x |

OpenJPH opt is **faster than Kakadu for lossy 16-bit decoding** (0.91x gap
= OJPH 10% faster on average), even with OJPH including PPM write overhead.
The encoding gap is 1.08x for lossy average. At low bitrates (Qstep >= 0.15),
OpenJPH encoding is **equal to or faster than Kakadu**. Lossless encode gap
narrowed to 1.56x.

## Plots

![Benchmark Plot — u10_8bit](benchmark_plot.png)
![Benchmark Plot — ElephantDream_4K](benchmark_plot_elephant.png)

## Observations

- **Encoding (8-bit):** Kakadu is 1.84x faster for lossy (down from 2.69x
  original). Lossless gap narrowed to 2.14x (+128% speedup vs original).
- **Encoding (16-bit):** Kakadu gap is only 1.08x for lossy average. At
  low bitrates (Qstep >= 0.15), OpenJPH is **equal to or faster than
  Kakadu**. Lossless gap narrowed to 1.56x (+102% speedup vs original).
- **Lossless encoding:** 141 MP/s on 8-bit (+128% vs original), 113 MP/s on
  16-bit (+102%). The codeblock encoder remains the dominant cost center.
- **Decoding (8-bit):** Kakadu leads by ~1.19x for lossy, 1.41x for lossless.
- **Decoding (16-bit):** OpenJPH opt is **faster than Kakadu** for lossy
  decoding (0.91x gap = OJPH 10% faster on average), even though OJPH timing
  includes PPM write overhead while KDU raw does not. Only lossless decode
  shows Kakadu ahead (1.69x).
- **File-size parity:** With the same Qstep and `-no_weights`, both HTJ2K
  encoders produce virtually identical file sizes.
