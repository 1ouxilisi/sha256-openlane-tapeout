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
| `cts9_lvs.txt` | 622 B | **这一版的 LVS 结论**：`Circuits match uniquely`、151 处叶子单元 `Netlists match uniquely`、顶层 pin 表与器件类等价 | 生成结果（netgen 原文截取） |
| `cts9_sta3c.txt` | 469 B | 同一次 run 的三 corner 签核时序：Slowest +0.51/+0.41、Typical +0.74/+0.41、Fastest +0.99/+0.40（全 MET） | 生成结果 |
| `cts9_metrics.csv` | 1,955 B | 同一次 run 的 `reports/metrics.csv` 原文件：0 违例五列全 0，`flow_status` 为 `flow failed`，五列 `-1` | 原样，未改一个字节 |
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
c33ea3177d7ac75ee086803df8aa519cea1cbac8774c6cc5fccada04461322aa  cts9_metrics.csv
3b1129de86ff8517cd6fca6b027f8ab403fc6df2e877aad3450cc3d1e37507e3  cts25.log
1aa40f480db24a43f57d40d6b975f97a561db32e31ed3c50bff53b4efa2e5e36  cts8.log
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

已经补上的：**天线的版图已经修好了（布线级）**——补跑原本报 67 个 net / 87 个 pin 越限、`DiodeCells = 0`；后来查出前五次失败的根因是我手写脚本漏传 `global_route -allow_congestion`，补上后从 `22-global.odb` 出发三轮插 430 个二极管、复测 **0 / 0**，并流出新 GDS（18,618,660 B，`a58cdfea…`），在其上重跑 KLayout DRC（218 类 0 条）、密度（六层 0 条）、Magic DRC（`No errors found`）。**仍然缺的**：新版的功耗、GDS XOR、ERC、iRdrop、金属密度窗口都还没重跑（**LVS 已在新版通过**：`Circuits match uniquely`，两侧 15,588 器件 / 15,645 网，证据 `lvs_new_pass.txt`；**时序已补到 signoff 口径**：OpenROAD rcx 从 `fixed16.def` 提寄生（`-lef_res`，三份 RCX 规则各一份 SPEF）+ `ss_100C_1v60`/`tt_025C_1v80`/`ff_n40C_1v95` 三 corner，最差 setup +0.4058 ns / hold +0.4096 ns / TNS 0，证据 `sta_signoff_3corner.txt`；同一脚本在旧版产物上复现 +0.5619，口径对齐；早前那版估算口径 +9.8329 → +9.9243 已作废），所以旧版上的 XOR「21 层全一致」与所有 signoff 功耗数字仍只属于未修版；密度只跑了 PDK 的「最小空孔率」这一份 deck，各层金属密度窗口没跑；以及**每个标准单元内部逐管等价**（LVS 的口径是展平后的顶层晶体管级等价）。XOR 一致只说明两份产出相同，不等于两份都满足设计规则——DRC 那两份是各自单独跑的，天线更是另一套规则。

## 整条 flow 重跑的那一版（tag `ctsfix3`，2026-11-08）

前面那些文件是「分段补跑」拼出来的：时序一个 run、违例一个 run、LVS 又一个 run。这一组不一样，全部来自**同一次 OpenLane run**：

- 同一份 GDS（40,396,222 B）先被 Magic 提取成 SPICE，再用 netgen 与同一次 run 写的 `nl.v`（3,379,950 B）比对，结论 `Circuits match uniquely`；
- 同一次 run 的 detailed routing 收在 0 违例；
- 同一次 run 的 RCX 三 corner STA 全部 MET。

要说清的边界：flow 自己在第 36 步「Magic Spice Export from LEF」假死（chroot 环境限制），所以 `metrics.csv` 的 `flow_status` 是 `flow failed`，`lvs_total_errors` / `Magic_violations` / `pin_antenna_violations` / `net_antenna_violations` / `klayout_violations` 五列仍是 `-1`——那是**没跑**，不是 0。LVS 是在 flow 之外、用同一份 GDS 手跑出来的；KLayout DRC、GDS XOR、天线与密度检查这一版都没跑。

这一版第一次让「布线 0 违例」和「可交付 GDS + LVS 通过」落在同一个版本上，但仍不是签核：缺 DRC、天线、密度、XOR 四项。
