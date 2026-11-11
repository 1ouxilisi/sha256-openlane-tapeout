signoff 复现脚本（DRC / SPEF / STA / seal ring）
====================================================

这是 2026-11-11 跑 T8 时实际用的脚本，原样留档，配合 docs/evidence 下三份证据：
  drc_t8_pass.txt       全片 DRC 两条引擎 + 正对照
  sta_t8_3corner.txt    真 RCX SPEF 下的三 corner STA
  padring_t8.txt        seal ring 已做、pad ring 未做

文件
----
drc_generic.tcl       magic 全片 DRC 主脚本（需同目录 read.tcl）
run_drc.sh            magic DRC 启动器（两参数：def、报告）
drc_klayout_core.sh   KLayout 官方 deck，裸 core
drc_klayout_seal.sh   KLayout 官方 deck，core + seal ring
rcx.tcl               OpenRCX 抽 SPEF
rcx_run.sh            SPEF 启动器（两参数：规则、输出）
sta_t8_rcx.tcl        STA 主脚本（stdout 分段）
sta_rcx_run.sh        STA 启动器（四参数：liberty、sdc、spef、tag）
seal_merge.py         seal ring 合并（klayout python）

环境
----
全部在 chroot 里跑，PDK 走 /pdk：
  sudo -n /usr/sbin/chroot /home/user/openlane-rootfs <chroot 内脚本> <实参...>
路径里的 /nix/store/... 是本机 nix 的绝对路径，换机器要按 which magic / which openroad 改。
环境变量经 sudo 会被重置，所以参数一律用脚本实参传。

两个会静默出错的地方
--------------------
1. magic DRC：不设 box 铺满 die，或没写 drc style drc(full)，结果会是 0 条假阴性。
   判据：日志里必须有 DIE box: 0 0 128000 128000，且同一套规则有过非零的正对照（本版是 9408 条）。
2. KLayout：不加 -zz、不做 /proc/$$/exe 符号链接，直接跑不起来（argv[0] 解析失败）。

一个口径陷阱
------------
estimate_parasitics -global_routing 得到的时序不能当签核数。同一版图、同一 SDC：
估算寄生给 18 ns +9.987 ns（全 MET），真 SPEF 给 -6.057 ns（慢角不过）。
要判过没过，必须先抽 SPEF。
