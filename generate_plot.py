#!/usr/bin/env python3
"""Generate benchmark plots for benchmark_results.md."""

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

# ============================================================
# 8-bit data (u10_8bit.ppm, 3840x2160, 8.29 MP)
# ============================================================

jpeg_bpp  = [0.43, 1.04, 1.38, 1.71, 2.49, 3.63]
ojph_bpp  = [0.38, 0.92, 1.31, 1.75, 2.02, 2.88]
kdu_bpp   = [0.38, 0.92, 1.31, 1.75, 2.02, 2.88]

jpeg_enc_mps  = [471, 432, 400, 391, 351, 304]
ojph_enc_mps  = [231, 176, 159, 139, 133, 114]
kdu_enc_mps   = [500, 453, 432, 409, 399, 367]
ojph_opt_enc_mps = [284, 240, 217, 199, 192, 168]

jpeg_enc_ms  = [17.6, 19.2, 20.7, 21.2, 23.6, 27.2]
ojph_enc_ms  = [35.8, 47.1, 52.1, 59.3, 61.9, 72.4]
kdu_enc_ms   = [16.6, 18.3, 19.2, 20.3, 20.8, 22.6]
ojph_opt_enc_ms  = [29.2, 34.6, 38.2, 41.6, 43.1, 49.4]

jpeg_dec_mps  = [416, 370, 337, 312, 261, 219]
ojph_dec_mps  = [267, 221, 197, 184, 177, 158]
kdu_dec_mps   = [290, 259, 249, 240, 229, 215]
ojph_opt_dec_mps = [285, 230, 211, 190, 184, 165]

jpeg_dec_ms  = [19.9, 22.4, 24.6, 26.5, 31.7, 37.8]
ojph_dec_ms  = [31.0, 37.4, 42.1, 45.0, 46.6, 52.3]
kdu_dec_ms   = [28.6, 32.0, 33.3, 34.5, 36.1, 38.5]
ojph_opt_dec_ms  = [29.1, 36.1, 39.4, 43.7, 45.1, 50.4]

ll_bpp = 9.12
ojph_ll_enc_orig_mps, ojph_ll_enc_opt_mps, kdu_ll_enc_mps = 62, 113, 302
ojph_ll_enc_orig_ms,  ojph_ll_enc_opt_ms,  kdu_ll_enc_ms  = 133.6, 73.2, 27.5
ojph_ll_dec_orig_mps, ojph_ll_dec_opt_mps, kdu_ll_dec_mps = 109, 115, 163
ojph_ll_dec_orig_ms,  ojph_ll_dec_opt_ms,  kdu_ll_dec_ms  = 76.0, 71.9, 51.0

# ============================================================
# 16-bit data (ElephantDream_4K.ppm, 4096x2160, 8.85 MP)
# ============================================================

e_bpp = [0.02, 0.03, 0.05, 0.08, 0.13, 0.20, 0.29, 0.44, 0.67, 1.10, 1.46]

e_orig_enc_mps = [366, 351, 327, 308, 278, 255, 235, 212, 194, 178, 171]
e_opt_enc_mps  = [367, 353, 334, 317, 300, 275, 265, 248, 239, 224, 215]
e_kdu_enc_mps  = [341, 339, 333, 334, 320, 312, 312, 304, 298, 294, 291]

e_orig_enc_ms = [24.1, 25.2, 27.0, 28.7, 31.7, 34.7, 37.5, 41.6, 45.4, 49.4, 51.5]
e_opt_enc_ms  = [24.1, 25.0, 26.5, 27.9, 29.5, 32.2, 33.4, 35.6, 37.0, 39.5, 41.1]
e_kdu_enc_ms  = [25.9, 26.1, 26.5, 26.5, 27.6, 28.3, 28.3, 29.0, 29.6, 30.0, 30.4]

e_orig_dec_mps = [327, 313, 295, 285, 261, 245, 233, 215, 204, 195, 191]
e_opt_dec_mps  = [344, 325, 310, 298, 277, 253, 238, 225, 212, 201, 197]
e_kdu_dec_mps  = [256, 259, 249, 246, 241, 236, 233, 220, 219, 212, 208]

e_orig_dec_ms = [27.1, 28.2, 29.9, 31.0, 33.8, 36.0, 38.0, 41.0, 43.2, 45.2, 46.2]
e_opt_dec_ms  = [25.7, 27.2, 28.5, 29.7, 31.9, 34.9, 37.1, 39.2, 41.4, 43.8, 44.7]
e_kdu_dec_ms  = [34.6, 34.1, 35.4, 35.9, 36.7, 37.4, 37.8, 40.1, 40.3, 41.7, 42.4]

