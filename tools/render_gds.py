#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
render_gds.py - 用 KLayout 把 GDS 版图渲染成 PNG 图片

用途: OpenLane 跑完 RTL->GDS 后, 把最终版图渲染成可视化图片, 作为作品展示。

用法 (在 OpenLane 镜像内, KLayout 已自带):
    klayout -b -r render_gds.py <input.gds> <output.png> [top_cell_name]

说明:
    - 依赖 KLayout 的 Python API (pya), OpenLane 镜像内自带。
    - 若 PDK 提供 Sky130 的 KLayout 层属性文件 (.lyp), 优先用它设颜色更美观。
    - 不同 KLayout 版本 API 略有差异, 如报错按实际版本微调。
"""
import sys
import pya


def render_gds(gds_path: str, png_path: str, top_name: str = None) -> None:
    app = pya.Application.instance()
    mw = app.main_window()

    # 读取版图
    ly = pya.Layout()
    ly.read(gds_path)
    print(f"  layout: {gds_path}")
    print(f"  cells: {[c.name for c in ly.each_cell()]}")

    # 指定顶层 (默认取顶层 cell)
    if top_name:
        top = ly.cell(top_name)
        if top is None:
            raise ValueError(f"top cell '{top_name}' not found")
        ly.top_cell = top

    # 在 KLayout 主窗口创建视图
    lv = mw.view(ly)
    if lv is None:
        raise RuntimeError("failed to create layout view")

    # 缩放到整个版图范围
    lv.zoom_fit()

    # 渲染为 PNG (按当前视图尺寸)
    lv.save_image(png_path, lv.width(), lv.height())
    print(f"  rendered -> {png_path}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("usage: klayout -b -r render_gds.py <input.gds> <output.png> [top_cell]")
        sys.exit(1)
    gds = sys.argv[1]
    png = sys.argv[2]
    top = sys.argv[3] if len(sys.argv) > 3 else None
    render_gds(gds, png, top)
