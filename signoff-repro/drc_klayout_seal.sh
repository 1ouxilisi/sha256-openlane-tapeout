#!/bin/bash
# KLayout 官方 deck 全片 DRC（core + seal ring）。同一份 deck，只换 topcell 与输入。
export LANG=C LC_ALL=C HOME=/tmp/kl
export PATH=/nix/store/k00cc6mbl072mnrad9wrq30mb2dcna2n-coreutils-full-9.5/bin:/bin:/usr/bin
BIN=/nix/store/zdin7gzr638czb3isvn7hf2vrnm3k289-klayout/bin/klayout
P=$$; mkdir -p /proc/$P; ln -sfn $BIN /proc/$P/exe
exec $BIN -b -zz -r /pdk/sky130A/libs.tech/klayout/drc/sky130A_mr.drc \
  -rd topcell=t8_sealed \
  -rd input=/tmp/gds2/t8_sealed.gds -rd report=/tmp/kl/drc_t8seal.xml \
  -rd feol=true -rd beol=true -rd floating_metal=false -rd seal=true -rd thread=4
