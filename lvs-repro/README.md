# lvs-repro —— 一条命令从 GDS 复现 LVS 结论

```
bash repro3.sh <GDS> <TAG> <PORTS> <基准网表>
```

| 参数 | 默认 | 说明 |
|---|---|---|
| `GDS` | `/tmp/eco/eco_it2f.gds` | 待抽取的版图 |
| `TAG` | `f3` | 本次运行标号，产物落在 `run_<TAG>/` |
| `PORTS` | `94` | 期望的顶层端口数，对不上就在 C 段停 |
| `基准网表` | `/tmp/lvs_it2c/net.spice` | netgen 的参考网表 |

退出码：`0` PASS｜`2` 结果不一致（NOT-PASS）｜`3` 提取链自己在某一段就失败（`summary.txt` 写 `FAIL@PHASEx`）。

## 四条实跑记录

| 命令 | 结论 |
|---|---|
| `bash repro3.sh /tmp/eco/eco_it2f.gds f4 94 /tmp/lvs_it2c/net.spice` | 88 秒 → `Final result: Circuits match uniquely.`，网表 1,686,735 B / md5 `09183c364b9f5e749c05cfb23a8e3333` |
| `bash repro3.sh /tmp/eco/eco_it2g.gds g5 93 /tmp/lvs_it2c/net.spice` | 87 秒 → `Top level cell failed pin matching.`（15,981 vs 15,983 器件、15,799 vs 15,828 网） |
| `bash repro3.sh /tmp/eco/eco_it2g.gds g4 97 …` | `FAIL@C`：`port count 93 != expected 97` |
| `bash repro3.sh … f3 …`（第一版） | `FAIL@D`：netgen 拿到了宿主路径，`Error in SPICE file read` |

证据正文见 [`../docs/evidence/onecmd_repro.txt`](../docs/evidence/onecmd_repro.txt)。

## 文件

| 文件 | 作用 |
|---|---|
| `repro3.sh` | 宿主侧驱动，四段 + 阶段 0，写 `summary.txt` |
| `ext.tcl` | A 段 magic 脚本（`gds read` → 抽取顶层） |
| `sp.tcl` | B 段 magic 脚本（新会话 `ext2spice -o`，不带 ext 名） |
| `build_cache.tcl` | 阶段 0：从 PDK 逐单元重抽标准单元 `.ext` |
| `cache.sh` | 阶段 0 的 chroot 侧入口，成功后打 `CACHE_DONE` |
| `masters.txt` | 148 个被抽过的标准单元名 |

## 三条不要改的地方

1. **标准单元的 `.ext` 必须 `cp` 进工作目录。** 只放在别的目录用 `addpath` 指过去，magic 抽顶层时会静默停住（不报错、不写文件、不退出），因为它在逐个单元现场重抽 —— 148 个单元 × 每个几秒到几十秒。三组对照见证据第三节。
2. **`ext2spice` 必须另起会话，且不带 ext 名。** 写成 `ext2spice -o <输出> <ext 名>` 时，若 `<ext 名>` 不存在，magic 不报错、不落盘，直接回落读当前目录里旧的 `<top>.ext`。
3. **netgen 的输入路径写 chroot 视角**（`/tmp/repro/run_<TAG>/…`）。写宿主路径（`/home/user/openlane-rootfs/tmp/…`）在 chroot 里不存在，会假失败。

## 装到别的机器

路径写死在 `repro3.sh` 头部（`ROOT`、`BASHX`、`MAGIC`、`NETGEN`、`SETUP`、`HOSTPY`、`PREP`），换机器改这几行即可。把这 6 个文件放进 chroot 内的 `/tmp/repro/`，`repro3.sh` 留在宿主侧执行。

阶段 0 不需要外部拷进来的二进制：缓存由 `build_cache.tcl` 从 `/pdk/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds` 自己重抽（148 个 `.ext`、572,151 B）。缓存不足 100 个时驱动会自动重建。
