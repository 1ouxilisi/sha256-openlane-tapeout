import json
br = json.load(open("/tmp/pwr_bridges.json"))
left = [b for b in br if (b[3]-b[1]) > (b[4]-b[2]) and (b[1]+b[3])/2 < 860]
for xv in [767.94, 848.715, 848.94]:
    grp = [b for b in left if abs(b[3]-xv) < 1e-6]
    print("x1", xv, "n", len(grp), "y min", min(b[2] for b in grp), "y max", max(b[4] for b in grp))
    for b in grp[:5]:
        print("   ", b)
# ring band y range check
print("ring band y 860.55..1564.45; pieces at 848.94 within:",
      sum(1 for b in left if abs(b[3]-848.94)<1e-6 and not (b[4]<860.55 or b[2]>1564.45)))
