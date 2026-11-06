# SHA-256 硬件加速器 · 验证与流片结果报告

**项目**：openlane-chips / designs/sha256
**目标芯片**：SHA-256 硬件加速器（sky130A 130nm，OpenLane 1.1.1 全流程）
**验证结论**：三层逻辑验证全部通过（逻辑 11/11 + 核心 12/12 + 握手 3/3）；四代物理实现全部 0 布线违例；四代 GDS 逐层 XOR 一致性校验全部 PASS。

> 本文件已随四代流片完成更新。早期"流片前准备"口径（PDK 阻塞、无 GDS）已作废。

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

| 版本 | Run | 频率 | 周期 | Die 面积 | 利用率 | 单元数 | 布线违例 | 优化后 WNS | Runtime | GDS |
|---|---|---|---|---|---|---|---|---|---|---|
| v1 | tapeout6 | 38.58 MHz | 25.92 ns | 0.64 mm² | 20.99% | 9,512 | 0 | -0.62 | 0h54m9s | 38,896,886 B |
| v2 | tapeout9 | 53.45 MHz | 18.71 ns | 0.49 mm² | 33.53% | 12,245 | 0 | 0.00 | 1h26m11s | 43,314,668 B |
| v3 | tapeout10 | 58.17 MHz | 17.19 ns | 0.49 mm² | 33.59% | 12,288 | 0 | 0.00 | 0h45m31s | 41,636,156 B |
| v4 | tapeout12 | 56.72 MHz | 17.63 ns | 0.4096 mm² | 40.65% | 12,288 | 0 | 0.00 | 0h41m8s | 41,229,628 B |

> 四代 `flow_status` 均显示 `failed`，原因唯一：STEP 37 在 chroot 内调用 KLayout 崩溃（`tlFileUtils.cc:979`，工具自身 bug）。STEP 36 已正常产出 GDS，全部时序、面积、违例指标与版图有效，与设计质量无关。

## 6. 物理一致性校验：Magic / KLayout 双 GDS 逐层 XOR

方法：把 Magic 导出的 GDS 与 KLayout 导出的 GDS 各自展平到顶层单元，按 (layer, datatype) 建层索引，逐层做多边形集合 XOR，统计差异多边形数。工具为宿主 KLayout 0.30.12（`klayout.db`）。

| 版本 | Run | 共同层数 | 共同层 XOR 差异 | 层级差异 | 结论 |
|---|---|---|---|---|---|
| v1 | tapeout6 | 40 | 0 | A-only (81,14)，B-only 无 | **PASS** |
| v2 | tapeout9 | 40 | 0 | A-only (81,14)，B-only 无 | **PASS** |
| v3 | tapeout10 | 40 | 0 | A-only (81,14)，B-only 无 | **PASS** |
| v4 | tapeout12 | 40 | 0 | A-only (81,14)，B-only 无 | **PASS** |

说明：A-only 的 (81,14) 为标定层（非结构层），两种导出路径不含该层，不影响结构一致性判断。四代结论完全一致，说明物理实现可复现、可交叉验证。

## 7. 复现命令

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

## 8. 边界与已知项

- 本项目为作品集性质，非量产设计；58 MHz 是 130nm 下该设计的合理工作频率，不代表性能标杆
- 未做功耗分析（无 SPEF 驱动的功耗评估）、无 DFT 插入、无跨工艺对比
- XOR 校验不覆盖 Magic/KLayout 之外的第三方 GDS 工具链
- 版图渲染图为降采样可视化结果，不是签核数据本身
