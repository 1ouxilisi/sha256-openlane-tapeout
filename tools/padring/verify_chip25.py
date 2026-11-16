import klayout.db as db

GDS = "/home/user/padring/sha256_chip25.gds"
SHIFT = 20.0
W5 = 16.9
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

CLIP = db.Box(U(835), U(150), U(1612), U(2280))
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
    return key(nm, hits[0].bbox())

for s in reg["via4"]:
    b = s.bbox(); cx = (b.left+b.right)//2; cy = (b.bottom+b.top)//2
    probe = db.Region(db.Box(cx, cy, cx+1, cy+1))
    h4 = reg["met4"].interacting(probe); h5 = reg["met5"].interacting(probe)
    if h4.size() and h5.size():
        union(key("met4", h4[0].bbox()), key("met5", h5[0].bbox()))

# 外移后中心
VX0, VX1 = 862.0 - SHIFT, 1563.0 + SHIFT
GX0, GX1 = 872.0 - SHIFT, 1553.0 + SHIFT
S_STRIP_TOP = 861.95 - SHIFT
N_STRIP_BOT = 1563.05 + SHIFT
TESTS = []
for y in (920.03, 1073.21, 1226.39, 1379.57): TESTS.append(("VPWR stripe y=%.2f" % y, "met5", 1000.0, y))
for y in (923.33, 1076.51, 1229.69, 1382.87): TESTS.append(("VGND stripe y=%.2f" % y, "met5", 1000.0, y))
TESTS += [
    ("N VCCD pad pin", "met4", 1173.5, 2234.60),
    ("N VSSD pad pin", "met4", 1178.4, 2268.00),
    ("S VCCD pad pin", "met4", 1560.0, 189.00),
    ("S VSSD pad pin", "met4", 1505.0, 156.00),
    ("VPWR ring 左", "met4", VX0, 1200.0),
    ("VPWR ring 右", "met4", VX1, 1200.0),
    ("VPWR ring 上", "met4", 1200.0, VX1),
    ("VPWR ring 下", "met4", 1200.0, VX0),
    ("VGND ring 左", "met5", GX0, 1200.0),
    ("VGND ring 右", "met5", GX1, 1200.0),
    ("VGND ring 上", "met5", 1200.0, GX1),
    ("VGND ring 下", "met5", 1200.0, GX0),
]
nodes = {}
for tag, nm, x, y in TESTS:
    nodes[tag] = poly_at(nm, x, y, tag)
groups = {}
for tag, k in nodes.items():
    if k is None: continue
    groups.setdefault(find(k), []).append(tag)
print("=== 连通分量 ===")
for g, tags in groups.items():
    print("  group: " + " | ".join(tags))

vpwr = [t for t in nodes if t.startswith("VPWR") and nodes[t]]
vgnd = [t for t in nodes if t.startswith("VGND") and nodes[t]]
gv = {find(nodes[t]) for t in vpwr}; gg = {find(nodes[t]) for t in vgnd}
print("VPWR 单网络:", len(gv) == 1, " VGND 单网络:", len(gg) == 1, " 无短路:", not (gv & gg))
print("N/S VCCD→VPWR:", find(nodes["N VCCD pad pin"]) in gv, find(nodes["S VCCD pad pin"]) in gv)
print("N/S VSSD→VGND:", find(nodes["N VSSD pad pin"]) in gg, find(nodes["S VSSD pad pin"]) in gg)

# S 边竖条顶端 + gap + via4 包围
sp = reg["met5"] & db.Region(db.Box(U(1549.0), U(150), U(1552.0), U(843.0)))
stop = max(p.bbox().top for p in sp) * D
ring_b = GX0 - W5/2.0
print("S 竖条顶 %.3f, ring 底 %.3f, gap %.3f" % (stop, ring_b, ring_b - stop))
sv = reg["met5"] & db.Region(db.Box(U(1549.0), U(840.0), U(1552.0), U(842.2)))
print("S via4 上包围 %.3f (>=0.31)" % (max(p.bbox().top for p in sv) * D - (861.6 - SHIFT)))

# N 边
np_ = reg["met5"] & db.Region(db.Box(U(1172.0), U(1582.0), U(1175.0), U(2240)))
sbot = min(p.bbox().bottom for p in np_) * D
ring_t = GX1 + W5/2.0
print("N 竖条底 %.3f, ring 顶 %.3f, gap %.3f" % (sbot, ring_t, sbot - ring_t))
nv = reg["met5"] & db.Region(db.Box(U(1172.0), U(1582.5), U(1175.0), U(1584.0)))
print("N via4 下包围 %.3f (>=0.31)" % ((1563.4 + SHIFT) - min(p.bbox().bottom for p in nv) * D))
