import json, os, klayout.db as db

SRC = "/home/user/padring/sha256_chip6.gds"
OUT = "/home/user/padring/sha256_chip13.gds"
L = db.Layout(); L.dbu = 0.001
L.read(SRC)
D = L.dbu
U = lambda v: int(round(v / D))
def lid(ln, dt):
    for i in L.layer_indexes():
        inf = L.get_info(i)
        if inf.layer == ln and inf.datatype == dt:
            return i
M4, M5, V4 = lid(71, 20), lid(72, 20), lid(71, 44)
top = L.top_cell()
ADDED = []
def add(li, x0, y0, x1, y1):
    if x1 <= x0 or y1 <= y0:
        raise ValueError("degenerate %s %s" % (li, (x0, y0, x1, y1)))
    top.shapes(li).insert(db.Box(U(x0), U(y0), U(x1), U(y1)))
    ADDED.append((li, x0, y0, x1, y1))

n4 = n5 = nv = 0
# ---- 1. 1440 seam bridges ----
for (net, x0, y0, x1, y1) in json.load(open("/tmp/pwr_bridges.json")):
    add(M4, x0, y0, x1, y1); n4 += 1

# ---- 2. rings ----
# VPWR ring on met4, center lines x/y 862 & 1563
for (x0, y0, x1, y1) in [
    (861.2, 861.2, 862.8, 1563.8),
    (1562.2, 861.2, 1563.8, 1563.8),
    (861.2, 861.2, 1563.8, 862.8),
    (861.2, 1562.2, 1563.8, 1563.8),
]:
    add(M4, x0, y0, x1, y1); n4 += 1
# VGND ring on met5, inset 8, center x/y 870 & 1555
for (x0, y0, x1, y1) in [
    (869.2, 869.2, 870.8, 1555.8),
    (1554.2, 869.2, 1555.8, 1555.8),
    (869.2, 869.2, 1555.8, 870.8),
    (869.2, 1554.2, 1555.8, 1555.8),
]:
    add(M5, x0, y0, x1, y1); n5 += 1

# ---- 3. core connections (left ring -> nearest core stripes) ----
# VGND: met5 horizontal bar, ring-left (x870) into core VGND stripe (starts x897.78)
add(M5, 870.0, 922.53, 900.0, 924.13); n5 += 1
# VPWR: met4 horizontal bar + via into core VPWR met5 stripe
add(M4, 862.0, 919.23, 900.0, 920.83); n4 += 1
add(V4, 898.6, 919.63, 899.4, 920.43); nv += 1

# ---- 4. N-side pad exits (mid gpiov2, global x origin 1172) ----
# VCCD: pin via -> met5 vertical strap -> ring via -> VPWR ring top (y1563)
add(V4, 1173.2, 2235.6, 1174.0, 2236.4); nv += 1   # pin via, inside met4 pin
add(M5, 1172.8, 1562.25, 1174.4, 2236.75); n5 += 1  # strap wraps both vias >=0.35
add(V4, 1173.2, 1562.6, 1174.0, 1563.4); nv += 1    # ring via
# VSSD: pin via -> met5 vertical strap -> VGND ring top (y1555, same layer, no ring via)
add(V4, 1178.0, 2268.6, 1178.8, 2269.4); nv += 1
add(M5, 1177.6, 1555.0, 1179.2, 2269.75); n5 += 1

L.write(OUT)
lname = {M4: "met4", M5: "met5", V4: "via4"}
json.dump([(lname[li], a, b, c, d) for (li, a, b, c, d) in ADDED],
          open("/tmp/chip13_added.json", "w"))
print("met4", n4, "met5", n5, "via4", nv, "total added", n4 + n5 + nv)
print("->", OUT, os.path.getsize(OUT))
