#!/bin/bash
# KLayout 官方 deck 全片 DRC（裸 core）。三处可改：topcell / input / report。
# 必须 -zz，并把 /proc/$$/exe 指到 klayout，否则 argv[0] 解析失败，跑不起来。
export LANG=C LC_ALL=C HOME=/tmp/kl
export PATH=/nix/store/k00cc6mbl072mnrad9wrq30mb2dcna2n-coreutils-full-9.5/bin:/bin:/usr/bin
BIN=/nix/store/zdin7gzr638czb3isvn7hf2vrnm3k289-klayout/bin/klayout
P=$$; mkdir -p /proc/$P; ln -sfn $BIN /proc/$P/exe
exec $BIN -b -zz -r /pdk/sky130A/libs.tech/klayout/drc/sky130A_mr.drc \
  -rd topcell=sha256_axil \
  -rd input=/tmp/gds2/eco_it2t8.gds -rd report=/tmp/kl/drc_t8.xml \
  -rd feol=true -rd beol=true -rd floating_metal=false -rd seal=true -rd thread=4
