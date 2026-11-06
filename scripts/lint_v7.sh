#!/usr/bin/env bash
# ============================================================
# v7 静态 lint（verilator），要求**零告警**
#
# 与 v6 的 lint_check.sh 不同：v7 是新写的 RTL、没有历史包袱，
# 所以不设任何豁免——4 条初始告警（WIDTHEXPAND、UNUSEDSIGNAL、
# wstrb 未用、awaddr 位宽）全部改在 RTL 里，而不是加 -Wno- 掩盖。
# 判据：出现 %Error 或 %Warning 都算失败。
# ============================================================
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
D="$ROOT/designs/sha256_v7/src"
OUT="${OUT:-$ROOT/build/lint_v7.log}"

if ! command -v verilator >/dev/null 2>&1; then
  echo "[SKIP] 找不到 verilator，跳过 v7 lint。"
  exit 0
fi

mkdir -p "$(dirname "$OUT")"
echo "[1/2] verilator --lint-only -Wall --top-module sha256_axil（$(verilator --version 2>/dev/null)）"

verilator --lint-only -Wall --top-module sha256_axil \
  "$D/sha256_core.v" "$D/sha256_axil.v" 2>&1 | tee "$OUT"

if grep -q "%Error" "$OUT"; then
  echo "[FAIL] verilator 报出错误"
  exit 1
fi

W=$(grep -c "%Warning" "$OUT" || true)
[ -z "$W" ] && W=0
echo "[2/2] SUMMARY: warnings=$W errors=0"
if [ "$W" -gt 0 ]; then
  echo "[FAIL] v7 承诺零告警，实际有 $W 条"
  exit 1
fi
echo "  干净：v7 原生零告警（无豁免）"
