#!/bin/bash
# PHASE 0 的 chroot 侧入口：在 chroot 里跑 magic + build_cache.tcl，成功后打 CACHE_DONE。
# repro3.sh 在缓存不足 100 个 .ext 时会调用它，并等这个标记出现。
set -u
export PATH=/nix/store/k00cc6mbl072mnrad9wrq30mb2dcna2n-coreutils-full-9.5/bin:/bin:/usr/bin
export PDK_ROOT=/pdk
export REPRO_LIB=/pdk/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds
export MASTERS=/tmp/repro/masters.txt
export REPRO_CACHE=/tmp/repro/cache_stdcel

mkdir -p "$REPRO_CACHE"
/nix/store/vqkxcjih78792qy07hw88gg0v3svr95a-magic-vlsi/bin/magic -dnull -noconsole \
  -rcfile /pdk/sky130A/libs.tech/magic/sky130A.magicrc /tmp/repro/build_cache.tcl
ls "$REPRO_CACHE"/*.ext | wc -l
echo CACHE_DONE
