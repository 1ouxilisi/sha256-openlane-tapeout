#!/usr/bin/env python3
"""li1_guard.py — 出 GDS 前的最后一道闸

判据：DEF 的 NETS 里不允许出现「竖直 li1 线段长度 >= 一个标准单元行高」的走线。
sky130A 行高 2.72 um = 2720 dbu。li1 是单元内部互连层，一旦被当成跨行走线，
就会同时碰到相邻两行的 tap / diode li1，而 tap li1 分别经 mcon 接在 VGND 与
VPWR 的 met1 电源轨上 —— 两条轨连成一片，LVS 侧表现就是电源网并网。

实测对照（同一判据，2026-11-11）：
  eco_it2.def           0 条（f 线，LVS 通过那版；最长竖线 1,700 dbu）
  eco_it2_eco2.def      0 条
  eco_it2_eco3.def     23 条（最长 105,060 dbu）
  eco_it2_eco4.def     23 条
  eco_it2_t2.def        0 条（先布后插二极管的修复版）

用法: python3 li1_guard.py <def> [行高dbu，默认 2720]
退出码: 0 通过 / 1 发现跨行 li1 / 2 用法错误
"""
import sys


def scan(path, pitch=2720):
    rows = []
    cur = ''
    for line in open(path, encoding='utf-8', errors='ignore'):
        s = line.rstrip('\n')
        if s.startswith('    - '):
            cur = s.split()[1]
        t = s.split()
        if len(t) < 10 or t[0] != 'NEW' or t[1] != 'li1':
            continue
        if t[2] != '(' or t[6] != '(':
            continue
        ax, ay = int(t[3]), int(t[4])
        bx = ax if t[7] == '*' else int(t[7])
        by = ay if t[8] == '*' else int(t[8])
        if bx != ax:
            continue
        length = abs(by - ay)
        if length >= pitch:
            rows.append((cur, ax, min(ay, by), max(ay, by), length))
    return rows


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    path = sys.argv[1]
    pitch = int(sys.argv[2]) if len(sys.argv) > 2 else 2720
    rows = scan(path, pitch)
    print('DEF            : %s' % path)
    print('row pitch      : %d dbu' % pitch)
    print('cross-row li1  : %d' % len(rows))
    for r in rows[:12]:
        print('  net=%-12s x=%d y=%d..%d len=%d' % r)
    if rows:
        print('VERDICT: FAIL  存在 %d 条跨行 li1 走线，出 GDS 前必须重布' % len(rows))
        return 1
    print('VERDICT: PASS  无跨行 li1 走线')
    return 0


if __name__ == '__main__':
    sys.exit(main())
