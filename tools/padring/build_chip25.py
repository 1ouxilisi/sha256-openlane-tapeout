import json, os, klayout.db as db

SRC = "/home/user/padring/sha256_chip6.gds"
OUT = "/home/user/padring/sha256_chip25.gds"
SHIFT = 20.0          # 整环向 die 边外移量（µm）
W4 = 2.9
W5 = 16.9
# chip23 原始常量（S 边）
S_STRIP_TOP0, S_VIA_CY0 = 861.95, 861.2
N_STRIP_BOT0, N_VIA_CY0 = 1563.05, 1563.8
# 外移后：左/下减 SHIFT，右/上加 SHIFT
S_STRIP_TOP, S_VIA_CY = S_STRIP_TOP0 - SHIFT, S_VIA_CY0 - SHIFT
N_STRIP_BOT, N_VIA_CY = N_STRIP_BOT0 + SHIFT, N_VIA_CY0 + SHIFT

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

h4 = W4 / 2.0
h5 = W5 / 2.0
n4 = n5 = nv = 0

# ---- 1. 1440 seam bridges（固定，不随环移动）----
for (net, x0, y0, x1, y1) in json.load(open("/tmp/pwr_bridges.json")):
    add(M4, x0, y0, x1, y1); n4 += 1

# ---- 2. rings（整环外移 SHIFT）----
VX0, VX1 = 862.0 - SHIFT, 1563.0 + SHIFT
VY0, VY1 = VX0, VX1
GX0, GX1 = 872.0 - SHIFT, 1553.0 + SHIFT
for (x0, y0, x1, y1) in [
    (VX0 - h4, VY0 - h4, VX0 + h4, VY1 + h4),
    (VX1 - h4, VY0 - h4, VX1 + h4, VY1 + h4),
    (VX0 - h4, VY0 - h4, VX1 + h4, VY0 + h4),
    (VX0 - h4, VY1 - h4, VX1 + h4, VY1 + h4),
]:
    add(M4, x0, y0, x1, y1); n4 += 1
for (x0, y0, x1, y1) in [
    (GX0 - h5, GX0 - h5, GX0 + h5, GX1 + h5),
    (GX1 - h5, GX0 - h5, GX1 + h5, GX1 + h5),
    (GX0 - h5, GX0 - h5, GX1 + h5, GX0 + h5),
    (GX0 - h5, GX1 - h5, GX1 + h5, GX1 + h5),
]:
    add(M5, x0, y0, x1, y1); n5 += 1

# ---- 3. core 8 stripe（环外移，stripe 朝环方向延长）----
VPWR_Y = [920.03, 1073.21, 1226.39, 1379.57]
VGND_Y = [923.33, 1076.51, 1229.69, 1382.87]
CORE_X1 = 900.0
add(M5, GX0 - h5, VGND_Y[0] - 0.8, CORE_X1, VGND_Y[0] + 0.8); n5 += 1
add(M4, VX0 - h4, VPWR_Y[0] - 0.8, CORE_X1, VPWR_Y[0] + 0.8); n4 += 1
add(V4, 898.6, VPWR_Y[0] - 0.4, 899.4, VPWR_Y[0] + 0.4); nv += 1
for y in VPWR_Y[1:]:
    add(M4, VX0 - h4, y - 0.8, CORE_X1, y + 0.8); n4 += 1
    add(V4, 898.6, y - 0.4, 899.4, y + 0.4); nv += 1
for y in VGND_Y[1:]:
    add(M5, GX0 - h5, y - 0.8, CORE_X1, y + 0.8); n5 += 1

# ---- 4. N 边出线（整组随环外移）----
add(V4, 1173.2, 2235.6, 1174.0, 2236.4); nv += 1
add(M5, 1172.8, N_STRIP_BOT, 1174.4, 2236.75); n5 += 1
add(V4, 1173.2, N_VIA_CY - 0.4, 1174.0, N_VIA_CY + 0.4); nv += 1
add(V4, 1178.0, 2268.6, 1178.8, 2269.4); nv += 1
add(M5, 1177.6, GX1 - h5 + 0.05, 1179.2, 2269.75); n5 += 1

# ---- 5. S 边出线（整组随环外移）----
add(V4, 1550.0, 188.0, 1550.8, 188.8); nv += 1
add(M5, 1549.6, 187.6, 1551.2, S_STRIP_TOP); n5 += 1
add(V4, 1550.0, S_VIA_CY - 0.4, 1550.8, S_VIA_CY + 0.4); nv += 1
add(V4, 1510.0, 155.5, 1510.8, 156.3); nv += 1
add(M5, 1509.6, 155.1, 1511.2, GX0 + h5 - 0.05); n5 += 1

L.write(OUT)
lname = {M4: "met4", M5: "met5", V4: "via4"}
json.dump([(lname[li], a, b, c, d) for (li, a, b, c, d) in ADDED],
          open("/tmp/chip25_delta.json", "w"))
ring_b, ring_t = GX0 - W5/2.0, GX1 + W5/2.0
print("SHIFT %.1f W5 %.1f: S gap %.2f, N gap %.2f" %
      (SHIFT, W5, ring_b - S_STRIP_TOP, N_STRIP_BOT - ring_t))
print("inner channel (m5 inner edge -> core): %.3f" % (892.5 - (GX0 + h5)))
print("met4", n4, "met5", n5, "via4", nv, "total", n4+n5+nv)
print("->", OUT, os.path.getsize(OUT))
