#!/usr/bin/env bash
#
# =============================================================================
#  OpenLane + SkyWater 130nm PDK 一键部署脚本
#  ---------------------------------------------------------------------------
#  目标环境 : Ubuntu 22.04+ / Debian 12+ 等任意现代 Linux
#  前置条件 : 磁盘 ≥ 30G、能访问 github.com 与 hub.docker.com、root 或 sudo
#  部署方式 : 优先 Docker（最省事）；若机器无特权/禁 Docker，改用 Nix 路线
#  用法     : sudo bash deploy_openlane.sh
#  说明     : 本脚本只做"环境安装"，不跑设计；跑设计见 run_sha256_flow.sh
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------- 常量
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PDK_DIR="$PROJECT_DIR/pdk"            # Sky130 PDK 落盘目录（Docker 挂载点）
DESIGNS_DIR="$PROJECT_DIR/designs"    # 设计根目录（Docker 挂载点）
PDK_NAME="sky130"

MIN_DISK_GB=30     # 建议最小磁盘（含工具链 + PDK + 中间产物）
MIN_AVAIL_GB=10    # 硬性最低可用磁盘

# ---------------------------------------------------------------- 打印函数
red()   { printf '\033[1;31m%s\033[0m\n' "$*"; }
green() { printf '\033[1;32m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[1;33m%s\033[0m\n' "$*"; }
die()   { red "[出错] $*"; exit 1; }
step()  { echo; green "==> $*"; }

# ---------------------------------------------------------------- 前置检查
step "检查运行用户"
if [[ "$(id -u)" -ne 0 ]]; then
    yellow "建议以 root 运行（很多步骤需要 sudo）。若当前非 root，以下命令会自动用 sudo。"
fi
have_sudo=false
if sudo -n true 2>/dev/null; then have_sudo=true; fi
if [[ "$(id -u)" -ne 0 && "$have_sudo" != "true" ]]; then
    die "需要 root 或可用的 sudo 权限。请以 root 或具有 sudo 权限的用户重新运行。"
fi
SUDO=""
if [[ "$(id -u)" -ne 0 ]]; then SUDO="sudo"; fi

step "检查磁盘空间（要求可用 ≥ ${MIN_AVAIL_GB}G，建议 ≥ ${MIN_DISK_GB}G）"
AVAIL_GB=$(df -P / | awk 'NR==2 {gsub(/[^0-9]/,"",$4); print $4/1024/1024}')
TOTAL_GB=$(df -P / | awk 'NR==2 {gsub(/[^0-9]/,"",$2); print $2/1024/1024}')
printf '  总容量 %sG / 可用 %sG\n' "$TOTAL_GB" "$AVAIL_GB"
if (( $(echo "$AVAIL_GB < $MIN_AVAIL_GB" | bc -l) )); then
    red "可用磁盘 ${AVAIL_GB}G < ${MIN_AVAIL_GB}G，无法部署 OpenLane（完整流程需 20-30G）。"
    red "请扩容磁盘，或换一台更大磁盘的 Linux 机器后重试。"
    exit 1
fi

step "检查网络连通性"
net_ok=false
for url in https://github.com https://hub.docker.com; do
    if curl -sI --max-time 10 -o /dev/null -w '%{http_code}' "$url" | grep -qE '2|3'; then
        net_ok=true; green "  可达: $url"
    else
        yellow "  不可达: $url"
    fi
done
if [[ "$net_ok" != "true" ]]; then
    die "无法访问 github.com / hub.docker.com，OpenLane 部署需要这两个源。请检查网络后重试。"
fi

step "检查基础工具 (curl / git / jq)"
$SUDO apt-get update -qq 2>/dev/null || true
$SUDO apt-get install -y -qq curl git jq ca-certificates >/dev/null 2>&1 || \
    die "安装基础工具失败，请检查 apt 源"

# ---------------------------------------------------------------- 选择部署路线
echo
yellow "======== 部署路线选择 ========"
yellow " [1] Docker 路线（推荐：最省事，官方镜像开箱即用）"
yellow " [2] Nix 路线（机器无特权/禁 Docker 时使用）"
printf   " 默认回车 = Docker。请输入 [1/2]："
read -r CHOICE || true
CHOICE="${CHOICE:-1}"

