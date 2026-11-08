# 复现这一版：0 违例 + GDS + LVS 通过

本文只讲一件事：**怎么用仓库里的文件，把 tag `ctsfix3` 那次 run 重新跑出来，并判断跑对没跑对。**

设计目录：[`designs/sha256_v7b/`](designs/sha256_v7b/)，`config.tcl` 2,956 B / sha256 `a9018e78…`。这一版和 `designs/sha256_v7/` 的区别只有四行配置，逐条说明见该目录的 README。

---

## 一、一条命令

前置：一台 Linux 机器（本项目实测 4 核 / 8 GB 可跑完），已按 [`tapeout/deploy_openlane.sh`](tapeout/deploy_openlane.sh) 部署好 **OpenLane 1.1.1 rootfs**（`$R=/home/user/openlane-rootfs`）与 **sky130A PDK**（`$R/pdk`，chroot 内挂为 `/pdk`），root 权限。

```bash
R=/home/user/openlane-rootfs
cp -r designs/sha256_v7b "$R/designs/"          # 设计目录必须在 rootfs 的 /designs 下
nohup sudo chroot $R \
  /nix/store/306znyj77fv49kwnkpxmb0j2znqpa8bj-bash-5.2p26/bin/bash -c \
  "export LANG=C LC_ALL=C TERM=xterm-256color PDK_ROOT=/pdk; cd /; \
   exec /nix/store/xpc7xd67rslanlqh566s6jph53bn830w-openlane1-1.1.1/bin/flow.tcl \
   -design /designs/sha256_v7b -tag ctsfix3" > "$R/tmp/ctsfix3.out" 2>&1
```

（`nix/store` 里的那两个哈希路径随 rootfs 版本而变；用 `ls "$R"/nix/store/*-bash-*/bin/bash` 与 `ls "$R"/nix/store/*-openlane1-1.1.1/bin/flow.tcl` 取实际路径替换。上文是本次实测的值。）

四个环境变量不能省：漏 `LC_ALL=C LANG=C` 会在 STEP 0 `verilator_lint_check` 直接失败；漏 `TERM` 会让日志输出异常。`cd /` 也不能省——在 `/designs/sha256_v7b` 里启动会 prep 失败。

有完整 `/proc` 的 Docker 宿主上等价做法是 `docker run --rm -v "$PWD/designs:/designs" -v "$PDK_ROOT:/pdk" openlane:1.1.1 flow.tcl -design /designs/sha256_v7b -tag ctsfix3`。**这条路本项目没有实际验证过**，只是 OpenLane 官方用法；走这条路线时记得把 `config.tcl` 第 64 行 `RUN_KLAYOUT` 改回 `1`，否则会主动放弃 KLayout 那两步。

耗时约 **37 分钟**（本机 0h37m21s）。

## 二、怎么判断跑对了

不看 `flow_status`，看下面四处原文（路径相对 `$R/designs/sha256_v7b/runs/ctsfix3/`）：

| 检查点 | 期望 | 位置 |
|---|---|---|
| CTS 聚类确实生效 | `Total number of sinks after clustering: 248.` 与 `Fanout distribution … 9:244, 10:2` | `logs/cts/15-cts.log` 第 **1049** / **1084** 行 |
| 详细布线收敛到 0 | `12,932 → 4,974 → 4,733 → 1,076 → 79 → 34 → 1 → 1 → 0` | `logs/routing/26-detailed.log` 第 **194/245/295/345/395/442/489/535/581** 行 |
| GDS 字节数 | `results/signoff/sha256_axil.gds` **40,396,222 B** | `results/signoff/` |
| 网表字节数 | `results/routing/sha256_axil.nl.v` **3,379,950 B** | `results/routing/` |
| 指标 | `TotalCells 47559`、`Final_Util 46.2004`、`wire_length 618229`、`vias 117592`、`DIEAREA_mm^2 0.4096` | `reports/metrics.csv` |
| 三 corner 时序 | setup **+0.51 / +0.74 / +0.99**、hold **+0.41 / +0.41 / +0.40**（Slowest / Typical / Fastest） | `reports/signoff/29,31,33-sta-rcx_*/multi_corner_sta.*` |

已经归档的原文摘录（710 / 288 / 622 / 469 / 1,953 B，附 SHA-256）在 `docs/evidence/`：`cts9_route.txt`、`cts9_cts.txt`、`cts9_lvs.txt`、`cts9_sta3c.txt`、`cts9_metrics.csv`。`docs/numbers.html` 第六节列了全部指纹，可逐字节核。

