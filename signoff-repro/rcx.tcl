# 从 ODB 抽真 SPEF（OpenRCX）。corner 由环境变量传入，不写死。
# RCX_RULES：PDK 的 rules.openrcx.sky130A.{nom,max,min}.magic
# RCX_OUT  ：输出 spef 路径
read_db /tmp/eco/eco_it2_t8.odb
puts "DB_LOADED"
extract_parasitics -ext_model_file $::env(RCX_RULES)
puts "RCX_DONE"
write_spef $::env(RCX_OUT)
puts "SPEF_WRITTEN $::env(RCX_OUT)"
exit
