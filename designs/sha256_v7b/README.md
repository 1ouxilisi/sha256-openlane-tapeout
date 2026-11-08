# sha256_v7b —— 产出「0 违例 + LVS 通过」那一版的完整配置

这个目录不是新的一代设计，而是 **tag `ctsfix3` 那次整条 flow 重跑所用的设计目录**，逐字节保留：

- `config.tcl` —— **2,956 B / 64 行 / sha256 `a9018e7886750ec6c969708c99a69d267090bb7ca6a5c894e552d40025d829a7`**，就是当时跑出那批产物的那一份，没有二次编辑。
- `src/sha256_core.v` —— 10,598 B / sha256 `3ff53878d6ca168b179f76a03b76f69c3ecc96c484bcb2565b22551bb930b56c`
- `src/sha256_axil.v` —— 8,670 B / sha256 `d59d4d5f8c4a50374d7dceec27e6b96abc1e399bb4723e1c2b78c7be8dd673a9`

两个 RTL 文件与 `designs/sha256_v7/src/` 下的同名文件**字节完全相同**（同一 sha256）。这里复制一份的原因是 OpenLane 只从 `DESIGN_DIR` 里找 RTL（`config.tcl` 第 17–19 行用 `$::env(DESIGN_DIR)/src/...`），设计目录必须自包含才能「一条命令跑起来」。两份副本若哪天出现差异，以本文列出的 sha256 为准判定哪份被改过。

## 与原版 `designs/sha256_v7/config.tcl` 的差异

原版 50 行 / 2,111 B（sha256 `4395090e7a6d30a106db27c6e5e990635f45de253860a62bdc8091cc3714a967`）。这一版只加了四行有效配置 + 两段说明注释：

| 行 | 内容 | 为什么 |
|---|---|---|
| 40 | `set ::env(GRT_REPAIR_ANTENNAS) "1"` | 让全局布线阶段就做天线修复，而不是出图后手工补二极管 |
| 56 | `set ::env(CTS_SINK_CLUSTERING_SIZE) "9"` | 时钟树聚类每簇 sink 数。原版没有这两行，走的是 PDK 默认值（25 / 50），导致 `max_fanout 10` 必然被违反 |
| 57 | `set ::env(CTS_SINK_CLUSTERING_MAX_DIAMETER) "80"` | 聚类直径（µm）。实测 9 + 70–100 时扇出违例为 0；这里固定 80，与已归档的 `cts9d80` 试点一致，便于逐条对照 |
| 64 | `set ::env(RUN_KLAYOUT) "0"` | **只为本地 chroot 环境**。KLayout 0.29.1 启动要读 `/proc/<pid>/exe`（`tlFileUtils.cc:979`），而 `sudo chroot` 里的 `/proc` 是普通空目录，必崩 |

第 52–57 行与第 59–63 行是两段中文注释，分别记录 DRV 修复的参数扫描依据、以及 chroot 里 KLayout 的死点。散掉的四行配置和原版其余 50 行（`DIE_AREA 0 0 640 640`、`CLOCK_PERIOD 18.0`、`FP_CORE_UTIL 45`、四个 resizer margin 等）都没有改。

## 这份配置跑出来的东西（tag `ctsfix3`）

| 项 | 值 | 出处 |
|---|---|---|
| 详细布线 DRC | **0**（12,932 → 4,974 → 4,733 → 1,076 → 79 → 34 → 1 → 1 → 0） | `logs/routing/26-detailed.log` 第 194/245/295/345/395/442/489/535/581 行 |
| CTS 聚类 | 聚类后 sink 248，扇出分布 `9:244, 10:2`，上界 = SDC 的 `max_fanout 10` | `logs/cts/15-cts.log` 第 1049 / 1084 行 |
| GDS | 40,396,222 B（`results/signoff/sha256_axil.gds`） | run 目录 |
| 网表 | `results/routing/sha256_axil.nl.v` 3,379,950 B | 同上 |
| 走线 / 过孔 | 618,229 µm / 117,592 | `reports/metrics.csv` |
| 单元 / 利用率 / die | 47,559 / 46.2004% / 0.4096 mm² | 同上 |
| 三 corner 时序 | setup +0.51 / +0.74 / +0.99 ns，hold +0.41 / +0.41 / +0.40 ns（Slowest / Typical / Fastest） | `reports/signoff/29,31,33-sta-rcx_*/multi_corner_sta.*` |
| runtime | 0h37m21s | `reports/metrics.csv` |

LVS 是在 flow 之外用手跑出来的（`Final result: Circuits match uniquely.`），过程与命令见仓库根 [`REPRODUCE.md`](../../REPRODUCE.md) 与 `docs/evidence/cts9_lvs.txt`。

## 边界（跟着这份配置一起读）

1. **`RUN_KLAYOUT "0"` 是环境妥协，不是设计决定。** 换成正常的 Docker 宿主（有完整 `/proc`）应把它改回 `1`，才能拿到 KLayout DRC 与 GDS XOR。这一版因此没有 KLayout DRC、没有 XOR。
2. **`metrics.csv` 的 `flow_status` 是 `flow failed`。** 第 36 步「Magic Spice Export from LEF」在 chroot 里假死（15 分钟 CPU 只跑 17 秒、fd 停在 155 不增长），所以 `lvs_total_errors`、`Magic_violations`、`pin_antenna_violations`、`net_antenna_violations`、`klayout_violations` 五列是 `-1`（**没跑，不是 0**）。GDS 本身在第 36 步之前已经由 magic 产出，LVS 用它另行完成。
3. **这一版不是签核。** 0 违例 + GDS + LVS 通过这三件事第一次落在同一版，但 KLayout DRC、天线、金属密度、GDS XOR、功耗都没有在本版取值。
4. 目录名带 `b`（`sha256_v7b`）是因为原始 run 目录就叫这个名。`designs/sha256_v7` 是同一套 RTL 的配置母本（未打补丁），两者 RTL 相同、config 不同。
