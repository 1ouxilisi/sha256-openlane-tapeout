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
| `klayout_drc_ctsfix3.txt` | 3,792 B | **ctsfix3 那版 GDS（40,396,222 B）的 KLayout DRC 补跑**：218 个规则类 / **0 条**，93.690 s，报告 34,074 B；同一 deck 同一参数下 `ctl.gds` 报 **1 条 `m1.2`**；写清四处边界——① 这份报告与 tapeout16 那次**逐字节相同**（空 RDB 只含类别表，不能用哈希区分两次 run）② 上游传的 `topcell`/`thread` 其实与 deck 读的 `$top_cell`/`$thr` 不一致，本次两个名字都传 ③ 不含天线、不含密度 ④ 是补跑，`metrics.csv` 那列仍为 `-1` | 生成结果 |
| `klayout_drc_ctsfix3_log.txt` | 70,588 B | 上面那次 DRC 的 KLayout stdout 原样（含逐规则图形计数，可核对引擎真在读这份版图），头部 `#` 块写明对象路径 / GDS sha256 / deck / 完整命令 / 报告字节与 sha256 | 原始输出 + 说明头 |
| `density_ctsfix3.txt` | 2,490 B | **ctsfix3 那版 GDS 的密度检查**：六层空孔率 li1 0.4993 / m1 0.7275 / m2 0.9055 / m3 0.9264 / m4 0.9460 / m5 0.9763，全部高于阈值（li1–m4 ≥0.40、m5 ≥0.24），**0 条**，5.780 s；写明这份 deck 通过时不写类别、所以报告为空是 PASS 的形态 | 生成结果 |
| `density_ctsfix3_log.txt` | 3,580 B | 上面那次密度检查的 KLayout stdout（六行 `<层>_ca_density is <值>` 即实测值），头部 `#` 块含对象、报告字节与 sha256 | 原始输出 + 说明头 |
| `antenna_check.txt` | 3,635 B | **天线检查：没通过**。OpenROAD `check_antennas` 对布线后 ODB 补跑 → **67 个 net / 87 个 pin 越限**；本 run `GRT_REPAIR_ANTENNAS=0`、`DiodeCells=0`，检查也没在流程里跑到；含第一条违例原文、口径与复跑命令 | 生成结果 |
| `antenna_repair_attempt.txt` | 4,006 B | **天线修法验证**：ODB 副本上跑 `repair_antennas`——直接插卡在 `DPL-0036`（先要 `remove_fillers`）；删 fill 后三轮共插 **147 个二极管**，同一检查器复测 **0 net / 0 pin**。但插入发生在详细布线之后、未重新出 GDS，版图仍未修 | 生成结果 |
| `antenna_repair_route_attempt.txt` | 5,693 B | **走到新 GDS 的五次尝试（全失败）**：详细布线后的库 → `DRT-0218`；重跑全局布线 → 仍 `DRT-0218`；`22-global.odb` 起点 → `GRT-0226`；`20-sha256_axil.odb` 起点 → `GRT-0226`；补层调整参数 → 仍 `GRT-0226`。附「修法可行 ≠ 版图已修」的口径与下一步两条路 | 生成结果 |
| `antenna_repair_route_fixed.txt` | 6,164 B | **天线真正修成的那一次**：前五次的真因是手写脚本漏传 `global_route -allow_congestion`（OpenLane 只在 `GRT_ALLOW_CONGESTION=1` 时传这个开关，本 run 配置正是 1），**「工具走不通」的结论撤回**。三轮 GRT+repair 共插 **430 个二极管**，详细布线后复测 **0 / 0**；补 fill 后出 GDS **18,618,660 B**（sha256 `a58cdfea…`），新 GDS 上 KLayout DRC 218 类 0 条、密度六层 0 条、Magic DRC `No errors found`；明确写出版图只到「布线级修好」，STA/功耗/XOR/LVS 未在新版重跑 | 生成结果 |
| `lvs_top_level_gap.txt` | 4,692 B | **新版 LVS 的失败边界**：四组对照（合并衬底网 / 不合并 / 同内容无 fill / 两侧删物理单元）全部 `Netlists do not match`，但 **150 个叶子单元逐个 `Netlists match uniquely`**、器件与网数逐单元相等，失败只在顶层；顶层差 = 物理单元口径（版图 16,472 实例 vs 网表 21,968，差 5,496 正好是 `tapvpwrvgnd_1` 实例数）+ 衬底网命名口径（版图每实例一份 `VPB`/`VNB`，网表单个全局网，PDK setup 无此规则）。同时撤回上一版「逐单元网数差 2」——那是把 `VNB→VGND`/`VPB→VPWR` 全量替换时连单元内部定义一起合并造成的 | 生成结果 |
| `lvs_new_pass.txt` | 4,572 B | **新版 LVS 通过**：天线修好那版 GDS 提出的网表 vs OpenROAD 网表，`Final result: Circuits match uniquely.`；两侧 **15,588 器件 / 15,645 网**相等，149 个叶子单元逐个 `Netlists match uniquely`。文件逐条写清先前四组对照为何全败——`+` 续行导致两侧删物理单元不一致、只在网表侧合并 `VPB/VNB`、总线被压成单网并丢 4 条 `assign` 端口别名、`write_verilog` 不写电源脚——附复现链、字节数、md5 与「这证明不了什么」 | 生成结果 |
| `sta_signoff_3corner.txt` | 7,176 B | **RCX + 三 corner 的 signoff 口径时序对照**：寄生由 OpenROAD rcx 从 `fixed16.def` 直接提取（`extract_parasitics -lef_res -ext_model_file rules.openrcx.sky130A.{max,nom,min}.calibre`，三份 SPEF 19.9/18.9/18.6 MB），三工艺角 `ss_100C_1v60`/`tt_025C_1v80`/`ff_n40C_1v95` 各算一次。结果：最差 setup **+0.4058 ns**（Slowest）、最差 hold **+0.4096 ns**（Fastest）、TNS 0；对比未修版 +0.5619 / +0.4021，setup 少 0.156 ns。方法自证：同一脚本跑旧版官方 `nl.v` + SPEF 复现 +0.5619（与已公布值逐位一致）。同时**撤回**估算口径的 +9.83 → +9.92 | 生成结果 |
| `drv_fix_routed.txt` | 7,204 B | **DRV 修复跑到底：扇出归零 + 重布线 + 三 corner 复核**：CTS 聚类 size 9 / 直径 80 后扇出违例 **0**（最大扇出正好等于限值 10），面积 142,876 u²（比原配置 142,952 小 76），buffer 238 → 289；重布线（层调整 0.3）详细布线 0 违例、布线后扇出仍 0，走线 584,628 µm、过孔 104,134；三 corner 真 STA：setup +4.0576 / +11.0275 / +12.2001 全 MET，hold +0.4374 / +0.0820 / **−0.0391**（Fastest 一条），max fanout 与 cap 全 MET，max slew Slowest 剩 90 条（最差 1.04）。**同时公开撤回上一份「参数调不到 0」** | 本轮新增 |
| `cts9d80_adj.log` | 27,498 B | 上述重布线原始日志：`DRT-0199 Number of violations = 0.` 在第 606 行，`== AFTER_ROUTE_FANOUT ==` 第 654 行（该段为空） | 原始输出 |
| `sta_cts9.log` | 159,550 B | 修好版三 corner STA + DRV + 功耗 + 面积原始报告：setup/hold 六格在 1006–1037 行，`-- corner Slowest violators` 第 1064 行（90 个 max slew 块），`==DONE==` 第 1690 行 | 原始输出 |
| `cts9_route.txt` | 710 B | **整条 flow 重跑版的布线收敛原文**：`logs/routing/26-detailed.log` 里 9 条 `DRT-0199 Number of violations =` 全列，带行号：194/245/295/345/395/442/489/535/581，序列 12,932 → 4,974 → 4,733 → 1,076 → 79 → 34 → 1 → 1 → **0** | 原样摘录 |
| `cts9_cts.txt` | 288 B | 同一次 run 的 CTS 原文：第 1049 行聚类后 sink 248、第 1084 行扇出分布 `9:244, 10:2`（上界等于 SDC 限值 10） | 原样摘录 |
| `antenna_ctsfix3.txt` | 707 B | **ctsfix3 的天线复检结果：不是 0**。OpenROAD `check_antennas -verbose` 对 `results/routing/sha256_axil.odb` → **39 net / 49 pin**；正对照 `tapeout16` → **67 / 87**（证明脚本有分辨力）；附两份日志的字节数、行数、sha256 与违例块内各层出现次数（met1/li1 229、met2 220、met3 205、met4 145、met5 2） | 生成结果 |
| `antenna_closed_loop.txt` | 4,062 B | **天线 39/49 → 32/38 → 2/2 → 0/0 的完整闭环**：每轮 tcl 原文、逐轮日志行号（round1 L305/L645/L11309/L11310、round2 L619/L1523/L1524、round3 L509/L534/L535）、`loop_progress.txt` 四行、独立进程复检 0/0、四件产物（DEF/ODB/GDS/网表）字节与 sha256、二极管 327 与 filler 25,656 的出处 | 生成结果 |
| `klayout_drc_antclean.txt` | 1,182 B | **天线归零那版 GDS（40,666,588 B, `89cda760…`）的 KLayout DRC**：`sky130A_mr.drc` 五个开关全开，**218 个规则类 / 0 条**（`<item>` 计数），日志 2,146 行、报告 2,824,878 B；附 ctsfix3 版与 `ctl.gds` 两组对照 | 生成结果 |
| `density_antclean.txt` | 780 B | **同一份 GDS 的金属密度**：li1 0.4991 / m1 0.7232 / m2 0.9033 / m3 0.9223 / m4 0.9478 / m5 0.9716，六层全在阈值之上、**0 条**；日志 5.400 s，附 ctsfix3 对照与 `m1.pd.1d` 正对照 | 生成结果 |
| `lvs_antclean.txt` | 1,616 B | **同一份 GDS 的 LVS**：Magic 提取 `layout.ext.spice` 2,815,680 B → 清洗 `TOP_INST 34,289` → 网表侧 `INSTANCES 34,289 (dropped fill/tap 13,382)` → netgen **`Final result: Circuits match uniquely.` / `LVS PASS`**（日志 321 行）；写明与 ctsfix3 的 34,182 相差 +107 尚未逐条追查，以及「本版未重跑 STA/DRV、功耗未取」 | 生成结果 |
| `xor_antclean.txt` | 1,706 B | **GDS XOR：两条 stream-out 路径 0 差异**。A = Magic 出图 40,666,588 B，B = KLayout「读同一份 DEF + PDK 单元 GDS 回填空 cell」18,758,880 B；flatten 后逐层 `Region ^` → `common=42 A_only=[(81,14)] B_only=[]`、`TOTAL_DIFF=0`、**RESULT PASS**；含上一版同法 PASS 的对照，以及「为何不拿逐层形状数相减当判据」的口径说明 | 生成结果 |
| `sta_drv_antclean.txt` | 7,702 B | **同一份 ODB 的 RCX + 三 corner STA + DRV**：逐角提 SPEF（各 15,587 net / 131,195 段线；18,878,430 / 19,148,078 / 20,231,383 B），一个进程成对读（Fastest←min、Typical←nom、Slowest←max）→ setup **+11.9732 / +9.1690 / +0.4543**、hold **+0.4042 / +0.7551 / +1.5854**，TNS 0.00 / WNS 0.00；DRV 两套口径：PDK 库自身（`default_max_transition 1.5`、无 fanout/cap 上限）三 corner 全 0，自加严 0.75 / 10 口径则 Slowest 275 slew、61 fanout（基线 ctsfix3 同口径 241 / 40）；逐条 ODB 探针证明 21 条新增扇出**扣掉二极管引脚后逻辑负载 ≤10**；含旧三份日志的口径自检与复现命令 | 生成结果 |
| `power_irdrop_antclean.txt` | 5,876 B | **同一份 ODB 上的功耗与电源网络压降**：`report_power` 三工艺角（ss 1.60 V 100 °C 内 5.62 / 开关 1.85 / 漏电 0.111 → 合计 **7.58 mW**；tt 1.80 V 25 °C 7.18 / 2.39 / 0.000119 → **9.57 mW**；ff 1.95 V −40 °C 8.30 / 2.84 / 0.00025 → **11.1 mW**），tt 角活动率 0.01 / 0.10 / 0.50 三档 9.16 / 9.57 / 10.7 mW、时钟组恒 4.17 mW（43.6%）；PDNSim `analyze_power_grid`：VPWR 平均 0.113 mV / 最差 **1.09 mV（0.06%）**、VGND 平均 0.111 mV / 最差 **1.08 mV**，两网 `PSM-0040` 全连通；含两段可复跑 Tcl、五条「证明 / 不证明」，以及两个坑（不读 liberty 会报 0 V 假成功、report_power 单进程只能跑一个 corner） | 本轮新增 |
| `eco_local_slew_eco.txt` | 15,534 B | **只动违例网的局部 ECO：Slowest 角 max_slew 275 → 60（-78%）**。两轮 275 → 102 → 60，每轮只剥当前违例所在的 47 / 19 条网重布，其余 15,536 条走线原样保留；总电容 126.5 → 126.3 pF（几乎不动）、setup +0.45 → +1.31、hold +1.59 → +1.33、DRT 0 违例。同文件记录了被证伪的整片重布（电容 126.5 → 151.0 pF / +19%、slew 275 → 1,147、setup +0.4543 → -0.0149）与四组交叉对照（旧 DEF 自抽 SPEF 复跑得到 275 / 0 / 0.45，与基线逐值重合），以及停在 60 的两个具体阻塞（resizer 在无真实寄生时按线载模型插 283 个 buffer、12 条网的 pin 接入点被邻居占用）。**未清零，页面与 PDF 的数字没有替换**。第九节（订正）追加了 ECO 库上的六项复核：功耗 9.57 / 9.16 / 10.7 mW、iRdrop VPWR 1.09 mV / VGND 1.08 mV、filler 35,334、密度六值 0 违例（0.7425 / 0.7231 / 0.9032 / 0.9228 / 0.9481 / 0.9723）有数且与 tapeout 逐值对齐；DRC 由 0 条变成 6 条 li.6（magic 与 klayout 两套独立出图给出同一 6 处 0.17 um li1 方块，属 DEF 几何临界）；XOR TOTAL_DIFF 94,607 但层号在 sky130A.map 里未映射，只能证明两版 GDS 不等价；LVS 三版 GDS 同为 devices 15,983 \| 15,983、nets 15,931 \| 15,828（差 103），判 Top level cell failed pin matching；天线三次尝试均卡在 magic 提取，记作未复核。同节作废了两条旧判断：721 条 implant DRC 与「先 gds read」无关（改用官方 mag_gds.tcl 后同为 6 条 li.6），klayout 在 chroot 里必崩的真因是缺 coreutils PATH | 本轮新增 |
| `../images/sha256_antclean_layout.png` | 1,600,361 B | **天线 0/0 那版 GDS 自己的金属层渲染**：输入就是 `antclean_fill.gds`（40,666,588 B / `89cda760…`），`gdspy` 展平后 3,021,383 个多边形、bbox 0,0 – 640,640 µm，只画 li1 与 m1–m5 共六层，4200×4200 px，sha256 `33179acd…`；渲染脚本 `render_antclean.py`（gdspy + matplotlib，非查看器截图）。**它与页面早先那张 `fixed15.gds`（16,621,738 B）的渲染不是同一份版图** | 本轮新增 |
| `cts9_lvs.txt` | 622 B | **这一版的 LVS 结论**：`Circuits match uniquely`、151 处叶子单元 `Netlists match uniquely`、顶层 pin 表与器件类等价 | 生成结果（netgen 原文截取） |
| `cts9_sta3c.txt` | 469 B | 同一次 run 的三 corner 签核时序：Slowest +0.51/+0.41、Typical +0.74/+0.41、Fastest +0.99/+0.40（全 MET） | 生成结果 |
| `cts9_metrics.csv` | 1,953 B | 同一次 run 的 `reports/metrics.csv` 原文件：0 违例五列全 0，`flow_status` 为 `flow failed`，五列 `-1` | 原样，未改一个字节 |
| `drv_fix_pilot.txt` | 5,065 B | **DRV 修复试点（CTS 阶段）**：从 placement 重跑 CTS 只改聚类目标，143 → 9（原配置 25/50 重跑量到 143，与线上 signoff 的 143 逐条相同）；当时把残留 9 条归因到 `CTS-0032 Max number of sinks is 15` 这一工具内部判据——**该结论已被 `drv_fix_routed.txt` 推翻，本文件原样保留不改** | 本轮新增 |
| `cts25.log` | 20,148 B | CTS 聚类 25/50（原配置）原始日志：`== AFTER_CTS_FANOUT ==` 段 143 条 | 本轮新增 |
| `cts8.log` | 5,322 B | CTS 聚类 8/50 原始日志：同段 9 条，含 `CTS-0032 ... Max number of sinks is 15` 原文 | 本轮新增 |
| `drv_rootcause.txt` | 4,475 B | **DRV 违例根因**：`config.tcl` 第 10 行时钟扇出目标 16、第 29 行 sink 聚类 25，而第 207 行→SDC 第 213 行要求 ≤10——配置自相矛盾；含 Slowest 角扇出值分布（11–20 密集成团 + 孤立 25/27，127 条为时钟叶子） | 本轮新增 |
| `sta_signoff_drv_3corner.txt` | 6,686 B | **DRV（max transition 0.75 / max fanout 10，来自 SDC 第 212–213 行）三 corner 检查**：新版 474 / 219 / 219 条违例，旧版 353 / 151 / 143 条；最差 slew 1.17（限 0.75）、最差扇出 27（限 10）；含「时序 MET ≠ signoff 通过」的口径说明 | 本轮新增 |
| `sta3c_chk.log` | 244,996 B | DRV 检查的**原始 OpenROAD 报告**（新版），`-- corner Slowest violators` 段起于第 1030 行，Typical 第 3900 行，Fastest 第 5238 行 | 原始输出 |
| `sta3c_chk_old.log` | 217,799 B | 旧版同脚本 DRV 报告，作新旧对照 | 原始输出 |
| `sta3c.log` | 167,259 B | 新版三 corner STA 的**原始 OpenROAD 报告**（逐字，未剪裁）：`==SETUP==` / `==HOLD==` 每角 `report_checks`、`==POWER==` 三角功耗、`==AREA==`、`==PARASITIC_ANNOTATION==` 210 个未标注 driver。**第 1096 行就是 `0.4058 slack (MET)`** | 原始输出 |
| `sta3c_old.log` | 167,264 B | 旧版同脚本三 corner 原始报告，**第 1096 行 `0.5619 slack (MET)`**——两行落在同一行号，因为脚本形状完全一样，只换了网表与 SPEF | 原始输出 |
| `sta_est_compare.txt` | 3,585 B | **估算口径 STA 对照（已被 `sta_signoff_3corner.txt` 取代，保留作过程记录）**：同一口径（`tt_025C_1v80` 单角 + `estimate_parasitics -global_routing`，无 RCX/SPEF）对 `25-fill.odb` 与 `fixed16.odb` 各跑一次：worst setup +9.8329 → +9.9243 ns、hold +0.6247 → +0.6274 ns。**这组数过于乐观，不能当 signoff** | 生成结果（作废） |
| `lvs_pass.txt` | 8,292 B | **LVS 结案**：两侧网名集合做差，真正多出的只有 `VNB`/`VPB` 两个网（井/衬底由 5,496 个 tap 接电源，Magic 提取时体端并入电源，而网表里 tap 引脚为空被整批丢掉）；`47 = 43 + 4`，两处都补后展平顶层 **166,353 器件 / 84,178 网**两侧相等，`Circuits match uniquely`；第 7 节记两次对照实跑：tap 单元在 PDK 里只有 `VGND VPWR` 两脚、body 为空，补回 5,496 个 tap 仍 47 行，强加 VNB/VPB 脚仍 47 行——另一条路线做不到，口径由定义决定 | 生成结果 |
| `eco_antenna.txt` | 5,696 B | **天线复核的两条入口与两套口径**：magic 从 GDS 进（`antennacheck`，48,600 gates，0 条；同时段 debug 复跑 489 行同样 0；正对照 `axil_spi_top.gds` 写出 1,100 B feedback 证明不是假阴性）；OpenROAD 从 routed ODB 进（`check_antennas -verbose`：`net52` / `output52/A` 的 met3 侧面比 1680.81 超门槛 400，面积比 311.19 反而未违例）→ 对外取严记 **1 条**，不记 0/0；并记 `net52` 与 DRV 残余 12 条网的交叉（同一根 1.14 ns 的最差脚） | 本轮新增 |
| `eco_drc_zero.txt` | 6,536 B | **ECO 版 DRC 从 6 条 li.6 修到 0 条**：起点是六处 0.170 × 0.170 µm 的 li1 岛（0.0289 µm²，不到 `li.6` 门槛 0.0561 µm² 的一半）；修法是朝空白区逐边试扩（每步 10 dbu、躲避区取其它 li1 sized 0.170），六块各长成 0.330 × 0.170 = 0.0561 µm²；第一版对称放大到 0.240 × 0.240 时有一块与相邻 li1 相并，作废留证。KLayout 全规则 **0 条**（92.830 s）；XOR 对 `eco_it2c` **7 处且全在 67/20（li1）**、净加 0.163 µm²；密度六值逐值不变；magic 重提版图网表 1,686,833 B / 20,155 行 / 18,534 器件 / 144 subckt 与修补前逐一相同，netgen 版图对版图 `Circuits match uniquely` → 没有改任何连接。magic 侧全片 DRC 用 OpenLane 自带 drc.tcl 那套配方（drc euclidean on + drc style drc(full) + drc listall why）也归 0，同一配方在修前那版上把 6 个坐标原样复现作正对照；天线 / slew / LVS 三项不受影响（ODB 未动） | 本轮新增 |

