import json, klayout.db as db

L6 = db.Layout(); L6.dbu = 0.001; L6.read("/home/user/padring/sha256_chip6.gds")
L9 = db.Layout(); L9.dbu = 0.001; L9.read("/home/user/padring/sha256_chip19.gds")

def lid(L, ln, dt):
    for i in L.layer_indexes():
        inf = L.get_info(i)
        if inf.layer == ln and inf.datatype == dt:
            return i
m4_6 = lid(L6, 71, 20); m4_9 = lid(L9, 71, 20)

r6 = db.Region(L6.top_cell().begin_shapes_rec(m4_6)); r6.merge()
r9 = db.Region(L9.top_cell().begin_shapes_rec(m4_9)); r9.merge()
added = r9 - r6
added.merge()
print("added M4 polygons:", added.size())

# 非桥接的已知 M4 新增盒（chip19 参数：4 环段 + 4 VPWR 横 stripe）
W4, W5 = 2.9, 9.8
h4 = W4 / 2.0
VX0, VX1, VY0, VY1 = 862.0, 1563.0, 862.0, 1563.0
GX0 = 870.0
h5 = W5 / 2.0
known = [
    (VX0-h4, VY0-h4, VX0+h4, VY1+h4),
    (VX1-h4, VY0-h4, VX1+h4, VY1+h4),
    (VX0-h4, VY0-h4, VX1+h4, VY0+h4),
    (VX0-h4, VY1-h4, VX1+h4, VY1+h4),
]
VPWR_Y = [920.03, 1073.21, 1226.39, 1379.57]
for y in VPWR_Y:
    known.append((VX0-h4, y-0.8, 900.0, y+0.8))
U = lambda v: int(round(v / 0.001))
kreg = db.Region()
for (x0, y0, x1, y1) in known:
    kreg.insert(db.Box(U(x0), U(y0), U(x1), U(y1)))
kreg.merge()

bridges = added - kreg
bridges.merge()
print("bridge polygons:", bridges.size())
assert bridges.size() == 1440, "expected 1440 disjoint bridges"

out = []
for p in bridges:
    b = p.bbox()
    out.append(["", b.left*0.001, b.bottom*0.001, b.right*0.001, b.top*0.001])
json.dump(out, open("/tmp/pwr_bridges.json", "w"))
print("wrote /tmp/pwr_bridges.json", len(out))
