#!/bin/bash
# SPEF 抓取启动器。两个参数：OpenRCX 规则文件、输出 spef。
# sudo 会重置环境变量，所以一律用脚本实参传，不靠外部 export。
export PDK_ROOT=/pdk
export RCX_RULES="$1"
export RCX_OUT="$2"
cd /tmp/eco
exec /nix/store/7g30wn9qnkcvnkk5h9q1cqk0yl86qxil-openroad/bin/openroad -no_init /tmp/eco/rcx.tcl