e_ll_bpp = 18.54
e_ll_orig_enc_mps, e_ll_opt_enc_mps, e_ll_kdu_enc_mps = 56, 95, 176
e_ll_orig_enc_ms,  e_ll_opt_enc_ms,  e_ll_kdu_enc_ms  = 157.5, 92.3, 50.0
e_ll_orig_dec_mps, e_ll_opt_dec_mps, e_ll_kdu_dec_mps = 83, 90, 152
e_ll_orig_dec_ms,  e_ll_opt_dec_ms,  e_ll_kdu_dec_ms  = 105.6, 97.9, 58.1

# ============================================================
# Colors
# ============================================================

C_JPEG = '#e74c3c'
C_OJPH = '#27ae60'
C_OJPH_OPT = '#2ecc71'
C_KDU  = '#3498db'

ms = 7
lw = 1.8

# ============================================================
# Plot 1: 8-bit (u10_8bit.ppm) — with JPEG-1 and Kakadu
# ============================================================

fig, axes = plt.subplots(2, 2, figsize=(14, 10))
fig.suptitle(
    'Codec Benchmark: JPEG-1 vs HTJ2K (OpenJPH) vs HTJ2K (Kakadu)\n'
    'Image: u10_8bit.ppm (3840x2160, 8-bit RGB, 4:4:4) — Single-threaded',
    fontsize=13, fontweight='bold'
)

ax = axes[0, 0]
ax.plot(jpeg_bpp, jpeg_enc_mps, 'o-', color=C_JPEG, label='JPEG (libjpeg-turbo)', ms=ms, lw=lw)
ax.plot(ojph_bpp, ojph_enc_mps, 's-', color=C_OJPH, label='HTJ2K (OpenJPH orig)', ms=ms, lw=lw)
ax.plot(ojph_bpp, ojph_opt_enc_mps, 's--', color=C_OJPH_OPT, label='HTJ2K (OpenJPH opt)', ms=ms, lw=lw, markerfacecolor='none', markeredgewidth=2)
ax.plot(kdu_bpp, kdu_enc_mps, '^-', color=C_KDU, label='HTJ2K (Kakadu)', ms=ms, lw=lw)
ax.plot(ll_bpp, ojph_ll_enc_orig_mps, 's', color=C_OJPH, ms=ms+2)
ax.plot(ll_bpp, ojph_ll_enc_opt_mps, 's', color=C_OJPH_OPT, ms=ms+2, markerfacecolor='none', markeredgewidth=2)
ax.plot(ll_bpp, kdu_ll_enc_mps, '^', color=C_KDU, ms=ms+2)
ax.annotate('+83%', xy=(ll_bpp, ojph_ll_enc_opt_mps),
            xytext=(ll_bpp - 1.5, ojph_ll_enc_opt_mps + 20),
            fontsize=9, fontweight='bold', color=C_OJPH_OPT,
            arrowprops=dict(arrowstyle='->', color=C_OJPH_OPT, lw=1.2))
ax.set_xlabel('Bitrate (bpp)')
ax.set_ylabel('Throughput (MP/s)')
ax.set_title('Encoding Throughput')
ax.legend(fontsize=8, loc='upper right')
ax.grid(True, alpha=0.3)
ax.set_xlim(0, 10)

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

ax = axes[1, 0]
ax.plot(jpeg_bpp, jpeg_enc_ms, 'o-', color=C_JPEG, label='JPEG (libjpeg-turbo)', ms=ms, lw=lw)
ax.plot(ojph_bpp, ojph_enc_ms, 's-', color=C_OJPH, label='HTJ2K (OpenJPH orig)', ms=ms, lw=lw)
ax.plot(ojph_bpp, ojph_opt_enc_ms, 's--', color=C_OJPH_OPT, label='HTJ2K (OpenJPH opt)', ms=ms, lw=lw, markerfacecolor='none', markeredgewidth=2)
ax.plot(kdu_bpp, kdu_enc_ms, '^-', color=C_KDU, label='HTJ2K (Kakadu)', ms=ms, lw=lw)
ax.plot(ll_bpp, ojph_ll_enc_orig_ms, 's', color=C_OJPH, ms=ms+2)
ax.plot(ll_bpp, ojph_ll_enc_opt_ms, 's', color=C_OJPH_OPT, ms=ms+2, markerfacecolor='none', markeredgewidth=2)
ax.plot(ll_bpp, kdu_ll_enc_ms, '^', color=C_KDU, ms=ms+2)
ax.annotate('+83%', xy=(ll_bpp, ojph_ll_enc_opt_ms),
            xytext=(ll_bpp - 1.8, ojph_ll_enc_opt_ms + 12),
            fontsize=9, fontweight='bold', color=C_OJPH_OPT,
            arrowprops=dict(arrowstyle='->', color=C_OJPH_OPT, lw=1.2))
