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

# region the left band could move into: x 200..860, y 860..1564 (band y range)
def innermost(li, xlo, xhi, ylo, yhi):
    r = db.Region(top.begin_shapes_rec(li)); r.merge()
    box = db.Box(int(xlo*1000), int(ylo*1000), int(xhi*1000), int(yhi*1000))
    clip = r & db.Region(box)
    best = None
    for p in clip.each():
        b = p.bbox()
        if best is None or b.right > best:
            best = b.right
    return best, clip.size()

# left band corridor
for nm, li in [("met4", M4), ("met5", M5)]:
    v, n = innermost(li, 200.0, 860.0, 860.55, 1564.45)
    print("LEFT corridor", nm, "innermost x", (v/1000 if v else None), "polys", n)
# bottom band corridor (y 200..860, x 860..1564)
for nm, li in [("met4", M4), ("met5", M5)]:
    v, n = innermost(li, 860.55, 1564.45, 200.0, 860.0)
    print("BOTTOM corridor", nm, "innermost y", (v/1000 if v else None), "polys", n)
# widen y window to see corner chains
for nm, li in [("met4", M4), ("met5", M5)]:
    v, n = innermost(li, 200.0, 860.0, 150.0, 1564.45)
    print("LEFT wide-y", nm, "innermost x", (v/1000 if v else None), "polys", n)
