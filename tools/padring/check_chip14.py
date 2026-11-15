import json, klayout.db as db

L = db.Layout(); L.dbu = 0.001
L.read("/home/user/padring/sha256_chip13.gds")   # 基线（已通过 DRC）
D = L.dbu
U = lambda v: int(round(v / D))
def lid(ln, dt):
    for i in L.layer_indexes():
        inf = L.get_info(i)
        if inf.layer == ln and inf.datatype == dt:
            return i
M4, M5, V4 = lid(71, 20), lid(72, 20), lid(71, 44)
top = L.top_cell()

DELTA = json.load(open("/tmp/chip14_delta.json"))
LAY = {"met4": M4, "met5": M5, "via4": V4}
RULE = {"met4": 0.3, "met5": 1.6, "via4": 0.8}
WMIN = {"met4": 0.3, "met5": 1.6, "via4": 0.8}

def region(li):
    r = db.Region(top.begin_shapes_rec(li)); r.merge(); return r

base = {k: region(v) for k, v in LAY.items()}
delta_boxes = {}
for (nm, a, b, c, d) in DELTA:
    delta_boxes.setdefault(nm, []).append(db.Box(U(a), U(b), U(c), U(d)))

report = []
# 1) 宽度检查
for nm, boxes in delta_boxes.items():
    for bx in boxes:
        w = min(bx.width(), bx.height()) * D
        if w < WMIN[nm] - 1e-9:
            report.append("WIDTH-FAIL %s %s w=%.3f" % (nm, bx, w))

# 2) 同层间距：combined 上做 space_check，保留与 delta 相接触的边对
for nm, boxes in delta_boxes.items():
    if nm == "via4":
        continue
    comb = base[nm].dup()
    for bx in boxes: comb.insert(bx)
    comb.merge()
    pairs = comb.space_check(U(RULE[nm]))
    n_bad = 0
    for ep in pairs.each():
        hit = False
        for bx in boxes:
            if db.Region(bx).expanded(2).interacting(db.Region(ep.polygon().bbox())).size() > 0:
                hit = True; break
        if hit:
            n_bad += 1
            if n_bad <= 6:
                report.append("SPACE-FAIL %s %.3f vs %.3f" % (nm, ep.distance(), RULE[nm]))
    if n_bad:
        report.append("SPACE total %s: %d pairs involving delta" % (nm, n_bad))

# 3) 兼容性：delta 与既有同层图形的接触情况（列出接触到的既有图形 bbox，人工确认是预期连接）
print("=== delta 与既有同层图形的接触 ===")
for nm, boxes in delta_boxes.items():
    for bx in boxes:
        t = base[nm].interacting(db.Region(bx))
        info = []
        for s in t:
            b = s.bbox()
            ov = db.Region(bx) & db.Region(s.bbox())
            info.append("[(%.2f,%.2f)-(%.2f,%.2f) ov=%.3f]" % (
                b.left*D, b.bottom*D, b.right*D, b.top*D, ov.area()*D*D))
        print("%-5s %s -> %d contacts %s" % (nm, ("(%.2f,%.2f)-(%.2f,%.2f)" % (
            bx.left*D, bx.bottom*D, bx.right*D, bx.top*D)), len(info), " ".join(info[:3])))

# 4) via 必须被 m4 与 m5 双侧覆盖，且余量 >= 0.19 / 0.31
print("=== via 上下层包覆检查 ===")
comb4 = base["met4"].dup(); comb5 = base["met5"].dup()
for bx in delta_boxes.get("met4", []): comb4.insert(bx)
for bx in delta_boxes.get("met5", []): comb5.insert(bx)
for bx in delta_boxes.get("via4", []): comb4.insert(bx); comb5.insert(bx)
comb4.merge(); comb5.merge()
for bx in delta_boxes.get("via4", []):
    for nm, reg, need in (("met4", comb4, 0.19), ("met5", comb5, 0.31)):
        # 找包含该 via 的图形，算 via 到该图形边界的最小距离
        cand = reg.interacting(db.Region(bx))
        best = -1
        for s in cand:
            b = s.bbox()
            # 只在候选完全包住 via 时计算
            if b.left <= bx.left and b.right >= bx.right and b.bottom <= bx.bottom and b.top >= bx.top:
                d = min(bx.left - b.left, b.right - bx.right, bx.bottom - b.bottom, b.top - bx.top) * D
                best = max(best, d)
        ok = best >= need - 1e-9
        print("  via(%.2f,%.2f) %s enclosure=%.3f need>=%.2f %s" % (
            bx.left*D, bx.bottom*D, nm, best, need, "OK" if ok else "FAIL"))
        if not ok:
            report.append("ENCL-FAIL via %s %s %.3f" % (bx, nm, best))

print("=== 报告 ===")
if report:
    for line in report: print("  ", line)
else:
    print("  no geometry rule failures detected")
