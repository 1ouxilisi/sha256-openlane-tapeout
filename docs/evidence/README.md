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
| `lvs_instance_audit.txt` | 6,312 B | 实例级对账：47,087 / 33,984 / 15,588 三个数字的关系，13,103 的差额拆成 fill 与 tap；**其中「1,795 行缺单元名」一节的结论已被 `lvs_selfcheck.txt` 证伪**，读到那节请以 selfcheck 为准；第二引擎（KLayout）假通过的记录 | 生成结果 |
| `lvs_selfcheck.txt` | 6,016 B | 口径更正 + 三项对照实验：1,795 行是 SPICE `+` 续行（拼接后 33,984/33,984 都有单元名）；版图网表自比 0 个端口失配；转换网表逐脚与 `nl.v` 核对 15,381 个实例一致 | 生成结果 |
| `lvs_pin_parity.txt` | 7,491 B | 端口层复核：两侧各删 32 个端口反应一致（32 唯一名 / 64 行）、两侧 header 折成每行 8 个后两个方向仍 47+1；**推翻「端口表整体错位一格」**，47 个名字只打印一遍说明端口两侧都在、失败在网这一层；netgen Tcl 通道的正确调用方式 | 生成结果 |
| `lvs_port_graph.txt` | 5,278 B | 端口级连通性对账：把每个端口连到的（单元，引脚名）列表按各自文件的单元定义翻译后比对，**98 个端口里 94 个逐字相同**；4 个差异（bresp / rresp）成因是转换器漏读网表末尾 4 条 `assign` 别名；**推翻「47 是版图与网表的实际连接差异」** | 生成结果 |
| `klayout_drc.txt` | 4,190 B | KLayout 侧 signoff DRC 补跑：同一份 GDS、PDK deck `sky130A_mr.drc`（2023.6.14_01.08）、与 OpenLane 等价参数 → **218 个规则类 / 0 条违例**；含「四次必崩」真实原因（`tlFileUtils.cc:979` = 找不到 `/proc/<pid>/exe` 的断言，chroot 里 `/proc` 是空目录）、绕过办法（造路径 + 同 pid exec）、故意违规的 met1 正对照（1 条 `m1.2`）与口径边界 | 生成结果 |
| `klayout_drc_report.xml` | 34,074 B | 上面那次 DRC 的 KLayout RDB 原文（`<categories>` 218 类 / `<items>` 0 条），可直接数条目核对 | 生成结果 |
| `density_check.txt` | 1,954 B | 密度检查（PDK `met_min_ca_density.lydrc`）：六层空孔率 li1 0.4988 / m1 0.7280 / m2 0.9061 / m3 0.9293 / m4 0.9470 / m5 0.9732，全部高于阈值，**0 条违例**；含「met1 铺满 die」的正对照（报 1 条 `m1.pd.1d`）与口径 | 生成结果 |
| `density_report.xml` | 465 B | 上面那次密度检查的 KLayout 报告原文（`<items>` 0 条） | 生成结果 |
| `antenna_check.txt` | 3,635 B | **天线检查：没通过**。OpenROAD `check_antennas` 对布线后 ODB 补跑 → **67 个 net / 87 个 pin 越限**；本 run `GRT_REPAIR_ANTENNAS=0`、`DiodeCells=0`，检查也没在流程里跑到；含第一条违例原文、口径与复跑命令 | 生成结果 |
| `antenna_repair_attempt.txt` | 4,006 B | **天线修法验证**：ODB 副本上跑 `repair_antennas`——直接插卡在 `DPL-0036`（先要 `remove_fillers`）；删 fill 后三轮共插 **147 个二极管**，同一检查器复测 **0 net / 0 pin**。但插入发生在详细布线之后、未重新出 GDS，版图仍未修 | 生成结果 |
| `lvs_pass.txt` | 8,292 B | **LVS 结案**：两侧网名集合做差，真正多出的只有 `VNB`/`VPB` 两个网（井/衬底由 5,496 个 tap 接电源，Magic 提取时体端并入电源，而网表里 tap 引脚为空被整批丢掉）；`47 = 43 + 4`，两处都补后展平顶层 **166,353 器件 / 84,178 网**两侧相等，`Circuits match uniquely`；第 7 节记两次对照实跑：tap 单元在 PDK 里只有 `VGND VPWR` 两脚、body 为空，补回 5,496 个 tap 仍 47 行，强加 VNB/VPB 脚仍 47 行——另一条路线做不到，口径由定义决定 | 生成结果 |

三份 STA 原始日志（`logs/signoff/29-rcx_mcsta.min.log`、`31-rcx_mcsta.max.log`、`33-rcx_mcsta.nom.log`）各约 33 MB，一次性的，没有入库。

