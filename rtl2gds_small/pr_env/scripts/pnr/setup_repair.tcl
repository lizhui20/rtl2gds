puts "RM-Info: \[date\] Running setup_repair.tcl"
source $env(ROOT_PATH)/scripts/pnr/layout_context.tcl

open_lib $DESIGN_LIBRARY
open_block ${PNR_LIB_NAME}:${DESIGN_NAME}/route
link_block
pnr_apply_implementation_controls
pnr_enable_tie_cells
pnr_apply_library_attributes

set setup_scenarios {}
foreach c $PNR_CORNERS {
    lassign $c cname sname process volt temp pspec a_su a_ho a_dp a_lk
    if {$a_su} { lappend setup_scenarios $sname }
}
if {[llength $setup_scenarios] == 0} {
    error "No active setup scenarios found in PNR_CORNERS"
}

update_timing -full
redirect -file ${REPORTS_DIR}/setup_eco.before.rpt {
    report_qor
    report_timing -delay_type max -max_paths 50 -slack_lesser_than 0.0 -nosplit
    report_timing -delay_type min -max_paths 50 -slack_lesser_than 0.0 -nosplit
}

foreach c $PNR_CORNERS {
    lassign $c cname sname process volt temp pspec a_su a_ho a_dp a_lk
    set_scenario_status $sname -active $a_su -setup $a_su -hold false \
        -leakage_power $a_lk -dynamic_power $a_dp
}

if {[info exists env(SETUP_MARGIN_NS)] && $env(SETUP_MARGIN_NS) ne ""} {
    set SETUP_MARGIN $env(SETUP_MARGIN_NS)
} else {
    set SETUP_MARGIN 0.00
}
if {$SETUP_MARGIN > 0.0} {
    foreach s $setup_scenarios {
        current_scenario $s
        set_clock_uncertainty -setup $SETUP_MARGIN [all_clocks]
    }
    update_timing -full
    puts "RM-Info: temporary setup ECO uncertainty set to ${SETUP_MARGIN}ns on $setup_scenarios"
} else {
    puts "RM-Info: SETUP_MARGIN_NS=0; using existing SDC setup uncertainty for ECO."
}

pnr_try_set_app_option route.global.timing_driven true
pnr_try_set_app_option route.track.timing_driven true
pnr_try_set_app_option route.detail.timing_driven true
pnr_try_set_app_option opt.timing.effort high
route_opt
connect_pg_net

current_mode $MCMM_MODE
read_sdc $SYNTH_SDC
foreach c $PNR_CORNERS {
    lassign $c cname sname process volt temp pspec a_su a_ho a_dp a_lk
    set_scenario_status $sname -active true \
        -setup $a_su -hold $a_ho -leakage_power $a_lk -dynamic_power $a_dp
}
update_timing -full

redirect -variable route_check {check_routes}
set fh [open ${REPORTS_DIR}/setup_eco.check_routes.rpt w]
puts $fh $route_check
close $fh
if {[regexp {@@@@@@@ TOTAL VIOLATIONS =[ \t]*([0-9]+)} $route_check -> drc_count] && $drc_count != 0} {
    puts "RM-Info: Setup ECO left $drc_count route DRC violation(s); running ECO route repair."
    pnr_try_set_app_option route.detail.drc_convergence_effort_level high
    pnr_try_set_app_option route.detail.eco_route_use_soft_spacing_for_timing_optimization false
    pnr_try_set_app_option route.detail.check_patchable_drc_from_fixed_shapes true
    pnr_apply_route_drc_shape_controls
    route_eco -reroute any_nets -reuse_existing_global_route false \
        -max_detail_route_iterations 300 -max_reported_nets -1
    connect_pg_net
    update_timing -full
    redirect -variable route_check {check_routes}
    set fh [open ${REPORTS_DIR}/setup_eco.check_routes.rpt w]
    puts $fh $route_check
    close $fh
}
if {[regexp {@@@@@@@ TOTAL VIOLATIONS =[ \t]*([0-9]+)} $route_check -> drc_count] && $drc_count != 0} {
    error "Setup ECO left $drc_count route DRC violation(s); inspect ${REPORTS_DIR}/setup_eco.check_routes.rpt"
}

redirect -file ${REPORTS_DIR}/setup_eco.after.rpt {
    report_qor
    report_timing -delay_type max -max_paths 50 -slack_lesser_than 0.0 -nosplit
    report_timing -delay_type min -max_paths 50 -slack_lesser_than 0.0 -nosplit
}

save_block
save_lib
set_svf -off
if {![file exists $PNR_SVF]} {
    error "PnR SVF was not written: $PNR_SVF"
}

puts "RM-Info: setup-fix ECO done; run_chip_finish must run next to write final outputs."
puts "RM-Info: \[date\] Completed setup_repair.tcl"
if {[info exists env(FC_AUTO_EXIT)]} { exit }
