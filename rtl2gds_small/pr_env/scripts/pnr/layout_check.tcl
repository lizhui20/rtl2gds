puts "RM-Info: \[date\] Running layout_check.tcl"
source $env(ROOT_PATH)/scripts/pnr/layout_context.tcl

set signoff_block_label [pnr_open_existing_signoff_block]

file mkdir $REPORTS_DIR

set FC_DRC_RPT     ${REPORTS_DIR}/fc_drc.rpt
set FC_LVS_RPT     ${REPORTS_DIR}/fc_lvs.rpt
set FC_PG_RPT      ${REPORTS_DIR}/fc_pg_connectivity.rpt
set FC_SUMMARY_RPT ${REPORTS_DIR}/fc_drc_lvs.summary.rpt

proc slurp_file {path} {
    set fh [open $path r]
    set data [read $fh]
    close $fh
    return $data
}

proc first_int {pattern text default_value} {
    if {[regexp $pattern $text -> value]} {
        return [expr {$value + 0}]
    }
    return $default_value
}

proc sum_pg_metric {label text} {
    set total 0
    set pattern [format {Number of floating %s:\s*([0-9]+)} $label]
    foreach {match value} [regexp -all -inline $pattern $text] {
        incr total $value
    }
    return $total
}

proc parse_drc_report {path} {
    set text [slurp_file $path]
    set total [first_int {TOTAL VIOLATIONS =\s*([0-9]+)} $text 0]
    set open_nets [first_int {Total number of open nets =\s*([0-9]+)} $text 0]
    set eol [first_int {End of line spacing\s*:\s*([0-9]+)} $text 0]
    set same_net_spacing [first_int {Same net spacing\s*:\s*([0-9]+)} $text 0]

    return [dict create \
        drc_total $total \
        drc_open_nets $open_nets \
        drc_eol $eol \
        drc_same_net_spacing $same_net_spacing]
}

proc parse_lvs_report {path} {
    set text [slurp_file $path]
    set shorts [first_int {Total number of short violations is\s*([0-9]+)} $text 0]
    set open_locations 0
    set open_nets 0
    if {[regexp {Total number of open locations is\s*([0-9]+) \(([0-9]+) open nets\)} $text -> locs nets]} {
        set open_locations [expr {$locs + 0}]
        set open_nets [expr {$nets + 0}]
    }
    set floating_pins [first_int {Total number of floating pins is\s*([0-9]+)} $text 0]
    set floating_routes [first_int {Total number of floating route violations is\s*([0-9]+)} $text 0]

    return [dict create \
        lvs_shorts $shorts \
        lvs_open_locations $open_locations \
        lvs_open_nets $open_nets \
        lvs_floating_pins $floating_pins \
        lvs_floating_routes $floating_routes]
}

proc parse_pg_report {path} {
    set text [slurp_file $path]
    return [dict create \
        pg_floating_wires [sum_pg_metric wires $text] \
        pg_floating_vias [sum_pg_metric vias $text] \
        pg_floating_std_cells [sum_pg_metric {std cells} $text] \
        pg_floating_hard_macros [sum_pg_metric {hard macros} $text] \
        pg_floating_io_pads [sum_pg_metric {I/O pads} $text] \
        pg_floating_terminals [sum_pg_metric terminals $text] \
        pg_floating_hier_blocks [sum_pg_metric {hierarchical blocks} $text]]
}

proc merge_metrics {base extra} {
    dict for {k v} $extra {
        dict set base $k $v
    }
    return $base
}

proc run_physical_checks {iteration} {
    global FC_DRC_RPT FC_LVS_RPT FC_PG_RPT

    puts "RM-Info: DRC/LVS iteration ${iteration}: running built-in checkers"

    redirect -file $FC_DRC_RPT {
        check_routes -drc true -open_net true -antenna true
    }
    redirect -file $FC_PG_RPT {
        check_pg_connectivity -check_std_cell_pins one
    }
    redirect -file $FC_LVS_RPT {
        check_lvs -checks all -open_reporting detailed -report_floating_pins true \
            -ignore_filler_cells true
    }

    set metrics [parse_drc_report $FC_DRC_RPT]
    set metrics [merge_metrics $metrics [parse_pg_report $FC_PG_RPT]]
    set metrics [merge_metrics $metrics [parse_lvs_report $FC_LVS_RPT]]
    return $metrics
}

