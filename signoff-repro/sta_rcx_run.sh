#!/bin/bash
# STA 启动器。四个参数：liberty、sdc、spef、tag。
# 例（slow 角、18 ns）：
#   sudo -n /usr/sbin/chroot /home/user/openlane-rootfs /tmp/eco/sta_rcx_run.sh \
#     /pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ss_100C_1v60.lib \
#     /tmp/eco/sdc_t8_55mhz.sdc /tmp/eco/t8_max.spef slow18
export PDK_ROOT=/pdk
export STA_LIB="$1"
export STA_SDC="$2"
export STA_SPEF="$3"
export STA_TAG="$4"
cd /tmp/eco
exec /nix/store/7g30wn9qnkcvnkk5h9q1cqk0yl86qxil-openroad/bin/openroad -no_init /tmp/eco/sta_t8_rcx.tcl