ax.set_xlabel('Bitrate (bpp)')
ax.set_ylabel('Time (ms)')
ax.set_title('Encoding Time')
ax.legend(fontsize=8, loc='upper left')
ax.grid(True, alpha=0.3)
ax.set_xlim(0, 10)

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

# ============================================================
# Plot 2: 16-bit (ElephantDream_4K.ppm) — OpenJPH vs Kakadu
#         Broken x-axis: lossy (0–2 bpp) | lossless (~18.5 bpp)
# ============================================================

LOSSY_XLIM = (-0.05, 2.0)
LL_XLIM    = (17.5, 19.5)
WIDTH_RATIO = [4, 1]

def make_broken_pair(fig, gs_row, title, is_time=False):
    ax_l = fig.add_subplot(gs_row[0])
    ax_r = fig.add_subplot(gs_row[1])
    for a in (ax_l, ax_r):
        a.grid(True, alpha=0.3)
    ax_l.set_xlim(*LOSSY_XLIM)
    ax_r.set_xlim(*LL_XLIM)
    ax_r.set_yticklabels([])
    ax_r.tick_params(axis='y', length=0)
    ax_l.spines['right'].set_visible(False)
    ax_r.spines['left'].set_visible(False)
    d = 0.012
    kwargs = dict(transform=ax_l.transAxes, color='k', clip_on=False, lw=1)
    ax_l.plot((1 - d, 1 + d), (-d, +d), **kwargs)
    ax_l.plot((1 - d, 1 + d), (1 - d, 1 + d), **kwargs)
    kwargs['transform'] = ax_r.transAxes
    ax_r.plot((-d, +d), (-d, +d), **kwargs)
    ax_r.plot((-d, +d), (1 - d, 1 + d), **kwargs)
    ax_l.set_title(title)
    ax_l.set_xlabel('Bitrate (bpp)')
    ax_r.set_xlabel('')
    ax_l.set_ylabel('Time (ms)' if is_time else 'Throughput (MP/s)')
    return ax_l, ax_r

def plot_on_pair(ax_l, ax_r, datasets, ll_points, legend_loc):
    for bpp, yvals, style, color, label, mkw in datasets:
        ax_l.plot(bpp, yvals, style, color=color, label=label, ms=ms, lw=lw, **mkw)
        ax_r.plot(bpp, yvals, style, color=color, ms=ms, lw=lw, **mkw)
    for x, y, marker, color, mkw in ll_points:
        ax_l.plot(x, y, marker, color=color, ms=ms+2, **mkw)
        ax_r.plot(x, y, marker, color=color, ms=ms+2, **mkw)
    yl = ax_l.get_ylim()
    yr = ax_r.get_ylim()
    ymin = min(yl[0], yr[0])
    ymax = max(yl[1], yr[1])
    ax_l.set_ylim(ymin, ymax)
    ax_r.set_ylim(ymin, ymax)
    ax_l.legend(fontsize=8, loc=legend_loc)

MK_NONE = {}
MK_OPEN = dict(markerfacecolor='none', markeredgewidth=2)

fig2 = plt.figure(figsize=(14, 10))
fig2.suptitle(
    'HTJ2K Benchmark: OpenJPH vs Kakadu\n'
    'Image: ElephantDream_4K.ppm (4096x2160, 16-bit RGB) — Single-threaded',
    fontsize=13, fontweight='bold'
)
gs = fig2.add_gridspec(2, 4, width_ratios=WIDTH_RATIO + WIDTH_RATIO,
                       hspace=0.30, wspace=0.08)

