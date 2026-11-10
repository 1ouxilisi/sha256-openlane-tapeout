#!/bin/bash
# SHA-256 / sky130A : LVS 一条命令复现（宿主侧驱动）
#
# 用法: repro3.sh [GDS] [TAG] [PORTS] [REF_NETLIST]
#   GDS   待抽取的版图     默认 /tmp/eco/eco_it2f.gds
#   TAG   本次运行的标号    默认 f3（产物落在 run_<TAG>/ 下）
#   PORTS 期望的顶层端口数  默认 94
#   REF   基准网表          默认 /tmp/lvs_it2c/net.spice
#
# 产物:
#   $ROOT/tmp/repro/run_<TAG>/   全部中间件与四段日志
#   .../summary.txt              VERDICT 结论（PASS / NOT-PASS / FAIL@PHASEx）
#
# 退出码: 0 PASS / 2 结果不一致 / 3 提取链失败 / 4 用错
#
# 四段：A magic extract -> B 新会话 ext2spice -> C prep_lay 端口整理 -> D netgen lvs
# 关键约束（都是踩过的坑，别改）：
#   1) 标准单元的 .ext 必须 cp 进工作目录；只放别处靠 addpath 指过去，magic 会静默停住。
#   2) ext2spice 必须另起会话、且不带 ext 名；带一个不存在的 ext 名时 magic 不报错，
#      会回落到当前目录里旧的 <top>.ext。
#   3) netgen 的输入路径必须写 chroot 视角（/tmp/repro/...），写宿主路径必失败。
set -u
GDS=${1:-/tmp/eco/eco_it2f.gds}
TAG=${2:-f3}
PORTS=${3:-94}
NET=${4:-/tmp/lvs_it2c/net.spice}
TOP=sha256_axil

ROOT=/home/user/openlane-rootfs
WORK=$ROOT/tmp/repro/run_$TAG
CACHE=$ROOT/tmp/repro/cache_stdcel
BASHX=/nix/store/306znyj77fv49kwnkpxmb0j2znqpa8bj-bash-5.2p26/bin/bash
MAGIC=/nix/store/vqkxcjih78792qy07hw88gg0v3svr95a-magic-vlsi/bin/magic
NETGEN=/nix/store/b9kirpfkif1852bcy64f96np93xjalsi-netgen/bin/netgen
SETUP=/pdk/sky130A/libs.tech/netgen/sky130A_setup.tcl
HOSTPY=/opt/python3.12/bin/python3
PREP=/home/user/lvspkg/prep_lay.py

say() { echo "[$(date +%H:%M:%S)] $*"; }
fail() { say "FAIL@$1: $2"; echo "VERDICT: FAIL@$1 $2" > "$WORK/summary.txt"; exit 3; }

say "TAG=$TAG GDS=$GDS PORTS=$PORTS NET=$NET"

# ---------- PHASE 0 : 标准单元 .ext 缓存（从 PDK 生成，只需一次） ----------
if [ "$(ls "$CACHE"/*.ext 2>/dev/null | wc -l)" -lt 100 ]; then
  say "PHASE 0: 缓存缺失，从 PDK 生成 148 个标准单元 .ext"
  mkdir -p "$CACHE"
  nohup sudo -E chroot "$ROOT" /tmp/repro/cache.sh >> "$WORK.phase0.log" 2>&1 &
  for i in $(seq 1 180); do
    grep -q CACHE_DONE "$WORK.phase0.log" 2>/dev/null && break
    sleep 10
  done
  grep -q CACHE_DONE "$WORK.phase0.log" 2>/dev/null || fail 0 "缓存生成未完成"
  say "PHASE 0 done: $(ls "$CACHE"/*.ext | wc -l) 个 .ext"
else
  say "PHASE 0: 缓存已就位（$(ls "$CACHE"/*.ext | wc -l) 个 .ext）"
fi

