# 把 seal ring GDS 合并进 core GDS。
# 注意：copy_tree_shapes 的第二个参数必须是 CellMapping，直接传 Cell 或 int 会 TypeError。
import klayout.db as k
core = k.Layout(); core.read('/home/user/openlane-rootfs/tmp/gds2/eco_it2t8.gds')
seal = k.Layout(); seal.read('/home/user/openlane-rootfs/tmp/seal8/advSeal_6um_gen.gds')
print('seal bbox', seal.top_cell().bbox())
newtop = core.create_cell('t8_sealed')
main = core.cell('sha256_axil')
# core 640x640 放到 (12,12)-(652,652)，落在 seal 内框内侧
newtop.insert(k.CellInstArray(main.cell_index(), k.Trans(k.Vector(12000, 12000))))
sc = core.create_cell('advSeal_6um_gen')
cm = k.CellMapping(); cm.for_single_cell_full(sc, seal.top_cell())
core.copy_tree_shapes(seal, cm)
newtop.insert(k.CellInstArray(sc.cell_index(), k.Trans()))
print('sealed bbox', newtop.bbox())
core.write('/home/user/openlane-rootfs/tmp/gds2/t8_sealed.gds')
print('OK')
