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
| Platform | Linux x86-64 |

Both HTJ2K encoders use the same `Qstep` value at each operating point,
producing nearly identical file sizes. JPEG quality is chosen to give
comparable bitrates.

## Encoding

| Qstep | JPEG bpp | OJPH bpp | KDU bpp | JPEG (s) | OJPH (s) | KDU (s) | JPEG (MP/s) | OJPH (MP/s) | KDU (MP/s) |
|------:|----------|----------|---------|----------|----------|---------|-------------|-------------|------------|
| 0.15  | 0.43     | 0.37     | 0.38    | 0.0174   | 0.0358   | 0.0167  | 476         | 231         | 496        |
| 0.06  | 1.04     | 0.91     | 0.91    | 0.0193   | 0.0460   | 0.0186  | 429         | 180         | 445        |
| 0.038 | 1.38     | 1.31     | 1.31    | 0.0202   | 0.0526   | 0.0192  | 410         | 157         | 431        |
| 0.025 | 1.71     | 1.75     | 1.75    | 0.0214   | 0.0585   | 0.0202  | 387         | 141         | 410        |
| 0.02  | 2.49     | 2.02     | 2.02    | 0.0240   | 0.0629   | 0.0209  | 345         | 131         | 396        |
| 0.011 | 3.63     | 2.87     | 2.88    | 0.0272   | 0.0718   | 0.0226  | 304         | 115         | 366        |

## Decoding

| Qstep | JPEG bpp | OJPH bpp | KDU bpp | JPEG (s) | OJPH (s) | KDU (s) | JPEG (MP/s) | OJPH (MP/s) | KDU (MP/s) |
|------:|----------|----------|---------|----------|----------|---------|-------------|-------------|------------|
| 0.15  | 0.43     | 0.37     | 0.38    | 0.0198   | 0.0319   | 0.0298  | 418         | 260         | 278        |
| 0.06  | 1.04     | 0.91     | 0.91    | 0.0238   | 0.0393   | 0.0320  | 348         | 211         | 258        |
| 0.038 | 1.38     | 1.31     | 1.31    | 0.0260   | 0.0432   | 0.0342  | 319         | 191         | 242        |
| 0.025 | 1.71     | 1.75     | 1.75    | 0.0272   | 0.0458   | 0.0358  | 304         | 181         | 231        |
| 0.02  | 2.49     | 2.02     | 2.02    | 0.0321   | 0.0475   | 0.0365  | 258         | 174         | 227        |
| 0.011 | 3.63     | 2.87     | 2.88    | 0.0387   | 0.0538   | 0.0392  | 214         | 154         | 211        |

## Summary

| Metric | JPEG | OpenJPH | Kakadu |
|--------|-----:|--------:|-------:|
| Avg encode throughput (MP/s) | 392 | 159 | 424 |
| Avg decode throughput (MP/s) | 310 | 195 | 241 |

| Comparison | Encode | Decode |
|------------|-------:|-------:|
| Kakadu / OpenJPH | 2.66x | 1.23x |
| JPEG / OpenJPH   | 2.46x | 1.59x |
| Kakadu / JPEG     | 1.08x | 0.78x |

## Plot

![Benchmark Plot](benchmark_plot.png)

## Observations

- **Encoding:** Kakadu's HT block encoder is 2.7x faster than OpenJPH's
  and slightly outpaces libjpeg-turbo. Kakadu's encode time stays nearly
  flat across bitrates (17–23 ms), whereas OpenJPH scales with bitrate
  (36–72 ms).
- **Decoding:** Kakadu is about 1.2x faster than OpenJPH. libjpeg-turbo
  remains the fastest decoder overall.
- **File-size parity:** With the same Qstep and `-no_weights`, both HTJ2K
  encoders produce virtually identical file sizes, confirming equivalent
  quantization.
