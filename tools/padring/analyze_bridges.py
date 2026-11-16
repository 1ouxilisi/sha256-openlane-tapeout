import json
br = json.load(open("/tmp/pwr_bridges.json"))
print("count", len(br))
xs0 = min(b[1] for b in br); xs1 = max(b[3] for b in br)
ys0 = min(b[2] for b in br); ys1 = max(b[4] for b in br)
print("global x", xs0, xs1, " y", ys0, ys1)

# classify: horizontal if width > height (left/right-side pieces), vertical otherwise
hor = [b for b in br if (b[3]-b[1]) > (b[4]-b[2])]
ver = [b for b in br if (b[3]-b[1]) <= (b[4]-b[2])]
print("horizontal(met4 run along x, on left/right)", len(hor),
      " vertical(along y, on top/bottom)", len(ver))

# Left side: horizontal pieces with small x; find inner edge (max x1) and outer edge (min x0)
left = [b for b in hor if (b[1]+b[3])/2 < 800]
right = [b for b in hor if (b[1]+b[3])/2 > 1600]
print("LEFT n", len(left), "x0 min", min(b[1] for b in left), "x1 max", max(b[3] for b in left))
print("RIGHT n", len(right), "x0 min", min(b[1] for b in right), "x1 max", max(b[3] for b in right))
# sample left pieces
for b in sorted(left)[:6]:
    print("  L", b)
print("  ...")
for b in sorted(left, key=lambda t: -t[3])[:4]:
    print("  L inner-most", b)

# Top/bottom: vertical pieces
bot = [b for b in ver if (b[2]+b[4])/2 < 800]
top = [b for b in ver if (b[2]+b[4])/2 > 1600]
print("BOT n", len(bot), "y0 min", min(b[2] for b in bot), "y1 max", max(b[4] for b in bot))
print("TOP n", len(top), "y0 min", min(b[2] for b in top), "y1 max", max(b[4] for b in top))
for b in sorted(bot, key=lambda t: -t[4])[:4]:
    print("  B inner-most", b)