# ---------- 工作目录 ----------
rm -rf "$WORK"; mkdir -p "$WORK"
cp "$CACHE"/*.ext "$WORK"/          # 见文件头约束 1
rm -f "$WORK/$TOP.ext" "$WORK/$TOP.mag"

# ---------- PHASE A : gds read + extract ----------
say "PHASE A: magic gds read + extract（cwd 已植入缓存 $(( $(ls "$WORK"/*.ext | wc -l) )) 个 .ext）"
timeout 1800 sudo -E chroot "$ROOT" "$BASHX" -c \
  "export PATH=/nix/store/k00cc6mbl072mnrad9wrq30mb2dcna2n-coreutils-full-9.5/bin:/bin:/usr/bin; export PDK_ROOT=/pdk; export REPRO_WORK=/tmp/repro/run_$TAG; export REPRO_GDS=$GDS; cd /tmp/repro/run_$TAG; $MAGIC -dnull -noconsole -rcfile /pdk/sky130A/libs.tech/magic/sky130A.magicrc /tmp/repro/ext.tcl" \
  > "$WORK/phaseA.log" 2>&1
grep -q "PHASE_A extract_done" "$WORK/phaseA.log" || fail A "extract 未完成（日志见 phaseA.log）"
[ -s "$WORK/$TOP.ext" ] || fail A "extract 没有产出 $TOP.ext"
say "PHASE A done: $TOP.ext $(stat -c%s "$WORK/$TOP.ext") B"

# ---------- PHASE B : 新会话 ext2spice（不带 ext 名，避免回落到旧缓存） ----------
say "PHASE B: ext2spice -o（独立会话）"
timeout 900 sudo -E chroot "$ROOT" "$BASHX" -c \
  "export PATH=/nix/store/k00cc6mbl072mnrad9wrq30mb2dcna2n-coreutils-full-9.5/bin:/bin:/usr/bin; export PDK_ROOT=/pdk; export REPRO_WORK=/tmp/repro/run_$TAG; export REPRO_SPICE=/tmp/repro/run_$TAG/layout_$TAG.spice; cd /tmp/repro/run_$TAG; $MAGIC -dnull -noconsole -rcfile /pdk/sky130A/libs.tech/magic/sky130A.magicrc /tmp/repro/sp.tcl" \
  > "$WORK/phaseB.log" 2>&1
grep -q "PHASE_B spice_done" "$WORK/phaseB.log" || fail B "ext2spice 未完成"
[ -s "$WORK/layout_$TAG.spice" ] || fail B "ext2spice 没有落盘"
say "PHASE B done: layout_$TAG.spice $(stat -c%s "$WORK/layout_$TAG.spice") B md5 $(md5sum "$WORK/layout_$TAG.spice" | cut -d' ' -f1)"

# ---------- PHASE C : 端口整理 ----------
say "PHASE C: prep_lay（宿主机 python）"
$HOSTPY "$PREP" -i "$WORK/layout_$TAG.spice" -o "$WORK/lay_$TAG.spice" --expect-ports "$PORTS" > "$WORK/phaseC.log" 2>&1 \
  || fail C "prep_lay 失败（端口数不等于 $PORTS？见 phaseC.log）"
grep -E "TOP_PORTS|TOP_INST" "$WORK/phaseC.log" | sed 's/^/    /'
[ -s "$WORK/lay_$TAG.spice" ] || fail C "整理后网表为空"

# ---------- PHASE D : netgen LVS ----------
say "PHASE D: netgen lvs"
timeout 1800 sudo -E chroot "$ROOT" "$BASHX" -c \
  "export PATH=/nix/store/k00cc6mbl072mnrad9wrq30mb2dcna2n-coreutils-full-9.5/bin:/bin:/usr/bin; cd /tmp; $NETGEN -batch lvs \"/tmp/repro/run_$TAG/lay_$TAG.spice $TOP\" \"$NET $TOP\" $SETUP /tmp/repro/run_$TAG/lvs_$TAG.out" \
  > "$WORK/phaseD.log" 2>&1
RES=$(grep -a "Final result" "$WORK/lvs_$TAG.out" 2>/dev/null | tail -1)
say "PHASE D 结论: ${RES:-<无 Final result>}"
if echo "$RES" | grep -q "match uniquely"; then
  echo "VERDICT: PASS  $(date -Is)  gds=$(basename "$GDS") spice_md5=$(md5sum "$WORK/layout_$TAG.spice" | cut -d' ' -f1)" > "$WORK/summary.txt"
  say "PASS —— 提取链与 LVS 全部走通"
  exit 0
else
  echo "VERDICT: NOT-PASS  $(date -Is)  ${RES:-no-result}" > "$WORK/summary.txt"
  exit 2
fi