| `lvs_repro.txt` | 17,339 B | **抽取复现性结案：两次独立抽取网表逐字节相同、netgen 两次都过**。病根是 `ext2spice -o <输出> <ext 名>` 在 ext 不存在时不报错、不落盘，回落到上一次留下的 `sha256_axil.ext` 缓存 —— 早前「换会话重抽就对不上」因此撤回。含两条 run 的 md5/字节、GDS 记录头 450 字节差异解析（0x102/0x502 时间戳）、三份缓存同源反证、一条命令复现脚本、仍缺口（带 diode 版未复跑）。**第七节为 11-11 追加**：第四节那两条缺口已闭合（带 diode 版同口径重跑 = NOT-PASS，`Top level cell failed pin matching.`、顶层 `.subckt` 少 `VGND`）、「magic 卡住」撤回为极慢推进 + cwd 缺 `.ext` 缓存（t6/t7/t8/t9 四组对照，`addpath` 不能替代）、`repro3.sh` 四段与 `run_f4` / `run_g5` 指纹、`lvs-repro/` 入库与 Pages 只发 `docs/` 的事实。**第八节 11-11 再追加**：撤回「it2f 是无二极管版」（实测 327 颗，it2g 347 颗）、2 器件 = 2 条 `diode_2:ANTENNA` 未配对、29 条网里只有 1 条是 VGND、`15,981 vs 15,983` 是压平合并后的数、`VGND` 在 it2g 网表里 0 次而 `VPWR` 66,562 次、两版 GDS 顶层标签逐点相同 | 生成结果 |
| `lvs_diff_breakdown.txt` | 6,050 B | **差额拆解（第八节的可独立复算版）**：2 个器件 / 29 条网 / 顶层 VGND 并进 VPWR 的分项与出处。含 it2f 327 颗 diode 的 GDS 实例计数（57,382 顶层实例）、it2g 347 颗（新增 22 个坐标、消失 2 个）、`lvs_g5.out` 第 3,961 / 4,666–5,144 / 5,200 / 5,204 行定位、顶层实例表三份对照、电源脚 token 计数（33,104 vs 0 / 33,104 vs 66,562）、顶层 `datatype 5` 文本 112 个与坐标、met1 两个标签点多边形 bbox、以及「下一轮先换同版参考」的入口 | 生成结果 |
| `lvs_sameversion_ref.txt` | 9,664 B | **同版参考落地：换成与 347 颗 diode 同源的参考后，「20 颗器件差额 / 29 条无匹配网」两条全部消失**。参考是现做的：`eco_it2_eco4.odb` 里 `write_verilog` 出 `eco4_nl.v`（INSTS 57,395、diode 347、fill 35,327 行，与 `eco_it2g.gds` 顶层 57,395 对上），再用 `lvspkg/nl2spice.py` 转成 `net_eco4.spice` 2,873,227 B（37,400 实例 / 145 单元类 / 94 脚）；新旧参考 `.subckt` 端口逐 token 相同。第 6 次 run（tag g6）：`layout_g6.spice` 1,686,616 B md5 `0751c0c8…` 与 run_g5 逐字节相同，TOP_PORTS 93 / TOP_INST 16,572，145 个单元类逐类相等、`Netlists match uniquely` 143 处、器件 15,981 vs 15,995，唯一实质差异是每个实例 VPWR 64,174 脚对 31,990 脚（版图侧一条网吃了两份电源脚），2,119 / 110 / 32 / 26 四条计数全是这一个原因的下游。第 7 次 run（tag g7，`tmp/gds2/nod.gds` 无二极管版）：`layout_g7.spice` 1,663,156 B md5 `1e673279…`，VGND 842 / VPWR 66,019 —— **并网与 20 颗二极管无关**；且端口 93≠94 被 PHASE C 停住，守卫生效。另记 ODB 侧未并（参考 31,990+31,990 脚）、met1 全宽轨两版都是 228 条、met3 全宽 8 条、`.ext` 里 271,786 条 merge 把 VNB/VGND/VPWR/VPB 串成一条；短接坐标未定位，不写「已找到根因」 | 本轮新增 |
| `lvs_short_rootcause.txt` | 6,234 B | **电源短接根因闭合（带坐标）：短接不是电源网画错，是信号网 net46 的一条 105.06 um 竖直 li1 线穿过 38 条电源轨带**。自建 klayout 全片连通引擎（li1/mcon/met1~met5，网格索引 + `Polygon.touches` + 并查集）先在 f4 对照：两网分属组件 669588/669587、无路径；g6 两网同属组件 669827，BFS 路径 3 节点（mcon 切口 319845 起 → 合并 li1 多边形 gid 9，18,590 顶点 → mcon 切口）。DEF 第 280034 行 `NEW li1 ( 242190 14110 ) ( * 119170 )` 在 GDS 顶层落成矩形 `(242105,14025;242275,119255)`（宽 170、高 105,230）；该段 ECO2 实测 0 处、ECO3 首次出现，对应 `rep2.log` 第 214 行 `[WARNING DRT-0225] net46 … feedthrough mode`（同次 11 条 DRT-0225，仅 net46 拉出跨轨 li1 长线）。`nod.gds` 顶层仍有同矩形，确认与二极管无关。14 颗 diode 差仍记未闭合；本文件只定位、未改任何 DEF/GDS | 本轮新增 |
| `lvs_short_fix.txt` | 9574 | **成因更正 + 修复实验：短接不是那条 105.06 um 的线，是 DRT 把 li1 当跨行走线层**。单变量删除（只删第 280034 行 li1 → `eco_it2_eco4a.def` 17,658,922 B → `eco_it2ga.gds` 41,685,212 B）后并网仍在，只是存活网名翻成 VGND（顶层脚 66,531 / 0，原版 0 / 66,541），BFS 新桥落在 mcon `(319845,250155;320015,250325)` ↔ `(319845,247435;320015,247605)`（相邻两行，间距 2,720）。换判据「竖直 li1 ≥ 2,720 dbu」：`eco_it2.def` 0、`eco2` 0、`eco3` 23、`eco4` 23（最长 105,060），这 23 条与 `ant/rep2b.log` 里 23 条 `DRT-0225 … feedthrough mode` 一一对上。三次对照把触发条件钉在「先插二极管再重布」：只删 filler 再布 0 条；清掉 164,535 条 guide 重做 `global_route` 仍 23 条。修复实验改成先布后插：`eco_it2_t2.def` 二极管 347 颗、跨行 li1 0 条、`check_antennas` 0 net / 0 pin，`eco_it2t2.gds` 38,178,974 B，顶层 VGND 33,134 / VPWR 30,737，连通引擎 555,801 vs 555,800 无路径（12 s）→ **并网消失**；但 LVS 仍 NOT-PASS（器件 16,209 对 15,995、顶层 pin 未匹配），eco4 同版参考与 T2 自身 ODB 现出的参考两次同形。T2 无 `filler_placement`，不作发布版图。闸门脚本 `lvs-repro/li1_guard.py`（退出码 0/1） | 本轮新增 |
| `lvs_t3t4_route.txt` | 12,218 B | **T2 剩余差异查实是 39 颗二极管物理开路，T3/T4/T5 三轮修复确认「开路 vs 跨行 feedthrough」结构性二选一，仍无 LVS 通过版**。先纠正解析器：magic 网表单元名是行末 token（旧脚本误取第二 token），正确计数 T2 顶层 TOTAL 16,572 vs 16,572、143 类零差异。T2 真缺陷：magic 孤立节点与 klayout 几何扫描两路一致数出 39 颗二极管 DIODE 脚开路（20 颗 GRT 新插 ANTENNA_328..347 无详细布线 + 19 颗旧管被 detailed_route 报 0 违规的同时丢了 li1）。T3 补跑 detailed_route（1551→318→288→52→1→0）：开路清零、电源 token 平衡（33,988/31,630），但 li1_guard 报 23 条跨行 li1 长回来，LVS 仍 NOT-PASS（器件 16,231/15,995、网 16,943/15,828、4,157 条 no matching，无 filler 时井节点是局部名）。T4 回填 35,327 颗 filler：NWELL 114 片 area 202,221,734,000 与 f4 一致，但 magic 抽取塌缩（VGND 843/VPWR 67,436、顶层电源脚全命名 VPWR、与 g5/g6 抽取件同 md5），prep_lay FAIL@C（93 端口缺 VGND）。T5 只跑一轮：开路 0 但仍 15 条跨行 li1、318 违规未收敛。连通引擎更正：旧引擎在 f4 上也假阳性，修正版同层标签匹配后 f4=SEPARATE、g6=SHORT，实测 T2/T3 SEPARATE、T4 SHORT。四轮无任一同时满足跨行 0、开路 0、电源分开、端口 94，不写通过 | 本轮新增 |
| `onecmd_repro.txt` | 9,974 B | **一条命令复现结案：两版各给结论**。`lvs-repro/repro3.sh`（A 抽出 / B 新会话 ext2spice / C 端口整理 / D netgen，阶段 0 自建 148 个标准单元 `.ext` 缓存）在 `eco_it2f.gds` 上 21:58:00→21:59:28 跑出 **PASS**（88 秒、网表 md5 `09183c36…` 与历史两份独立抽取逐字节相同）；同一命令在 `eco_it2g.gds`（带 347 颗 diode）22:08:44→22:10:11 跑出 **不通过**——`Top level cell failed pin matching.`、`15,981 vs 15,983` 器件、`15,799 vs 15,828` 网，文件头即可定位到顶层 `.subckt` 少了 `VGND`（`VPWR …` vs `VGND VPWR …`，93 vs 94 端口，`VGND` 出现次数 842 vs 17,395）。另记「extract 静默停住」的真成因：工作目录里缺标准单元 `.ext`（空目录三次对照 12,503 / 12,095 / 12,027 B 日志零产物；拷进 cwd 后 2 分钟跑通；仅 `addpath` 指向缓存仍停） | 本轮新增 |
| `eco_lvs_map.txt` | 18,650 B | **LVS 的一次映射探针：名字不是死路，多出来的 103 条网才是**。第一版按「脚位置」对齐立刻崩（单一个版图 VPWR 就映射到两百多个网名，因为同一颗单元在两份网表里的 .subckt 端口顺序不同）；改按「端口名」对齐后：16,552 个顶层实例两侧同名同脚数全对上（网表侧多出的 20,832 个全是 FILLER_）、脚数不匹配 0 个、15,931 条版图网零冲突地落到 15,828 条网表网；反方向 68 个网名各收到 2 至 8 条版图网、合计多出 103 条，与 15,931 − 15,828 的差逐条对上。抽样 _07117_：DEF 原文是一个驱动 _12330_/Y + 五个负载同一网，版图侧被拆成 _12330_/Y 与 _12670_/C1 两条。正对照：把探针的两个输入换成已 PASS 的 tapeout 版（work_full/lay.spice 2,768,173 B 对 net.spice 2,708,330 B，同一条链），34,182 实例两侧全对、15,795 条网一一对应、分裂 0 条 —— 所以这 103 条是这一版特有，不是提取链固有。结论只到「卡点收敛成这 103 条、并已排除提取链」，不写成开路，也不写成 LVS 有解。第八节补记：按第五节路 B 做了分层几何抽刀，但那套窗口化判据被自己的对照否掉（30 条随机网里 17 条被判成断），因此不出结论；同时记下 DEF 侧可确定的事实 —— 68 条网的 ROUTED 段各自都是一整段（同口径 40 条随机网只有 1 条多组件），分裂更像出在脚与走线的接合处而不是走线中段。第九节把这条做实了：改用 LEF 引脚形状做判据（40 条随机网 98 脚对照开路 0），68 条网的 272 个脚里 OPEN 64 个、至少一脚开路的网 43 条，抽样 `_03524_` 的 `L1M1` 落点离 `_16239_/Y` 引脚左边界 2.210 µm 没压到脚 —— 这一版确实有真开路，位置在 pin access；DRT 那句 `_03524_ 1 pin not visited` 与之逐字对上。仍不写 LVS 有解 | 本轮新增 |
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
2821ea07bbdbd86ecd9c6b454abd5ed4073c5a5fb0b46644df410aebbfb6be01  klayout_drc_ctsfix3.txt
e5b7ec1351f7b53f1bec6a4f02696ef8807cbb4ff10c3093c8d762ba2ded5ddf  klayout_drc_ctsfix3_log.txt
b4180e1c6ef04e97c29a3a2f60cd07a5d68d3d409a22f62f125036e3f6d7ffd7  density_ctsfix3.txt
728788b76f652b340adcb08063e19ca326a17e332ec4a3d8152f0c83a78727be  density_ctsfix3_log.txt
a9403329a5963aa998f1b7c2711fa772c308298ab48111d949221818924647d6  antenna_check.txt
5f76607cf83cff7478f120c37d3536927e1662a54da1db2b91ae16ff74cce068  antenna_repair_attempt.txt
858300362d2267da025ea7e88efcf8c9dff5905c3e20813cc6a51cf2380786f1  antenna_repair_route_attempt.txt
f949e0d0ec5a81c30de9db98e4cc8851d40ecb1196e1470f5464cd79cccaccaf  antenna_repair_route_fixed.txt
ea954e06f4182e4fd0f88058c402824bf3f0eeb6ff6b81ef172233d080cb5c0c  lvs_top_level_gap.txt
a3dd1f65f39b93bf20eefe2d5458efba3053d073cacdf5fe275f73b0113193ee  lvs_new_pass.txt
e0b905155bdb1fcb4793feebc2570029536d69ed4abcd1e65d592ca3b694a221  sta_est_compare.txt
681637a543e750b338077d1ded658785f90cd198342277a78878c2e48f8bd2e2  sta_signoff_3corner.txt
7dd34ffaa667dc8dc6b6662083993c709e5754f9f80a5119dbd44947253271e0  sta3c.log
2ceda13c54e277c081cdad1dbf81c58eac5428c9110d799a40d1309ab4222200  sta3c_old.log
8af0d95e2a966bf7f01a49275332ea2a503c28379aa65b10860e365218b897fa  sta_signoff_drv_3corner.txt
6e34a60a9205b7b39ad6f42b216c64ac0b6c0ef301b4a83fcdadc048686750e1  sta3c_chk.log
8b9893df273506ec51a28b23c8931ed799f95bddcd3ffb3ac851b702bafeed9d  sta3c_chk_old.log
32d6e89d569bfa377c1130a464044c947fd503be845759cfc1f0cd9c251c7dcf  drv_rootcause.txt
b67a197da8c234c707755ba41dd20bbc96e1b9e05905dbf5158f4daeb0716675  drv_fix_pilot.txt
d08e23fe2fc94e5a1cb056e63cce7300cd2152948d5196237cbb60fbaaa079ac  drv_fix_routed.txt
1ffb8c6c42292230d848da5176fb5d8aaade1c7e10bf7b6466d81ca95eb67975  cts9d80_adj.log
0931bfeea7efc11f22631b6a73c3de52878c179c8e06c533008a169d467be16b  sta_cts9.log
de5d8a91e1c8e36f55e4e33edc1fbe966473d0a7d9e1f6a73f49ebf999ba3e32  cts9_route.txt
4d09b720220a0125efe446c6fbb2be7bbc83e9cd5c752ff431ab72fffdd9ca33  cts9_cts.txt
36b37506fc99d13cca0bebb73ad8e54d36fd038b60a267bdb2a9308e1a0f170d  cts9_lvs.txt
af75ba9599faedab25c24cd38e785e1d29b1e9385c6640d8b43a06990c5b8c8e  cts9_sta3c.txt
dd0d88d7cb73f98423f3e30fa946ad841b9f7f8f1674edd5835268e81cb4034e  cts9_metrics.csv
3b1129de86ff8517cd6fca6b027f8ab403fc6df2e877aad3450cc3d1e37507e3  cts25.log
1aa40f480db24a43f57d40d6b975f97a561db32e31ed3c50bff53b4efa2e5e36  cts8.log
304a4406735091a1425df27420ac6d395089c25bb655cfb248f8b720b4082683  lvs_attempt.txt
8397535d6d8f3a804c7d4d320699f815764eb261d09a7a57117ef40df1eda35e  lvs_rootcause.txt
23d7022ac3cb9136bed59ba43baf67adb5a137a0f5790ebe33549b12b6db1af9  lvs_instance_audit.txt
e2be16bc18b791c16b99030f0691d7c17f2b638748cdf4c7fdda2597cbce9bc0  lvs_selfcheck.txt
42237b91ed66826eabb58405c2acedce88fa9c6262b6c7847c72e1af5a2b4a42  lvs_pin_parity.txt
db6dc46de5298354ba0af0169a9086e94f085f949fae6bd92f11a003643edd13  lvs_port_graph.txt
37329768afd8f27f5f0f900d9f0fb987973d18a2912e03c9a6fec439259c012c  lvs_pass.txt（上一版 5,517 B）
1252cf940453f64f2005ef99570b61d938b48dffac49243cdcb5cba189d4b278  antenna_ctsfix3.txt
551a7a0bcf9f91bb68cc0ecc45562c5b57770c3aaba6f9b062a5c47204eab746  antenna_closed_loop.txt
0df4a6f8778ff8dc56b3c82251078f62a7273cfde723e69d7ce007efa7fc3626  klayout_drc_antclean.txt
4a07da9d1b4b3e2594359580cf6591b60e859be5a5a1676dc9d4a03736ce4715  density_antclean.txt
975e7494941bc0af0f38618f6029832f26bd07c106403af2ef50d41c469ccc98  lvs_antclean.txt
0edaf51f2610f8644283c700238b92739ca02fa190cb2ce5034589494a00f8a3  xor_antclean.txt
289559dac8ba8843d9b02f0573ec0f80ae4641c6540b089ff1a34b319963ecb7  sta_drv_antclean.txt
df77e80c1df3b97419d0f4687e44b006d95e30d7c8f64eb533922fa685923afe  power_irdrop_antclean.txt
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

