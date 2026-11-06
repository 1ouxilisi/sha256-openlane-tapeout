# ============================================================
# config.tcl - OpenLane 设计配置 (sha256_top) v2
# 目标: OpenLane 1.1.1 + SkyWater 130nm (sky130A) RTL -> GDS 全流程
# 变更 (相对 v1): RTL 换代 -> 流水线核心 sha256_pipe + 32-bit 串行接口顶层
#   - IO 从 773 -> ~71, DIE_AREA 800x800 -> 550x550, 利用率 ~19% -> ~40%+
#   - 流水线后目标时钟 100MHz (CLOCK_PERIOD 10)
# ============================================================

# ---------- 设计名称 (综合顶层 = sha256_top) ----------
set ::env(DESIGN_NAME) "sha256_top"

# ---------- RTL 源文件 (依赖顺序: 先流水线核心, 后串行顶层) ----------
set ::env(VERILOG_FILES) [list \
    $::env(DESIGN_DIR)/src/sha256_pipe.v \
    $::env(DESIGN_DIR)/src/sha256_top.v]

# ---------- PDK 与标准单元库 ----------
set ::env(PDK) "sky130A"
set ::env(STANDARD_CELL_LIBRARY) "sky130_fd_sc_hd"

# ---------- 时钟 (流水线后目标 100 MHz) ----------
set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_NET) "clk"
set ::env(CLOCK_PERIOD) "10.0"

# ---------- 综合策略 (压缩核逻辑, 面积优先更利于时序收敛) ----------
set ::env(SYNTH_STRATEGY) "AREA 0"

# ---------- Floorplan: 串行接口后 IO 大幅减少, die 缩小 + 利用率提高 ----------
set ::env(FP_CORE_UTIL) "50"
set ::env(FP_ASPECT_RATIO) "1"
set ::env(FP_SIZING) "absolute"
set ::env(DIE_AREA) "0 0 550 550"
set ::env(GRT_REPAIR_ANTENNAS) "0"