# -- Encoding Throughput (top-left) --
al, ar = make_broken_pair(fig2, [gs[0, 0], gs[0, 1]], 'Encoding Throughput')
plot_on_pair(al, ar,
    [(e_bpp, e_orig_enc_mps, 's-',  C_OJPH,     'OpenJPH orig', MK_NONE),
     (e_bpp, e_opt_enc_mps,  's--', C_OJPH_OPT, 'OpenJPH opt',  MK_OPEN),
     (e_bpp, e_kdu_enc_mps,  '^-',  C_KDU,      'Kakadu',        MK_NONE)],
    [(e_ll_bpp, e_ll_orig_enc_mps, 's', C_OJPH,     MK_NONE),
     (e_ll_bpp, e_ll_opt_enc_mps,  's', C_OJPH_OPT, MK_OPEN),
     (e_ll_bpp, e_ll_kdu_enc_mps,  '^', C_KDU,      MK_NONE)],
    'upper right')
ar.annotate('+71%', xy=(e_ll_bpp, e_ll_opt_enc_mps),
            xytext=(e_ll_bpp - 0.6, e_ll_opt_enc_mps + 25),
            fontsize=9, fontweight='bold', color=C_OJPH_OPT,
            arrowprops=dict(arrowstyle='->', color=C_OJPH_OPT, lw=1.2))

# -- Decoding Throughput (top-right) --
al, ar = make_broken_pair(fig2, [gs[0, 2], gs[0, 3]], 'Decoding Throughput')
plot_on_pair(al, ar,
    [(e_bpp, e_orig_dec_mps, 's-',  C_OJPH,     'OpenJPH orig', MK_NONE),
     (e_bpp, e_opt_dec_mps,  's--', C_OJPH_OPT, 'OpenJPH opt',  MK_OPEN),
     (e_bpp, e_kdu_dec_mps,  '^-',  C_KDU,      'Kakadu (raw)',  MK_NONE)],
    [(e_ll_bpp, e_ll_orig_dec_mps, 's', C_OJPH,     MK_NONE),
     (e_ll_bpp, e_ll_opt_dec_mps,  's', C_OJPH_OPT, MK_OPEN),
     (e_ll_bpp, e_ll_kdu_dec_mps,  '^', C_KDU,      MK_NONE)],
    'upper right')

# -- Encoding Time (bottom-left) --
al, ar = make_broken_pair(fig2, [gs[1, 0], gs[1, 1]], 'Encoding Time', is_time=True)
plot_on_pair(al, ar,
    [(e_bpp, e_orig_enc_ms, 's-',  C_OJPH,     'OpenJPH orig', MK_NONE),
     (e_bpp, e_opt_enc_ms,  's--', C_OJPH_OPT, 'OpenJPH opt',  MK_OPEN),
     (e_bpp, e_kdu_enc_ms,  '^-',  C_KDU,      'Kakadu',        MK_NONE)],
    [(e_ll_bpp, e_ll_orig_enc_ms, 's', C_OJPH,     MK_NONE),
     (e_ll_bpp, e_ll_opt_enc_ms,  's', C_OJPH_OPT, MK_OPEN),
     (e_ll_bpp, e_ll_kdu_enc_ms,  '^', C_KDU,      MK_NONE)],
    'upper left')
ar.annotate('+71%', xy=(e_ll_bpp, e_ll_opt_enc_ms),
            xytext=(e_ll_bpp - 0.6, e_ll_opt_enc_ms + 12),
            fontsize=9, fontweight='bold', color=C_OJPH_OPT,
            arrowprops=dict(arrowstyle='->', color=C_OJPH_OPT, lw=1.2))

# -- Decoding Time (bottom-right) --
al, ar = make_broken_pair(fig2, [gs[1, 2], gs[1, 3]], 'Decoding Time', is_time=True)
plot_on_pair(al, ar,
    [(e_bpp, e_orig_dec_ms, 's-',  C_OJPH,     'OpenJPH orig', MK_NONE),
     (e_bpp, e_opt_dec_ms,  's--', C_OJPH_OPT, 'OpenJPH opt',  MK_OPEN),
     (e_bpp, e_kdu_dec_ms,  '^-',  C_KDU,      'Kakadu (raw)',  MK_NONE)],
    [(e_ll_bpp, e_ll_orig_dec_ms, 's', C_OJPH,     MK_NONE),
     (e_ll_bpp, e_ll_opt_dec_ms,  's', C_OJPH_OPT, MK_OPEN),
     (e_ll_bpp, e_ll_kdu_dec_ms,  '^', C_KDU,      MK_NONE)],
    'upper left')

plt.savefig('benchmark_plot_elephant.png', dpi=150, bbox_inches='tight')
print('Saved benchmark_plot_elephant.png')
