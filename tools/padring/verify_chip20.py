import sys, klayout.db as db

GDS = "/home/user/padring/sha256_chip20.gds"
L = db.Layout(); L.dbu = 0.001; L.read(GDS)
D = L.dbu
U = lambda v: int(round(v / D))
def lid(ln, dt):
    for i in L.layer_indexes():
        inf = L.get_info(i)
        if inf.layer == ln and inf.datatype == dt:
            return i
M4, M5, V4 = lid(71, 20), lid(72, 20), lid(71, 44)
top = L.top_cell()

CLIP = db.Box(U(855), U(150), U(1592), U(2280))
def build(li):
    r = db.Region(top.begin_shapes_rec(li)); r.merge(); r = r & db.Region(CLIP); r.merge()
    return r
reg = {"met4": build(M4), "met5": build(M5), "via4": build(V4)}
print("clip 内图形数 met4=%d met5=%d via4=%d" % (reg["met4"].size(), reg["met5"].size(), reg["via4"].size()))

parent = {}
def find(x):
    while parent[x] != x: x = parent[x]
    return x
def union(a, b):
    ra, rb = find(a), find(b)
    if ra != rb: parent[rb] = ra
def key(nm, b):
    k = (nm, b.left, b.bottom, b.right, b.top)
    parent.setdefault(k, k)
    return k
for nm in ("met4", "met5"):
    for s in reg[nm]: key(nm, s.bbox())

def poly_at(nm, x, y, tag=""):
    probe = db.Region(db.Box(U(x)-50, U(y)-50, U(x)+50, U(y)+50))
    hits = reg[nm].interacting(probe)
    if hits.size() == 0:
        print("  [MISS] %-16s %s (%.2f,%.2f) no polygon" % (tag, nm, x, y)); return None
    ks = [key(nm, s.bbox()) for s in hits]
    return ks[0]

for s in reg["via4"]:
    b = s.bbox(); cx = (b.left+b.right)//2; cy = (b.bottom+b.top)//2
    probe = db.Region(db.Box(cx, cy, cx+1, cy+1))
    h4 = reg["met4"].interacting(probe); h5 = reg["met5"].interacting(probe)
    if h4.size() and h5.size():
        union(key("met4", h4[0].bbox()), key("met5", h5[0].bbox()))

TESTS = []
for y in (920.03, 1073.21, 1226.39, 1379.57): TESTS.append(("VPWR stripe y=%.2f" % y, "met5", 1000.0, y))
for y in (923.33, 1076.51, 1229.69, 1382.87): TESTS.append(("VGND stripe y=%.2f" % y, "met5", 1000.0, y))
TESTS += [
    ("N VCCD pad pin", "met4", 1173.5, 2234.60),
    ("N VSSD pad pin", "met4", 1178.4, 2268.00),
    ("S VCCD pad pin", "met4", 1560.0, 189.00),
    ("S VSSD pad pin", "met4", 1505.0, 156.00),
    ("VPWR ring 左", "met4", 862.0, 1200.0),
    ("VPWR ring 右", "met4", 1563.0, 1200.0),
    ("VPWR ring 上", "met4", 1200.0, 1563.0),
    ("VPWR ring 下", "met4", 1200.0, 862.0),
    ("VGND ring 左", "met5", 870.0, 1200.0),
    ("VGND ring 右", "met5", 1555.0, 1200.0),
    ("VGND ring 上", "met5", 1200.0, 1555.0),
    ("VGND ring 下", "met5", 1200.0, 870.0),
]
nodes = {}
for tag, nm, x, y in TESTS:
    k = poly_at(nm, x, y, tag)
    nodes[tag] = k
    print("%-22s %-5s -> %s" % (tag, nm, k))

groups = {}
for tag, k in nodes.items():
    if k is None: continue
    groups.setdefault(find(k), []).append(tag)
print("\n=== 连通分量 ===")
for g, tags in groups.items():
    print("  group: " + " | ".join(tags))

vpwr = [t for t in nodes if t.startswith("VPWR") and nodes[t]]
vgnd = [t for t in nodes if t.startswith("VGND") and nodes[t]]
gv = {find(nodes[t]) for t in vpwr}
gg = {find(nodes[t]) for t in vgnd}
print("\nVPWR 侧分量数", len(gv), " VGND 侧分量数", len(gg))
print("VPWR 8 条 stripe + 4 段环 = 同一网络:", len(gv) == 1)
print("VGND 8 条 stripe + 4 段环 = 同一网络:", len(gg) == 1)
print("VPWR 与 VGND 无短路:", not (gv & gg))
print("N VCCD → VPWR:", find(nodes["N VCCD pad pin"]) in gv)
print("S VCCD → VPWR:", find(nodes["S VCCD pad pin"]) in gv)
print("N VSSD → VGND:", find(nodes["N VSSD pad pin"]) in gg)
print("S VSSD → VGND:", find(nodes["S VSSD pad pin"]) in gg)

# 环宽实测
for nm, x, y in (("met4", 862.0, 1200.0), ("met5", 870.0, 1200.0)):
    probe = db.Region(db.Box(U(x)-50, U(y)-50, U(x)+50, U(y)+50))
    h = reg[nm].interacting(probe)
    b = h[0].bbox()
    print("%s 竖段 bbox x %.3f..%.3f 宽 %.3f" % (nm, b.left*D, b.right*D, (b.right-b.left)*D))

# S 边 VCCD met5 竖条顶端实测 + 与 VGND 环下沿间距
sp = db.Region(db.Box(U(1549.0), U(150), U(1552.0), U(864.0)))
sp = reg["met5"] & sp
topv = max(p.bbox().top for p in sp) * D
ring_bottom = 870.0 - 10.0 / 2.0
print("S VCCD met5 竖条顶端 %.3f, VGND 环下沿 %.3f, gap %.3f" % (topv, ring_bottom, ring_bottom - topv))
# via4(y862) 与 met5 包围量
vprobe = db.Region(db.Box(U(1549.0), U(861.0), U(1552.0), U(863.5)))
vh = reg["met5"] & vprobe
print("via4 上方 met5 包围 %.3f (要求 >=0.31)" % (max(p.bbox().top for p in vh) * D - 862.4))
