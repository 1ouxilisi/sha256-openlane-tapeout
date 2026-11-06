# -*- coding: utf-8 -*-
"""trace2hex.py —— 把 C 驱动打出的可读 trace 转成 testbench 的 72-bit 程序文件

这一层刻意做得很薄，且可审计：只做格式转换，不解释任何语义。
谁改了 trace 格式，这里一眼就能看出。

trace 行格式：
    # 注释
    W <addr 8 hex> <data 8 hex>
    WAIT
    END

输出 72-bit 行 = {cmd[7:0], addr[31:0], data[31:0]}，cmd: 01=W / 02=WAIT / 03=END
"""
import sys
import pathlib

CMD = {"W": 0x01, "WAIT": 0x02, "END": 0x03}


def convert(trace_path, out_path):
    lines = pathlib.Path(trace_path).read_text(encoding="utf-8").splitlines()
    out = []
    for ln in lines:
        s = ln.strip()
        if not s or s.startswith("#"):
            continue
        parts = s.split()
        op = parts[0].upper()
        if op not in CMD:
            raise SystemExit("trace 里有不认识的指令: %r" % ln)
        addr = int(parts[1], 16) if len(parts) > 1 else 0
        data = int(parts[2], 16) if len(parts) > 2 else 0
        out.append("%02x%08x%08x" % (CMD[op], addr, data))
    pathlib.Path(out_path).write_text("\n".join(out) + "\n", encoding="utf-8")
    return len(out)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: trace2hex.py <trace.txt> <prog.hex>")
    n = convert(sys.argv[1], sys.argv[2])
    print("CONVERTED %d ops -> %s" % (n, sys.argv[2]))
