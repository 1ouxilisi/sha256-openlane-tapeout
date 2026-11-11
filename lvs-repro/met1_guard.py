#!/usr/bin/env python3
"""met1_guard.py — met1 做 bottom layer 之后的配套闸门

判据：DEF 的 NETS 里不允许出现「竖直 met1 线段长度 >= 一个标准单元行高」的走线。
sky130A 行高 2.72 µm = 2720 dbu。met1 上每隔一条就是全宽电源轨
（VGND y = 625600 − 5440k，VPWR y = 628320 − 5440k，相邻两条间距 2720 dbu），
所以一条跨 2720 dbu 的竖直 met1 段会同时碰到相邻两条不同网的轨。
这就是 `detailed_route -bottom_routing_layer met1` 会引入的那类短接
（旧账：net46 被拉成 94 µm met1 竖线，`NEW met1 ( 241730 12750 ) ( * 106930 )`）。

这个判据只说明「几何上跨了两条轨的高度」，不说明电一定短——
要不要放行，得再看抽取网表的 VGND/VPWR token 是否平衡、netgen 是否唯一匹配。

用法: python3 met1_guard.py <def> [行高dbu，默认 2720]
退出码: 0 通过 / 1 发现跨行 met1 / 2 用法错误
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
        if len(t) < 10 or t[0] != 'NEW' or t[1] != 'met1':
            continue
        if t[2] != '(' or t[6] != '(':
            continue
        ax, ay = int(t[3]), int(t[4])
        bx = ax if t[7] == '*' else int(t[7])
        by = ay if t[8] == '*' else int(t[8])
        if bx != ax:
            continue
        L = abs(by - ay)
        if L >= pitch:
            rows.append((cur, ax, min(ay, by), max(ay, by), L))
    return rows


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    path = sys.argv[1]
    pitch = int(sys.argv[2]) if len(sys.argv) > 2 else 2720
    rows = scan(path, pitch)
    rows.sort(key=lambda r: -r[4])
    print('DEF            : %s' % path)
    print('row pitch      : %d dbu' % pitch)
    print('cross-row met1 : %d' % len(rows))
    for r in rows[:12]:
        print('  net=%-14s x=%d y=%d..%d len=%d' % r)
    if rows:
        print('VERDICT: FAIL  %d 条跨行 met1，出 GDS 前需确认与电源轨无 overlap' % len(rows))
        return 1
    print('VERDICT: PASS  无跨行 met1')
    return 0


if __name__ == '__main__':
    sys.exit(main())
