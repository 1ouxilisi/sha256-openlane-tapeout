# -*- coding: utf-8 -*-
"""独立校验 testbench 里的期望值常量。

目的：仿真通过只证明「设计等于 testbench 里写的期望值」，
     还需证明「testbench 里的期望值等于真实 SHA-256 结果」。
本脚本用 Python 标准库 hashlib 独立算出三组锚点的结果，
再与 designs/sha256/src/sha256_top_tb.v 里的 localparam DIG_* 常量比对。

用法：python3 scripts/check_vectors.py
退出码：0 = 全部一致，1 = 有差异
"""
import hashlib
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TB = ROOT / "designs" / "sha256" / "src" / "sha256_top_tb.v"

CASES = {
    "DIG_ABC": b"abc",
    "DIG_EMPTY": b"",
    "DIG_FOX": b"The quick brown fox jumps over the lazy dog",
}

CONST_RE = re.compile(r"localparam\s+\[255:0\]\s+(DIG_\w+)\s*=\s*256'h([0-9a-fA-F]{64})\s*;")


def padded_block(msg: bytes) -> bytes:
    n = len(msg)
    m = bytearray(msg)
    m.append(0x80)
    while len(m) % 64 != 56:
        m.append(0x00)
    m += (n * 8).to_bytes(8, "big")
    return bytes(m)


def main() -> int:
    if not TB.exists():
        print("[FAIL] 找不到 testbench: %s" % TB)
        return 1

    text = TB.read_text(encoding="utf-8", errors="replace")
    found = {name: h.lower() for name, h in CONST_RE.findall(text)}
    if not found:
        print("[FAIL] testbench 中未找到 DIG_* 常量，检查文件是否被改动")
        return 1

    ok = 0
    bad = 0
    for name, msg in CASES.items():
        block = padded_block(msg)
        # 单块消息：SHA-256(msg) 就等于「IV + 对 padded(msg) 做一次压缩」，
        # 也正是 testbench 里那个 512-bit 块喂给 core 后期望得到的结果。
        assert len(block) == 64, "向量必须正好占一个 512-bit 块"
        want = hashlib.sha256(msg).hexdigest()
        got = found.get(name)
        if got is None:
            print("[FAIL] %-10s testbench 缺少该常量" % name)
            bad += 1
        elif got == want:
            print("[OK]   %-10s %s" % (name, got))
            ok += 1
        else:
            print("[FAIL] %-10s tb=%s hashlib=%s" % (name, got, want))
            bad += 1

    print("-" * 50)
    print("SUMMARY: ok=%d bad=%d" % (ok, bad))
    if bad == 0:
        print("VECTORS MATCH HASH LIBRARY")
        return 0
    print("VECTORS MISMATCH")
    return 1


if __name__ == "__main__":
    sys.exit(main())
