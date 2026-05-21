#!/usr/bin/env python3
"""Generate benchmark plot for benchmark_results.md."""

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

# Data from benchmark_results.md
# bpp values
jpeg_bpp  = [0.43, 1.04, 1.38, 1.71, 2.49, 3.63]
ojph_bpp  = [0.37, 0.91, 1.31, 1.75, 2.02, 2.87]
kdu_bpp   = [0.38, 0.91, 1.31, 1.75, 2.02, 2.88]

# Original encoding throughput (MP/s)
jpeg_enc_mps  = [471, 432, 400, 391, 351, 304]
ojph_enc_mps  = [231, 176, 159, 139, 133, 114]
kdu_enc_mps   = [499, 453, 432, 408, 398, 367]

# Original encoding time (ms)
jpeg_enc_ms  = [17.6, 19.2, 20.7, 21.2, 23.6, 27.2]
ojph_enc_ms  = [35.8, 47.1, 52.1, 59.3, 61.9, 72.4]
kdu_enc_ms   = [16.6, 18.3, 19.2, 20.3, 20.8, 22.6]

# Optimized OpenJPH encoding (internal Elapsed time)
ojph_opt_enc_mps = [265, 217, 192, 178, 171, 150]
ojph_opt_enc_ms  = [31.3, 38.2, 43.3, 46.5, 48.5, 55.4]

# Original decoding throughput (MP/s)
jpeg_dec_mps  = [416, 370, 337, 312, 261, 219]
ojph_dec_mps  = [267, 221, 197, 184, 177, 158]
kdu_dec_mps   = [290, 259, 249, 240, 229, 215]

# Original decoding time (ms)
jpeg_dec_ms  = [19.9, 22.4, 24.6, 26.5, 31.7, 37.8]
ojph_dec_ms  = [31.0, 37.4, 42.1, 45.0, 46.6, 52.3]
kdu_dec_ms   = [28.6, 32.0, 33.3, 34.5, 36.1, 38.5]

# Optimized OpenJPH decoding (internal Elapsed time)
ojph_opt_dec_mps = [283, 227, 210, 188, 187, 164]
ojph_opt_dec_ms  = [29.3, 36.5, 39.4, 44.1, 44.4, 50.7]

# Lossless data points
ll_bpp = 9.11
ojph_ll_enc_orig_mps = 62
ojph_ll_enc_opt_mps = 110
kdu_ll_enc_mps = 301
ojph_ll_enc_orig_ms = 133.6
ojph_ll_enc_opt_ms = 75.7
kdu_ll_enc_ms = 27.5
ojph_ll_dec_orig_mps = 109
ojph_ll_dec_opt_mps = 114
kdu_ll_dec_mps = 163
ojph_ll_dec_orig_ms = 76.0
ojph_ll_dec_opt_ms = 72.9
kdu_ll_dec_ms = 51.0

# Colors
C_JPEG = '#e74c3c'
C_OJPH = '#27ae60'
C_OJPH_OPT = '#2ecc71'
C_KDU  = '#3498db'

fig, axes = plt.subplots(2, 2, figsize=(14, 10))
fig.suptitle(
    'Codec Benchmark: JPEG-1 vs HTJ2K (OpenJPH) vs HTJ2K (Kakadu)\n'
    'Image: u10_8bit.ppm (3840x2160, 8-bit RGB, 4:4:4) — Single-threaded',
    fontsize=13, fontweight='bold'
)

ms = 7
lw = 1.8

# --- Encoding Throughput ---
ax = axes[0, 0]
ax.plot(jpeg_bpp, jpeg_enc_mps, 'o-', color=C_JPEG, label='JPEG (libjpeg-turbo)', ms=ms, lw=lw)
ax.plot(ojph_bpp, ojph_enc_mps, 's-', color=C_OJPH, label='HTJ2K (OpenJPH orig)', ms=ms, lw=lw)
ax.plot(ojph_bpp, ojph_opt_enc_mps, 's--', color=C_OJPH_OPT, label='HTJ2K (OpenJPH opt)', ms=ms, lw=lw, markerfacecolor='none', markeredgewidth=2)
ax.plot(kdu_bpp, kdu_enc_mps, '^-', color=C_KDU, label='HTJ2K (Kakadu)', ms=ms, lw=lw)
# Lossless points
ax.plot(ll_bpp, ojph_ll_enc_orig_mps, 's', color=C_OJPH, ms=ms+2)
ax.plot(ll_bpp, ojph_ll_enc_opt_mps, 's', color=C_OJPH_OPT, ms=ms+2, markerfacecolor='none', markeredgewidth=2)
ax.plot(ll_bpp, kdu_ll_enc_mps, '^', color=C_KDU, ms=ms+2)
ax.annotate('+76%', xy=(ll_bpp, ojph_ll_enc_opt_mps),
            xytext=(ll_bpp - 1.5, ojph_ll_enc_opt_mps + 20),
            fontsize=9, fontweight='bold', color=C_OJPH_OPT,
            arrowprops=dict(arrowstyle='->', color=C_OJPH_OPT, lw=1.2))
