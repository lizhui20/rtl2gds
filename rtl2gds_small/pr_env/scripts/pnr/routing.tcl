puts "RM-Info: \[date\] Running routing.tcl"
source $env(ROOT_PATH)/scripts/pnr/layout_context.tcl

pnr_open_stage cts route

set_ignored_layers -min_routing_layer $MIN_ROUTE_LAYER -max_routing_layer $MAX_ROUTE_LAYER
pnr_try_set_app_option route.common.global_max_layer_mode hard
pnr_try_set_app_option route.global.effort_level high
pnr_try_set_app_option route.global.timing_driven true
pnr_try_set_app_option route.track.timing_driven true
pnr_try_set_app_option route.track.crosstalk_driven true
pnr_try_set_app_option route.detail.timing_driven true
pnr_apply_route_drc_shape_controls

pnr_source_antenna_rules
pnr_try_set_app_option route.detail.antenna true
pnr_try_set_app_option route.detail.diode_libcell_names $ANTENNA_CELLS
pnr_try_set_app_option route.detail.insert_diodes_during_routing true

route_auto
route_opt
pnr_run_max_transition_repair
pnr_repair_max_cap_violations

connect_pg_net

update_timing -full

redirect -file ${REPORTS_DIR}/route.check_routes.rpt   {check_routes}
redirect -file ${REPORTS_DIR}/route.report_qor.rpt     {report_qor}
redirect -file ${REPORTS_DIR}/route.report_timing.rpt  {report_timing -nosplit}
redirect -file ${REPORTS_DIR}/route.report_design.rpt  {report_design -physical}
pnr_report_constraint_violators ${REPORTS_DIR}/route.report_constraints.rpt
pnr_assert_no_constraint_violations ${REPORTS_DIR}/route.report_constraints.rpt

save_block -as ${DESIGN_NAME}/route
save_lib

puts "RM-Info: \[date\] Completed routing.tcl"
if {[info exists env(FC_AUTO_EXIT)]} { exit }