`klayout_violations` 这一项也补跑成功：`klayout -b -zz -r sky130A_mr.drc`（release 2023.6.14_01.08），同一份 GDS，参数与 OpenLane 的 `run_klayout_drc_sky130` 等价（`beol 1 feol 1 floating_metal 0 seal 1 offgrid 1`），报告 **218 个规则类 / 0 条违例**，见 `klayout_drc.txt` 与 `klayout_drc_report.xml`。0 条不是空跑：故意造一个 met1 间距 0.10 µm 的小版图做正对照，同一 deck 立刻报 1 条 `m1.2`。口径：这是补跑不是流水线原始记录（`metrics.csv` 那列仍为 -1，因为本次 run 的第 37 步是 XOR 崩的、KLayout DRC 没执行到）；不含天线，密度类检查在 PDK 单独的 `.lydrc` 里，本轮没跑。（这一段的对象是 tapeout16 那版 39,965,858 B 的 GDS；ctsfix3 那版另有一组记录，见下节。）

`lvs_total_errors` 这一项也补跑过，结论是**没过**：Magic 从版图提取出晶体管级网表（2,785,763 B / 154 个子电路），与 PnR 网表按 PDK 器件模型展开后用 netgen 对比，迭代八轮后顶层**器件数两侧完全相等（15,593 = 15,593）**，但网数差 2（15,645 vs 15,647）且有 47 个 AXI 顶层端口在网表侧报 `no matching pin`，最终 `Netlists do not match.`。卡点在 verilog→spice 的端口/网名映射这一侧，不是版图与电路不一致。详见 `lvs_attempt.txt`。

