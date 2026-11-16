import json
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

ADDED = json.load(open("/tmp/chip21_delta.json"))
PADS = json.load(open("/home/user/padring/padmap.json"))
COL = {"met4": "#b23b3b", "met5": "#2f5d8a", "via4": "#111111"}

def base(ax):
    for p in PADS:
        ax.add_patch(Rectangle((p["x0"], p["y0"]), max(p["x1"]-p["x0"], 0.1), max(p["y1"]-p["y0"], 0.1),
                               facecolor="#f4f4f4", edgecolor="#cfcfcf", linewidth=0.3, zorder=2))
    ax.add_patch(Rectangle((892.5, 892.5), 640, 640, facecolor="#fafafa",
                           edgecolor="#999", linewidth=0.7, zorder=3))

def draw(ax, x0, y0, x1, y1):
    for (ln, a, b, c, d) in ADDED:
        if c > x0 and a < x1 and d > y0 and b < y1:
            ax.add_patch(Rectangle((a, b), max(c-a, 0.02), max(d-b, 0.02), facecolor=COL[ln],
                                   edgecolor="none", zorder=6 if ln == "via4" else 5))
    ax.set_xlim(x0, x1); ax.set_ylim(y0, y1); ax.set_aspect("equal"); ax.set_facecolor("white")
    ax.tick_params(labelsize=7, colors="#666")
    for sp in ax.spines.values(): sp.set_color("#999")

fig, ax = plt.subplots(figsize=(9, 9)); base(ax); draw(ax, 0, 0, 2425, 2425)
ax.set_title("sha256_chip21: VGND ring met5 12.0 um - both exits via4 into met4 band (gap 2.25, waiting for DRC)",
             fontsize=10)
fig.tight_layout(); fig.savefig("/home/user/padring/sha256_chip21_ring.png", dpi=180)

fig2, ax2 = plt.subplots(figsize=(6, 11)); base(ax2); draw(ax2, 1470, 140, 1600, 900)
ax2.set_title("S edge, ring 12.0: VCCD strip top 861.75 to ring 864 = 2.25 (via4 in met4 band)",
              fontsize=8.5)
fig2.tight_layout(); fig2.savefig("/home/user/padring/sha256_chip21_sexit.png", dpi=200)

fig3, ax3 = plt.subplots(figsize=(5, 9)); base(ax3); draw(ax3, 850, 895, 960, 1400)
ax3.set_title("core left connections, ring 2.9/12.0: 4 VPWR / 4 VGND", fontsize=8.5)
fig3.tight_layout(); fig3.savefig("/home/user/padring/sha256_chip21_coreleft.png", dpi=200)
print("rendered chip21")
