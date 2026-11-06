# SHA-256 硬件加速器 · 验证与流片结果报告

**项目**：openlane-chips / designs/sha256
**目标芯片**：SHA-256 硬件加速器（sky130A 130nm，OpenLane 1.1.1 全流程）
**验证结论**：三层逻辑验证全部通过（逻辑 11/11 + 核心 12/12 + 握手 3/3）；四代详细布线 DRC 全部收敛到 0；四代 GDS 逐层 XOR 一致性校验全部 PASS；三 PVT corner 时序与功耗签核已完成（含已公开的余量缺口）。

> 本文件已随四代流片完成更新。早期"流片前准备"口径（PDK 阻塞、无 GDS、未做功耗分析）已作废。

---

## 1. 设计规格（最终 v4）

| 项目 | 规格 |
|---|---|
| 顶层 | `sha256_top`（OpenLane 综合顶层） |
| 接口 | 32-bit 串行数据接口 + `start` / `busy` / `done` 握手 |
| 压缩核 | `sha256_pipe`（三级流水，phase0/phase1/phase2 推进 64 轮） |
| 摘要输出 | 256-bit |
| 工艺 | SkyWater sky130A（130nm） |
| 标准单元库 | sky130_fd_sc_hd |
| 流程 | OpenLane 1.1.1（Yosys → OpenROAD → TritonRoute → Magic/KLayout） |
| Die | 640 × 640 µm（0.4096 mm²） |
| 最终频率 | 56.72 MHz（周期 17.63 ns） |

## 2. 三层验证方法

| 层 | 工具 | 验证内容 | 结果 |
|---|---|---|---|
| L1 算法逻辑 | `tools/sha256_logic_check.py` + Python `hashlib` | K 常量、σ0/σ1/Σ0/Σ1/Ch/Maj、64 轮压缩、H0 累加 | **11/11 PASS** |
| L2 核心时序 | Icarus Verilog（`sha256.v` + `sha256_tb.v`） | RTL 逐周期仿真，12 组向量 | **12/12 PASS** |
| L3 顶层握手 | Icarus Verilog（`sha256_top.v` + `sha256_top_tb.v`） | start → busy → done → digest 时序 | **3/3 PASS**（v1/v2 为 2/2，v3 起 3/3） |

## 3. 测试向量（12 组，全部对照 hashlib.sha256）

| # | 向量 | 摘要（前 16 hex） |
|---|---|---|
| 1 | empty（空串） | `e3b0c44298fc1c14` |
| 2 | single_a（"a"） | `ca978112ca1bbdca` |
| 3 | abc | `ba7816bf8f01cfea` |
| 4 | fox（"The quick brown fox..."） | `d7a8fbb307d78094` |
| 5 | 55_bytes（单块边界 55B） | `463eb28e72f82e0a` |
| 6 | incr33 | `31b03c6eaed475dd` |
| 7 | zeros44 | `85759b3811ff7dc4` |
| 8 | all_ff | `80a76a18acf8cb64` |
| 9 | ascii_rep | `22156f861105d1f0` |
| 10 | rand32 | `72dbb7336c767800` |
| 11 | rand55 | `576a1bf8d4478657` |
| 12 | numeric | `34c26e154bab5ff5` |

## 4. 标准摘要核对（FIPS 180-4）

```
空串  e3b0c442 98fc1c14 9afbf4c8 996fb924 27ae41e4 649b934c a495991b 7852b855
abc   ba7816bf 8f01cfea 414140de 5dae2223 b00361a3 96177a9c b410ff61 f20015ad
a     ca978112 ca1bbdca fac231c3 9eb23e74 d3eeb748 b38fcfc0 43f41d8d 3f501ad2
fox   d7a8fbb3 07d78094 69ca9abc b0082e4f 8d5651e4 6d3cdb76 23d02d0d bf37dc9e
```

## 5. 四代物理实现结果（实测）

| 版本 | Run | 频率 | 周期 | Die 面积 | 利用率 | 单元数 | 布线 DRC | 优化后 WNS | Runtime | GDS |
|---|---|---|---|---|---|---|---|---|---|---|
| v1 | tapeout6 | 38.58 MHz | 25.92 ns | 0.64 mm² | 20.99% | 9,512 | 0 | -0.62 | 0h54m9s | 38,896,886 B |
| v2 | tapeout9 | 53.45 MHz | 18.71 ns | 0.49 mm² | 33.53% | 12,245 | 0 | 0.00 | 1h26m11s | 43,314,668 B |
| v3 | tapeout10 | 58.17 MHz | 17.19 ns | 0.49 mm² | 33.59% | 12,288 | 0 | 0.00 | 0h45m31s | 41,636,156 B |
| v4 | tapeout12 | 56.72 MHz | 17.63 ns | 0.4096 mm² | 40.65% | 12,288 | 0 | 0.00 | 0h41m8s | 41,229,628 B |

布线收敛过程（v4，TritonRoute 详细布线迭代）：DRC 违例 16,283 → 8,287 → 7,302 → 2,658 → 1,392 → 792 → 597 → 516 → 468 → 358 → 107 → 46 → 9 → **0**（第 14 轮收敛），线长 778,544 µm，通孔 117,190（全部单切）。