这一版又把卡点往下压了一层：四次对照实验（顶层 `.subckt` 头折成 20 行、156 个单元原型前移、两侧 `[n]`→`_n` 统一改名、netgen `-auto`）**结果都还是 47 个 `no matching pin`**；端口表本身核对过——两侧顶层都是 98 个端口、名字逐字相同、无重复，被报无对应的名字在网表 body 里确实接在缓冲器输出上。四类变量因此全部排除，卡点收敛到 netgen 对这份手工转出 spice 的顶层端口识别。详见 `lvs_rootcause.txt`（其中含一处更正：早前「84 个端口未被引用」是正则边界的误报，真实是 8 个）。

再往下一层，卡点被具体到实例：版图网表顶层 33,984 行实例里，有 **1,795 行（5.3%）行尾不是单元名而是网名**（`X_20693_ VGND VPWR VPWR VGND clknet_leaf_41_clk net790 net193 u_core.W[3][23]`），netgen 判不出是什么单元，两边实例结构从这一层就不相等——这比「端口识别」具体。**但这一段后来被自己推翻了，见下一段。** 同一轮还把数字之间的关系拆干净了：PnR 放置的 47,087 个单元里 31,499 个是空引脚（fill / decap / tap），有引脚的 15,588 个正是 netgen 报的 15,593 的来源（差 5，未逐条对到）；版图提取的 33,984 与 47,087 的差 13,103 = fill_1 5,667 + fill_2 1,940 + tapvpwrvgnd_1 5,496，分毫不差。另有一个必须记下的失败：用 KLayout 的 `NetlistComparer` 当第二引擎时它**返回了 True，但 flatten 后两侧各只剩 8 个器件**，属假通过，不采用。详见 `lvs_instance_audit.txt`。

