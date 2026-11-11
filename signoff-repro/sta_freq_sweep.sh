#!/nix/store/306znyj77fv49kwnkpxmb0j2znqpa8bj-bash-5.2p26/bin/bash
# T8 慢角频率边界扫描：版图、SPEF、lib 都不动，只改 SDC 的 clk 周期
#
# 用法（宿主侧）：
#   sudo -n /usr/sbin/chroot /home/user/openlane-rootfs bash /tmp/eco/sta_freq_sweep.sh
# 前置：
#   /tmp/eco/eco_it2_t8.odb 与 t8_{nom,max,min}.spef 已存在（由 rcx_run.sh 抽出）
#   sdc_t8_55mhz.sdc 已存在（period 18.0000）
# 产出：
#   sdc_p{24.0,23.0,22.0}.sdc、sdc_t8_40mhz.sdc（period 25）
#   /home/user/sta_t8_slow{40,24.0,23.0,22.0}.log、sta_t8_typ40.log、sta_t8_fast40.log
#
# 这个脚本只证明一件事：slack 与周期是 1:1 的，所以"慢角在哪过"可以由一次线性外推得到，
# 再用相邻两档实测夹住。不要把它的结果当成 signoff —— hold 与 DRV 在每一档都一样违例。

E=/tmp/eco
SS=/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ss_100C_1v60.lib
TT=/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
FF=/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ff_n40C_1v95.lib

run(){ sudo -n /usr/sbin/chroot /home/user/openlane-rootfs /tmp/eco/sta_rcx_run.sh "$1" "$2" "$3" "$4" > /home/user/sta_t8_$4.log 2>&1; }

# 慢角：18 ns 是基准（见 sta_t8_3corner.txt），这里补 24 / 23 / 22 三档把临界点夹住
for p in 24.0 23.0 22.0; do
  sed "s/-period 18.0000/-period $p/" $E/sdc_t8_55mhz.sdc > $E/sdc_p$p.sdc
  run $SS /tmp/eco/sdc_p$p.sdc /tmp/eco/t8_max.spef slow$p
done

# 40 MHz（25 ns）下把另外两个角也跑一遍，确认只有慢角这一档 hold 违例
sed "s/-period 18.0000/-period 25.0000/" $E/sdc_t8_55mhz.sdc > $E/sdc_t8_40mhz.sdc
run $TT /tmp/eco/sdc_t8_40mhz.sdc /tmp/eco/t8_nom.spef typ40
run $FF /tmp/eco/sdc_t8_40mhz.sdc /tmp/eco/t8_min.spef fast40

echo SCAN_DONE
