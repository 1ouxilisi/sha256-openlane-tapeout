# 怎么验收一个"你看不懂但要用"的交付物

这份文件不是写给芯片工程师的，是写给**要点收、但没打算成为工程师**的人。

它的前提是一句不太客气的话：**你不需要懂这个领域，但你必须能判断对方给你的数字是真是假。** 两者不是一回事。前者要十年，后者要一条命令。

每一条结论，都应该配一条**能在两分钟内跑出相反结果**的命令。跑不出来，那条结论就只是话。

---

## 一、六条已经被真实踩过的坑

下面六条全部来自这个项目，不是假设。写法统一：**当时的结论 → 它是怎么假的 → 两分钟内怎么证伪 → 现在怎么处理**。

### 1. "功耗 6.84 mW，取的是 Fastest 工艺角（三组里最保守的那个）"

- **假在哪**：数字没错，**角名标错了**。它其实是 Typical 角。写"最保守"，让读者以为这是最坏情况，实际上比最坏情况乐观 14%。
- **证伪**：去原始报告里按块标题数，别按记忆数。
  ```bash
  grep -n "report_power" runs/tapeout14/logs/signoff/33-rcx_mcsta.nom.log
  # 定位到块首行后，看三块的标题顺序与各自 Total 行
  sed -n '492919,493120p' runs/tapeout14/logs/signoff/33-rcx_mcsta.nom.log | grep -E "Group|Total"
  ```
  三块顺序是 **Fastest → Slowest → Typical**，主表那个数在第三块里。
- **交叉验证**：`metrics.csv` 里 `power_typical_internal + switching + leakage` 相加正好等于主表那个数。
- **现在的处理**：四份对外文档 + Release 正文全部改角名，并把另两角数值一并列出。**允许读者自己挑更保守的口径。**

### 2. "优化后 WNS +2.12 ns，时序已收敛"

- **假在哪**：`+2.12` 是 resizer 在优化过程中**估算**的，不是签核结果。真实签核要看多角 STA 的原始报告。
- **证伪**：
  ```bash
  grep -rn "worst slack corner" runs/*/logs/signoff/*-rcx_mcsta.*.log | head
  ```
  这是 signoff 阶段跑出来的真实余量，与 resizer 的估算经常不是一个数。
- **现在的处理**：主表只引 signoff 三 corner（min / nom / max 各一行），resizer 数字不进结论。

### 3. "这条 RTL 在 sky130A 上的上限约 43.9 MHz"

- **假在哪**：这是拿"上一版 RTL 的余量反推"出来的，不是工艺极限，是**那一版架构**的极限。
- **证伪**：换架构重跑一次，看余量还在不在。
  ```bash
  # v7 换 W 为移位寄存器后，同样 24ns 约束下最紧 setup 从 +1.25 → +6.44 ns
  grep -A2 "worst slack corner" runs/tapeout15/logs/signoff/29-rcx_mcsta.min.log
  ```
  余量放大后把约束压到 18 ns 仍三角全正 → 55.56 MHz。
- **现在的处理**：文档里改写成"这是旧 RTL 的架构上限"，并在第 7 章写明**为什么这个数字曾经看起来像工艺极限**。
- **教训**：**任何"上限/极限"结论，都要问一句"是哪个东西的极限"**——是工艺、是架构、还是我的工具链。

### 4. "独立综合得 9,248 cells，OpenLane 报 12,288，差 5%，能互相印证"

- **假在哪**：两条流程的统计口径不同（一条没做 DFF 库映射）。换到 v7 复跑，结论**符号相反**：独立综合 14,375 > OpenLane 11,475。
- **证伪**：同一份 RTL 用两条流程各跑一次，比较**同一层级**的统计。
  ```bash
  grep "Number of cells" /tmp/synth_v7.log   # 裸 yosys：14,375
  grep "Number of cells" runs/tapeout16/logs/synthesis/1-synthesis.log | tail -1   # OpenLane：11,475
  ```
- **现在的处理**：不删这个结果，把它写成"一个必须留着的负面结果"专章，并明确写**这条对照只能证明 RTL 能综合进标准单元库，不能用来判断谁更小**。
- **教训**：**两个数字接近，不等于两个数字在说同一件事。** 先对齐口径，再比大小。

### 5. "flow_status: failed → 这颗芯片没做出来"

- **假在哪**：失败的只有**第 37 步**（chroot 里调 KLayout 崩溃，工具 bug）。第 36 步已经正常产出 GDS，全部签核指标有效。
- **证伪**：
  ```bash
  ls -l runs/tapeout16/results/signoff/*.gds     # 文件在不在、多大
  grep -c "^.*ERROR" runs/tapeout16/logs/klayout/37-klayout.log 2>/dev/null || true
  ```
  文件在、字节数正常、STA/DRC 全绿 → 结论有效；只有"最后那步出图"失效。
- **现在的处理**：全项目文档都写"flow failed 的唯一原因是 STEP 37"，并给出替代做法（在宿主机渲染、Magic/KLayout 双份 XOR）。
- **教训**：**看"哪一步失败"，不要只看"有没有失败"。**

