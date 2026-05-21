# Codec Benchmark: JPEG-1 vs HTJ2K (OpenJPH) vs HTJ2K (Kakadu)

## Setup

| Item | Detail |
|------|--------|
| Image | `u10_8bit.ppm` (3840 x 2160, 8-bit RGB) |
| JPEG-1 | libjpeg-turbo 2.1.5, 4:4:4 chroma (`-sample 1x1`) |
| OpenJPH | unknown, irreversible 9/7, `-qstep` |
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
| 0.15  | .43      | .37      | .38     | .0173    | .0365    | .0166   | 479         | 227         | 499        |
| 0.06  | 1.04     | .91      | .91     | .0192    | .0466    | .0180   | 432         | 177         | 460        |
| 0.038 | 1.38     | 1.31     | 1.31    | .0201    | .0530    | .0193   | 412         | 156         | 429        |
| 0.025 | 1.71     | 1.75     | 1.75    | .0212    | .0575    | .0202   | 391         | 144         | 410        |
| 0.02  | 2.49     | 2.02     | 2.02    | .0237    | .0619    | .0209   | 349         | 133         | 396        |
| 0.011 | 3.63     | 2.87     | 2.88    | .0275    | .0715    | .0228   | 301         | 116         | 363        |

## Decoding

| Qstep | JPEG bpp | OJPH bpp | KDU bpp | JPEG (s) | OJPH (s) | KDU (s) | JPEG (MP/s) | OJPH (MP/s) | KDU (MP/s) |
|------:|----------|----------|---------|----------|----------|---------|-------------|-------------|------------|
| 0.15  | .43      | .37      | .38     | .0203    | .0322    | .0293   | 408         | 257         | 283        |
| 0.06  | 1.04     | .91      | .91     | .0238    | .0390    | .0323   | 348         | 212         | 256        |
| 0.038 | 1.38     | 1.31     | 1.31    | .0259    | .0434    | .0347   | 320         | 191         | 239        |
| 0.025 | 1.71     | 1.75     | 1.75    | .0276    | .0462    | .0359   | 300         | 179         | 231        |
| 0.02  | 2.49     | 2.02     | 2.02    | .0324    | .0476    | .0368   | 256         | 174         | 225        |
| 0.011 | 3.63     | 2.87     | 2.88    | .0386    | .0536    | .0398   | 214         | 154         | 208        |

## Summary

| Metric | JPEG | OpenJPH | Kakadu |
|--------|-----:|--------:|-------:|
| Avg encode throughput (MP/s) | 394 | 158 | 426 |
| Avg decode throughput (MP/s) | 307 | 194 | 240 |

| Comparison | Encode | Decode |
|------------|-------:|-------:|
| Kakadu / OpenJPH | 2.69x | 1.23x |
| JPEG / OpenJPH   | 2.49x | 1.58x |
| Kakadu / JPEG     | 1.08x | .78x |

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
