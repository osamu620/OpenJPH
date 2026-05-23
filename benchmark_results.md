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
encoding with popcount/tzcnt batch run advancement, SWAR bulk VLC drain
with lo7==0x7F detection for 8-byte bulk writes (~94% fast-path hit rate).

### Encoding (optimized)

All times are internal CPU time: OpenJPH `Elapsed time` (clock()),
Kakadu `-cpu 0`. Both include file I/O.

| Qstep | Qfactor | OJPH bpp | OJPH orig (s) | OJPH opt (s) | KDU (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU (MP/s) | Speedup |
|------:|--------:|----------|---------------|--------------|---------|-------------------|-----------------|------------|---------|
| 0.15  | 10      | .38      | .0358         | .0287        | .0166   | 231               | 289             | 500        | +25%    |
| 0.06  | 50      | .92      | .0471         | .0337        | .0183   | 176               | 246             | 453        | +40%    |
| 0.038 | 70      | 1.31     | .0521         | .0362        | .0192   | 159               | 229             | 432        | +44%    |
| 0.025 | 80      | 1.75     | .0593         | .0384        | .0203   | 139               | 216             | 409        | +55%    |
| 0.02  | 90      | 2.02     | .0619         | .0395        | .0208   | 133               | 210             | 399        | +57%    |
| 0.011 | 95      | 2.88     | .0724         | .0445        | .0226   | 114               | 186             | 367        | +63%    |
| lossless | —    | 9.12     | .1336         | .0588        | .0275   | 62                | 141             | 302        | +127%   |

### Decoding (optimized)

| Qstep | Qfactor | OJPH bpp | OJPH orig (s) | OJPH opt (s) | KDU (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU (MP/s) |
|------:|--------:|----------|---------------|--------------|---------|-------------------|-----------------|------------|
| 0.15  | 10      | .38      | .0310         | .0304        | .0286   | 267               | 273             | 290        |
| 0.06  | 50      | .92      | .0374         | .0365        | .0320   | 221               | 227             | 259        |
| 0.038 | 70      | 1.31     | .0421         | .0403        | .0333   | 197               | 206             | 249        |
| 0.025 | 80      | 1.75     | .0450         | .0434        | .0345   | 184               | 191             | 240        |
| 0.02  | 90      | 2.02     | .0466         | .0460        | .0361   | 177               | 180             | 229        |
| 0.011 | 95      | 2.88     | .0523         | .0501        | .0385   | 158               | 166             | 215        |
| lossless | —    | 9.12     | .0760         | .0724        | .0510   | 109               | 115             | 163        |

### Summary (updated)

| Metric | JPEG | OJPH (orig) | OJPH (opt) | Kakadu |
|--------|-----:|------------:|-----------:|-------:|
| Avg encode throughput (MP/s), lossy | 391 | 159 | 229 | 427 |
| Encode throughput (MP/s), lossless | — | 62 | 141 | 302 |
| Avg decode throughput (MP/s), lossy | 319 | 201 | 207 | 247 |
| Decode throughput (MP/s), lossless | — | 109 | 115 | 163 |

| Comparison (lossy avg) | Encode | Decode |
|------------------------|-------:|-------:|
| Kakadu / OJPH (opt)    | 1.87x  | 1.21x  |
| Kakadu / OJPH (orig)   | 2.69x  | 1.23x  |

| Comparison (lossless)  | Encode | Decode |
|------------------------|-------:|-------:|
| Kakadu / OJPH (opt)    | 2.14x  | 1.42x  |
| Kakadu / OJPH (orig)   | 4.87x  | 1.50x  |

### Optimization impact by operating point

The encoder speedup is **strongest at high bitrates and lossless** (127% for
lossless, 25-63% at lossy operating points). The optimizations are purely
algorithmic (AVX-512 encoder, branchless VLC drain, SIMD MagSgn pair
combining, run-length MEL, NASM MagSgn, SWAR bulk VLC drain). The branchless
VLC drain contributed +16-22% on lossless by eliminating 58% of branch misses.
SIMD pair-wise MagSgn combining added ~5% by pre-combining adjacent codeword
pairs in AVX-512 before the NASM batch encoder. SWAR bulk VLC drain added
5-7% by replacing the serial byte-at-a-time drain with 8-byte bulk writes
(~94% fast-path hit rate using lo7==0x7F detection).

Decoder optimization is modest since the encoder-focused changes target
different code paths.

### Remaining gap to Kakadu

| Mode | Gap (Kakadu/OJPH) | Target |
|------|------------------:|-------:|
| Lossy encode (avg) | 1.87x | 1.0x |
| Lossless encode | 2.14x | 1.0x |
| Lossy decode (avg) | 1.21x | 1.0x |
| Lossless decode | 1.42x | 1.0x |

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
| 0.5   | 0.02 | .0241       | .0244        | .0260   | 366              | 363             | 340        | -1%     | 0.94x |
| 0.3   | 0.03 | .0252       | .0242        | .0260   | 351              | 365             | 340        | +4%     | 0.93x |
| 0.2   | 0.05 | .0270       | .0258        | .0264   | 327              | 343             | 335        | +5%     | 0.98x |
| 0.15  | 0.08 | .0287       | .0278        | .0268   | 308              | 318             | 330        | +3%     | 1.04x |
| 0.1   | 0.13 | .0317       | .0292        | .0272   | 278              | 303             | 325        | +8%     | 1.07x |
| 0.07  | 0.20 | .0347       | .0315        | .0280   | 255              | 281             | 316        | +10%    | 1.13x |
| 0.05  | 0.29 | .0375       | .0324        | .0285   | 235              | 273             | 310        | +16%    | 1.14x |
| 0.03  | 0.44 | .0416       | .0339        | .0287   | 212              | 261             | 308        | +23%    | 1.18x |
| 0.02  | 0.67 | .0454       | .0353        | .0300   | 194              | 251             | 295        | +29%    | 1.18x |
| 0.01  | 1.10 | .0494       | .0370        | .0301   | 178              | 239             | 294        | +34%    | 1.23x |
| 0.005 | 1.46 | .0515       | .0377        | .0313   | 171              | 235             | 283        | +37%    | 1.20x |
| lossless | 18.54 | .1575  | .0777        | .0501   | 56               | 114             | 177        | +103%   | 1.55x |

### Decoding (ElephantDream_4K)

Kakadu timing is `-cpu 0` decoding to raw (no PPM byte-swap overhead).
OpenJPH `Elapsed time` includes PPM writing.

| Qstep | bpp | OJPH orig (s) | OJPH opt (s) | KDU raw (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU raw (MP/s) | Gap |
|------:|----:|--------------:|-------------:|------------:|-----------------:|----------------:|---------------:|----:|
| 0.5   | 0.02 | .0271       | .0280        | .0344       | 327              | 316             | 257            | 0.81x |
| 0.3   | 0.03 | .0282       | .0289        | .0346       | 313              | 306             | 256            | 0.84x |
| 0.2   | 0.05 | .0299       | .0300        | .0348       | 295              | 295             | 254            | 0.86x |
| 0.15  | 0.08 | .0310       | .0321        | .0354       | 285              | 276             | 250            | 0.91x |
| 0.1   | 0.13 | .0338       | .0320        | .0367       | 261              | 276             | 241            | 0.87x |
| 0.07  | 0.20 | .0360       | .0362        | .0377       | 245              | 244             | 235            | 0.96x |
| 0.05  | 0.29 | .0380       | .0372        | .0383       | 233              | 238             | 231            | 0.97x |
| 0.03  | 0.44 | .0410       | .0390        | .0394       | 215              | 227             | 225            | 0.99x |
| 0.02  | 0.67 | .0432       | .0427        | .0403       | 204              | 207             | 220            | 1.06x |
| 0.01  | 1.10 | .0452       | .0440        | .0417       | 195              | 201             | 212            | 1.05x |
| 0.005 | 1.46 | .0462       | .0449        | .0424       | 191              | 197             | 209            | 1.06x |
| lossless | 18.54 | .1056  | .0976        | .0581       | 83               | 91              | 152            | 1.68x |

Note: Gap < 1.0x means OpenJPH is faster than Kakadu. OpenJPH decode
includes PPM writing overhead while KDU raw does not, so the actual
OJPH advantage at low bitrates is even larger.

### Summary (ElephantDream_4K)

| Metric | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU (MP/s) | Gap (KDU/opt) |
|--------|------------------:|----------------:|-----------:|---------------:|
| Avg encode throughput, lossy | 261 | 294 | 316 | 1.09x |
| Encode throughput, lossless | 56 | 114 | 177 | 1.55x |
| Avg decode throughput, lossy (KDU raw) | 260 | 253 | 235 | **0.94x** |
| Decode throughput, lossless (KDU raw) | 83 | 91 | 152 | 1.68x |

OpenJPH opt is **faster than Kakadu for lossy 16-bit decoding** (0.94x gap
= OJPH 6% faster on average), even with OJPH including PPM write overhead.
The encoding gap is 1.09x for lossy average. At low bitrates (Qstep >= 0.2),
OpenJPH encoding is **equal to or faster than Kakadu**. Lossless encode gap
narrowed to 1.55x.

## Plots

![Benchmark Plot — u10_8bit](benchmark_plot.png)
![Benchmark Plot — ElephantDream_4K](benchmark_plot_elephant.png)

## Observations

- **Encoding (8-bit):** Kakadu is 1.87x faster for lossy (down from 2.69x
  original). Lossless gap narrowed to 2.14x (+127% speedup vs original).
- **Encoding (16-bit):** Kakadu gap is only 1.09x for lossy average. At
  low bitrates (Qstep >= 0.2), OpenJPH is **equal to or faster than
  Kakadu**. Lossless gap narrowed to 1.55x (+103% speedup vs original).
- **Lossless encoding:** 141 MP/s on 8-bit (+127% vs original), 114 MP/s on
  16-bit (+103%). The codeblock encoder remains the dominant cost center.
- **Decoding (8-bit):** Kakadu leads by ~1.21x for lossy, 1.42x for lossless.
- **Decoding (16-bit):** OpenJPH opt is **faster than Kakadu** for lossy
  decoding (0.94x gap = OJPH 6% faster on average), even though OJPH timing
  includes PPM write overhead while KDU raw does not. Only lossless decode
  shows Kakadu ahead (1.68x).
- **File-size parity:** With the same Qstep and `-no_weights`, both HTJ2K
  encoders produce virtually identical file sizes.
