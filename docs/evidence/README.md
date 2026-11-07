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
| `lvs_attempt.txt` | 3,164 B | LVS 补跑记录：Magic 提取、netgen 八轮、最终两行原文、结论与已知坑 | 生成结果 |
| `lvs_rootcause.txt` | 6,079 B | LVS 卡点的逐轮排障：四次对照实验（头部折行 / 定义顺序 / 方括号改名 / `-auto`）全部仍为 47；端口表核对的硬证据；一处误报的更正 | 生成结果 |
| `lvs_instance_audit.txt` | 6,312 B | 实例级对账：47,087 / 33,984 / 15,588 三个数字的关系，13,103 的差额拆成 fill 与 tap；1,795 行实例缺单元名的实证；第二引擎（KLayout）假通过的记录 | 生成结果 |

三份 STA 原始日志（`logs/signoff/29-rcx_mcsta.min.log`、`31-rcx_mcsta.max.log`、`33-rcx_mcsta.nom.log`）各约 33 MB，一次性的，没有入库。

## 指纹

```
6526d0c4d2b608dd60fcaf46326d8379b000d74d83ee6399d0877c12cce492a4  metrics.csv
a4fad4c589dcd60a9ab8001bd255d89a0e59d3276690d01cb9f7c1a61e5274f5  errors.log
af0921bdabb0a663922e2ef1dbb703ecdf6779235d3198a1be37434f8bc21c80  sta_worst_slack.txt
30a4e6032e61c961f165182d660576f274d398d8bf27405a3f74b66a9f25a4fc  xor_layers.txt
f97fe245883cc40871630f33f0146b3d0faa904e6463963bf24838471e69e561  gds_layers.txt
6036d8791e18b26a2ca76f8a1b9e2523c88fdeb11d7538ec262c08091b7580f4  magic_drc.txt
304a4406735091a1425df27420ac6d395089c25bb655cfb248f8b720b4082683  lvs_attempt.txt
8397535d6d8f3a804c7d4d320699f815764eb261d09a7a57117ef40df1eda35e  lvs_rootcause.txt
23d7022ac3cb9136bed59ba43baf67adb5a137a0f5790ebe33549b12b6db1af9  lvs_instance_audit.txt
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

`lvs_total_errors` 这一项也补跑过，结论是**没过**：Magic 从版图提取出晶体管级网表（2,785,763 B / 154 个子电路），与 PnR 网表按 PDK 器件模型展开后用 netgen 对比，迭代八轮后顶层**器件数两侧完全相等（15,593 = 15,593）**，但网数差 2（15,645 vs 15,647）且有 47 个 AXI 顶层端口在网表侧报 `no matching pin`，最终 `Netlists do not match.`。卡点在 verilog→spice 的端口/网名映射这一侧，不是版图与电路不一致。详见 `lvs_attempt.txt`。

这一版又把卡点往下压了一层：四次对照实验（顶层 `.subckt` 头折成 20 行、156 个单元原型前移、两侧 `[n]`→`_n` 统一改名、netgen `-auto`）**结果都还是 47 个 `no matching pin`**；端口表本身核对过——两侧顶层都是 98 个端口、名字逐字相同、无重复，被报无对应的名字在网表 body 里确实接在缓冲器输出上。四类变量因此全部排除，卡点收敛到 netgen 对这份手工转出 spice 的顶层端口识别。详见 `lvs_rootcause.txt`（其中含一处更正：早前「84 个端口未被引用」是正则边界的误报，真实是 8 个）。

再往下一层，卡点被具体到实例：版图网表顶层 33,984 行实例里，有 **1,795 行（5.3%）行尾不是单元名而是网名**（`X_20693_ VGND VPWR VPWR VGND clknet_leaf_41_clk net790 net193 u_core.W[3][23]`），netgen 判不出是什么单元，两边实例结构从这一层就不相等——这比「端口识别」具体。同一轮还把数字之间的关系拆干净了：PnR 放置的 47,087 个单元里 31,499 个是空引脚（fill / decap / tap），有引脚的 15,588 个正是 netgen 报的 15,593 的来源（差 5，未逐条对到）；版图提取的 33,984 与 47,087 的差 13,103 = fill_1 5,667 + fill_2 1,940 + tapvpwrvgnd_1 5,496，分毫不差。另有一个必须记下的失败：用 KLayout 的 `NetlistComparer` 当第二引擎时它**返回了 True，但 flatten 后两侧各只剩 8 个器件**，属假通过，不采用。详见 `lvs_instance_audit.txt`。

仍然缺的：**KLayout 的 signoff DRC 违例数**（Ruby 引擎在本机 chroot 起不来，换 locale / HOME / TMPDIR 均无效）。XOR 一致只说明两份产出相同，不等于两份都满足设计规则。
