import json
br = json.load(open("/tmp/pwr_bridges.json"))

# ring band y range (left/right vertical bands): 860.55 .. 1564.45
# left corridor: horizontal pieces with x<860
left = [b for b in br if (b[3]-b[1]) > (b[4]-b[2]) and (b[1]+b[3])/2 < 860]
# restrict to those whose y overlaps ring band y range
inband = [b for b in left if not (b[4] < 860.55 or b[2] > 1564.45)]
print("left bridge pieces overlapping ring y-band:", len(inband))
if inband:
    print("  max x1 (innermost) within band:", max(b[3] for b in inband))
    for b in sorted(inband, key=lambda t: -t[3])[:8]:
        print("   ", b)
# all left pieces: distribution of x1
import collections
xs = sorted(set(round(b[3], 3) for b in left))
print("distinct x1 values among left pieces:", xs)
# y range of pieces at each x1
for xv in xs:
    grp = [b for b in left if abs(b[3]-xv) < 1e-6]
    ys = [(round(min(b[2],3),2), round(max(b[4]),2)) for b in grp]
    print("x1", xv, "n", len(grp), "y span", min(b[2] for b in grp), max(b[4] for b in grp))