### 6. "两条命令就能复现"

- **假在哪**：在别人机器上跑不起来——缺 locale 设置、缺 PATH、iverilog 版本低、工具在 chroot 里。
- **证伪**：找一台干净机器，或干净容器，按文档从零跑一遍。
  ```bash
  docker run --rm -v $PWD:/w -w /w ubuntu:24.04 bash -c "apt-get update -qq && apt-get install -y -qq iverilog python3 gcc >/dev/null && bash scripts/verify_driver.sh"
  ```
- **现在的处理**：`scripts/verify_driver.sh` 支持 `WRAP` 环境变量把命令包进 chroot/容器；CI 用 ubuntu-24.04（verilator 5.x）。
- **教训**：**"能复现"是相对某台机器成立的，写文档时必须说是哪台。**

---

## 二、六条通用验收动作（换任何领域都能用）

这六条不依赖任何专业知识。你审的不是技术，是**证据结构**。

| # | 问题 | 一句话判据 | 不合格的表现 |
|---|---|---|---|
| 1 | 这个数字有几个独立来源？ | ≥2 个互不依赖的来源 | 只有一个来源，且来源方就是被评估方自己 |
| 2 | 换条路径算同一件事，结果会变吗？ | 换个工具/换个顺序，结论不变 | "只有这条流程能得出这个结论" |
| 3 | 单位、工艺角、口径写全了吗？ | 数字后面跟着条件 | 只给数字不给条件，或条件名与原始报告不符 |
| 4 | "失败"是不是别的东西失败了？ | 能定位到具体步骤 | 用整体状态（failed/pass）代替步骤级证据 |
| 5 | 同一命令重跑两次给同样结果吗？ | 结果稳定 | 时好时坏，且解释为"环境问题" |
| 6 | 谁能不看文档、只用一条命令把我推翻？ | 存在这样一条命令 | 只有作者自己知道怎么验 |

**第 6 条是核心。** 一份交付物的可信度，约等于"外人能多快推翻它"的倒数。推不翻，不是因为对，是因为没人能试。

---

## 三、本项目的验收清单（可逐项打勾）

```bash
# ① 逻辑对不对（不需要硬件知识）
bash scripts/verify.sh                 # 末行应为 ALL TESTS PASSED
python3 scripts/check_vectors.py       # hashlib 独立复算期望值

# ② 接口驱动对不对（本文件配套新增）
bash scripts/verify_driver.sh          # 末行应为 ALL DRIVER TESTS PASSED
#   云主机上 iverilog 在 chroot 里时：
#   WRAP='sudo chroot /home/user/openlane-rootfs' bash scripts/verify_driver.sh

# ③ 静态质量
bash scripts/lint_v7.sh                # 应输出 warnings=0 errors=0

# ④ 物理版图（需要 Magic / KLayout 之一）
python3 scripts/xor_check.py a.gds b.gds   # 应输出结构差异 0

# ⑤ 线上是否真的可达
curl -sI https://1ouxilisi.github.io/sha256-openlane-tapeout/ | head -1     # 200
curl -sI <Release 附件直链> | head -1                                        # 200
```

五条里任意一条跑不出预期结果，就**先不要引用任何指标**——包括漂亮的那几个。

---

## 四、你不需要懂什么（明确划界）

| 不需要懂 | 替代手段 |
|---|---|
| 时序收敛怎么算 | 读 signoff 三 corner 的 setup/hold 余量行，看是否全正 |
| 综合怎么映射标准单元 | 看两套流程的 cell 数是否**同口径**，不同口径就只当"能综合"的证据 |
| 版图 DRC 规则细节 | 看 DRC 报告计数是否为 0，以及两份 GDS 逐层 XOR 是否 0 差异 |
| AXI 协议时序 | 跑 `verify_driver.sh`，让 hashlib 判对错 |
| 功耗怎么建模 | 只认原始 `report_power` 块，按块标题读角名 |

**你需要懂的那一件事**：什么时候该说"这个我没法验，所以我不引用它"。
这句话说出来，比任何指标都值钱。

---

## 五、换到别的领域怎么改（这份文件的可迁移部分）

把上面第二节六条原样搬过去，只替换"证据载体"：

| 领域 | 你的"两条独立来源" | 你的"一条命令能推翻" |
|---|---|---|
| 硬件/芯片 | STA 报告 + 独立 XOR + CI 仿真 | `verify_driver.sh` |
| 机器人动作包 | MuJoCo 正解 + 真机日志 + 关键帧回看 | 重放脚本 + 关节误差表 |
| 短剧/视频 | 分镜表 + 成片抽帧 + 字幕对轴表 | 抽帧比对脚本 |
| 新能源汽修手册 | 厂家维修手册条款 + 实车测量值 | 故障码复现步骤 |
| 财务/经营分析 | 原始凭证 + 系统导出 + 第三方口径 | 重算一遍毛利 |

判据不变：**每个关键数字≥2 个互不依赖来源；每个结论配一条外人能跑的命令；跑不出来就标黄，不引用。**

这就是"能迁移"的全部内容——不是把知识搬过去，是把**验收结构**搬过去。
