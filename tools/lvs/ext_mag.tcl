# Magic 版图提取（LVS 用），由 run_lvs.sh 通过环境变量驱动。
# 目录不用写死：MAGIC_WORK 是工作目录，MAGIC_GDS / MAGIC_CELL 是输入。
drc off
tech load $env(MAGIC_TECH)
addpath $env(MAGIC_WORK)
addpath $env(MAGIC_STDCELL_MAG)
cd $env(MAGIC_WORK)
gds read $env(MAGIC_GDS)
load $env(MAGIC_CELL)
select top cell
extract do local
extract no capacitance
extract no coupling
extract no resistance
extract no adjust
extract unique
extract
ext2spice lvs
ext2spice -o $env(MAGIC_WORK)/layout.ext.spice $env(MAGIC_CELL).ext
puts "SPICE_DONE"
quit -noprompt
