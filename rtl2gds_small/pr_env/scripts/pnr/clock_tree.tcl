puts "RM-Info: \[date\] Running clock_tree.tcl"
source $env(ROOT_PATH)/scripts/pnr/layout_context.tcl

pnr_open_stage place cts

update_timing -full
pnr_try_set_app_option cts.compile.enable_global_route true
pnr_try_set_app_option time.remove_clock_reconvergence_pessimism true

pnr_apply_clock_routing_rules
set_ignored_layers -max_routing_layer $CTS_MAX_LAYER

clock_opt
pnr_run_post_cts_hold_repair

set_ignored_layers -min_routing_layer $MIN_ROUTE_LAYER -max_routing_layer $MAX_ROUTE_LAYER

connect_pg_net

redirect -file ${REPORTS_DIR}/cts.report_qor.rpt          {report_qor}
redirect -file ${REPORTS_DIR}/cts.report_timing.rpt       {report_timing -nosplit}
redirect -file ${REPORTS_DIR}/cts.report_clock_qor.rpt    {report_clock_qor}
redirect -file ${REPORTS_DIR}/cts.report_clock_trees.rpt  {report_clock_timing -type skew}
redirect -file ${REPORTS_DIR}/cts.report_clock_routing_rules.rpt {report_clock_routing_rules}

save_block -as ${DESIGN_NAME}/cts
save_lib

puts "RM-Info: \[date\] Completed clock_tree.tcl"
if {[info exists env(FC_AUTO_EXIT)]} { exit }