ax.set_xlabel('Bitrate (bpp)')
ax.set_ylabel('Throughput (MP/s)')
ax.set_title('Encoding Throughput')
ax.legend(fontsize=8, loc='upper right')
ax.grid(True, alpha=0.3)
ax.set_xlim(0, 10)

# --- Decoding Throughput ---
ax = axes[0, 1]
ax.plot(jpeg_bpp, jpeg_dec_mps, 'o-', color=C_JPEG, label='JPEG (libjpeg-turbo)', ms=ms, lw=lw)
ax.plot(ojph_bpp, ojph_dec_mps, 's-', color=C_OJPH, label='HTJ2K (OpenJPH orig)', ms=ms, lw=lw)
ax.plot(ojph_bpp, ojph_opt_dec_mps, 's--', color=C_OJPH_OPT, label='HTJ2K (OpenJPH opt)', ms=ms, lw=lw, markerfacecolor='none', markeredgewidth=2)
ax.plot(kdu_bpp, kdu_dec_mps, '^-', color=C_KDU, label='HTJ2K (Kakadu)', ms=ms, lw=lw)
ax.plot(ll_bpp, ojph_ll_dec_orig_mps, 's', color=C_OJPH, ms=ms+2)
ax.plot(ll_bpp, ojph_ll_dec_opt_mps, 's', color=C_OJPH_OPT, ms=ms+2, markerfacecolor='none', markeredgewidth=2)
ax.plot(ll_bpp, kdu_ll_dec_mps, '^', color=C_KDU, ms=ms+2)
ax.set_xlabel('Bitrate (bpp)')
ax.set_ylabel('Throughput (MP/s)')
ax.set_title('Decoding Throughput')
ax.legend(fontsize=8, loc='upper right')
ax.grid(True, alpha=0.3)
ax.set_xlim(0, 10)

# --- Encoding Time ---
ax = axes[1, 0]
ax.plot(jpeg_bpp, jpeg_enc_ms, 'o-', color=C_JPEG, label='JPEG (libjpeg-turbo)', ms=ms, lw=lw)
ax.plot(ojph_bpp, ojph_enc_ms, 's-', color=C_OJPH, label='HTJ2K (OpenJPH orig)', ms=ms, lw=lw)
ax.plot(ojph_bpp, ojph_opt_enc_ms, 's--', color=C_OJPH_OPT, label='HTJ2K (OpenJPH opt)', ms=ms, lw=lw, markerfacecolor='none', markeredgewidth=2)
ax.plot(kdu_bpp, kdu_enc_ms, '^-', color=C_KDU, label='HTJ2K (Kakadu)', ms=ms, lw=lw)
ax.plot(ll_bpp, ojph_ll_enc_orig_ms, 's', color=C_OJPH, ms=ms+2)
ax.plot(ll_bpp, ojph_ll_enc_opt_ms, 's', color=C_OJPH_OPT, ms=ms+2, markerfacecolor='none', markeredgewidth=2)
ax.plot(ll_bpp, kdu_ll_enc_ms, '^', color=C_KDU, ms=ms+2)
ax.annotate('+76%', xy=(ll_bpp, ojph_ll_enc_opt_ms),
            xytext=(ll_bpp - 1.8, ojph_ll_enc_opt_ms + 12),
            fontsize=9, fontweight='bold', color=C_OJPH_OPT,
            arrowprops=dict(arrowstyle='->', color=C_OJPH_OPT, lw=1.2))
ax.set_xlabel('Bitrate (bpp)')
ax.set_ylabel('Time (ms)')
ax.set_title('Encoding Time')
ax.legend(fontsize=8, loc='upper left')
ax.grid(True, alpha=0.3)
ax.set_xlim(0, 10)

# --- Decoding Time ---
ax = axes[1, 1]
ax.plot(jpeg_bpp, jpeg_dec_ms, 'o-', color=C_JPEG, label='JPEG (libjpeg-turbo)', ms=ms, lw=lw)
ax.plot(ojph_bpp, ojph_dec_ms, 's-', color=C_OJPH, label='HTJ2K (OpenJPH orig)', ms=ms, lw=lw)
ax.plot(ojph_bpp, ojph_opt_dec_ms, 's--', color=C_OJPH_OPT, label='HTJ2K (OpenJPH opt)', ms=ms, lw=lw, markerfacecolor='none', markeredgewidth=2)
ax.plot(kdu_bpp, kdu_dec_ms, '^-', color=C_KDU, label='HTJ2K (Kakadu)', ms=ms, lw=lw)
ax.plot(ll_bpp, ojph_ll_dec_orig_ms, 's', color=C_OJPH, ms=ms+2)
ax.plot(ll_bpp, ojph_ll_dec_opt_ms, 's', color=C_OJPH_OPT, ms=ms+2, markerfacecolor='none', markeredgewidth=2)
ax.plot(ll_bpp, kdu_ll_dec_ms, '^', color=C_KDU, ms=ms+2)
ax.set_xlabel('Bitrate (bpp)')
ax.set_ylabel('Time (ms)')
ax.set_title('Decoding Time')
ax.legend(fontsize=8, loc='upper left')
ax.grid(True, alpha=0.3)
ax.set_xlim(0, 10)

plt.tight_layout()
plt.savefig('benchmark_plot.png', dpi=150, bbox_inches='tight')
print('Saved benchmark_plot.png')
