#!/bin/bash
# magic 全片 DRC 启动器。两个参数：DEF 路径、报告输出路径。
# 在 chroot 内执行（PDK 走 /pdk）：
#   sudo -n /usr/sbin/chroot /home/user/openlane-rootfs /tmp/gds2/run_drc.sh <def> <out>
export PDK_ROOT=/pdk
export DRC_DEF="$1"
export DRC_OUT="$2"
cd /tmp/gds2
exec /nix/store/vqkxcjih78792qy07hw88gg0v3svr95a-magic-vlsi/bin/magic -dnull -noconsole \
  -rcfile /pdk/sky130A/libs.tech/magic/sky130A.magicrc /tmp/gds2/drc_generic.tcl
