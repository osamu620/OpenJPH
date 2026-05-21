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

| Qstep | JPEG bpp | OJPH bpp | KDU bpp | JPEG (s) | OJPH (s) | KDU (s) | JPEG (MP/s) | OJPH (MP/s) | KDU (MP/s) |
|------:|----------|----------|---------|----------|----------|---------|-------------|-------------|------------|
| 0.15  | .43      | .37      | .38     | .0176    | .0358    | .0166   | 471         | 231         | 499        |
| 0.06  | 1.04     | .91      | .91     | .0192    | .0471    | .0183   | 432         | 176         | 453        |
| 0.038 | 1.38     | 1.31     | 1.31    | .0207    | .0521    | .0192   | 400         | 159         | 432        |
| 0.025 | 1.71     | 1.75     | 1.75    | .0212    | .0593    | .0203   | 391         | 139         | 408        |
| 0.02  | 2.49     | 2.02     | 2.02    | .0236    | .0619    | .0208   | 351         | 133         | 398        |
| 0.011 | 3.63     | 2.87     | 2.88    | .0272    | .0724    | .0226   | 304         | 114         | 367        |

## Decoding

| Qstep | JPEG bpp | OJPH bpp | KDU bpp | JPEG (s) | OJPH (s) | KDU (s) | JPEG (MP/s) | OJPH (MP/s) | KDU (MP/s) |
|------:|----------|----------|---------|----------|----------|---------|-------------|-------------|------------|
| 0.15  | .43      | .37      | .38     | .0199    | .0310    | .0286   | 416         | 267         | 290        |
| 0.06  | 1.04     | .91      | .91     | .0224    | .0374    | .0320   | 370         | 221         | 259        |
| 0.038 | 1.38     | 1.31     | 1.31    | .0246    | .0421    | .0333   | 337         | 197         | 249        |
| 0.025 | 1.71     | 1.75     | 1.75    | .0265    | .0450    | .0345   | 312         | 184         | 240        |
| 0.02  | 2.49     | 2.02     | 2.02    | .0317    | .0466    | .0361   | 261         | 177         | 229        |
| 0.011 | 3.63     | 2.87     | 2.88    | .0378    | .0523    | .0385   | 219         | 158         | 215        |

## Summary

| Metric | JPEG | OpenJPH | Kakadu |
|--------|-----:|--------:|-------:|
| Avg encode throughput (MP/s) | 391 | 158 | 426 |
| Avg decode throughput (MP/s) | 319 | 200 | 247 |

| Comparison | Encode | Decode |
|------------|-------:|-------:|
| Kakadu / OpenJPH | 2.69x | 1.23x |
| JPEG / OpenJPH   | 2.47x | 1.59x |
| Kakadu / JPEG     | 1.08x | .77x |

## Plot

![Benchmark Plot](benchmark_plot.png)

## Observations

- **Encoding:** Kakadu's HT block encoder is 2.69x faster than OpenJPH's.
  Kakadu's encode time stays nearly flat across bitrates, whereas OpenJPH
  scales with bitrate.
- **Decoding:** Kakadu is about 1.23x faster than OpenJPH. libjpeg-turbo
  remains the fastest decoder overall.
- **File-size parity:** With the same Qstep and `-no_weights`, both HTJ2K
  encoders produce virtually identical file sizes, confirming equivalent
  quantization.
