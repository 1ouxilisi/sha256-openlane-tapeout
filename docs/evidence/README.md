# evidence —— 作品集数字的原始出处

这个目录里放的是「作品集里那些数字」的原始产出，不是二次整理的表格。

来源 run：`designs/sha256_v7b/runs/tapeout16`（OpenLane 1.1.1，sky130A，CLOCK_PERIOD = 18.0 ns）。

| 文件 | 大小 | 是什么 | 是否原样 |
|---|---|---|---|
| `metrics.csv` | 1,945 B | OpenLane 本次 run 的指标汇总（两行 CSV：列名 + 数据行） | 原样，未改一个字节 |
| `errors.log` | 1,987 B | 本次 run 的错误日志，末段为第 37 步 `gds_klayout` 失败原文 | 原样，未改一个字节 |
| `sta_worst_slack.txt` | 1,403 B | 三份 signoff 多角 STA 日志里 `worst slack corner` 行的摘录，前缀 `文件名:行号` | 原文行 + 三行说明头 |

| `xor_layers.txt` | 4,332 B | 独立重做第 37 步 GDS 逐层 XOR 的完整输出 | 生成结果 |
| `xor_layers.py` | 1,614 B | 生成上面那份报告的脚本（只依赖 `klayout.db`） | 脚本 |
| `gds_layers.txt` | 6,241 B | 同上那份 XOR 结果的「人话版」：42 层逐层对到 PDK 图层名表（`68/20 = met1.drawing`），含分类统计与两条交叉校验 | 生成结果 |
| `magic_drc.txt` | 2,480 B | Magic signoff DRC 的补跑记录：命令、技术版本、77 字节原文、局限 | 生成结果 |

三份 STA 原始日志（`logs/signoff/29-rcx_mcsta.min.log`、`31-rcx_mcsta.max.log`、`33-rcx_mcsta.nom.log`）各约 33 MB，一次性的，没有入库。

## 指纹

```
6526d0c4d2b608dd60fcaf46326d8379b000d74d83ee6399d0877c12cce492a4  metrics.csv
a4fad4c589dcd60a9ab8001bd255d89a0e59d3276690d01cb9f7c1a61e5274f5  errors.log
af0921bdabb0a663922e2ef1dbb703ecdf6779235d3198a1be37434f8bc21c80  sta_worst_slack.txt
30a4e6032e61c961f165182d660576f274d398d8bf27405a3f74b66a9f25a4fc  xor_layers.txt
f97fe245883cc40871630f33f0146b3d0faa904e6463963bf24838471e69e561  gds_layers.txt
6036d8791e18b26a2ca76f8a1b9e2523c88fdeb11d7538ec262c08091b7580f4  magic_drc.txt
```

## 一个必须知道的读数陷阱

每个 corner 日志里都有 **6** 处 `worst slack corner`：

- 前 3 处属于 `Path Type: min` → **hold**
- 后 3 处属于 `Path Type: max` → **setup**

所以同一份日志里会出现两组数（例如 `0.4021` 和 `11.9644`），它们不矛盾，量的是两件事。`sta_worst_slack.txt` 开头三行已写明这个结构。

## 本次 run 的状态

`metrics.csv` 的 `flow_status` = `flow failed`。失败在第 37 步 `gds_klayout`（KLayout GDS-vs-GDS XOR），原因是 KLayout 自身的 `tlFileUtils.cc:979` 内部错误（Ruby 引擎在本机 chroot 内初始化即崩），不是版图不一致。

由此：`tritonRoute_violations` 等 6 个 `0` 只覆盖布线阶段；`Magic_violations`、`klayout_violations`、`lvs_total_errors` 为 `-1`（未产出）。

第 37 步要证明的事，已用另一条路径补做：`xor_layers.py` 用同一套 KLayout 0.29.1 库的 Python 接口逐层 XOR，结果见 `xor_layers.txt`，层名对照见 `gds_layers.txt`——**42 层中 41 层几何完全一致，唯一差异在 81/14（areaid.lowTapDensity）**，而这一层流水线自己也用 `-rd ignore=81/14` 排除。**21 个制造层 XOR 全为 0。**

`Magic_violations` 这一项事后补跑成功：PDK 自带的 `run_standard_drc.py` 对着 `sha256_axil.gds` 跑 `drc(full)`，输出只有两行表头、**零条违例**，见 `magic_drc.txt`。注意 `run_standard_drc.py` 不含天线与密度检查。

仍然缺的：**KLayout 的 signoff DRC 违例数**（Ruby 引擎在本机 chroot 起不来）与 **LVS 错误数**（没跑成）。XOR 一致只说明两份产出相同，不等于两份都满足设计规则。