**更正（这一版）**：上一段那个「1,795 行缺单元名」的结论是错的，已撤回。Magic 的 `exttospice` 走标准 SPICE 续行——超长实例行的下一行以 `+` 开头，单元名就在续行上（`+ sky130_fd_sc_hd__dfrtp_1`）。把续行拼回去再判，**33,984 / 33,984 全部有单元名，缺名 0 行**；全文件 1,813 行以 `+` 开头，顶层体内正好 1,795 行，与那 1,795 处「行末是网名」逐行对应。同时补了两项正面实验：① 版图网表复制一份和自己比，**0 行 `no matching pin`、98 个端口全对、`Circuits match uniquely.`**，说明读取侧无障碍（另做了单行 1,295 字符与 `+` 折行两份构造对照，也都匹配）；② 转换出的网表逐实例逐脚与 `nl.v` 核对，**15,381 个实例一致**，206 个例外是 `clkload0` 这类在 `nl.v` 里本就没有该引脚的实例，31,499 个空引脚单元无信号脚可比。于是归因改判为**真实的版图与网表差异**（时钟负载与常量类单元的特殊连接、两侧网名集合 212 / 11 处不对称），不是名字、折行或格式问题。**LVS 仍未通过**，这一点没变。详见 `lvs_selfcheck.txt`。

