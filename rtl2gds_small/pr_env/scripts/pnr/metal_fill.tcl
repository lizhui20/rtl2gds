puts "RM-Info: \[date\] Running metal_fill.tcl"
source $env(ROOT_PATH)/scripts/pnr/layout_context.tcl

if {[info exists ENABLE_METAL_FILL] && $ENABLE_METAL_FILL} {
    if {![llength [info commands signoff_create_metal_fill]]} {
        error "signoff_create_metal_fill command is not available in this Fusion Compiler session"
    }
    if {[auto_execok icv] eq "" && [auto_execok icv_shell] eq ""} {
        error "ENABLE_METAL_FILL=1 requires IC Validator, but neither 'icv' nor 'icv_shell' is on PATH. Install/configure ICV or set ENABLE_METAL_FILL=0 to continue Calibre DRC with real density errors exposed."
    }
}

pnr_open_stage chip_finish metal_fill

if {![info exists ENABLE_METAL_FILL] || !$ENABLE_METAL_FILL} {
    puts "RM-info: ENABLE_METAL_FILL=0; preserving chip_finish geometry in metal_fill block."
} else {
    file mkdir ${run_path}/work/signoff/metal_fill
    pnr_try_set_app_option signoff.create_metal_fill.run_dir ${run_path}/work/signoff/metal_fill
    pnr_try_set_app_option signoff.create_metal_fill.flat true
    pnr_try_set_app_option signoff.create_metal_fill.fix_density_errors true

    set fill_cmd [list signoff_create_metal_fill -mode overwrite \
        -track_fill $METAL_FILL_TRACK_MODE \
        -fill_all_tracks false \
        -report_density ${REPORTS_DIR}/metal_fill.density]
    if {[info exists METAL_FILL_LAYERS] && [llength $METAL_FILL_LAYERS] > 0} {
        lappend fill_cmd -select_layers [get_layers $METAL_FILL_LAYERS]
    }

    puts "RM-info: running $fill_cmd"
    if {[catch {eval $fill_cmd} msg]} {
        error "signoff_create_metal_fill failed: $msg"
    }
}

connect_pg_net

redirect -file ${REPORTS_DIR}/metal_fill.check_routes.rpt {check_routes}
redirect -file ${REPORTS_DIR}/metal_fill.check_pg_connectivity.rpt {
    check_pg_connectivity -check_std_cell_pins one
}
redirect -file ${REPORTS_DIR}/metal_fill.check_lvs.rpt {
    check_lvs -checks all -open_reporting detailed -report_floating_pins true \
        -ignore_filler_cells true
}
redirect -file ${REPORTS_DIR}/metal_fill.report_qor.rpt {report_qor}
redirect -file ${REPORTS_DIR}/metal_fill.report_timing.rpt {report_timing -nosplit}
redirect -file ${REPORTS_DIR}/metal_fill.report_power.rpt {report_power}
redirect -file ${REPORTS_DIR}/metal_fill.report_design.rpt {report_design -physical}
pnr_report_constraint_violators ${REPORTS_DIR}/metal_fill.report_constraints.rpt
pnr_assert_no_constraint_violations ${REPORTS_DIR}/metal_fill.report_constraints.rpt

write_verilog -exclude {leaf_module_declarations pg_objects \
    end_cap_cells well_tap_cells filler_cells pad_spacer_cells physical_only_cells \
    cover_cells diode_cells} ${RESULTS_DIR}/${DESIGN_NAME}.pnr.v
write_verilog ${RESULTS_DIR}/${DESIGN_NAME}.pnr.lvs.v
write_def -compress gzip -version 5.8 ${RESULTS_DIR}/${DESIGN_NAME}.pnr.def
pnr_write_signoff_sdc ${RESULTS_DIR}/${DESIGN_NAME}.pnr.sdc

save_block -as ${DESIGN_NAME}/metal_fill
save_lib
set marker [open ${RESULTS_DIR}/${DESIGN_NAME}.metal_fill.done w]
puts $marker "completed [clock format [clock seconds]] ENABLE_METAL_FILL=$ENABLE_METAL_FILL"
close $marker

puts "RM-Info: \[date\] Completed metal_fill.tcl"
if {[info exists env(FC_AUTO_EXIT)]} { exit }
