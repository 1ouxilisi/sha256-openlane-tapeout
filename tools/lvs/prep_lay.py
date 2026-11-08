#!/usr/bin/env python3
"""把 Magic 从 .mag 提取出的 SPICE 整理成 netgen 可读的版图侧网表。

两件事：
  1. Magic 写 SPICE 时按固定列宽折行，端口表与长行会另起一行并以 `+` 开头。
     不拼回去，按行首数实例/端口就会数错（这是本项目真实踩过的坑）。
  2. Magic 对带方括号的总线网名做转义（u_core.msg\\[275\\]）。
     不还原，netgen 会认为两侧是两个不同名字的网。
"""
import argparse
import re
import sys

TOP_DEFAULT = "sha256_axil"
# 顶层重复端口：Magic 从版图里也提到了这 4 条（DEF 里有 pin label），但两侧都不该有。
DROP_PORTS = {"s_axil_bresp[0]", "s_axil_bresp[1]", "s_axil_rresp[0]", "s_axil_rresp[1]"}


def unwrap(lines):
    out = []
    for ln in lines:
        if ln.lstrip().startswith("+") and out:
            out[-1] = out[-1].rstrip() + " " + ln.lstrip()[1:].strip()
        else:
            out.append(ln.rstrip())
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-i", "--input", required=True)
    ap.add_argument("-o", "--output", required=True)
    ap.add_argument("--top", default=TOP_DEFAULT)
    ap.add_argument("--expect-ports", type=int, default=94)
    args = ap.parse_args()

    raw = open(args.input, encoding="utf-8", errors="replace").read().splitlines()
    folded = sum(1 for ln in raw if ln.lstrip().startswith("+"))
    lines = [ln.replace("\\", "") for ln in unwrap(raw)]

    ports = None
    subs, empty = 0, []
    insts = 0
    cur = None
    body_count = {}
    for ln in lines:
        s = ln.strip()
        if s.startswith(".subckt"):
            parts = s.split()
            subs += 1
            cur = parts[1]
            body_count[cur] = 0
            if cur == args.top:
                ports = parts[2:]
            continue
        if s.startswith(".ends"):
            cur = None
            continue
        if cur:
            body_count[cur] += 1
            if cur == args.top and s[:1] in ("X", "R"):
                insts += 1
    empty = [c for c, n in body_count.items() if n == 0]

    if ports is None:
        raise SystemExit("top subckt %s not found" % args.top)
    ports = [p for p in ports if p not in DROP_PORTS]
    if len(ports) != args.expect_ports:
        raise SystemExit("port count %d != expected %d" % (len(ports), args.expect_ports))

    for i, ln in enumerate(lines):
        s = ln.strip()
        if s.startswith(".subckt") and s.split()[1] == args.top:
            lines[i] = ".subckt %s %s" % (args.top, " ".join(ports))
            break
    if empty:
        raise SystemExit("empty subckts present: %s" % empty)

    header = "* LVS layout side: %s (unwrapped %d continuation lines, unescaped)" % (args.top, folded)
    open(args.output, "w", encoding="utf-8").write(header + "\n" + "\n".join(lines).lstrip("\n") + "\n")

    print("UNWRAPPED   %d continuation lines" % folded)
    print("SUBCKTS     %d (empty 0)" % subs)
    print("TOP_PORTS   %d" % len(ports))
    print("TOP_INST    %d" % insts)
    print("OUT         %s" % args.output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
