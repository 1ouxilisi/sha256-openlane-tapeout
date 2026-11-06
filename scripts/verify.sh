#!/usr/bin/env bash
# ============================================================
# 一键功能回归：编译 RTL + testbench -> 跑三条锚点向量 -> 断言通过
#
# 用法：bash scripts/verify.sh
# 依赖：Icarus Verilog（Ubuntu/Debian: sudo apt-get install -y iverilog；
#       macOS: brew install icarus-verilog）
#
# 说明：本脚本只验证功能正确性（逻辑层），不涉及综合/STA/DRC。
#       签核数据见 docs/signoff_summary_all.txt 与 reports/ 下的原始报告。
# ============================================================
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/designs/sha256/src"
TB="$SRC/sha256_top_tb.v"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
BUILD="$ROOT/build"
OUT="$BUILD/simv"
LOG="$BUILD/sim.log"

if ! command -v "$IVERILOG" >/dev/null 2>&1; then
  echo "[FAIL] 找不到 iverilog。安装方式：sudo apt-get install -y iverilog（或 brew install icarus-verilog）"
  exit 127
fi

mkdir -p "$BUILD"

echo "[1/3] 编译 RTL + testbench"
"$IVERILOG" -g2005 -o "$OUT" \
  "$SRC/sha256_pipe.v" \
  "$SRC/sha256_top.v" \
  "$TB"
if [ $? -ne 0 ]; then
  echo "[FAIL] 编译失败"
  exit 1
fi

echo "[2/3] 运行仿真"
"$VVP" "$OUT" | tee "$LOG"

echo "[3/3] 判定"
if grep -q "ALL TESTS PASSED" "$LOG" \
   && ! grep -q "SOME TESTS FAILED" "$LOG" \
   && ! grep -q "^FAIL" "$LOG" \
   && ! grep -q "TIMEOUT" "$LOG"; then
  echo "[OK] 三条锚点向量全部通过：abc / empty / fox"
  exit 0
else
  echo "[FAIL] 向量未通过，见 $LOG"
  exit 1
fi