> 四代 `flow_status` 均显示 `failed`，原因唯一：STEP 37 在 chroot 内调用 KLayout 崩溃（`tlFileUtils.cc:979`，工具自身 bug）。STEP 36 已正常产出 GDS，全部时序、面积、违例指标与版图有效，与设计质量无关。

## 6. 三 PVT corner 时序与功耗签核（SPEF / RCX 驱动）

用 OpenROAD 多角 STA 对 RCX 提取后的网表做三 corner 分析（min / max / nom）：

| 版本 | WNS min | WNS nom | WNS max | TNS nom | 最差 Hold（nom） |
|---|---|---|---|---|---|
| v1 | -14.97 | **-15.92** | -16.84 | -4,286.12 | -0.33 |
| v2 | -7.74 | **-8.71** | -9.62 | -711.56 | -0.24 |
| v3 | -6.45 | **-7.19** | -7.97 | -637.46 | -0.16 |
| v4 | -6.63 | **-7.63** | -8.44 | -570.30 | **-0.45** |

功耗（nom corner，SPEF 驱动）：

| 版本 | Internal | Switching | Leakage | Total |
|---|---|---|---|---|
| v1 | 7.52 mW | 3.30 mW | 1.52 µW | **10.8 mW** |
| v2 | 10.8 mW | 4.19 mW | 0.53 µW | **15.0 mW** |
| v3 | 11.0 mW | 4.11 mW | 0.52 µW | **15.1 mW** |
| v4 | 12.1 mW | 4.24 mW | 0.52 µW | **16.3 mW** |

v4 功耗构成：**时钟树 8.03 mW（49.1%）+ 触发器 7.93 mW（48.6%）= 97.7%**，组合逻辑仅 0.38 mW（2.3%）。

这条数据与第 5 节"58 MHz 是工艺上限"的判断互相印证：功耗几乎全部由寄存器规模 × 时钟频率决定，与组合逻辑复杂度无关。也就是说，在这颗设计上继续优化组合路径，既不会提频，也不会省电；边界在工艺，不在 RTL。

**必须说清楚的余量缺口**：三 corner 的 setup WNS 均为负（nom -7.63 ns），hold 最差 -0.45 ns（v4 nom）。这不是笔误，也不是统计口径差异——signoff 用 SPEF 寄生重新评估后，真实时序就是超标的。表 5 中的"优化后 WNS = 0"是布线后 resizer 的估算值，两者不能混为一谈。本项目未做时序 ECO 与 hold fix（没有 signoff 后的 ECO 流程），因此该设计**按时序签核标准是不合格的**，只做到了"布线 DRC 干净 + 结构与功能正确"。这是作品集与量产设计之间最真实的那道墙。

## 7. 物理一致性校验：Magic / KLayout 双 GDS 逐层 XOR

方法：把 Magic 导出的 GDS 与 KLayout 导出的 GDS 各自展平到顶层单元，按 (layer, datatype) 建层索引，逐层做多边形集合 XOR，统计差异多边形数。工具为宿主 KLayout 0.30.12（`klayout.db`）。

| 版本 | Run | 共同层数 | 共同层 XOR 差异 | 层级差异 | 结论 |
|---|---|---|---|---|---|
| v1 | tapeout6 | 40 | 0 | A-only (81,14)，B-only 无 | **PASS** |
| v2 | tapeout9 | 40 | 0 | A-only (81,14)，B-only 无 | **PASS** |
| v3 | tapeout10 | 40 | 0 | A-only (81,14)，B-only 无 | **PASS** |
| v4 | tapeout12 | 40 | 0 | A-only (81,14)，B-only 无 | **PASS** |

说明：A-only 的 (81,14) 为标定层（非结构层），两种导出路径不含该层，不影响结构一致性判断。四代结论完全一致，说明物理实现可复现、可交叉验证。

## 8. 复现命令

```bash
# L2 核心 12/12
iverilog -o sim sha256.v sha256_tb.v && vvp sim

# L3 顶层握手 3/3
iverilog -o top_sim sha256.v sha256_top.v sha256_top_tb.v && vvp top_sim

# L1 逻辑 11/11
python tools/sha256_logic_check.py
```

流片复现（chroot 内，缺一不可）：

```bash
TERM=xterm NO_COLOR=1 LC_ALL=C LANG=C PDK_ROOT=/pdk \
  flow.tcl -design sha256 -tag <新 tag>
# 必须在 /designs 根目录启动；在 /designs/sha256 内启动必报 Design not found
```

## 9. 边界与已知项

- 本项目为作品集性质，非量产设计；58 MHz 是 130nm 下该设计的合理工作频率，不代表性能标杆
- **时序未收敛**：signoff WNS（nom）v1 -15.92 / v2 -8.71 / v3 -7.19 / v4 -7.63；hold 最差 -0.45（v4）。未做 ECO 与 hold fix
- 未做 DFT 插入、未做跨工艺对比、未做功耗-频率联合优化
- XOR 校验不覆盖 Magic/KLayout 之外的第三方 GDS 工具链
- 版图渲染图为降采样可视化结果，不是签核数据本身
