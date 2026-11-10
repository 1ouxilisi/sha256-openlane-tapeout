# 从 PDK 的 sky130_fd_sc_hd.gds 逐单元重抽标准单元 .ext，建成 PHASE 0 缓存。
# 一个 magic 会话里跑完 148 个单元；每个单元 load -> select top cell -> extract。
# 环境变量：REPRO_LIB（库 gds）、MASTERS（单元名清单）、REPRO_CACHE（输出目录）
drc off
tech load /pdk/sky130A/libs.tech/magic/sky130A.tech
cd $env(REPRO_CACHE)
gds read $env(REPRO_LIB)

set fh [open $env(MASTERS) r]
set names {}
while {[gets $fh line] >= 0} {
    set line [string trim $line]
    if {$line ne ""} { lappend names $line }
}
close $fh
puts "BUILD_CACHE masters=[llength $names]"

set n 0
foreach m $names {
    load $m
    select top cell
    extract do local
    extract no capacitance
    extract no coupling
    extract no resistance
    extract no adjust
    extract
    incr n
    if {[expr {$n % 20}] == 0} { puts "BUILD_CACHE $n/[llength $names]" }
}
puts "BUILD_CACHE done n=$n"
quit -noprompt