**`metrics.csv` 的 `flow_status` 会是 `flow failed`，这是预期。** 第 36 步「Magic Spice Export from LEF」在 `sudo chroot` 里会假死（15 分钟 CPU 只跑 17 秒、fd 停在 155 不增长；`sudo pkill -f magicdnull` 可终止）。GDS 在这步之前已由 magic 出好，所以 GDS 与 RTL 网表都是完整的；但 `lvs_total_errors`、`Magic_violations`、`pin_antenna_violations`、`net_antenna_violations`、`klayout_violations` 五列会是 **`-1`（没跑，不是 0）**。

## 三、LVS 怎么复现

LVS 不在 flow 里（第 36 步死在 chroot），是在 flow 之外用同一份 GDS 手跑出来的：

```
netgen -batch lvs "<版图侧.spice> sha256_axil" "<网表侧.spice> sha256_axil" \
       <pdk>/libs.tech/netgen/sky130A_setup.tcl <输出文件>
```

通过的样子是末行 **`Final result: Circuits match uniquely.`**、`Net:` 计数 0（原文在 `docs/evidence/cts9_lvs.txt`）。

两侧输入不是原样可比的，中间必须做四件事——每一条都是踩出来的真缺陷，不是工具玄学：

1. **Magic 写出的网表按固定列宽折行，下一条以 `+` 起头。** 先 unwrap 再统计，否则实例数/引脚数都会数错（顶层实例 34,182 两侧一致，但引脚 187,216 对 189,886）。
2. **电源引脚按版图口径连**：网表侧 `VNB→VGND`、`VPB→VPWR`（版图侧每实例是 `… VGND VGND VPWR VPWR …`）。不做的话电源网扇出 31,740 对 15,870、报 13,961 个 `Net:` 片段。
3. **fill / tap 单元两侧同删**：`sky130_fd_sc_hd__fill_1`、`fill_2`、`tapvpwrvgnd` 在版图里 `.subckt` 为空（无器件），实例留着会被 netgen 展平成 unmatched。
4. **未连引脚不能用共享常量名**：CTS 加的均衡负载 `clkload*` 输出悬空，版图侧命名是 `clkload90/X` 这类「实例/引脚」。网表侧若写成 `NC_Y`/`NC_HI`/`NC_X` 这种共享名，178 个 `clkbuf_4/X`、11 个 `clkbuf_8/X`、5 个 `clkinvlp_4/Y` 会被归成同一类，报 222 个 Net mismatch；改成 `f'{inst}/{pin}'` 后归零。
   另外顶层有 4 个重复端口（`s_axil_bresp[0..1]`、`s_axil_rresp[0..1]`），两侧同删后 98 → 94 端口，`Cell pin lists are equivalent`。

版图侧提取用 Magic 从 `sha256_axil.mag`（run 产物，32,237,466 B）跑 `extract` + `ext2spice`，不要用 gdspy 从 GDS 重写（那样只出 4 个端口）。另外：不要在 FUSE 网络盘上跑 Magic（`/home/user` 单次 open 约 1 s，会表现为「零输出假死」），把工作目录放在本地盘。

**已知缺口（如实写在这里）**：把上述四点做出来的清洗脚本（`mk_net2.py` 一类）与最终两侧 SPICE（`lay_u2.spice` 2.8 MB、`pnr_v4.spice` 4.0 MB）**尚未入库**。所以「LVS 这一段」现在可复现的是**方法与判据**，不是「一条命令」。补齐它需要把四个变换固化成脚本并附上两侧输入的生成命令，这是下一步要做的事，页面与 `docs/evidence/README.md` 里不声称它已完成。

## 四、这一版明确不是签核

- `RUN_KLAYOUT "0"` 导致 **KLayout DRC 与 GDS XOR 本版没跑**（flow 原文警告 `…klayout.gds wasn't found. Skipping GDS XOR.`）。
- **天线检查**（`pin_antenna_violations` / `net_antenna_violations`）与**金属密度**本版没跑到。
- **功耗**本版没取（三 corner 报告存在但未解析，约 1.09e-2 / 1.12e-2 / 1.11e-2 W，口径未统一，故不写进任何结论）。
- `metrics.csv` 里的 `wns -23.05` 是 `pl/estimate` 口径，**不是签核值**，不可引用。

准确的说法是：这一版第一次让「详细布线 0 违例」「可交付 GDS」「LVS 通过」落在同一次 run 上，但它不是签核完成。