**再更正（最新，第三次）**：上一段之后的「端口表整体错位一格」这个读法也不成立，撤回。三条依据：① 两侧端口表本来就是 98 / 98、名字逐字相同、顺序相同；② 两侧各删 32 个 `s_axil_rdata[n]` 端口后分别与原件比，版图侧与网表侧都报 **32 个唯一名 / 64 行**（每名重复两遍），反应一字不差，说明两侧读入等价；③ 把两侧 header 分别折成每行 8 个端口、两个方向各跑一次，仍是 **47 + 1**，pins 表起始行号都不变（162352）。关键的判别是行数：只有「某端口只在一侧存在」时 netgen 才把名字打印两遍，而真实比对里这 47 个名字**只打印一遍、无重复**——它们两侧端口表里都在，失败在**它们所连的网**。报告本身也把层次写清了：`Cell pin lists are equivalent.` + `Device classes ... are equivalent.` + `Final result: Netlists do not match.`。末行 `clk | s_axil_wdata[27] **Mismatch**` 是 netgen 自己改配对（`altered to match`）的痕迹，不是文件里的命名关系。当前只剩一句有依据的话：**47 个端口所连的网没配上，机制未定**。详见 `lvs_pin_parity.txt`（内含 netgen Tcl 通道的正确调用方式：`netgen -batch < 脚本` 不执行，须 `netgenexec -- -batch source <脚本>`）。

