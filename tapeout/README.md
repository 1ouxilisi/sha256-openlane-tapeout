# SHA-256 芯片 · 一键流片包（RTL → GDS）

> ⚠️ 本文件为流片前的准备记录。四代实际流片结果（含 run tag、实测指标与踩坑要点）见仓库根目录 `README.md`。

把你本地已完成并验证的 **SHA-256 硬件加速器** 设计，搬到任意一台满足条件的 Linux 机器上，用开源 OpenLane + SkyWater 130nm PDK 跑通完整流片流程，产出**真实 GDS 版图**。

---

## 一、这个包里有什么

| 文件 | 作用 |
|------|------|
| `deploy_openlane.sh` | 一键安装 Docker/OpenLane 镜像 + 下载 Sky130 PDK |
| `run_sha256_flow.sh`  | 跑 SHA-256 设计，产出 GDS 版图 |
| 上级 `designs/sha256/` | 设计文件（RTL、顶层、config.tcl，均已验证） |
| 上级 `pdk/`           | Sky130 PDK 落盘目录（脚本自动创建） |

设计侧已在本机用 iverilog 真仿真验证通过：
- 逻辑核对 11/11 PASS、核心仿真 12/12 PASS、顶层握手 2/2 PASS
- 设计摘要：`abc` → `ba7816bf...015ad`，`empty` → `e3b0c442...52b855`，`fox` → `d7a8fbb3...37c9e592`

---

## 二、目标机器的前置条件

- **系统**：Ubuntu 22.04+ / Debian 12+ 等现代 Linux
- **磁盘**：≥ 30G（完整流程 + 中间产物需要 20-30G）
- **网络**：能访问 `github.com` 与 `hub.docker.com`（部署/拉镜像必需）
- **权限**：root 或可用的 sudo
- **CPU/内存**：4 核 2GHz+、8G 内存以上（推荐）

> 重要：**磁盘小是致命瓶颈**。OpenLane 完整环境装不下 20G 以下的机器（一台 9.8G 的机器实测三条路线全部因磁盘失败）。

---

## 三、快速开始（两步）

```bash
# 第 1 步：部署环境（安装 Docker/OpenLane 镜像 + 下载 Sky130 PDK）
#         → 首次约 10-30 分钟（取决于网络）
sudo bash deploy_openlane.sh

# 第 2 步：跑 SHA-256 设计 → 出 GDS
#         → 综合 + 布局布线约 10-60 分钟
sudo bash run_sha256_flow.sh
```

跑完后 GDS 版图在：

```
designs/sha256/runs/<时间戳>/results/final/gds/*.gds
```

用 **KLayout** 或 **Magic** 打开该 `.gds` 文件，即可看到真实的芯片版图。

---

## 四、两种部署路线详解

### 路线 1：Docker（推荐，最省事）
`deploy_openlane.sh` 默认走这条：
1. 自动安装 Docker（若没有）
2. 拉取官方镜像 `efabless/openlane:latest`
3. 用镜像内的 `openlane --install-pdk sky130` 下载 Sky130 PDK 到 `pdk/`

要求机器**有完整特权**（能正常跑 Docker）。云沙箱等无特权环境会失败。

### 路线 2：Nix（无特权/禁 Docker 时用）
在 `deploy_openlane.sh` 提示时输入 `2`：
1. 安装 Determinate Nix + OpenLane Cachix 缓存
2. 进入 `openlane2/` 目录用 `nix develop` 获取工具链

Nix 方式同样吃磁盘（建议 ≥ 30G），且部分工具需源码编译较慢。

---

## 五、设计文件清单（`designs/sha256/`）

| 文件 | 说明 |
|------|------|
| `src/sha256.v`        | SHA-256 压缩核 RTL（四态 FSM，大端字序，12/12 仿真 PASS） |
| `src/sha256_top.v`    | OpenLane 综合顶层（start/busy/done/digest 握手接口） |
| `src/sha256_tb.v`     | 核心 testbench（12 组 hashlib 核对向量） |
| `src/sha256_top_tb.v` | 顶层握手 testbench（empty/abc，2/2 PASS） |
| `config.tcl`          | OpenLane 配置（sky130A + sky130_fd_sc_hd，clk=10ns，AREA=0，FP_CORE_UTIL=45） |
| `README.md` / `VERIFICATION.md` | 设计文档与验证报告 |

---

## 六、常见问题

| 现象 | 原因 / 处理 |
|------|------------|
| 部署提示"可用磁盘 < 10G" | 磁盘不够，扩容或换大磁盘机器（硬瓶颈，无捷径） |
| Docker 启动失败 | 无特权/沙箱环境 → 改用 Nix 路线（deploy 时选 2） |
| 拉镜像很慢 | 网络问题；确认能访问 hub.docker.com |
| 流程运行失败"时序不收敛" | 配置已放宽（clk=10ns、AREA=0），仍失败可把 clk 调到 15-20ns |
| PDK 下载失败 | 重跑 deploy；确认网络能访问 PDK 源（GitHub） |

---

## 七、参考

- OpenLane 官方文档：https://openlane.readthedocs.io
- OpenLane 仓库：https://github.com/efabless/openlane2
- SkyWater PDK：https://github.com/google/skywater-pdk
