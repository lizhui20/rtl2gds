puts "RM-Info: \[date\] Running layout_export.tcl"
source $env(ROOT_PATH)/scripts/pnr/layout_context.tcl

pnr_open_stage route chip_finish

proc pnr_insert_chip_finish_fillers {} {
    global FILLER_CELLS GFILLER_CELLS ENABLE_GFILL_STD_FILL

    set filler_patterns $FILLER_CELLS
    set filler_kind "standard"
    if {[info exists ENABLE_GFILL_STD_FILL] && $ENABLE_GFILL_STD_FILL &&
        [info exists GFILLER_CELLS] && [llength $GFILLER_CELLS] > 0} {
        set gfillers [get_lib_cells -quiet $GFILLER_CELLS]
        if {[sizeof_collection $gfillers] > 0} {
            set filler_patterns [concat $GFILLER_CELLS $FILLER_CELLS]
            set filler_kind "gfill+standard"
        } else {
            puts "RM-warning: ENABLE_GFILL_STD_FILL=1 but no GFILLER_CELLS matched; using standard FILLER_CELLS."
        }
    }

    set fillers [get_lib_cells -quiet $filler_patterns]
    if {[sizeof_collection $fillers] == 0} {
        puts "RM-warning: no filler cells matched '$filler_patterns'; skipping filler insertion."
        return
    }

    set filler_entries {}
    foreach_in_collection filler $fillers {
        set width [get_attribute -quiet $filler width]
        if {$width eq ""} { set width 0.0 }
        lappend filler_entries [list $width [get_object_name $filler]]
    }
    set filler_entries [lsort -real -decreasing -index 0 $filler_entries]
    set sorted_filler_names {}
    foreach entry $filler_entries {
        lappend sorted_filler_names [lindex $entry 1]
    }
    set fillers [get_lib_cells -quiet $sorted_filler_names]
    puts "RM-info: inserting $filler_kind filler cells: $sorted_filler_names"
    create_stdcell_fillers -lib_cells $fillers -rules {check_pnet}
    connect_pg_net
}

connect_pg_net

pnr_repair_max_cap_violations
pnr_run_max_transition_repair
connect_pg_net

pnr_insert_chip_finish_fillers
check_legality
connect_pg_net

redirect -file ${REPORTS_DIR}/chip_finish.check_pg_connectivity.rpt \
    {check_pg_connectivity -check_std_cell_pins one}
redirect -file ${REPORTS_DIR}/chip_finish.check_pg_connectivity_all_shapes.rpt \
    {check_pg_connectivity -check_std_cell_pins all}

redirect -file ${REPORTS_DIR}/chip_finish.report_qor.rpt          {report_qor}
redirect -file ${REPORTS_DIR}/chip_finish.report_timing.rpt       {report_timing -nosplit}
redirect -file ${REPORTS_DIR}/chip_finish.report_power.rpt        {report_power}
redirect -file ${REPORTS_DIR}/chip_finish.check_routes.rpt        {check_routes}
redirect -file ${REPORTS_DIR}/chip_finish.report_design.rpt       {report_design -physical}
pnr_report_constraint_violators ${REPORTS_DIR}/chip_finish.report_constraints.rpt
pnr_assert_no_route_open_nets ${REPORTS_DIR}/chip_finish.check_routes.rpt
pnr_assert_no_constraint_violations ${REPORTS_DIR}/chip_finish.report_constraints.rpt

write_verilog -exclude {leaf_module_declarations pg_objects \
    end_cap_cells well_tap_cells filler_cells pad_spacer_cells physical_only_cells \
    cover_cells diode_cells} ${RESULTS_DIR}/${DESIGN_NAME}.pnr.v
write_verilog ${RESULTS_DIR}/${DESIGN_NAME}.pnr.lvs.v
write_def -compress gzip -version 5.8 ${RESULTS_DIR}/${DESIGN_NAME}.pnr.def
pnr_write_signoff_sdc ${RESULTS_DIR}/${DESIGN_NAME}.pnr.sdc

save_block -as ${DESIGN_NAME}/chip_finish
save_lib

puts "RM-Info: \[date\] Completed layout_export.tcl"
if {[info exists env(FC_AUTO_EXIT)]} { exit }
