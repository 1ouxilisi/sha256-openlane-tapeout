import klayout.db as db

for tag, W5, G0, G1 in (("chip22", 12.9, 870.0, 1555.0), ("chip23", 16.9, 872.0, 1553.0),
                        ("chip24", 17.0, 872.0, 1553.0)):
    L = db.Layout(); L.dbu = 0.001
    L.read("/home/user/padring/sha256_%s.gds" % tag)
    D = L.dbu
    U = lambda v: int(round(v / D))
    def lid(ln, dt):
        for i in L.layer_indexes():
            inf = L.get_info(i)
            if inf.layer == ln and inf.datatype == dt:
                return i
    M4, M5 = lid(71, 20), lid(72, 20)
    top = L.top_cell()

    def reg(li):
        r = db.Region(top.begin_shapes_rec(li)); r.merge()
        return r

    m4, m5 = reg(M4), reg(M5)
    overlap = m4 & m5
    b5 = m5.merged()
    # y=1200 切片
    row = db.Region(db.Box(U(850), U(1199.9), U(1600), U(1200.1)))
    s5 = (m5 & row).merged()
    s4 = (m4 & row).merged()
    xs5 = sorted((p.bbox().left * D, p.bbox().right * D) for p in s5)
    xs4 = sorted((p.bbox().left * D, p.bbox().right * D) for p in s4)
    left5 = [x for x in xs5 if x[0] < 900]
    right5 = [x for x in xs5 if x[0] > 1500]
    left4 = [x for x in xs4 if x[0] < 900]
    right4 = [x for x in xs4 if x[0] > 1560]
    print("== %s W5=%.1f G0/G1=%.1f/%.1f" % (tag, W5, G0, G1))
    print("  met5 左环 x %.3f-%.3f  宽 %.3f (期望 %.3f)" % (left5[0][0], left5[0][1], left5[0][1]-left5[0][0], W5))
    print("  met5 右环 x %.3f-%.3f  宽 %.3f" % (right5[0][0], right5[0][1], right5[0][1]-right5[0][0]))
    print("  met4 左环 x %.3f-%.3f | met5 左环外沿 %.3f -> 跨层间隙 %.3f"
          % (left4[0][0], left4[0][1], left5[0][0], left5[0][0]-left4[0][1]))
    print("  met4 右环 x %.3f-%.3f | met5 右环外沿 %.3f -> 跨层间隙 %.3f"
          % (right4[0][0], right4[0][1], right5[0][1], right4[0][0]-right5[0][1]))
    print("  met5 环内沿: 左 %.3f 右 %.3f (core 892.5/1532.5)" % (left5[0][1], right5[0][0]))
    print("  met4&met5 重叠多边形数 %d  面积 %.1f um2" % (overlap.size(), overlap.area() * (D**2)))
