drc off
tech load /pdk/sky130A/libs.tech/magic/sky130A.tech
addpath $env(REPRO_WORK)
cd $env(REPRO_WORK)
gds read $env(REPRO_GDS)
load sha256_axil
select top cell
extract do local
extract no capacitance
extract no coupling
extract no resistance
extract no adjust
extract unique
extract
puts "PHASE_A extract_done"
quit -noprompt
