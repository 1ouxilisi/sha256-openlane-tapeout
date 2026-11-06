#!/usr/bin/env bash
# ============================================================
# v7（AXI4-Lite 顶层 + 移位寄存器压缩核）功能回归
# 跑 tb_v7_axil：single_block(abc) + two_block(a×119 两块流式)
#
# 用法：bash scripts/verify_v7.sh
# 依赖：iverilog（apt: sudo apt-get install -y iverilog）
# 判据：末行出现 ALL TESTS PASSED；出现 FAIL / TIMEOUT 即失败
# ============================================================
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
D="$ROOT/designs/sha256_v7"
OUT="$(mktemp -d)"
LOG="$OUT/v7_sim.log"

if ! command -v iverilog >/dev/null 2>&1; then
  echo "[SKIP] 找不到 iverilog，跳过 v7 回归。"
  exit 0
fi

iverilog -g2005 -o "$OUT/v7sim" \
  "$D/tb/tb_v7_axil.v" "$D/src/sha256_axil.v" "$D/src/sha256_core.v" > "$LOG" 2>&1
if [ $? -ne 0 ]; then
  echo "[FAIL] 编译失败："
  cat "$LOG"
  exit 1
fi

vvp "$OUT/v7sim" >> "$LOG" 2>&1

grep -E "^(PASS|FAIL|SUMMARY)" "$LOG" || true

if grep -q "ALL TESTS PASSED" "$LOG" && ! grep -qE "FAIL |TIMEOUT" "$LOG"; then
  echo "[OK] v7 AXI4-Lite 回归通过（含两块流式）"
  exit 0
fi

echo "[FAIL] v7 回归未通过，完整日志："
cat "$LOG"
exit 1
