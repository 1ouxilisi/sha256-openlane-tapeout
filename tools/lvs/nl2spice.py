#!/usr/bin/env python3
"""把 nl.v（OpenROAD 布线后网表）转成 netgen 可比的 SPICE。

三条规则都是踩出来的，不是风格选择：
  1. 未连接的引脚必须按「实例/引脚」命名。写成 NC_X / NC_Y 这类共享常量名，
     几十上百个悬空输出会被 netgen 归成同一类，报成一片 Net mismatch。
  2. 电源引脚按版图口径连：VGND/VNB -> VGND，VPB/VPWR -> VPWR。
     Verilog 网表里常常不写电源连接，靠这里补齐。
  3. fill_1 / fill_2 / tapvpwrvgnd_1 在版图里没有器件（.subckt 是空的），
     实例与定义两侧同删，否则会被展平成 unmatched。

另外顶层有 4 个重复端口（s_axil_bresp[0..1] / s_axil_rresp[0..1]）只出现在
Verilog 侧、版图侧不存在，必须两侧同删（98 -> 94）。删掉端口后，
原先 assign 给这些端口的那几个 net 变成单引脚悬空网，netgen 不参与比对。
"""
import argparse
import re
import sys

POWER = {"VGND", "VNB", "VPB", "VPWR"}
POWER_MAP = {"VGND": "VGND", "VNB": "VGND", "VPB": "VPWR", "VPWR": "VPWR"}
DROP_CELLS = {"sky130_fd_sc_hd__fill_1", "sky130_fd_sc_hd__fill_2",
              "sky130_fd_sc_hd__tapvpwrvgnd_1"}
DROP_PORTS = {"s_axil_bresp[0]", "s_axil_bresp[1]", "s_axil_rresp[0]", "s_axil_rresp[1]"}


def unescape(name):
    """Verilog 里 \\u_core.t[4] 这种转义标识符 -> u_core.t[4]。"""
    n = name.replace("\\", "").strip()
    return n


def parse_ports(text):
    """读 module 头里的端口声明顺序与位宽，展开成 94 个具体端口名。"""
    m = re.search(r"module\s+(\w+)\s*\((.*?)\);", text, re.S)
    if not m:
        raise SystemExit("module header not found")
    mod = m.group(1)
    names = [p.strip() for p in m.group(2).replace("\n", " ").split(",")]
    widths = {}
    for mm in re.finditer(r"^\s*(input|output|inout)\s*(?:\[(\d+):(\d+)\]\s*)?(\w+)\s*;",
                          text, re.M):
        kind, hi, lo, nm = mm.groups()
        widths[nm] = (int(hi), int(lo)) if hi is not None else None
    ports = []
    for nm in names:
        w = widths.get(nm)
        if w:
            hi, lo = w
            step = -1 if hi >= lo else 1
            ports += ["%s[%d]" % (nm, i) for i in range(hi, lo + step, step)]
        else:
            ports.append(nm)
    return mod, ports


INST_RE = re.compile(r"^\s*(sky130\w+)\s+(\w+)\s*\((.*?)\)\s*;", re.S | re.M)
PIN_RE = re.compile(r"\.(\w+)\s*\(\s*(.*?)\s*\)")


def parse_instances(text):
    inst = []
    for m in INST_RE.finditer(text):
        cell, name, body = m.groups()
        conns = {}
        for pm in PIN_RE.finditer(body):
            conns[pm.group(1)] = unescape(pm.group(2))
        inst.append((cell, name, conns))
    return inst


def cell_defs(pdk_spice_files, wanted):
    """从 PDK 单元库里逐个抠出用到的 .subckt，并返回每个单元的引脚顺序。"""
    blocks, order = {}, {}
    for path in pdk_spice_files:
        txt = open(path, encoding="utf-8", errors="replace").read()
        for m in re.finditer(r"^\.subckt\s+(\S+)(.*?)^\.ends\s*$", txt, re.S | re.M):
            name = m.group(1)
            if name not in wanted or name in blocks:
                continue
            pins = m.group(2).split("\n", 1)[0].split()
            order[name] = pins
            blocks[name] = ".subckt " + name + m.group(2).rstrip() + "\n.ends\n"
    return blocks, order


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-n", "--netlist", required=True)
    ap.add_argument("-p", "--pdk-spice", nargs="+", required=True)
    ap.add_argument("-o", "--out", required=True)
    ap.add_argument("--cell", default="sha256_axil")
    args = ap.parse_args()

    text = open(args.netlist, encoding="utf-8", errors="replace").read()
    mod, ports = parse_ports(text)
    insts = parse_instances(text)

    used = {c for c, _, _ in insts if c not in DROP_CELLS}
    dropped = sum(1 for c, _, _ in insts if c in DROP_CELLS)
    blocks, pins = cell_defs(args.pdk_spice, used)
    missing = sorted(used - set(blocks))
    if missing:
        raise SystemExit("cell spice not found for: %s" % missing)

    n_ports_before = len(ports)
    # nl.v 不声明电源端口（隐含 SUPPLY），版图侧 VGND/VPWR 是显式顶层端口，这里补上。
    ports = ["VGND", "VPWR"] + [p for p in ports if p not in DROP_PORTS and p not in ("VGND", "VPWR")]

    lines = []
    for cell, name, conns in insts:
        if cell in DROP_CELLS:
            continue
        args_ = []
        for pin in pins[cell]:
            if pin in POWER:
                net = POWER_MAP[pin]
            elif pin in conns and conns[pin]:
                net = conns[pin]
            else:
                # 未连接：按「实例/引脚」命名，不能用共享常量名
                net = "%s/%s" % (name, pin)
            args_.append(net)
        lines.append("X%s %s %s" % (name, " ".join(args_), cell))

    out = []
    out.append("* LVS netlist side: %s (from %s)" % (mod, args.netlist.split("/")[-1]))
    out.append(".subckt %s %s" % (mod, " ".join(ports)))
    out += lines
    out.append(".ends %s" % mod)
    out.append("")
    for cell in sorted(blocks):
        out.append(blocks[cell].rstrip())
    open(args.out, "w", encoding="utf-8").write("\n".join(out) + "\n")

    pd = sorted(used)
    print("INSTANCES   %d  (dropped fill/tap %d)" % (len(lines), dropped))
    print("CELL_TYPES  %d" % len(pd))
    print("PORTS       %d  (dropped %d duplicate)" % (len(ports), n_ports_before - len(ports)))
    print("OUT         %s" % args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