proc drc_is_clean {metrics} {
    set total [dict get $metrics drc_total]
    set open_nets [dict get $metrics drc_open_nets]
    return [expr {$total == 0 && $open_nets == 0}]
}

proc drc_has_only_fc_route_warnings {metrics} {
    set total [dict get $metrics drc_total]
    set open_nets [dict get $metrics drc_open_nets]
    set same_net_spacing [dict get $metrics drc_same_net_spacing]
    return [expr {$open_nets == 0 && $total > 0 && $total == $same_net_spacing}]
}

proc pg_is_clean {metrics} {
    foreach key {
        pg_floating_wires
        pg_floating_vias
        pg_floating_std_cells
        pg_floating_hard_macros
        pg_floating_io_pads
        pg_floating_terminals
        pg_floating_hier_blocks
    } {
        if {[dict get $metrics $key] != 0} {
            return 0
        }
    }
    return 1
}

proc lvs_is_clean {metrics} {
    foreach key {
        lvs_shorts
        lvs_open_locations
        lvs_open_nets
        lvs_floating_pins
        lvs_floating_routes
    } {
        if {[dict get $metrics $key] != 0} {
            return 0
        }
    }
    return 1
}

proc overall_is_clean {metrics} {
    return [expr {[drc_is_clean $metrics] && [pg_is_clean $metrics] && [lvs_is_clean $metrics]}]
}

proc overall_is_signoff_ready {metrics} {
    return [expr {([drc_is_clean $metrics] || [drc_has_only_fc_route_warnings $metrics]) &&
        [pg_is_clean $metrics] && [lvs_is_clean $metrics]}]
}

proc metrics_line {metrics} {
    return [format \
        "drc=%d drc_open_nets=%d eol=%d same_net_spacing=%d pg_float(w/v/std/term)=%d/%d/%d/%d lvs(short/open_loc/open_net/float_pin/float_route)=%d/%d/%d/%d/%d" \
        [dict get $metrics drc_total] \
        [dict get $metrics drc_open_nets] \
        [dict get $metrics drc_eol] \
        [dict get $metrics drc_same_net_spacing] \
        [dict get $metrics pg_floating_wires] \
        [dict get $metrics pg_floating_vias] \
        [dict get $metrics pg_floating_std_cells] \
        [dict get $metrics pg_floating_terminals] \
        [dict get $metrics lvs_shorts] \
        [dict get $metrics lvs_open_locations] \
        [dict get $metrics lvs_open_nets] \
        [dict get $metrics lvs_floating_pins] \
        [dict get $metrics lvs_floating_routes]]
}

proc set_route_repair_options {} {
    set_app_options -name route.detail.drc_convergence_effort_level -value high
    set_app_options -name route.detail.eco_route_use_soft_spacing_for_timing_optimization -value false
    set_app_options -name route.detail.check_patchable_drc_from_fixed_shapes -value true
    pnr_apply_route_drc_shape_controls
}

proc repair_unresolved {metrics} {
    set_route_repair_options

    if {![drc_is_clean $metrics]} {
        puts "RM-Info: attempting full ECO routing for remaining route DRC/open-net issues"
        route_eco -reroute any_nets -reuse_existing_global_route false \
            -max_detail_route_iterations 300 -max_reported_nets -1
    }

    if {![pg_is_clean $metrics] || ![lvs_is_clean $metrics]} {
        puts "RM-Info: reconnecting PG and running ECO routing for LVS/PG connectivity"
        connect_pg_net
        route_eco -reroute any_nets -reuse_existing_global_route false \
            -max_detail_route_iterations 300 -max_reported_nets -1
    }
}

proc write_summary_report {metrics status repaired iterations} {
    global FC_SUMMARY_RPT FC_DRC_RPT FC_LVS_RPT FC_PG_RPT
    set fh [open $FC_SUMMARY_RPT w]
    puts $fh "status: $status"
    puts $fh "repair_attempted: $repaired"
    puts $fh "iterations: $iterations"
    puts $fh "metrics: [metrics_line $metrics]"
    puts $fh "drc_report: $FC_DRC_RPT"
    puts $fh "pg_report: $FC_PG_RPT"
    puts $fh "lvs_report: $FC_LVS_RPT"
    close $fh
}