**第四次改写（最新）**：连「47 是版图与网表的实际连接差异」这句也撤了。换了个量法——不比端口名，比端口**连着什么**：对每个端口收集所有挂在它上面的器件脚，记成（单元名，引脚名），引脚名按**各文件自己声明的单元定义**翻译（Magic 的单元引脚顺序与 PDK 不同，`conb_1` 在 Magic 里是 `LO HI VPB VNB VGND VPWR`，PDK 里是 `VGND VNB VPB VPWR HI LO`，按位置比必然误判）。结果：**98 个端口里 94 个邻域逐字相同**；真正不同的只有 `bresp[0..1]`、`rresp[0..1]`，成因是 `nl.v` 末尾 4 条 `assign s_axil_bresp[0] = net389;` 这类别名被转换器漏读，补进去重跑仍是 47。所以现在只剩：**netgen 在这份数据上的顶层匹配没有收敛**。候选两类（大规模重复结构上的图同构搜索 / 更深处确实不同），本仓库不做裁决。详见 `lvs_port_graph.txt`。

**结案（最新）**：`lvs_pass.txt`。两侧网名集合做差，真正多出来的只有 `VNB` / `VPB` 两个网——版图里井与衬底由 5,496 个 `tapvpwrvgnd_1` 直接接到 VPWR/VGND，Magic 提取时体端一律并到电源，而 `nl.v` 里这些 tap 单元引脚是空的、被转换器整批丢掉，于是这两个网在网表侧悬空。`47 = 43 + 4`（43 归 VNB/VPB，4 归 assign 漏读），两处都补之后：展平顶层 **166,353 个器件、84,178 条网两侧完全相等**，netgen 原文 `Netlists match uniquely` / `Final result: Circuits match uniquely`，全文 `(no matching pin)` 出现 0 次。口径写在明处：`VNB≡VGND`、`VPB≡VPWR`，叶子单元由 netgen 展平后再比，因此是「顶层晶体管级等价」。第 7 节把「把 tap 补回网表」这条等价路线**实跑完了**：PDK 的 `tapvpwrvgnd_1` 只有 `VGND VPWR` 两个脚、body 为空，补回 5,496 个之后仍是 47 行 `Netlists do not match`；强加 VNB/VPB 脚仍是 47 行。所以这条路线做不到，口径不是可选项而是由单元定义决定的唯一写法。

已经补上的：**天线的版图已经修好了（布线级）**——补跑原本报 67 个 net / 87 个 pin 越限、`DiodeCells = 0`；后来查出前五次失败的根因是我手写脚本漏传 `global_route -allow_congestion`，补上后从 `22-global.odb` 出发三轮插 430 个二极管、复测 **0 / 0**，并流出新 GDS（18,618,660 B，`a58cdfea…`），在其上重跑 KLayout DRC（218 类 0 条）、密度（六层 0 条）、Magic DRC（`No errors found`）。**仍然缺的**：新版的功耗、GDS XOR、ERC、iRdrop、金属密度窗口都还没重跑（**LVS 已在新版通过**：`Circuits match uniquely`，两侧 15,588 器件 / 15,645 网，证据 `lvs_new_pass.txt`；**时序已补到 signoff 口径**：OpenROAD rcx 从 `fixed16.def` 提寄生（`-lef_res`，三份 RCX 规则各一份 SPEF）+ `ss_100C_1v60`/`tt_025C_1v80`/`ff_n40C_1v95` 三 corner，最差 setup +0.4058 ns / hold +0.4096 ns / TNS 0，证据 `sta_signoff_3corner.txt`；同一脚本在旧版产物上复现 +0.5619，口径对齐；早前那版估算口径 +9.8329 → +9.9243 已作废），所以旧版上的 XOR「21 层全一致」与所有 signoff 功耗数字仍只属于未修版；密度只跑了 PDK 的「最小空孔率」这一份 deck，各层金属密度窗口没跑；以及**每个标准单元内部逐管等价**（LVS 的口径是展平后的顶层晶体管级等价）。XOR 一致只说明两份产出相同，不等于两份都满足设计规则——DRC 那两份是各自单独跑的，天线更是另一套规则。

## 整条 flow 重跑的那一版（tag `ctsfix3`，2026-11-08）

前面那些文件是「分段补跑」拼出来的：时序一个 run、违例一个 run、LVS 又一个 run。这一组不一样，全部来自**同一次 OpenLane run**：

- 同一份 GDS（40,396,222 B）先被 Magic 提取成 SPICE，再用 netgen 与同一次 run 写的 `nl.v`（3,379,950 B）比对，结论 `Circuits match uniquely`；
- 同一次 run 的 detailed routing 收在 0 违例；
- 同一次 run 的 RCX 三 corner STA 全部 MET。

要说清的边界：flow 自己在第 36 步「Magic Spice Export from LEF」假死（chroot 环境限制），所以 `metrics.csv` 的 `flow_status` 是 `flow failed`，`lvs_total_errors` / `Magic_violations` / `pin_antenna_violations` / `net_antenna_violations` / `klayout_violations` 五列仍是 `-1`——那是**没跑**，不是 0。LVS 是在 flow 之外、用同一份 GDS 单独跑出来的，现已固化成仓库 `tools/lvs/run_lvs.sh` 一条命令（`bash tools/lvs/run_lvs.sh <run目录> sha256_axil`，末行 `LVS PASS`；两侧各 34,182 个实例、94 个端口，实跑数字见 `tools/lvs/EXPECTED.txt`）。KLayout DRC 与金属密度也已在这一版 GDS 上补跑（`klayout_drc_ctsfix3.txt`：218 类 / 0 条，正对照报 1 条 `m1.2`；`density_ctsfix3.txt`：六层空孔率 0.4993–0.9763 全高于阈值 / 0 条）；GDS XOR 与天线检查在这一版 GDS 上当时没跑（flow 原文 `…klayout.gds wasn't found. Skipping GDS XOR.`），**后来补跑并解决了**：`antenna_ctsfix3.txt` 记录复检结果是 39 net / 49 pin（不是 0），随后在同一份布线后 ODB 上按 `antenna_closed_loop.txt` 的三轮流程压到 **0 / 0**（独立进程复检仍 0/0），补 fill 后重出 GDS 40,666,588 B（`89cda760…`），并在这一份上四项同版复核：`klayout_drc_antclean.txt` 218 类 0 条、`density_antclean.txt` 六层 0 条、`lvs_antclean.txt` `Circuits match uniquely`、`xor_antclean.txt` `TOTAL_DIFF=0`。

这一版第一次让「布线 0 违例」「可交付 GDS + LVS 通过」「KLayout DRC 0 条 + 密度 0 条」落在同一个版本上；天线归零的那一版又把天线与 GDS XOR 补齐，六项在同一份 GDS 上拿到结论。**但仍不是签核**：天线归零版的 RCX + 三 corner STA + DRV 现已补跑（`sta_drv_antclean.txt`：时序六格全正、TNS 0.00；DRV 按 PDK 库自身口径 0 条，按自加严 0.75 / 10 口径 Slowest 275 slew / 61 fanout，属「时序通过、DRV 未清」，本轮未做 ECO），功耗仍未取；本版 LVS 两侧 34,289 实例与 ctsfix3 的 34,182 相差 +107，未逐条追到单元级。

## 第 ④ 项：另一颗设计 AXIL-SPI（tag `axspi1`，2026-11-09）

前面所有文件都来自 SHA-256 那一颗（只有 AXI4-Lite 寄存器接口的计算核）。这一组是**另一颗设计**：AXI4-Lite 从口 + SPI Master 主口，8 位 mode0，220 × 220 µm，用来证明同一套 PDK / 脚本 / 验收口径能承接带真实外设协议的设计。全部数字来自**同一次 OpenLane 1.1.1 run**，`flow_status = flow completed`，`total_runtime = 0h5m15s`。

