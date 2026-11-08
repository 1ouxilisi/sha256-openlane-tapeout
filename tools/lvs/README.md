# LVS 复现脚本

把 flow 之外手工跑出来的那次 LVS（`ctsfix3` 这版 GDS，`Final result: Circuits match uniquely.`）
固化成一条命令。`REPRODUCE.md` 第三节原先写着「清洗脚本尚未入库」，现在这些脚本就在这里。

## 用法

```bash
bash tools/lvs/run_lvs.sh <run目录> [单元名]
# 例：
bash tools/lvs/run_lvs.sh /home/user/openlane-rootfs/designs/sha256_v7b/runs/ctsfix3 sha256_axil
```

`<run目录>` 里要有这两样（都是 flow 的产物，不需要另存）：

- `results/signoff/sha256_axil.gds`（40,396,222 B）
- `results/routing/sha256_axil.nl.v`（3,379,950 B）

可选环境变量：`PDK_ROOT`（默认 `/pdk2`）、`MAGIC_BIN`、`NETGEN_BIN`、`LVS_WORK`（默认临时目录，会打印出来）。

成功时最后一行是：

```
LVS PASS  workdir=...
```

## 四步在做什么

| 步骤 | 脚本 | 做的事 |
|---|---|---|
| 1 | `ext_mag.tcl` | Magic 从 GDS 读版图，`extract` + `ext2spice lvs`，出 `layout.ext.spice` |
| 2 | `prep_lay.py` | 拼回 `+` 续行（本次 1,839 行）、去掉 `\[` `\]` 转义、删 4 个重复端口 |
| 3 | `nl2spice.py` | `.nl.v` + PDK 单元库 → SPICE：补电源脚、按「实例/引脚」命名悬空脚、删 fill/tap |
| 4 | netgen | 两侧比对，判据只看最后一行 `Final result` |

四步对应的四条规则都是踩出来的真缺陷，不是风格选择，改写前先看 `REPRODUCE.md` 第三节的说明。

## 实跑数字（`EXPECTED.txt`）

两侧各 **34,182** 个顶层实例、**149** 种单元、**94** 个顶层端口；网表侧从 47,559 个实例里删掉
13,377 个 fill/tap，端口从 98 删到 94。netgen 输出 298,274 B，与归档的 `cts9_lvs6.out` 同字节数。

## 两条边界

1. **不保证与归档的 `lay_u2.spice` 逐字节相同。** 单元 `.subckt` 的端口顺序会随提取来源（`.mag` 还是 `gds read`）浮动；名字、数量、拓扑一致，`sha256` 不同，LVS 结论相同。用归档的 `cts9_mag.ext.spice` 做输入时，`prep_lay.py` 的输出与 `lay_u2.spice` 只差一行文件头。
2. **这不是签核。** 本目录只解决「版图与网表等价」这一项；KLayout DRC、天线、金属密度、GDS XOR、功耗仍是缺口，见 `REPRODUCE.md` 第四节。
