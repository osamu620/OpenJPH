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
| 0.15  | 10      | .38      | .0358         | .0292        | .0166   | 231               | 284             | 500        | +23%    |
| 0.06  | 50      | .92      | .0471         | .0346        | .0183   | 176               | 240             | 453        | +36%    |
| 0.038 | 70      | 1.31     | .0521         | .0382        | .0192   | 159               | 217             | 432        | +36%    |
| 0.025 | 80      | 1.75     | .0593         | .0416        | .0203   | 139               | 199             | 409        | +43%    |
| 0.02  | 90      | 2.02     | .0619         | .0431        | .0208   | 133               | 192             | 399        | +44%    |
| 0.011 | 95      | 2.88     | .0724         | .0494        | .0226   | 114               | 168             | 367        | +47%    |
| lossless | —    | 9.12     | .1336         | .0732        | .0275   | 62                | 113             | 302        | +83%    |

### Decoding (optimized)

| Qstep | Qfactor | OJPH bpp | OJPH orig (s) | OJPH opt (s) | KDU (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU (MP/s) |
|------:|--------:|----------|---------------|--------------|---------|-------------------|-----------------|------------|
| 0.15  | 10      | .38      | .0310         | .0291        | .0286   | 267               | 285             | 290        |
| 0.06  | 50      | .92      | .0374         | .0361        | .0320   | 221               | 230             | 259        |
| 0.038 | 70      | 1.31     | .0421         | .0394        | .0333   | 197               | 211             | 249        |
| 0.025 | 80      | 1.75     | .0450         | .0437        | .0345   | 184               | 190             | 240        |
| 0.02  | 90      | 2.02     | .0466         | .0451        | .0361   | 177               | 184             | 229        |
| 0.011 | 95      | 2.88     | .0523         | .0504        | .0385   | 158               | 165             | 215        |
| lossless | —    | 9.12     | .0760         | .0719        | .0510   | 109               | 115             | 163        |

### Summary (updated)

| Metric | JPEG | OJPH (orig) | OJPH (opt) | Kakadu |
|--------|-----:|------------:|-----------:|-------:|
| Avg encode throughput (MP/s), lossy | 391 | 159 | 217 | 427 |
| Encode throughput (MP/s), lossless | — | 62 | 113 | 302 |
| Avg decode throughput (MP/s), lossy | 319 | 201 | 211 | 247 |
| Decode throughput (MP/s), lossless | — | 109 | 115 | 163 |

| Comparison (lossy avg) | Encode | Decode |
|------------------------|-------:|-------:|
| Kakadu / OJPH (opt)    | 1.97x  | 1.17x  |
| Kakadu / OJPH (orig)   | 2.69x  | 1.23x  |

| Comparison (lossless)  | Encode | Decode |
|------------------------|-------:|-------:|
| Kakadu / OJPH (opt)    | 2.67x  | 1.42x  |
| Kakadu / OJPH (orig)   | 4.87x  | 1.50x  |

### Optimization impact by operating point

The encoder speedup is **strongest at high bitrates and lossless** (83% for
lossless, 23-47% at lossy operating points). The optimizations are purely
algorithmic (AVX-512 encoder, branchless drains, run-length MEL, NASM
MagSgn). A controlled sweep of elastic allocator chunk sizes (64 KiB to
32 MiB, with and without doubling growth) showed no measurable performance
difference — the allocator is not a bottleneck.

Decoder optimization is modest (3-6% improvement at most operating points).
The encoder-focused optimizations do not significantly change decode
performance, which is expected since they target different code paths.

### Remaining gap to Kakadu

| Mode | Gap (Kakadu/OJPH) | Target |
|------|------------------:|-------:|
| Lossy encode (avg) | 1.97x | 1.0x |
| Lossless encode | 2.67x | 1.0x |
| Lossy decode (avg) | 1.17x | 1.0x |
| Lossless decode | 1.42x | 1.0x |

The decode gap is close (1.17x for lossy). The main opportunity remains
in encoding, where a ~2x gap persists. The codeblock encoder
(`encode_codeblock`) remains the dominant cost center.

## ElephantDream_4K (16-bit, 4096x2160)

| Item | Detail |
|------|--------|
| Image | `ElephantDream_4K.ppm` (4096 x 2160, 16-bit RGB) |
| Pixels | 8,847,360 (8.85 MP) |
| Qsteps | Finer geometric series (no JPEG-1 comparison needed for 16-bit) |

### Encoding (ElephantDream_4K)

| Qstep | bpp | OJPH orig (s) | OJPH opt (s) | KDU (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU (MP/s) | Speedup | Gap |
|------:|----:|--------------:|-------------:|--------:|-----------------:|----------------:|-----------:|--------:|----:|
| 0.5   | 0.02 | .0241       | .0241        | .0259   | 366              | 367             | 341        | 0%      | 0.93x |
| 0.3   | 0.03 | .0252       | .0250        | .0261   | 351              | 353             | 339        | +1%     | 0.96x |
| 0.2   | 0.05 | .0270       | .0265        | .0265   | 327              | 334             | 333        | +2%     | 1.00x |
| 0.15  | 0.08 | .0287       | .0279        | .0265   | 308              | 317             | 334        | +3%     | 1.05x |
| 0.1   | 0.13 | .0317       | .0295        | .0276   | 278              | 300             | 320        | +7%     | 1.07x |
| 0.07  | 0.20 | .0347       | .0322        | .0283   | 255              | 275             | 312        | +8%     | 1.14x |
| 0.05  | 0.29 | .0375       | .0334        | .0283   | 235              | 265             | 312        | +12%    | 1.18x |
| 0.03  | 0.44 | .0416       | .0356        | .0290   | 212              | 248             | 304        | +17%    | 1.23x |
| 0.02  | 0.67 | .0454       | .0370        | .0296   | 194              | 239             | 298        | +23%    | 1.25x |
| 0.01  | 1.10 | .0494       | .0395        | .0300   | 178              | 224             | 294        | +25%    | 1.31x |
| 0.005 | 1.46 | .0515       | .0411        | .0304   | 171              | 215             | 291        | +25%    | 1.35x |
| lossless | 18.54 | .1575  | .0923        | .0500   | 56               | 95              | 176        | +71%    | 1.85x |

### Decoding (ElephantDream_4K)

Kakadu timing is `-cpu 0` decoding to raw (no PPM byte-swap overhead).
OpenJPH `Elapsed time` includes PPM writing.

| Qstep | bpp | OJPH orig (s) | OJPH opt (s) | KDU raw (s) | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU raw (MP/s) | Gap |
|------:|----:|--------------:|-------------:|------------:|-----------------:|----------------:|---------------:|----:|
| 0.5   | 0.02 | .0271       | .0257        | .0346       | 327              | 344             | 256            | 0.74x |
| 0.3   | 0.03 | .0282       | .0272        | .0341       | 313              | 325             | 259            | 0.80x |
| 0.2   | 0.05 | .0299       | .0285        | .0354       | 295              | 310             | 249            | 0.80x |
| 0.15  | 0.08 | .0310       | .0297        | .0359       | 285              | 298             | 246            | 0.83x |
| 0.1   | 0.13 | .0338       | .0319        | .0367       | 261              | 277             | 241            | 0.87x |
| 0.07  | 0.20 | .0360       | .0349        | .0374       | 245              | 253             | 236            | 0.93x |
| 0.05  | 0.29 | .0380       | .0371        | .0378       | 233              | 238             | 233            | 0.98x |
| 0.03  | 0.44 | .0410       | .0392        | .0401       | 215              | 225             | 220            | 0.98x |
| 0.02  | 0.67 | .0432       | .0416        | .0403       | 204              | 212             | 219            | 1.03x |
| 0.01  | 1.10 | .0452       | .0438        | .0417       | 195              | 201             | 212            | 1.05x |
| 0.005 | 1.46 | .0462       | .0447        | .0424       | 191              | 197             | 208            | 1.06x |
| lossless | 18.54 | .1056  | .0979        | .0581       | 83               | 90              | 152            | 1.69x |

Note: Gap < 1.0x means OpenJPH is faster than Kakadu. OpenJPH decode
includes PPM writing overhead while KDU raw does not, so the actual
OJPH advantage at low bitrates is even larger.

### Summary (ElephantDream_4K)

| Metric | OJPH orig (MP/s) | OJPH opt (MP/s) | KDU (MP/s) | Gap (KDU/opt) |
|--------|------------------:|----------------:|-----------:|---------------:|
| Avg encode throughput, lossy | 264 | 285 | 316 | 1.11x |
| Encode throughput, lossless | 56 | 95 | 176 | 1.85x |
| Avg decode throughput, lossy (KDU raw) | 262 | 271 | 237 | **0.88x** |
| Decode throughput, lossless (KDU raw) | 83 | 90 | 152 | 1.69x |

OpenJPH opt is **faster than Kakadu for lossy 16-bit decoding** (0.88x gap
= OJPH 14% faster on average), even with OJPH including PPM write overhead.
The encoding gap is 1.11x for lossy average — much closer than the 1.97x
gap on 8-bit. At very low bitrates (Qstep >= 0.2), OpenJPH encoding is
**equal to or faster than** Kakadu. Lossless encode/decode gaps are
1.85x/1.69x.

## Plots

![Benchmark Plot — u10_8bit](benchmark_plot.png)
![Benchmark Plot — ElephantDream_4K](benchmark_plot_elephant.png)

## Observations

- **Encoding (8-bit):** Kakadu's HT block encoder is ~2.0x faster than
  optimized OpenJPH for lossy (down from 2.69x original). The gap narrows at
  lower bitrates where fixed overhead dominates.
- **Encoding (16-bit):** Kakadu gap is only 1.11x for lossy average. At very
  low bitrates (Qstep >= 0.2), OpenJPH is **equal to or faster than** Kakadu.
  Gap grows to 1.35x at high bitrates and 1.85x for lossless.
- **Lossless encoding:** 113 MP/s on 8-bit (+83% vs original), 95 MP/s on
  16-bit (+71%). The codeblock encoder remains the dominant cost center.
- **Decoding (8-bit):** Kakadu leads by ~1.17x for lossy, 1.42x for lossless.
- **Decoding (16-bit):** OpenJPH opt is **faster than Kakadu** for lossy
  decoding (0.88x gap = OJPH 14% faster on average), even though OJPH timing
  includes PPM write overhead while KDU raw does not. Only lossless decode
  shows Kakadu ahead (1.69x).
- **File-size parity:** With the same Qstep and `-no_weights`, both HTJ2K
  encoders produce virtually identical file sizes.
