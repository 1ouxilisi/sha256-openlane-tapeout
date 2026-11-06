# -*- coding: utf-8 -*-
# rtl_fsm_sim.py
# 用途: 精确模拟 sha256.v 的四态 FSM (IDLE/COMPUTE/ACCUM/FINISH) 与 W 窗口,
#       在 iverilog 被 360 拦截期间, 用 Python 验证 RTL 状态机逻辑的时序正确性。
# 说明: 这是"RTL 逻辑行为"级模拟, 与 sha256.v 的 always 块逐周期对应;
#       不等同于 Verilog 语法/综合验证, 语法仍需仿真器确认。
# 运行: python tools\rtl_fsm_sim.py

import hashlib, struct
from struct import pack

MASK = 0xffffffff

# ---- 与 sha256.v 的 case 函数一致的 64 个 K 常量 ----
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

def rotr(x, n): return ((x >> n) | (x << (32-n))) & MASK
def sigma0(x): return (rotr(x,7) ^ rotr(x,18) ^ (x >> 3)) & MASK
def sigma1(x): return (rotr(x,17) ^ rotr(x,19) ^ (x >> 10)) & MASK
def bs0(x):    return (rotr(x,2) ^ rotr(x,13) ^ rotr(x,22)) & MASK
def bs1(x):    return (rotr(x,6) ^ rotr(x,11) ^ rotr(x,25)) & MASK
def ch(x,y,z): return ((x & y) ^ ((~x) & z)) & MASK
def maj(x,y,z):return ((x & y) ^ (x & z) ^ (y & z)) & MASK

# ---- 单块填充 ----
def pad_single(msg):
    L = len(msg)*8
    assert L < 448, "message too long for single block"
    m = msg + b"\x80"
    while (len(m)*8) % 512 != 448:
        m += b"\x00"
    m += L.to_bytes(8,'big')
    assert len(m)==64
    return m

# ---- 精确模拟 sha256.v 的 FSM ----
def sha256_core_sim(block_512):
    """block_512: 64 字节. 返回 digest(32字节) 与周期计数. 逐周期对应 sha256.v."""
    msg_words = list(struct.unpack('>16I', block_512))  # msg[0]=最高字... msg[15]=最低字
    # sha256.v: IDLE 装载 W[i] = msg[(15-i)*32 +: 32] => W[0]=msg[15]..W[15]=msg[0]
    W = [msg_words[i] for i in range(16)]  # 修复后: W[0]=最高字 (标准字序)
    regs = {'A':0,'B':0,'C':0,'D':0,'E':0,'F':0,'G':0,'H':0}
    state = 'IDLE'
    t = 0
    digest = None
    cycles = 0
    start_given = False  # start 拉高 1 周期 (testbench 时序)

    while digest is None:
        start = (not start_given)
        start_given = True
        cycles += 1

        if state == 'IDLE':
            if start:
                regs = dict(zip(['A','B','C','D','E','F','G','H'], H0))
                W = [msg_words[i] for i in range(16)]  # W[0]=最高字 (标准字序)
                t = 0
                state = 'COMPUTE'
            # else stay IDLE
        elif state == 'COMPUTE':
            # w_cur: t<16 直接取输入, t>=16 窗口扩展
            if t < 16:
                w_cur = msg_words[t]  # W[t]=M[t], M[0]=最高字
            else:
                w_cur = (sigma1(W[(t-2)%16]) + W[(t-7)%16]
                         + sigma0(W[(t-15)%16]) + W[(t-16)%16]) & MASK
            # t1, t2 用当前 regs
            t1 = (regs['H'] + bs1(regs['E']) + ch(regs['E'],regs['F'],regs['G'])
                  + K[t] + w_cur) & MASK
            t2 = (bs0(regs['A']) + maj(regs['A'],regs['B'],regs['C'])) & MASK
            # 非阻塞更新 (全部用旧值)
            A0,B0,C0,D0,E0,F0,G0,Hh0 = (regs['A'],regs['B'],regs['C'],regs['D'],
                                       regs['E'],regs['F'],regs['G'],regs['H'])
            regs = {'A':(t1+t2)&MASK, 'B':A0, 'C':B0, 'D':C0,
                    'E':(D0+t1)&MASK, 'F':E0, 'G':F0, 'H':G0}
            W[t%16] = w_cur
            if t == 63:
                state = 'ACCUM'
            else:
                t += 1
        elif state == 'ACCUM':
            regs = {k: (regs[k] + H0[i]) & MASK for i,k in enumerate(['A','B','C','D','E','F','G','H'])}
            state = 'FINISH'
        elif state == 'FINISH':
            digest = b''.join(pack('>I', regs[k]) for k in ['A','B','C','D','E','F','G','H'])
            state = 'IDLE'

    return digest, cycles

# ---- 12 组向量 (与 sha256_tb.v 一致) ----
cases = [
    ("empty",      b""),
    ("single_a",   b"a"),
    ("abc",        b"abc"),
    ("fox",        b"The quick brown fox jumps over the lazy dog"),
    ("55_bytes",   bytes(range(55))),
    ("incr33",     bytes(range(1, 34))),
    ("zeros44",    b"\x00"*44),
    ("all_ff",     b"\xff"*48),
    ("ascii_rep",  b"abc123xyz"*5),
    ("rand32",     bytes(range(0x20, 0x40))),
    ("rand55",     bytes((i*7)%256 for i in range(55))),
    ("numeric",    b"0123456789abcdef0123456789abcdef0123456789abcd"),
]

print("=== sha256.v 四态 FSM 逻辑模拟 (逐周期对应 RTL) ===")
ok = 0
for name, data in cases:
    block = pad_single(data)
    got, cyc = sha256_core_sim(block)
    exp = hashlib.sha256(data).digest()
    status = "PASS" if got == exp else "FAIL"
    if got == exp: ok += 1
    print(f"[{status}] {name:10s} cycles={cyc:3d} got={got.hex()[:16]}... exp={exp.hex()[:16]}...")
print(f"结果: {ok}/{len(cases)} 通过 (典型周期数应为 67: IDLE1+COMPUTE64+ACCUM1+FINISH1)")
print("(注: 验证 RTL 状态机时序逻辑; Verilog 语法/综合仍需仿真器)")
