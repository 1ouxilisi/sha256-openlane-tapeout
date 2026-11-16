import klayout.db as db
L = db.Layout(); L.dbu = 0.001
L.read("/home/user/padring/sha256_chip23.gds")
def lid(ln, dt):
    for i in L.layer_indexes():
        inf = L.get_info(i)
        if inf.layer == ln and inf.datatype == dt:
            return i
M4, M5 = lid(71, 20), lid(72, 20)
top = L.top_cell()

def segs(li, y, xlo=0.0, xhi=2425.0):
    r = db.Region(top.begin_shapes_rec(li))
    box = db.Box(int(xlo*1000), int((y-0.05)*1000), int(xhi*1000), int((y+0.05)*1000))
    clip = r & db.Region(box)
    out = []
    for p in clip.each():
        b = p.bbox()
        out.append((b.left/1000.0, b.right/1000.0))
    return sorted(out)

for y in [280.715, 1200.0]:
    print("=== y", y, "MET4 (left half x<900)")
    for a, c in segs(M4, y):
        if c < 900:
            print("   m4", a, c, "w %.3f" % (c-a))
    print("    MET5 (left half x<900)")
    for a, c in segs(M5, y):
        if c < 900:
            print("   m5", a, c, "w %.3f" % (c-a))