## 指纹

```
6526d0c4d2b608dd60fcaf46326d8379b000d74d83ee6399d0877c12cce492a4  metrics.csv
a4fad4c589dcd60a9ab8001bd255d89a0e59d3276690d01cb9f7c1a61e5274f5  errors.log
af0921bdabb0a663922e2ef1dbb703ecdf6779235d3198a1be37434f8bc21c80  sta_worst_slack.txt
30a4e6032e61c961f165182d660576f274d398d8bf27405a3f74b66a9f25a4fc  xor_layers.txt
f97fe245883cc40871630f33f0146b3d0faa904e6463963bf24838471e69e561  gds_layers.txt
6036d8791e18b26a2ca76f8a1b9e2523c88fdeb11d7538ec262c08091b7580f4  magic_drc.txt
ffd427b546a5e60aa4af17e5adaf183c5efab2bdaee123f661f41ce98e6f361b  klayout_drc.txt
36045191fa8549ad8a29e232e0885978acf99bd793ba144e6351a5e2778f60d2  klayout_drc_report.xml
18b9c39e614e6d0039441d064880607893f944f25a9d2ce666cfce09fabe147b  density_check.txt
6681d364b2c424d55a95ad4444cace1f7aac6012fb812dfbecf3eac51f4501ea  density_report.xml
a9403329a5963aa998f1b7c2711fa772c308298ab48111d949221818924647d6  antenna_check.txt
5f76607cf83cff7478f120c37d3536927e1662a54da1db2b91ae16ff74cce068  antenna_repair_attempt.txt
304a4406735091a1425df27420ac6d395089c25bb655cfb248f8b720b4082683  lvs_attempt.txt
8397535d6d8f3a804c7d4d320699f815764eb261d09a7a57117ef40df1eda35e  lvs_rootcause.txt
23d7022ac3cb9136bed59ba43baf67adb5a137a0f5790ebe33549b12b6db1af9  lvs_instance_audit.txt
e2be16bc18b791c16b99030f0691d7c17f2b638748cdf4c7fdda2597cbce9bc0  lvs_selfcheck.txt
42237b91ed66826eabb58405c2acedce88fa9c6262b6c7847c72e1af5a2b4a42  lvs_pin_parity.txt
db6dc46de5298354ba0af0169a9086e94f085f949fae6bd92f11a003643edd13  lvs_port_graph.txt
37329768afd8f27f5f0f900d9f0fb987973d18a2912e03c9a6fec439259c012c  lvs_pass.txt（上一版 5,517 B）
```

## 一个必须知道的读数陷阱

每个 corner 日志里都有 **6** 处 `worst slack corner`：

- 前 3 处属于 `Path Type: min` → **hold**
- 后 3 处属于 `Path Type: max` → **setup**

所以同一份日志里会出现两组数（例如 `0.4021` 和 `11.9644`），它们不矛盾，量的是两件事。`sta_worst_slack.txt` 开头三行已写明这个结构。

## 本次 run 的状态

`metrics.csv` 的 `flow_status` = `flow failed`。失败在第 37 步 `gds_klayout`（KLayout GDS-vs-GDS XOR），原因是 KLayout 报 `tlFileUtils.cc:979` 内部错误，不是版图不一致。**这一条的真因后来查清了**：979 行是 `get_app_path_internal()` 的兜底断言，Linux 分支只检查 `/proc/<当前 pid>/exe` 是否存在，不存在就 `tl_assert(false)`；本机 chroot 的 `/proc` 是空目录，所以必崩——与版图无关、与 locale 无关。在 chroot 内先 `mkdir -p /proc/$$` 并把 `proc/$$/exe` 链到 klayout 二进制、再用同一个 pid `exec` 启动，Ruby 引擎即可正常运行（见 `klayout_drc.txt`）。

由此：`tritonRoute_violations` 等 6 个 `0` 只覆盖布线阶段；`Magic_violations`、`klayout_violations`、`lvs_total_errors` 为 `-1`（未产出）。

第 37 步要证明的事，已用另一条路径补做：`xor_layers.py` 用同一套 KLayout 0.29.1 库的 Python 接口逐层 XOR，结果见 `xor_layers.txt`，层名对照见 `gds_layers.txt`——**42 层中 41 层几何完全一致，唯一差异在 81/14（areaid.lowTapDensity）**，而这一层流水线自己也用 `-rd ignore=81/14` 排除。**21 个制造层 XOR 全为 0。**

