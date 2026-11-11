# T8 signoff STA：真 RCX SPEF + 指定 corner liberty。全部输出走 stdout，由日志收集。
# OpenROAD 里没有 redirect 命令，report_checks 也不返回值，所以只能靠 SECTION_* 分段标记。
# 环境变量：STA_LIB / STA_SDC / STA_SPEF（none 表示退回估算口径）/ STA_TAG
set LIB $::env(STA_LIB)
read_liberty $LIB
puts "LIB_LOADED $LIB"
read_db /tmp/eco/eco_it2_t8.odb
puts "DB_LOADED"
read_sdc $::env(STA_SDC)
puts "SDC_LOADED $::env(STA_SDC)"
if {[info exists ::env(STA_SPEF)] && $::env(STA_SPEF) ne "none"} {
  read_spef $::env(STA_SPEF)
  puts "SPEF_LOADED $::env(STA_SPEF)"
} else {
  set_wire_rc -signal -layer met1
  set_wire_rc -clock -layer met3
  estimate_parasitics -global_routing
  puts "PARASITICS_ESTIMATED"
}
puts "=== SECTION_HEADER ==="
puts "LIB=$LIB"
puts "SPEF=$::env(STA_SPEF)"
puts "SDC=$::env(STA_SDC)"
puts "=== SECTION_SETUP_PATHS ==="
report_checks -path_delay max -format full_clock_expanded -digits 3 -group_count 10 -endpoint_count 10
puts "=== SECTION_SETUP_WNS_TNS ==="
report_wns
report_tns
puts "=== SECTION_HOLD_PATHS ==="
report_checks -path_delay min -format full_clock_expanded -digits 3 -group_count 10 -endpoint_count 10
puts "=== SECTION_HOLD_WNS_TNS ==="
report_worst_slack -min
puts "=== SECTION_DRV ==="
report_check_types -max_slew -max_capacitance -max_fanout -violators
puts "=== SECTION_CLOCK_SKEW ==="
report_clock_skew -digits 3
puts "=== SECTION_POWER ==="
report_power
puts "STA_DONE $::env(STA_TAG)"
exit
