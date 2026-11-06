#!/usr/bin/env bash
# ============================================================
# 综合层对照（可选）：不依赖 OpenLane，用裸 yosys + sky130 标准单元库
# 把同一份 RTL 映射到 sky130_fd_sc_hd，输出 cell 数与面积，
# 用来证明这条设计可以独立综合到真实工艺库，而不是只能在 OpenLane 里跑。
#
# 用法：
#   bash scripts/synth_check.sh [SRC_DIR]
# 依赖：
#   yosys（apt: sudo apt-get install -y yosys；或 OpenLane rootfs 内的 yosys）
#   sky130 liberty：默认从 $PDK_ROOT 里找，也可用 SKY130_LIB 直接指定
#
# 说明（诚实边界）：
#   这是最小流程对照，不等于 OpenLane 的综合链。
#   OpenLane 的综合脚本会额外插入 tie/buffer：v6 综合结果 12,288 cells 中
#   有 2,532 个 buf_1，净逻辑约 9,756。裸 yosys 不做这一步，
#   因此得到的 9,248 cells 与净逻辑口径只差约 5%，数量级一致即说明可综合。
#   本脚本只做可综合性与数量级检查，不作通过/失败判据。
# ============================================================
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SRC="${1:-$ROOT/designs/sha256/src}"
TOP="${TOP:-sha256_top}"
LOG="${LOG:-$ROOT/build/synth.log}"

if [ -z "${SKY130_LIB:-}" ]; then
  for cand in \
    "${PDK_ROOT:-}/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib" \
    "$ROOT/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"; do
    if [ -f "$cand" ]; then SKY130_LIB="$cand"; break; fi
  done
fi

if [ -z "${SKY130_LIB:-}" ] || [ ! -f "$SKY130_LIB" ]; then
  echo "[SKIP] 找不到 sky130 liberty。把 SKY130_LIB 指向 sky130_fd_sc_hd__tt_025C_1v80.lib 后重跑。"
  exit 0
fi

if ! command -v yosys >/dev/null 2>&1; then
  echo "[SKIP] 找不到 yosys。apt-get install -y yosys 后重跑。"
  exit 0
fi

mkdir -p "$(dirname "$LOG")"

echo "[1/2] yosys 综合 $TOP（liberty: $(basename "$SKY130_LIB")）"
yosys -p "read_verilog $SRC/sha256_pipe.v $SRC/sha256_top.v; \
synth -top $TOP; \
abc -liberty $SKY130_LIB; \
opt_clean; \
stat" > "$LOG" 2>&1

if ! grep -q "Number of cells" "$LOG"; then
  echo "[FAIL] yosys 没有产出 stat，见 $LOG"
  exit 1
fi

grep -E "Number of cells" "$LOG" | tail -3
grep -E "Chip area for module" "$LOG" | tail -1

echo "[2/2] 对照 OpenLane 记录（见 README 成果速览）"
echo "  OpenLane v6 综合：12,288 cells（其中 buf_1 2,532 个，净逻辑约 9,756）"
echo "  裸 yosys 最小流程只做逻辑映射、不插 buf，故数目略低；数量级一致即说明 RTL 可独立综合到 sky130。"
echo "  完整日志：$LOG"