proc refresh_outputs_after_repair {} {
    global REPORTS_DIR RESULTS_DIR DESIGN_NAME signoff_block_label
    puts "RM-Info: refreshing ${signoff_block_label} reports and output files after automatic repair"

    redirect -file ${REPORTS_DIR}/chip_finish.check_routes.rpt {check_routes}
    redirect -file ${REPORTS_DIR}/chip_finish.report_qor.rpt {report_qor}
    redirect -file ${REPORTS_DIR}/chip_finish.report_timing.rpt {report_timing -nosplit}
    redirect -file ${REPORTS_DIR}/chip_finish.report_power.rpt {report_power}
    redirect -file ${REPORTS_DIR}/chip_finish.report_design.rpt {report_design -physical}

    write_verilog -exclude {leaf_module_declarations pg_objects \
        end_cap_cells well_tap_cells filler_cells pad_spacer_cells physical_only_cells \
        cover_cells diode_cells} ${RESULTS_DIR}/${DESIGN_NAME}.pnr.v
    write_verilog ${RESULTS_DIR}/${DESIGN_NAME}.pnr.lvs.v
    write_def -compress gzip -version 5.8 ${RESULTS_DIR}/${DESIGN_NAME}.pnr.def
    pnr_write_signoff_sdc ${RESULTS_DIR}/${DESIGN_NAME}.pnr.sdc

    save_block -as ${DESIGN_NAME}/${signoff_block_label}
    save_lib
}

set max_iterations 3
set repair_attempted 0
set previous_signature ""
set final_metrics ""
set final_status "unresolved"
set final_iteration 0

for {set iteration 0} {$iteration <= $max_iterations} {incr iteration} {
    set metrics [run_physical_checks $iteration]
    set final_metrics $metrics
    set final_iteration $iteration
    set signature [metrics_line $metrics]
    puts "RM-Info: iteration ${iteration} metrics: $signature"

    if {[overall_is_clean $metrics]} {
        set final_status "pass"
        break
    }

    if {[overall_is_signoff_ready $metrics]} {
        set final_status "pass_with_fc_route_drc_warnings"
        break
    }

    if {$iteration >= $max_iterations} {
        break
    }

    if {$previous_signature ne "" && $signature eq $previous_signature} {
        puts "RM-Info: automatic repair made no metric improvement; stopping repair loop"
        break
    }

    set previous_signature $signature
    repair_unresolved $metrics
    set repair_attempted 1
}

if {$final_status ne "pass" && [overall_is_signoff_ready $final_metrics]} {
    set final_status "pass_with_fc_route_drc_warnings"
}

if {$final_status eq "pass" || $final_status eq "pass_with_fc_route_drc_warnings"} {
    write_summary_report $final_metrics $final_status $repair_attempted $final_iteration
    if {$repair_attempted} {
        refresh_outputs_after_repair
    }
    if {$final_status eq "pass_with_fc_route_drc_warnings"} {
        puts "RM-Warning: FC built-in route DRC still reports only same-net spacing marker(s)."
        puts "RM-Warning: Continuing so external Calibre DRC can be the tapeout-grade authority."
    }
    puts "RM-Info: built-in DRC report : $FC_DRC_RPT"
    puts "RM-Info: built-in PG report  : $FC_PG_RPT"
    puts "RM-Info: built-in LVS report : $FC_LVS_RPT"
    puts "RM-Info: summary report      : $FC_SUMMARY_RPT"
    puts "RM-Info: \[date\] Completed layout_check.tcl"
    if {[info exists env(FC_AUTO_EXIT)]} { exit 0 }
} else {
    write_summary_report $final_metrics "unresolved" $repair_attempted $final_iteration
    puts "RM-Info: DRC/LVS automatic repair stopped with unresolved real issues"
    puts "RM-Info: final metrics: [metrics_line $final_metrics]"
    puts "RM-Info: summary report: $FC_SUMMARY_RPT"
    if {[info exists env(FC_AUTO_EXIT)]} { exit 1 }
    error "run_fc_drc_lvs stopped with unresolved real DRC/LVS issues"
}
