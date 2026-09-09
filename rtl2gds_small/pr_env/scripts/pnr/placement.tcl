puts "RM-Info: \[date\] Running placement.tcl"
source $env(ROOT_PATH)/scripts/pnr/layout_context.tcl

pnr_open_stage power_mesh place

pnr_apply_clock_routing_rules

set_app_options -name place_opt.flow.do_spg -value true
set_app_options -name opt.timing.effort -value high
if {[info exists TIE_MAX_FANOUT]} {
    set_app_options -name opt.tie_cell.max_fanout -value $TIE_MAX_FANOUT
}


create_placement -effort high
legalize_placement
connect_pg_net

create_pg_std_cell_conn_pattern std_rail -layers [list $PG_RAIL_LAYER]
set_pg_strategy rail_strategy -core \
    -pattern "{name: std_rail} {nets: {$PG_POWER_NET $PG_GROUND_NET}}"
if {[info exists PG_RAIL_CONNECT_LAYER]} {
    set rail_via_master default
    if {[info exists PG_RAIL_TO_BRIDGE_VIAS] && [llength $PG_RAIL_TO_BRIDGE_VIAS] > 0} {
        set rail_via_master $PG_RAIL_TO_BRIDGE_VIAS
    }
    set_pg_strategy_via_rule rail_via_rule \
        -via_rule [subst { \
            {{strategies: rail_strategy} {{existing: strap} {layers: $PG_RAIL_CONNECT_LAYER}} {via_master: {$rail_via_master}}} \
            {{intersection: undefined} {via_master: NIL}} }]
    compile_pg -strategies rail_strategy -via_rule rail_via_rule
} else {
    compile_pg -strategies rail_strategy
}
connect_pg_net

place_opt

if {[info exists LEFT_BOUNDARY_CELL] && [info exists RIGHT_BOUNDARY_CELL]} {
    set left_boundary [get_lib_cells -quiet $LEFT_BOUNDARY_CELL]
    set right_boundary [get_lib_cells -quiet $RIGHT_BOUNDARY_CELL]
    if {[sizeof_collection $left_boundary] != 1 || [sizeof_collection $right_boundary] != 1} {
        error "Expected one left and one right boundary lib cell"
    }
    create_boundary_cells \
        -left_boundary_cell [get_object_name $left_boundary] \
        -right_boundary_cell [get_object_name $right_boundary] \
        -prefix ENDCAP
}
if {[info exists TAP_CELL] && [info exists TAP_DISTANCE]} {
    set tap_lib_cell [get_lib_cells -quiet $TAP_CELL]
    if {[sizeof_collection $tap_lib_cell] != 1} {
        error "Expected one tap lib cell matching $TAP_CELL"
    }
    set tap_pattern every_other_row
    if {[info exists TAP_PATTERN]} { set tap_pattern $TAP_PATTERN }
    create_tap_cells -lib_cell [get_object_name $tap_lib_cell] \
        -distance $TAP_DISTANCE -pattern $tap_pattern -prefix TAP \
        -skip_fixed_cells
}
legalize_placement
connect_pg_net

redirect -file ${REPORTS_DIR}/place.check_pg_drc.rpt \
    {check_pg_drc}
redirect -file ${REPORTS_DIR}/place.check_pg_drc_network.rpt \
    {check_pg_drc -ignore_std_cells}
redirect -file ${REPORTS_DIR}/place.check_pg_connectivity.rpt \
    {check_pg_connectivity -check_std_cell_pins one}
redirect -file ${REPORTS_DIR}/place.check_pg_connectivity_all_shapes.rpt \
    {check_pg_connectivity -check_std_cell_pins all}

redirect -file ${REPORTS_DIR}/place.report_qor.rpt          {report_qor}
redirect -file ${REPORTS_DIR}/place.report_timing.rpt       {report_timing -nosplit}
redirect -file ${REPORTS_DIR}/place.report_utilization.rpt  {report_utilization}
set legality_report ${REPORTS_DIR}/place.check_legality.rpt
redirect -file $legality_report {check_legality}
set fh [open $legality_report r]
set legality_text [read $fh]
close $fh
if {[regexp {TOTAL[ \t]+([1-9][0-9]*)[ \t]+Violations} $legality_text -> violation_count] ||
    [regexp {check_legality[^\n]*failed|check_legality failed} $legality_text]} {
    if {![info exists violation_count]} { set violation_count "unknown" }
    error "Placement legality failed after boundary/tap insertion: $violation_count violation(s); see $legality_report"
}

save_block -as ${DESIGN_NAME}/place
save_lib

puts "RM-Info: \[date\] Completed placement.tcl"
if {[info exists env(FC_AUTO_EXIT)]} { exit }
