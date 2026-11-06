#!/usr/bin/env bash
# ============================================================
# 静态 lint（verilator），不依赖 OpenLane
# 用法：bash scripts/lint_check.sh [SRC_DIR]
# 依赖：verilator（apt-get install -y verilator）
#
# 豁免说明（已知且无害，写清楚而不是假装没有）：
#   `15 - wptr`（wptr 4 bit）与 `7 - rptr`（rptr 3 bit）的减法在 Verilator 5.x 里
#   报 WIDTHEXPAND：代数被扩到 32 位，但结果范围仍是 0..15 / 0..7，语义与位宽无关，
#   综合后网表不受影响——属于风格告警，不是功能缺陷。
#   仅 5.x 有这类检查，4.x（Ubuntu 22.04 apt 版本）无此告警，故按版本条件豁免。
# ============================================================
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SRC="${1:-$ROOT/designs/sha256/src}"
TOP="${TOP:-sha256_top}"
OUT="${OUT:-$ROOT/build/lint.log}"

if ! command -v verilator >/dev/null 2>&1; then
  echo "[SKIP] 找不到 verilator。apt-get install -y verilator 后重跑。"
  exit 0
fi

VER="$(verilator --version 2>/dev/null)"
MAJ="${VER#Verilator }"
MAJ="${MAJ%%.*}"

EXTRA=()
if [ "${MAJ:-0}" -ge 5 ] 2>/dev/null; then
  EXTRA=(-Wno-WIDTHEXPAND)
fi

mkdir -p "$(dirname "$OUT")"

echo "[1/2] verilator --lint-only -Wall ${EXTRA[*]:-} --top-module $TOP（版本：${VER:-unknown}）"
verilator --lint-only -Wall -Wno-fatal "${EXTRA[@]}" \
  --top-module "$TOP" "$SRC/sha256_pipe.v" "$SRC/sha256_top.v" 2>&1 | tee "$OUT"

if grep -q "%Error" "$OUT"; then
  echo "[FAIL] verilator 报出错误"
  exit 1
fi

W=$(grep -c "%Warning" "$OUT" || true)
[ -z "$W" ] && W=0
echo "[2/2] SUMMARY: warnings=$W errors=0"
if [ "$W" -gt 0 ]; then
  echo "  有告警但不判失败；逐条看 $OUT"
else
  echo "  干净：除已豁免的位宽扩展告警外无其他告警"
fi
