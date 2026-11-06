#!/usr/bin/env bash
#
# =============================================================================
#  跑 SHA-256 硬件加速器设计 → 真实 GDS 版图
#  ---------------------------------------------------------------------------
#  前置   : 已运行过 deploy_openlane.sh（Docker 路线），PDK 已就绪
#  用法   : sudo bash run_sha256_flow.sh
#  产物   : designs/sha256/runs/<时间戳>/results/final/gds/*.gds
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------- 常量
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESIGNS_DIR="$PROJECT_DIR/designs"
PDK_DIR="$PROJECT_DIR/pdk"
DESIGN="sha256"              # 设计目录名（config.tcl 里 DESIGN_NAME=sha256_top）
IMG="efabless/openlane:latest"
MIN_AVAIL_GB=5               # 跑设计最低可用磁盘

# ---------------------------------------------------------------- 工具
red()   { printf '\033[1;31m%s\033[0m\n' "$*"; }
green() { printf '\033[1;32m%s\033[0m\n' "$*"; }
die()   { red "[出错] $*"; exit 1; }
step()  { echo; green "==> $*"; }

SUDO=""
if [[ "$(id -u)" -ne 0 ]]; then SUDO="sudo"; fi
DOCKER="$SUDO docker"

# ---------------------------------------------------------------- 前置检查
step "检查设计目录"
[[ -f "$DESIGNS_DIR/$DESIGN/config.tcl" ]] || \
    die "找不到 $DESIGNS_DIR/$DESIGN/config.tcl，请确认设计文件已就位。"
green "  找到 config.tcl"

step "检查 Docker 与镜像"
$DOCKER info >/dev/null 2>&1 || die "Docker 未运行。请先 bash deploy_openlane.sh 完成部署。"
$DOCKER image inspect "$IMG" >/dev/null 2>&1 || \
    die "OpenLane 镜像 $IMG 未拉取。请先 bash deploy_openlane.sh。"

step "检查 Sky130 PDK"
[[ -d "$PDK_DIR/sky130A" ]] || die "PDK 未就绪 ($PDK_DIR/sky130A)。请先 bash deploy_openlane.sh。"

step "检查磁盘（跑流程需要临时空间）"
AVAIL_GB=$(df -P / | awk 'NR==2 {gsub(/[^0-9]/,"",$4); print $4/1024/1024}')
printf '  可用 %sG\n' "$AVAIL_GB"
if (( $(echo "$AVAIL_GB < $MIN_AVAIL_GB" | bc -l) )); then
    die "可用磁盘 ${AVAIL_GB}G < ${MIN_AVAIL_GB}G，空间不足。请扩容后再跑。"
fi

# ---------------------------------------------------------------- 跑流程
step "启动 OpenLane 全流程 (RTL 综合 → 布局 → 布线 → 生成 GDS)"
echo "  设计   : $DESIGN"
echo "  时间戳 : $(date +%Y%m%d_%H%M%S)"
echo "  首次运行会自动用 volare 安装/加载 PDK，综合+布局布线约 10-60 分钟。"
echo

$DOCKER run --rm \
    -e PDK_ROOT=/home/openlane/.volare \
    -v "$DESIGNS_DIR:/home/openlane/designs" \
    -v "$PDK_DIR:/home/openlane/.volare" \
    -v "$PROJECT_DIR/logs:/home/openlane/logs" \
    "$IMG" \
    openlane --run-design "$DESIGN" || {
        red "流程运行失败。常见原因："
        red "  1. PDK 与工具版本不匹配 → 查看上方 OpenLane 报错"
        red "  2. 时序收敛问题 (配置已放宽 clk=10ns / AREA=0)"
        red "  3. 磁盘空间不足"
        exit 1
    }

# ---------------------------------------------------------------- 定位 GDS 产物
step "定位生成的 GDS 版图"
GDS="$(find "$DESIGNS_DIR/$DESIGN/runs" -path '*results/final/gds/*.gds' 2>/dev/null | sort | tail -1)"
if [[ -n "$GDS" ]]; then
    echo
    green "============================ 流片成功 ============================"
    green "  GDS 版图: $GDS"
    green "  可用 KLayout/Magic 查看该文件，即真实芯片版图。"
    green "================================================================"
    du -h "$GDS"
else
    yellow "未找到 GDS 文件。请查看 $DESIGNS_DIR/$DESIGN/runs 下的日志定位问题。"
    exit 1
fi
