import json, os, klayout.db as db

SRC = "/home/user/padring/sha256_chip13.gds"
OUT = "/home/user/padring/sha256_chip14.gds"
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

# ---- 1. core 其余 6 条 stripe（VPWR 3 条 met4+via4，VGND 3 条 met5 直连）----
VPWR_Y = [920.03, 1073.21, 1226.39, 1379.57]
VGND_Y = [923.33, 1076.51, 1229.69, 1382.87]
CORE_X0, CORE_X1 = 897.78, 900.0       # core stripe 左端
for y in VPWR_Y[1:]:                    # 第 1 条 chip13 已接
    add(M4, 862.0, y - 0.8, 905.0, y + 0.8)
    add(V4, 898.6, y - 0.4, 899.4, y + 0.4)
for y in VGND_Y[1:]:
    add(M5, 870.0, y - 0.8, CORE_X1, y + 0.8)

# ---- 2. S 边出线（中部 gpiov2，bbox x1496–1577.65）----
# VPWR: VCCD pin(met4 x1542.705–1576.94, y186.465–191.115)
#   -> via4 -> met5 竖条 -> via4 -> VPWR 环(met4) 底边 y861.2–862.8
add(V4, 1550.0, 188.0, 1550.8, 188.8)
add(M5, 1549.6, 187.6, 1551.2, 862.75)
add(V4, 1550.0, 861.6, 1550.8, 862.4)
# VGND: VSSD pin(met4 x1496.94–1521.235, y153.765–158.415)
#   -> via4 -> met5 竖条 -> VGND 环(met5) 底边 y869.2–870.8（同层相并）
add(V4, 1510.0, 155.5, 1510.8, 156.3)
add(M5, 1509.6, 155.1, 1511.2, 870.0)

L.write(OUT)
lname = {M4: "met4", M5: "met5", V4: "via4"}
json.dump([(lname[li], a, b, c, d) for (li, a, b, c, d) in ADDED],
          open("/tmp/chip14_delta.json", "w"))
print("delta shapes", len(ADDED))
print("->", OUT, os.path.getsize(OUT))
