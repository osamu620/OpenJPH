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
| 0.15  | 10      | .38      | .0358         | .0290        | .0166   | 231               | 286             | 499        | +24%    |
| 0.06  | 50      | .92      | .0471         | .0331        | .0183   | 176               | 250             | 453        | +42%    |
| 0.038 | 70      | 1.31     | .0521         | .0357        | .0192   | 159               | 232             | 432        | +46%    |
| 0.025 | 80      | 1.75     | .0593         | .0383        | .0203   | 139               | 216             | 408        | +55%    |
| 0.02  | 90      | 2.02     | .0619         | .0397        | .0208   | 133               | 208             | 398        | +56%    |
| 0.011 | 95      | 2.88     | .0724         | .0448        | .0226   | 114               | 185             | 367        | +62%    |
| lossless | —    | 9.12     | .1336         | .0592        | .0275   | 62                | 140             | 301        | +126%   |

### Decoding (optimized)

| Qstep | Qfactor | OJPH bpp | OJPH orig (s) | OJPH opt (s) | KDU (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU (MP/s) |
|------:|--------:|----------|---------------|--------------|---------|-------------------|-----------------|------------|
| 0.15  | 10      | .38      | .0310         | .0311        | .0286   | 267               | 266             | 290        |
| 0.06  | 50      | .92      | .0374         | .0371        | .0320   | 221               | 223             | 259        |
| 0.038 | 70      | 1.31     | .0421         | .0395        | .0333   | 197               | 209             | 249        |
| 0.025 | 80      | 1.75     | .0450         | .0439        | .0345   | 184               | 189             | 240        |
| 0.02  | 90      | 2.02     | .0466         | .0457        | .0361   | 177               | 181             | 229        |
| 0.011 | 95      | 2.88     | .0523         | .0499        | .0385   | 158               | 166             | 215        |
| lossless | —    | 9.12     | .0760         | .0716        | .0510   | 109               | 116             | 162        |

### Summary (updated)

| Metric | JPEG | OJPH (orig) | OJPH (opt) | Kakadu |
|--------|-----:|------------:|-----------:|-------:|
| Avg encode throughput (MP/s), lossy | 391 | 159 | 230 | 427 |
| Encode throughput (MP/s), lossless | — | 62 | 140 | 301 |
| Avg decode throughput (MP/s), lossy | 319 | 201 | 206 | 247 |
| Decode throughput (MP/s), lossless | — | 109 | 116 | 162 |

| Comparison (lossy avg) | Encode | Decode |
|------------------------|-------:|-------:|
| Kakadu / OJPH (opt)    | 1.87x  | 1.21x  |
| Kakadu / OJPH (orig)   | 2.69x  | 1.23x  |

| Comparison (lossless)  | Encode | Decode |
|------------------------|-------:|-------:|
| Kakadu / OJPH (opt)    | 2.15x  | 1.40x  |
| Kakadu / OJPH (orig)   | 4.87x  | 1.50x  |

### Optimization impact by operating point

The encoder speedup is **strongest at high bitrates and lossless** (126% for
lossless, 24-62% at lossy operating points). The optimizations are purely
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
| Lossy encode (avg) | 1.87x | 1.0x |
| Lossless encode | 2.15x | 1.0x |
| Lossy decode (avg) | 1.21x | 1.0x |
| Lossless decode | 1.40x | 1.0x |

The codeblock encoder (`encode_codeblock`) remains the dominant cost
center at ~32% of total encode time.

## ElephantDream_4K (16-bit, 4096x2160)

| Item | Detail |
|------|--------|
| Image | `ElephantDream_4K.ppm` (4096 x 2160, 16-bit RGB) |
| Pixels | 8,847,360 (8.85 MP) |
| Qsteps | Finer geometric series (no JPEG-1 comparison needed for 16-bit) |

### Encoding (ElephantDream_4K)

| Qstep | bpp | OJPH orig (s) | OJPH opt (s) | KDU (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU (MP/s) | Speedup | Gap |
|------:|----:|--------------:|-------------:|--------:|-----------------:|----------------:|-----------:|--------:|----:|
| 0.5   | 0.02 | .0241       | .0241        | .0260   | 367              | 367             | 340        | +0%     | 0.93x |
| 0.3   | 0.03 | .0252       | .0243        | .0260   | 351              | 364             | 340        | +4%     | 0.93x |
| 0.2   | 0.05 | .0270       | .0258        | .0264   | 327              | 342             | 335        | +5%     | 0.98x |
| 0.15  | 0.08 | .0287       | .0273        | .0268   | 308              | 324             | 330        | +5%     | 1.02x |
| 0.1   | 0.13 | .0317       | .0289        | .0272   | 279              | 306             | 325        | +10%    | 1.06x |
| 0.07  | 0.20 | .0347       | .0317        | .0280   | 254              | 279             | 315        | +9%     | 1.13x |
| 0.05  | 0.29 | .0375       | .0329        | .0285   | 235              | 269             | 310        | +14%    | 1.15x |
| 0.03  | 0.44 | .0416       | .0342        | .0287   | 212              | 258             | 308        | +22%    | 1.19x |
| 0.02  | 0.67 | .0454       | .0352        | .0300   | 194              | 251             | 294        | +29%    | 1.17x |
| 0.01  | 1.10 | .0494       | .0364        | .0301   | 179              | 242             | 293        | +36%    | 1.21x |
| 0.005 | 1.46 | .0515       | .0383        | .0313   | 171              | 231             | 282        | +34%    | 1.22x |
| lossless | 18.54 | .1575  | .0780        | .0501   | 56               | 113             | 176        | +102%   | 1.56x |

### Decoding (ElephantDream_4K)

Kakadu timing is `-cpu 0` decoding to raw (no PPM byte-swap overhead).
OpenJPH `Elapsed time` includes PPM writing.

| Qstep | bpp | OJPH orig (s) | OJPH opt (s) | KDU raw (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU raw (MP/s) | Gap |
|------:|----:|--------------:|-------------:|------------:|-----------------:|----------------:|---------------:|----:|
| 0.5   | 0.02 | .0271       | .0283        | .0344       | 326              | 312             | 257            | 0.82x |
| 0.3   | 0.03 | .0282       | .0290        | .0346       | 313              | 305             | 255            | 0.84x |
| 0.2   | 0.05 | .0299       | .0304        | .0348       | 295              | 291             | 254            | 0.87x |
| 0.15  | 0.08 | .0310       | .0307        | .0354       | 285              | 287             | 249            | 0.87x |
| 0.1   | 0.13 | .0338       | .0347        | .0367       | 261              | 254             | 241            | 0.95x |
| 0.07  | 0.20 | .0360       | .0358        | .0377       | 245              | 247             | 234            | 0.95x |
| 0.05  | 0.29 | .0380       | .0366        | .0383       | 232              | 241             | 231            | 0.96x |
| 0.03  | 0.44 | .0410       | .0395        | .0394       | 215              | 223             | 224            | 1.00x |
| 0.02  | 0.67 | .0432       | .0429        | .0403       | 204              | 206             | 219            | 1.06x |
| 0.01  | 1.10 | .0452       | .0444        | .0417       | 195              | 199             | 212            | 1.07x |
| 0.005 | 1.46 | .0462       | .0447        | .0424       | 191              | 197             | 208            | 1.06x |
| lossless | 18.54 | .1056  | .0985        | .0581       | 83               | 89              | 152            | 1.70x |

Note: Gap < 1.0x means OpenJPH is faster than Kakadu. OpenJPH decode
includes PPM writing overhead while KDU raw does not, so the actual
OJPH advantage at low bitrates is even larger.

### Summary (ElephantDream_4K)

| Metric | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU (MP/s) | Gap (KDU/opt) |
|--------|------------------:|----------------:|-----------:|---------------:|
| Avg encode throughput, lossy | 261 | 294 | 316 | 1.09x |
| Encode throughput, lossless | 56 | 113 | 176 | 1.56x |
| Avg decode throughput, lossy (KDU raw) | 260 | 252 | 235 | **0.95x** |
| Decode throughput, lossless (KDU raw) | 83 | 89 | 152 | 1.70x |

OpenJPH opt is **faster than Kakadu for lossy 16-bit decoding** (0.95x gap
= OJPH 5% faster on average), even with OJPH including PPM write overhead.
The encoding gap is 1.09x for lossy average. At low bitrates (Qstep >= 0.2),
OpenJPH encoding is **equal to or faster than Kakadu**. Lossless encode gap
narrowed to 1.56x.

## Plots

![Benchmark Plot — u10_8bit](benchmark_plot.png)
![Benchmark Plot — ElephantDream_4K](benchmark_plot_elephant.png)

## Observations

- **Encoding (8-bit):** Kakadu is 1.87x faster for lossy (down from 2.69x
  original). Lossless gap narrowed to 2.15x (+126% speedup vs original).
- **Encoding (16-bit):** Kakadu gap is only 1.09x for lossy average. At
  low bitrates (Qstep >= 0.2), OpenJPH is **equal to or faster than
  Kakadu**. Lossless gap narrowed to 1.56x (+102% speedup vs original).
- **Lossless encoding:** 140 MP/s on 8-bit (+126% vs original), 113 MP/s on
  16-bit (+102%). The codeblock encoder remains the dominant cost center.
- **Decoding (8-bit):** Kakadu leads by ~1.21x for lossy, 1.40x for lossless.
- **Decoding (16-bit):** OpenJPH opt is **faster than Kakadu** for lossy
  decoding (0.95x gap = OJPH 5% faster on average), even though OJPH timing
  includes PPM write overhead while KDU raw does not. Only lossless decode
  shows Kakadu ahead (1.70x).
- **File-size parity:** With the same Qstep and `-no_weights`, both HTJ2K
  encoders produce virtually identical file sizes.
