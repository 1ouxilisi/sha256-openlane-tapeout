#!/usr/bin/env bash
# ============================================================
# verify_driver.sh - 驱动级回归：C 驱动 -> 真 RTL -> hashlib 三方对照
#
# 这条命令回答的是"别人能不能接手"：一个不认识本项目的人，clone 仓库后
# 跑这一条命令，就能自己判断 AXI 接口驱动到底对不对，不需要相信任何文档。
#
# 三方互不依赖：
#   1) C 驱动（driver/sha256_axil.c）打出寄存器写序列 trace
#   2) Verilog 主机模型（driver/tb_v7_drv.v）把该序列原样发到真 RTL 的 AXI 总线
#   3) Python hashlib 独立算期望摘要
# 三者一致才算 PASS。
#
# 依赖：gcc、iverilog（>=11，需支持 -g2012）、python3
#
# 用法（本机已有 iverilog）：
#   bash scripts/verify_driver.sh
#
# 用法（iverilog 只在 chroot / 容器里，本项目云主机就是这样）：
#   WRAP='sudo chroot /home/user/openlane-rootfs' bash scripts/verify_driver.sh
# 脚本会自动把工作目录映射到 chroot 内的 /tmp/sha256_drv。
# ============================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
DRV="$ROOT/driver"

MSGS="abc empty fox a119"
WORK_IN="/tmp/sha256_drv"

# ---- 宿主机视角 vs 执行侧视角的路径映射 ----
if [ -n "${WRAP:-}" ]; then
    CHROOT_ROOT="${WRAP##* }"
    WORK_HOST="$CHROOT_ROOT$WORK_IN"
    DUT_IN="/designs/sha256_v7/src"
    TB_IN="$WORK_IN/tb_v7_drv.v"
    IV_PATH="/nix/store/vh3lcg8gq2c3pxbqkqmrk3fmf3papk52-iverilog-12.0/bin"
    shares_host_fs=1
else
    WORK_HOST="$WORK_IN"
    DUT_IN="$ROOT/designs/sha256_v7/src"
    TB_IN="$WORK_IN/tb_v7_drv.v"
    IV_PATH=""
    shares_host_fs=0
fi

run_in() {   # 在执行侧（可能是 chroot）跑一条命令
    if [ "$shares_host_fs" = "1" ]; then
        # chroot rootfs 是 nix 布局，里面没有 /bin/bash；用 nix 里那个
        $WRAP "${CHROOT_SH:-/nix/store/306znyj77fv49kwnkpxmb0j2znqpa8bj-bash-5.2p26/bin/bash}" -c "$*"
    else
        bash -c "$*"
    fi
}

mkdir -p "$WORK_HOST"

echo "== 1/4 编译 C 驱动 =="
gcc -O2 -Wall -std=c99 -I "$DRV" -o "$WORK_HOST/gen_trace" \
    "$DRV/gen_trace.c" "$DRV/sha256_axil.c"
echo "   ok: $WORK_HOST/gen_trace"

echo "== 2/4 生成寄存器写序列 =="
for m in $MSGS; do
    "$WORK_HOST/gen_trace" "$WORK_HOST/trace_$m.txt" "$m"
    python3 "$DRV/trace2hex.py" "$WORK_HOST/trace_$m.txt" "$WORK_HOST/prog_$m.hex" >/dev/null
done
echo "   4 条消息的 trace 已生成"

echo "== 3/4 用该序列驱动真 RTL（AXI4-Lite）=="
cp "$DRV/tb_v7_drv.v" "$WORK_HOST/tb_v7_drv.v"
printf '`define PROG_FILE "%s/prog.hex"\n' "$WORK_IN" > "$WORK_HOST/prog_path.vh"

IV="iverilog"
[ -n "$IV_PATH" ] && IV="$IV_PATH/iverilog"
VP="vvp"
[ -n "$IV_PATH" ] && VP="$IV_PATH/vvp"

run_in "$IV -g2012 -I $WORK_IN -o $WORK_IN/drv.out $TB_IN $DUT_IN/sha256_axil.v $DUT_IN/sha256_core.v"
echo "   编译通过"

for m in $MSGS; do
    cp "$WORK_HOST/prog_$m.hex" "$WORK_HOST/prog.hex"
    RAW="$(run_in "$VP $WORK_IN/drv.out" 2>/dev/null || true)"
    echo "$RAW" | grep -E "DIGEST|OPS|TIMEOUT|NO_MORE" | sed "s/^/   [$m] /"
    echo "$RAW" | awk '/^DIGEST /{print $2}' > "$WORK_HOST/got_$m.txt"
done

echo "== 4/4 hashlib 独立复算 =="
python3 - "$WORK_HOST" $MSGS <<'PY'
import hashlib, pathlib, sys

work = pathlib.Path(sys.argv[1])
msgs = sys.argv[2:]

def msg_bytes(name):
    return {
        "abc": b"abc",
        "empty": b"",
        "fox": b"The quick brown fox jumps over the lazy dog",
        "a119": b"a" * 119,
    }[name]

fails = 0
for name in msgs:
    exp = hashlib.sha256(msg_bytes(name)).hexdigest()
    p = work / ("got_%s.txt" % name)
    got = p.read_text().strip() if p.exists() else ""
    if got.lower() == exp:
        print("PASS %-6s %s" % (name, got))
    else:
        print("FAIL %-6s" % name)
        print("  got %s" % (got or "<空——RTL 没有输出摘要>"))
        print("  exp %s" % exp)
        fails += 1

print("ALL DRIVER TESTS PASSED" if fails == 0 else "DRIVER TESTS FAILED (%d)" % fails)
sys.exit(1 if fails else 0)
PY