`Magic_violations` 这一项事后补跑成功：PDK 自带的 `run_standard_drc.py` 对着 `sha256_axil.gds` 跑 `drc(full)`，输出只有两行表头、**零条违例**，见 `magic_drc.txt`。注意 `run_standard_drc.py` 不含天线与密度检查。

`klayout_violations` 这一项也补跑成功：`klayout -b -zz -r sky130A_mr.drc`（release 2023.6.14_01.08），同一份 GDS，参数与 OpenLane 的 `run_klayout_drc_sky130` 等价（`beol 1 feol 1 floating_metal 0 seal 1 offgrid 1`），报告 **218 个规则类 / 0 条违例**，见 `klayout_drc.txt` 与 `klayout_drc_report.xml`。0 条不是空跑：故意造一个 met1 间距 0.10 µm 的小版图做正对照，同一 deck 立刻报 1 条 `m1.2`。口径：这是补跑不是流水线原始记录（`metrics.csv` 那列仍为 -1，因为本次 run 的第 37 步是 XOR 崩的、KLayout DRC 没执行到）；不含天线，密度类检查在 PDK 单独的 `.lydrc` 里，本轮没跑。

`lvs_total_errors` 这一项也补跑过，结论是**没过**：Magic 从版图提取出晶体管级网表（2,785,763 B / 154 个子电路），与 PnR 网表按 PDK 器件模型展开后用 netgen 对比，迭代八轮后顶层**器件数两侧完全相等（15,593 = 15,593）**，但网数差 2（15,645 vs 15,647）且有 47 个 AXI 顶层端口在网表侧报 `no matching pin`，最终 `Netlists do not match.`。卡点在 verilog→spice 的端口/网名映射这一侧，不是版图与电路不一致。详见 `lvs_attempt.txt`。

这一版又把卡点往下压了一层：四次对照实验（顶层 `.subckt` 头折成 20 行、156 个单元原型前移、两侧 `[n]`→`_n` 统一改名、netgen `-auto`）**结果都还是 47 个 `no matching pin`**；端口表本身核对过——两侧顶层都是 98 个端口、名字逐字相同、无重复，被报无对应的名字在网表 body 里确实接在缓冲器输出上。四类变量因此全部排除，卡点收敛到 netgen 对这份手工转出 spice 的顶层端口识别。详见 `lvs_rootcause.txt`（其中含一处更正：早前「84 个端口未被引用」是正则边界的误报，真实是 8 个）。

再往下一层，卡点被具体到实例：版图网表顶层 33,984 行实例里，有 **1,795 行（5.3%）行尾不是单元名而是网名**（`X_20693_ VGND VPWR VPWR VGND clknet_leaf_41_clk net790 net193 u_core.W[3][23]`），netgen 判不出是什么单元，两边实例结构从这一层就不相等——这比「端口识别」具体。**但这一段后来被自己推翻了，见下一段。** 同一轮还把数字之间的关系拆干净了：PnR 放置的 47,087 个单元里 31,499 个是空引脚（fill / decap / tap），有引脚的 15,588 个正是 netgen 报的 15,593 的来源（差 5，未逐条对到）；版图提取的 33,984 与 47,087 的差 13,103 = fill_1 5,667 + fill_2 1,940 + tapvpwrvgnd_1 5,496，分毫不差。另有一个必须记下的失败：用 KLayout 的 `NetlistComparer` 当第二引擎时它**返回了 True，但 flatten 后两侧各只剩 8 个器件**，属假通过，不采用。详见 `lvs_instance_audit.txt`。

**更正（这一版）**：上一段那个「1,795 行缺单元名」的结论是错的，已撤回。Magic 的 `exttospice` 走标准 SPICE 续行——超长实例行的下一行以 `+` 开头，单元名就在续行上（`+ sky130_fd_sc_hd__dfrtp_1`）。把续行拼回去再判，**33,984 / 33,984 全部有单元名，缺名 0 行**；全文件 1,813 行以 `+` 开头，顶层体内正好 1,795 行，与那 1,795 处「行末是网名」逐行对应。同时补了两项正面实验：① 版图网表复制一份和自己比，**0 行 `no matching pin`、98 个端口全对、`Circuits match uniquely.`**，说明读取侧无障碍（另做了单行 1,295 字符与 `+` 折行两份构造对照，也都匹配）；② 转换出的网表逐实例逐脚与 `nl.v` 核对，**15,381 个实例一致**，206 个例外是 `clkload0` 这类在 `nl.v` 里本就没有该引脚的实例，31,499 个空引脚单元无信号脚可比。于是归因改判为**真实的版图与网表差异**（时钟负载与常量类单元的特殊连接、两侧网名集合 212 / 11 处不对称），不是名字、折行或格式问题。**LVS 仍未通过**，这一点没变。详见 `lvs_selfcheck.txt`。

