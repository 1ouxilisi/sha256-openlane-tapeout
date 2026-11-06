#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
gen_sha256_tb.py - 生成 SHA-256 单块压缩核的 testbench 与测试向量
验证基准: Python hashlib.sha256 (标准实现), 填充规则符合 FIPS 180-4
"""
import hashlib


def pad_to_single_block(msg: bytes) -> bytes:
    """SHA-256 填充, 要求填充后为单个 512-bit 块 (消息 < 448 bit)"""
    L = len(msg) * 8
    assert L < 448, f"message too long for single block: {L} bits"
    m = msg + b'\x80'
    while (len(m) * 8) % 512 != 448:
        m += b'\x00'
    m += L.to_bytes(8, 'big')
    assert len(m) == 64, f"padded block size = {len(m)}"
    return m


# 测试向量: (名称, 原始消息)
# 期望摘要 = hashlib.sha256(原始消息).hexdigest()
tests = [
    ("empty", b""),
    ("single_a", b"a"),
    ("abc", b"abc"),
    ("fox", b"The quick brown fox jumps over the lazy dog"),
    ("55_bytes", bytes(range(55))),                      # 长度字节递增, 接近单块上限
    ("incr33", bytes(range(1, 34))),                     # 33 字节递增
    ("zeros44", b"\x00" * 44),                           # 44 字节全 0
    ("all_ff", b"\xff" * 48),                            # 48 字节全 1
    ("ascii_rep", b"abc123xyz" * 5),                     # 45 字节循环文本
    ("rand32", bytes(range(0x20, 0x40))),                # 32 字节伪随机
    ("rand55", bytes((i * 7) % 256 for i in range(55))), # 55 字节确定性伪随机
    ("numeric", b"0123456789abcdef0123456789abcdef0123456789abcd"),  # 55 字节文本
]


def verilog_hex(value: bytes, width: int) -> str:
    return f"{width}'h{value.hex()}"


def build_testbench() -> str:
    lines = []
    lines.append("`timescale 1ns/1ps")
    lines.append("// ============================================================")
    lines.append("// sha256_tb.v - SHA-256 压缩核 testbench")
    lines.append("// 验证向量: Python hashlib.sha256 (FIPS 180-4 填充规则) 生成")
    lines.append("// 运行: iverilog -o sim sha256.v sha256_tb.v && vvp sim")
    lines.append("// ============================================================")
    lines.append("module sha256_tb;")
    lines.append("    reg clk = 0, reset_n = 0, start = 0;")
    lines.append("    reg [511:0] msg;")
    lines.append("    wire [255:0] digest;")
    lines.append("    wire done;")
    lines.append("    integer errors = 0;")
    lines.append("")
    lines.append("    sha256_core dut(")
    lines.append("        .clk(clk), .reset_n(reset_n), .start(start),")
    lines.append("        .msg(msg), .digest(digest), .done(done)")
    lines.append("    );")
    lines.append("")
    lines.append("    always #5 clk = ~clk;")
    lines.append("")
    lines.append("    task run_test(input [511:0] m, input [255:0] exp);")
    lines.append("        integer cycles;")
    lines.append("        begin")
    lines.append("            msg = m;")
    lines.append("            @(posedge clk); #1;")
    lines.append("            start = 1;")
    lines.append("            @(posedge clk); #1;")
    lines.append("            start = 0;")
    lines.append("            cycles = 0;")
    lines.append("            while (done !== 1'b1 && cycles < 200) begin")
    lines.append("                @(posedge clk); #1;")
    lines.append("                cycles = cycles + 1;")
    lines.append("            end")
    lines.append("            if (cycles >= 200) begin")
    lines.append("                errors = errors + 1;")
    lines.append("                $display(\"FAIL: done timeout\");")
    lines.append("            end")
    lines.append("            else if (digest !== exp) begin")
    lines.append("                errors = errors + 1;")
    lines.append("                $display(\"FAIL: digest mismatch\");")
    lines.append("                $display(\"  got  %h\", digest);")
    lines.append("                $display(\"  want %h\", exp);")
    lines.append("            end")
    lines.append("            else begin")
    lines.append("                $display(\"PASS: %h\", digest);")
    lines.append("            end")
    lines.append("            @(posedge clk); #1;")
    lines.append("        end")
    lines.append("    endtask")
    lines.append("")
    lines.append("    initial begin")
    lines.append("        reset_n = 0;")
    lines.append("        repeat (5) @(posedge clk);")
    lines.append("        reset_n = 1;")
    lines.append("        @(posedge clk); #1;")

    for name, msg_bytes in tests:
        block = pad_to_single_block(msg_bytes)
        expected = hashlib.sha256(msg_bytes).hexdigest()
        b_hex = verilog_hex(block, 512)
        e_hex = verilog_hex(bytes.fromhex(expected), 256)
        lines.append(f"        $display(\"--- test: {name} ---\");")
        lines.append(f"        run_test({b_hex}, {e_hex});")

    lines.append("        $display(\"================================\");")
    lines.append("        if (errors == 0)")
    lines.append("            $display(\"ALL TESTS PASSED (%0d)\", 1);")
    lines.append("        else")
    lines.append("            $display(\"TESTS FAILED: %0d error(s)\", errors);")
    lines.append("        $finish;")
    lines.append("    end")
    lines.append("endmodule")
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    tb = build_testbench()
    out = r"E:\BaiduNetdiskDownload\yuanbao\openlane-chips\designs\sha256\src\sha256_tb.v"
    with open(out, "w", encoding="utf-8", newline="") as f:
        f.write(tb)
    print(f"testbench written: {out} ({len(tb)} chars, {len(tests)} test vectors)")
    # 打印向量摘要供人工核对
    for name, msg_bytes in tests:
        block = pad_to_single_block(msg_bytes)
        expected = hashlib.sha256(msg_bytes).hexdigest()
        print(f"  {name:10s} block={block.hex()[:40]}...  expect={expected[:16]}...")
