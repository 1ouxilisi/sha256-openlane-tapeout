# -*- coding: utf-8 -*-
"""GDS 逐层 XOR（只依赖 KLayout 的 Python 接口 klayout.db）
用法：python3 xor_layers.py [A.gds] [B.gds]
在 OpenLane 的 chroot 里跑：
  PYTHONPATH=<klayout-pymod>/lib/python3.11/site-packages python3 xor_layers.py
比较的是顶层展开后的几何覆盖（Region XOR），不是多边形条数——
所以一方把多边形合并了，条数会不同但 XOR 仍为 0。
"""
import sys
import klayout.db as db

A_PATH = sys.argv[1] if len(sys.argv) > 1 else "/designs/sha256_v7b/runs/tapeout16/results/signoff/sha256_axil.gds"
B_PATH = sys.argv[2] if len(sys.argv) > 2 else "/designs/sha256_v7b/runs/tapeout16/results/signoff/sha256_axil.klayout.gds"

A = db.Layout(); A.read(A_PATH)
B = db.Layout(); B.read(B_PATH)
ta, tb = A.top_cell(), B.top_cell()
print("A top=%s cells=%d" % (ta.name, A.cells()))
print("B top=%s cells=%d" % (tb.name, B.cells()))

keys = set()
for ly in (A, B):
    for li in ly.layer_indices():
        i = ly.get_info(li)
        keys.add((i.layer, i.datatype))

la, lb = {}, {}
for li in A.layer_indices():
    i = A.get_info(li); la[(i.layer, i.datatype)] = li
for li in B.layer_indices():
    i = B.get_info(li); lb[(i.layer, i.datatype)] = li

total = 0
for k in sorted(keys):
    ia, ib = la.get(k), lb.get(k)
    ra = db.Region(ta.begin_shapes_rec(ia)) if ia is not None else db.Region()
    rb = db.Region(tb.begin_shapes_rec(ib)) if ib is not None else db.Region()
    x = ra ^ rb
    n = x.count()
    total += n
    print("%3d/%d  A=%-8d B=%-8d XOR=%d" % (k[0], k[1], ra.count(), rb.count(), n))

print("TOTAL_XOR_POLYGONS=%d" % total)