| 文件 | 大小 | 是什么 | 是否原样 |
|---|---|---|---|
| `axil_spi_flow.txt` | 7,831 B | 这次实跑的全记录：RTL 三文件与寄存器映射、config 关键项、两次失败的根因与修法、全流程数字、时序、功耗、物理复核、结论与边界 | 生成结果 |
| `axil_spi_flow_metrics.csv` | 1,890 B | 本次 run 的 `metrics.csv`（两行，93 列，`flow completed` 版） | 原样，未改一个字节 |
| `axil_spi_sta_nom_checks.txt` | 1,234 B | `33-sta-rcx_nom/multi_corner_sta.checks.rpt` 的 slack / DRV 计数摘录 + 日志里的 `worst slack` 行 | 原文行 |
| `axil_spi_power.txt` | 2,661 B | `33-sta-rcx_nom/multi_corner_sta.power.rpt` 原文（三 corner 分组功耗） | 原样，未改一个字节 |
| `axil_spi_lvs.txt` | 75 B | `39-axil_spi_top.lvs.rpt` 原文 | 原样，未改一个字节 |
| `axil_spi_drc_magic.txt` | 108 B | `reports/signoff/drc.rpt` 原文（`COUNT: 0`） | 原样，未改一个字节 |
| `axil_spi_drc_klayout.txt` | 239 B | KLayout DRC 补跑结论（0 items）与脚本出处 | 生成结果 |
| `axil_spi_antenna.txt` | 125 B | `41-antenna_violators.rpt` 与 `_pins.txt` 原文（1 条：net58 / hold68/A） | 原样，未改一个字节 |
| `docs/images/axil_spi_layout.png` | 221,587 B | 版图渲染（仅金属层，220 × 220 µm 铺满画面） | 生成结果 |

**这一版拿到什么**：`CLOCK_PERIOD 12.0 ns`（83.33 MHz）下 worst setup +1.74 ns（Slowest 角）、worst hold +0.32 ns（Fastest 角），全 MET；tritonRoute 0 违例；Magic DRC 0 条、KLayout DRC 0 条；LVS `no net, device, pin, or property mismatches` / `Total errors = 0`；功耗 Slowest 2.05 µW / Typical 2.60 µW / Fastest 3.02 µW；PDNSim 压降 VPWR 最差 1.8 mV、VGND 最差 0.72 mV；4,672 个单元、利用率 24.88%、线长 19,802 µm、过孔 5,183。

**这一版没拿到什么**：DRV 未干净——max_slew / max_cap / max_transition 都是 0，但 **max_fanout 还有 5 条**（`clkbuf_4_13_0_clk/X`、`clkbuf_4_8_0_clk/X` 等实际 11 > 约束 10）；天线还有 **1 条记录**（pin 级比值 1.14 远低于阈值 400，但仍计入 violator）；KLayout DRC 是在流程外补跑得到的 0 条，不在 `metrics.csv` 的 `flow_status` 覆盖范围内。所以口径是「时序通过、扇出未清 5 条、天线 1 条」，不写 signoff 通过。

**两次失败的根因（都不是设计问题）**：① `verilator_lint_check` 假失败——linter 日志本身无 ERROR，是流程里 `exec bash -c "grep -i 'Error-NEEDTIMINGOPT' …"` 在 chroot 默认 PATH 下找不到 grep，连带 `generate_reports.py` 抛 `IndexError`；把 coreutils / gnugrep 写进 PATH 即过。② KLayout DRC 内部报 `tlFileUtils.cc:979 false was not true`——chroot 里 `/proc` 是空目录，KLayout 启动读 `/proc/self/exe` 取自身安装路径失败；同一份 GDS 用「先建 `/proc/<pid>/exe` 软链到真二进制、再 exec 同一 pid」的写法跑，结果是 0 items。因此流程内关掉 `RUN_KLAYOUT_DRC`，改由 `/tmp/kl/drc_axspi.sh` 单独补跑，其余步骤照跑。

**不可横向对比**：这颗是 0.0484 mm²、4,672 单元、微瓦功耗的「跑通验证」小车，与 SHA-256 那颗 640 µm die、22,000 单元、mW 功耗、pF 级寄生不是同一量级；24.88% 利用率是 `FP_CORE_UTIL 40` 下面积优先策略的结果，不代表流程能力差异。

## ECO 版引脚开路修好之后：复核记录（2026-11-10）

这一节承接上文「ECO 版」：那一版记的「真开路 43 条网 / 64 个脚」在本轮被查明成因并修好，
但 LVS 这一格仍然不写通过。新增证据 `eco_opens_fix.txt`（各节数字与产物路径逐条对应）。

| 项 | 本轮结果 | 证据 |
| --- | --- | --- |
| 开路成因 | 15,622 条网里 `NOGUIDE=0`、`NOWIRE=36`：36 条信号网有 guide 字段但是空表、零走线，驱动全是布线后才插入的 `max_capN` buffer 输出网（`net3774 … net3803`） | `eco_opens_fix.txt` 一 |
| 修法 | 对 wire 为 NULL 的信号网清空 guide → 补 `global_route` → `detailed_route -droute_end_iter 6`（1794 → 1779 → 516 → 122 → 96 → 0） | 同上 二 |
| 几何判据 | 68 条网 272 个脚：`OPEN 0`、`nets_with_open 0`；对照 98 脚 0（修前同一脚本报 64 / 43） | 同上 二 |
| 时序 | `slew 60 → 21`、`cap 0`、**`max_fanout 61 条`（首次按实计入）**；setup `+1.43`、hold `+1.29` | 同上 三 |
| 寄生 | `spef/eco2nom.spef` 19,498,387 B / 15,620 nets | 同上 三 |
| DRC | KLayout 0 items；magic 全片 `0 / 0` | 同上 四 |
| 天线 | **16 net / 20 pin**（修前 1/1，全部 `Required ratio 400 (Side area)`）：36 条网真正接上金属后暴露 | 同上 五 |
| LVS | **未通过，卡点换到提取链**：同一份 DEF 的两个抽取会话，一次 `15,983 | 15,983`、`15,828 | 15,828`、`Circuits match uniquely`，另一次把 `VNB` 井网并进 `VPWR`，变 `15,981 | 15,983`、`15,799 | 15,828` | 同上 四 |

**口径**：①这是「时序压到 21 脚、DRV 未清」，不是 signoff 通过，`max_fanout 61` 是本轮唯一变差的数字；
②LVS 没过，但这一轮没过的是「同一份 GDS 必须抽出同一套网表」这件事，不是版图里还有开路；
③天线按严的记 16 条，diode 修法在 ODB 层能到 0/0（`eco_it2_eco4.def` / `eco_it2g.gds`），但那一版同样过不了抽取复检；
④XOR 一格仍写「未定」。

**未闭合**：LVS 提取链复现性（同一 GDS 两次抽取电源井网一次分开一次合并）；天线 16 条；`max_fanout` 61 条的约束来源未查；（2026-11-11 更正：提取链复现性这一条已闭合 —— g5 与 g6 对同一个 `eco_it2g.gds` 两次抽取，`layout_g5.spice` / `layout_g6.spice` 各 1,686,616 B、md5 同为 `0751c0c82e7e39007c97a33a84d9cbc2`，逐字节相同；并网不是「一次分开一次合并」，而是稳定复现的并网，与 20 颗二极管无关，见 `lvs_sameversion_ref.txt`）
带 diode 的 `eco4` 版 STA 未跑（SPEF `eco4nom.spef` 19,538,041 B 已就绪）。
f40b5aef2fd2ecdb58371ef7a00a790568d0577b606f78c91b2d7999c8f694ca  lvs_repro.txt
fd2925846022aeaee377c91e5bb7b9aa9b8e1b1aa9a82f03b8b0b3a85cf5bc76  onecmd_repro.txt
