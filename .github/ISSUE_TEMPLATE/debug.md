---
name: Debug request
about: 卡在 OpenLane / OpenROAD / netgen / Magic 的某一步，贴出可复现的信息
title: "[debug] "
labels: ""
assignees: ""
---

<!--
免费问题请按下面五项填，缺项我大概率回不了。
需要我直接上手排查（远程、按次）的，把标题改成 [paid]，并在第 6 项写明期望时间与预算区间。
-->

## 1. 卡在哪一步

<!-- 例如：detailed_route、repair_antennas、Magic spice export、netgen lvs、RCX、STA -->

## 2. 你跑的命令

```bash
# 原样贴，不要改写成描述
```

## 3. 报错原文

```text
# 贴文本，不要截图。至少保留第一条错误和最后一条错误
```

## 4. 工具与版本

- OpenLane / OpenROAD：
- PDK（sky130A 版本）：
- 其他（netgen / Magic / KLayout / yosys）：

## 5. 你已经试过什么

<!-- 试过的修法和结果，包括"改了没用"的。这一段能省掉一半来回 -->

## 6. 附带的产物

- [ ] 报错日志（完整文件）
- [ ] 相关 DEF / ODB / GDS（能脱敏就脱敏，不能就说明大小与单元数）
- [ ] 设计 config.tcl
- [ ] 跑出问题的 SDC

---

正在处理的常见症状，可以先对照仓库 README 的「排障索引」九条，大部分能自己排掉。
