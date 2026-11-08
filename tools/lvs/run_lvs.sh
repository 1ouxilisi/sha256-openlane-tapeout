#!/usr/bin/env bash
# 一条命令复现「LVS 通过」：
#   版图侧 GDS -> Magic 提取 SPICE -> 清洗 -> netgen
#   网表侧 nl.v -> + PDK 单元库 -> netgen
#
# 用法： bash tools/lvs/run_lvs.sh <run目录> [单元名]
#   <run目录> 需含 results/signoff/<cell>.gds 与 results/routing/<cell>.nl.v
# 判据： 输出出现 "Final result: Circuits match uniquely."
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN="${1:?usage: run_lvs.sh <run_dir> [cell]}"
CELL="${2:-sha256_axil}"
PDK_ROOT="${PDK_ROOT:-/pdk2}"
PDK="$PDK_ROOT/sky130A"
WORK="${LVS_WORK:-$(mktemp -d)}"
MAGIC="${MAGIC_BIN:-magic}"
NETGEN="${NETGEN_BIN:-netgen}"

GDS="$RUN/results/signoff/$CELL.gds"
NL="$RUN/results/routing/$CELL.nl.v"
for f in "$GDS" "$NL"; do
  [ -s "$f" ] || { echo "MISSING $f"; exit 2; }
done

export MAGIC_TECH="$PDK/libs.tech/magic/sky130A.tech"
export MAGIC_WORK="$WORK"
export MAGIC_GDS="$GDS"
export MAGIC_CELL="$CELL"
export MAGIC_STDCELL_MAG="$PDK/libs.ref/sky130_fd_sc_hd/mag"

echo "[1/4] Magic 提取版图网表"
mkdir -p "$WORK"
( cd "$WORK" && "$MAGIC" -dnull -noconsole -T "$MAGIC_TECH" "$HERE/ext_mag.tcl" ) \
  > "$WORK/magic.log" 2>&1
grep -q SPICE_DONE "$WORK/magic.log" || { echo "MAGIC FAILED, see $WORK/magic.log"; exit 3; }
ls -l "$WORK/layout.ext.spice"

echo "[2/4] 清洗版图侧"
python3 "$HERE/prep_lay.py" -i "$WORK/layout.ext.spice" -o "$WORK/lay.spice" --top "$CELL"

echo "[3/4] 生成网表侧"
python3 "$HERE/nl2spice.py" -n "$NL" --cell "$CELL" -o "$WORK/net.spice" \
  -p "$PDK/libs.ref/sky130_fd_sc_hd/spice/sky130_fd_sc_hd.spice" \
     "$PDK/libs.ref/sky130_fd_sc_hd/spice/sky130_ef_sc_hd__decap_12.spice"

echo "[4/4] netgen LVS"
"$NETGEN" -batch lvs "$WORK/lay.spice $CELL" "$WORK/net.spice $CELL" \
  "$PDK/libs.tech/netgen/sky130A_setup.tcl" "$WORK/lvs.out" \
  > "$WORK/netgen.log" 2>&1

grep -E "Cell pin lists|Device classes|Final result" "$WORK/lvs.out"
if grep -q "Final result: Circuits match uniquely." "$WORK/lvs.out"; then
  echo "LVS PASS  workdir=$WORK"
  exit 0
fi
echo "LVS FAIL  workdir=$WORK"
exit 1