if [[ "$CHOICE" == "2" ]]; then
    echo; step "Nix 路线（官方推荐非 Docker 部署）"
    $SUDO apt-get install -y -qq curl >/dev/null 2>&1
    # Determinate Nix + OpenLane Cachix 缓存
    if [[ ! -x /nix/var/nix/profiles/default/bin/nix ]]; then
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
            | $SUDO sh -s -- install --no-confirm \
            --extra-conf "extra-substituters = https://openlane.cachix.org" \
            --extra-conf "extra-trusted-public-keys = openlane.cachix.org-1:qqdwh+QMNGmZAuyeQJTH9ErW57OWSvdtuwfBKdS254E="
    fi
    # 无 systemd 的容器环境需手动启动 daemon
    if ! nix-store -q 2>/dev/null; then
        $SUDO nohup /nix/var/nix/profiles/default/bin/nix-daemon >/tmp/nixd.log 2>&1 &
        sleep 5
    fi
    green "Nix 已就绪。进入 openlane2 目录后用 'nix develop' 获取工具链，"
    green "然后参照 run_sha256_flow.sh 的 Nix 段跑设计。"
    exit 0
fi

# ---------------------------------------------------------------- Docker 路线
step "检查/安装 Docker"
if ! command -v docker >/dev/null 2>&1; then
    yellow "未检测到 Docker，正在通过官方脚本安装..."
    curl -fsSL https://get.docker.com | $SUDO sh 2>&1 | tail -5 || \
        die "Docker 安装失败"
fi
DOCKER="$SUDO docker"

step "启动 Docker（自动适配 systemd / 无 systemd）"
if systemctl is-system-running >/dev/null 2>&1; then
    $SUDO systemctl enable --now docker 2>/dev/null || true
    $SUDO systemctl start docker 2>/dev/null || true
fi
# 若 service 方式没起来，尝试直接起 daemon
if ! $DOCKER info >/dev/null 2>&1; then
    yellow "Docker 服务未通过 systemd 启动，尝试手动启动 dockerd..."
    $SUDO nohup dockerd >/tmp/dockerd.log 2>&1 &
    for i in $(seq 1 15); do
        sleep 2
        $DOCKER info >/dev/null 2>&1 && break
    done
fi
$DOCKER info >/dev/null 2>&1 || die "Docker 启动失败，请查看 /tmp/dockerd.log。若为沙箱/无特权环境，请改用 Nix 路线 (deploy 时选 2)。"
green "Docker 运行中"

step "拉取 OpenLane 官方镜像 efabless/openlane:latest（约 2-3G，网络快则几分钟）"
$DOCKER pull efabless/openlane:latest || die "拉取 OpenLane 镜像失败，请检查网络/磁盘"

step "准备 PDK 落盘目录"
mkdir -p "$PDK_DIR"
chmod -R 777 "$PDK_DIR" 2>/dev/null || true

step "下载 SkyWater 130nm PDK（经 OpenLane 镜像的 volare，约 1-2G）"
$DOCKER run --rm \
    -v "$PDK_DIR:/home/openlane/.volare" \
    efabless/openlane:latest \
    openlane --install-pdk "$PDK_NAME" || \
    die "PDK 下载失败。可重跑本脚本，或手动执行上述 docker run 命令。"

step "验证 PDK 是否就绪"
if ls "$PDK_DIR/sky130A" >/dev/null 2>&1; then
    green "PDK sky130A 已就绪: $PDK_DIR/sky130A"
else
    yellow "警告: 未在 $PDK_DIR 找到 sky130A，PDK 可能未完整落盘。请检查上方输出。"
fi

echo
green "==================== 部署完成 ===================="
green " OpenLane 镜像 : efabless/openlane:latest"
green " Sky130 PDK    : $PDK_DIR"
green " 下一步        : sudo bash run_sha256_flow.sh  （跑 SHA-256 设计出 GDS）"
green "==================================================="
