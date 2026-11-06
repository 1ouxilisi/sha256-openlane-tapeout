# -*- coding: utf-8 -*-
# sha256_logic_check.py
# 用途: 在 iverilog 被 360 拦截期间, 用 Python 对照 hashlib 验证
#       SHA-256 压缩核的算法逻辑与 K 常量是否正确 (与 sha256.v 同一套常量/函数)。
# 运行: python tools\sha256_logic_check.py
# 说明: 这是"算法逻辑"级验证, 不等同于 Verilog 仿真; 语法/时序仍需 iverilog。

import hashlib

# ---- 与 sha256.v 完全一致的 64 个 K 常量 (case 函数内容) ----
K = [
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2,
]
H0 = [0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19]
MASK = 0xffffffff

def rotr(x, n): return ((x >> n) | (x << (32-n))) & MASK
def rotl(x, n): return ((x << n) | (x >> (32-n))) & MASK
def sigma0(x): return (rotr(x,7) ^ rotr(x,18) ^ (x >> 3)) & MASK
def sigma1(x): return (rotr(x,17) ^ rotr(x,19) ^ (x >> 10)) & MASK
def bs0(x):    return (rotr(x,2) ^ rotr(x,13) ^ rotr(x,22)) & MASK
def bs1(x):    return (rotr(x,6) ^ rotr(x,11) ^ rotr(x,25)) & MASK
def ch(x,y,z): return ((x & y) ^ ((~x) & z)) & MASK
def maj(x,y,z):return ((x & y) ^ (x & z) ^ (y & z)) & MASK

def sha256_compress(msg_bytes):
    """对已填充好的 64 字节消息块做单块压缩, 返回 32 字节摘要。"""
    assert len(msg_bytes) == 64
    w = list(struct.unpack('>16I', msg_bytes))
    for t in range(16, 64):
        w.append((sigma1(w[t-2]) + w[t-7] + sigma0(w[t-15]) + w[t-16]) & MASK)
    a,b,c,d,e,f,g,h = H0
    for t in range(64):
        t1 = (h + bs1(e) + ch(e,f,g) + K[t] + w[t]) & MASK
        t2 = (bs0(a) + maj(a,b,c)) & MASK
        h,g,f,e,d,c,b,a = g,f,e,(d+t1)&MASK,c,b,a,(t1+t2)&MASK
    hh = [(x+y)&MASK for x,y in zip([a,b,c,d,e,f,g,h], H0)]
    return b''.join(pack('>I', x) for x in hh)

import struct
from struct import pack

# ---- 13 组测试向量: (描述, 待哈希原文) ----
cases = [
    ("empty",      b""),
    ("single_a",   b"a"),
    ("abc",        b"abc"),
    # 注: 标准 abc_large (56字节) 需双块, 本核为单块设计, 故省略
    ("fox",        b"The quick brown fox jumps over the lazy dog"),
    ("55_bytes",   bytes(range(0x00, 0x37))),
    ("incr33",     bytes(range(0x01, 0x22))),
    ("zeros44",    b"\x00"*44),
    ("all_ff",     b"\xff"*48),
    ("ascii_rep",  b"abc123xyz"*5),
    ("rand32",     bytes(range(0x20, 0x40))),
    # rand55 (56字节) 需双块, 单块核不适用, 省略
    ("numeric",    b"0123456789abcdef"*3),
]

def pad_single_block(m):
    """FIPS 180-4 单块填充: 要求 len(m) < 448 bits (56 bytes)。"""
    assert len(m) < 56, "消息过长, 单块无法容纳"
    ml = len(m) * 8
    padded = m + b"\x80" + b"\x00" * (55 - len(m)) + ml.to_bytes(8, 'big')
    assert len(padded) == 64
    return padded

print("=== SHA-256 核心算法逻辑验证 (对照 hashlib) ===")
ok = 0
for name, data in cases:
    block = pad_single_block(data)
    got = sha256_compress(block).hex()
    exp = hashlib.sha256(data).hexdigest()
    status = "PASS" if got == exp else "FAIL"
    if got == exp: ok += 1
    print(f"[{status}] {name:10s} got={got[:16]}...  exp={exp[:16]}...")
print(f"结果: {ok}/{len(cases)} 通过")
print("(注: 本脚本验证算法逻辑与 K 常量正确; Verilog 语法/时序仍需 iverilog 仿真)")