**再更正（最新，第三次）**：上一段之后的「端口表整体错位一格」这个读法也不成立，撤回。三条依据：① 两侧端口表本来就是 98 / 98、名字逐字相同、顺序相同；② 两侧各删 32 个 `s_axil_rdata[n]` 端口后分别与原件比，版图侧与网表侧都报 **32 个唯一名 / 64 行**（每名重复两遍），反应一字不差，说明两侧读入等价；③ 把两侧 header 分别折成每行 8 个端口、两个方向各跑一次，仍是 **47 + 1**，pins 表起始行号都不变（162352）。关键的判别是行数：只有「某端口只在一侧存在」时 netgen 才把名字打印两遍，而真实比对里这 47 个名字**只打印一遍、无重复**——它们两侧端口表里都在，失败在**它们所连的网**。报告本身也把层次写清了：`Cell pin lists are equivalent.` + `Device classes ... are equivalent.` + `Final result: Netlists do not match.`。末行 `clk | s_axil_wdata[27] **Mismatch**` 是 netgen 自己改配对（`altered to match`）的痕迹，不是文件里的命名关系。当前只剩一句有依据的话：**47 个端口所连的网没配上，机制未定**。详见 `lvs_pin_parity.txt`（内含 netgen Tcl 通道的正确调用方式：`netgen -batch < 脚本` 不执行，须 `netgenexec -- -batch source <脚本>`）。

**第四次改写（最新）**：连「47 是版图与网表的实际连接差异」这句也撤了。换了个量法——不比端口名，比端口**连着什么**：对每个端口收集所有挂在它上面的器件脚，记成（单元名，引脚名），引脚名按**各文件自己声明的单元定义**翻译（Magic 的单元引脚顺序与 PDK 不同，`conb_1` 在 Magic 里是 `LO HI VPB VNB VGND VPWR`，PDK 里是 `VGND VNB VPB VPWR HI LO`，按位置比必然误判）。结果：**98 个端口里 94 个邻域逐字相同**；真正不同的只有 `bresp[0..1]`、`rresp[0..1]`，成因是 `nl.v` 末尾 4 条 `assign s_axil_bresp[0] = net389;` 这类别名被转换器漏读，补进去重跑仍是 47。所以现在只剩：**netgen 在这份数据上的顶层匹配没有收敛**。候选两类（大规模重复结构上的图同构搜索 / 更深处确实不同），本仓库不做裁决。详见 `lvs_port_graph.txt`。

**结案（最新）**：`lvs_pass.txt`。两侧网名集合做差，真正多出来的只有 `VNB` / `VPB` 两个网——版图里井与衬底由 5,496 个 `tapvpwrvgnd_1` 直接接到 VPWR/VGND，Magic 提取时体端一律并到电源，而 `nl.v` 里这些 tap 单元引脚是空的、被转换器整批丢掉，于是这两个网在网表侧悬空。`47 = 43 + 4`（43 归 VNB/VPB，4 归 assign 漏读），两处都补之后：展平顶层 **166,353 个器件、84,178 条网两侧完全相等**，netgen 原文 `Netlists match uniquely` / `Final result: Circuits match uniquely`，全文 `(no matching pin)` 出现 0 次。口径写在明处：`VNB≡VGND`、`VPB≡VPWR`，叶子单元由 netgen 展平后再比，因此是「顶层晶体管级等价」。第 7 节把「把 tap 补回网表」这条等价路线**实跑完了**：PDK 的 `tapvpwrvgnd_1` 只有 `VGND VPWR` 两个脚、body 为空，补回 5,496 个之后仍是 47 行 `Netlists do not match`；强加 VNB/VPB 脚仍是 47 行。所以这条路线做不到，口径不是可选项而是由单元定义决定的唯一写法。

仍然缺的：**天线的版图本身还没修**——补跑报 67 个 net / 87 个 pin 越限，`DiodeCells = 0`；修法已实跑验证（删 fill 后插 147 个二极管、复测 0/0），但那是在详细布线之后的数据库上做的，没有重跑「全局布线 → 插二极管 → 详细布线」、也没有重新出 GDS，所以现有 XOR / 两套 DRC / LVS 仍指向旧版图；密度只跑了 PDK 的「最小空孔率」这一份 deck，各层金属密度窗口没跑；以及**每个标准单元内部逐管等价**（LVS 的口径是展平后的顶层晶体管级等价）。XOR 一致只说明两份产出相同，不等于两份都满足设计规则——DRC 那两份是各自单独跑的，天线更是另一套规则。
