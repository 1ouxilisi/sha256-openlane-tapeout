drc off
tech load /pdk/sky130A/libs.tech/magic/sky130A.tech
addpath $env(REPRO_WORK)
cd $env(REPRO_WORK)
load sha256_axil
select top cell
ext2spice lvs
ext2spice -o $env(REPRO_SPICE)
puts "PHASE_B spice_done"
quit -noprompt
