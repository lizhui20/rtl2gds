set DESIGN_NAME $env(DESIGN_NAME)
set ROOT_PATH   $env(ROOT_PATH)
set run_path    ${ROOT_PATH}/${DESIGN_NAME}
set results     ${run_path}/results
set reports     ${run_path}/reports/signoff
set TECH_DIR    ${run_path}/tech
set REF_DIR     ${run_path}/ref
file mkdir $reports

set PDK_DIR ${ROOT_PATH}/scripts/pdk
source ${PDK_DIR}/process_select.tcl
set pr_profile_file ${PDK_DIR}/process_${PDK_PROFILE}.tcl
if {![file exists $pr_profile_file]} {
    error "PT PDK profile not found: $pr_profile_file"
}
puts "RM-info: PT process profile = $PDK_PROFILE"
source $pr_profile_file
set mmcm_file ${PDK_DIR}/rc_corners.tcl
if {![file exists $mmcm_file]} {
    error "PT MCMM setup not found: $mmcm_file"
}
puts "RM-info: MCMM setup = $mmcm_file"
source $mmcm_file
source ${ROOT_PATH}/scripts/utilities/layout_defaults.tcl
set design_user_setup_file ${run_path}/inputs/${DESIGN_NAME}.pr_user_setting.tcl
if {[file exists $design_user_setup_file]} {
    source $design_user_setup_file
}
mmcm_report_summary

set NETLIST ${results}/${DESIGN_NAME}.pnr.v
set SDC     ${results}/${DESIGN_NAME}.pnr.sdc
set SIGNOFF_RESULTS ${results}/signoff
set SETUP_SPEF ${SIGNOFF_RESULTS}/${DESIGN_NAME}.${SPEF_SETUP_CORNER}.spef
set HOLD_SPEF  ${SIGNOFF_RESULTS}/${DESIGN_NAME}.${SPEF_HOLD_CORNER}.spef

set_app_var search_path [list ${run_path}/ref $results]
set_app_var target_library $PT_SETUP_DBS
set_app_var link_library [concat * $PT_SETUP_DBS]

read_verilog $NETLIST
current_design $DESIGN_NAME
link_design $DESIGN_NAME
foreach max_db $PT_SETUP_DBS min_db $PT_HOLD_DBS {
    set_min_library $max_db -min_version $min_db
}
set_operating_conditions -analysis_type on_chip_variation
read_sdc -version 2.1 $SDC
if {$MCMM_MODE eq "func"} {
    foreach control [list $SCAN_ENABLE_PORT $TEST_MODE_PORT] {
        set control_ports [get_ports -quiet $control]
        if {[sizeof_collection $control_ports] > 0} {
            set_case_analysis 0 $control_ports
        }
    }
}
set_max_fanout $MAX_FANOUT [current_design]

if {![file exists $SETUP_SPEF] || [file size $SETUP_SPEF] == 0} {
    error "Setup SPEF not found or empty: $SETUP_SPEF"
}
if {![file exists $HOLD_SPEF] || [file size $HOLD_SPEF] == 0} {
    if {$SPEF_HOLD_CORNER eq $SPEF_SETUP_CORNER} {
        set HOLD_SPEF $SETUP_SPEF
    } else {
        error "Hold SPEF not found or empty: $HOLD_SPEF"
    }
}

proc pt_read_corner_parasitics {spef label reports} {
    catch {remove_annotated_parasitics}
    puts "RM-info: read $label parasitics from $spef"
    read_parasitics -format spef $spef
    set_propagated_clock [all_clocks]
    update_timing -full
    redirect -file ${reports}/pt.${label}.parasitic_annotation.rpt {
        report_annotated_parasitics -check
    }
}

proc pt_write_combined_report {out_file files} {
    set out [open $out_file w]
    foreach f $files {
        puts $out "################################################################################"
        puts $out "# $f"
        puts $out "################################################################################"
        if {[file exists $f]} {
            set in [open $f r]
            puts $out [read $in]
            close $in
        } else {
            puts $out "Missing report: $f"
        }
    }
    close $out
}

proc pt_count_constraint_violations {report} {
    set input [open $report r]
    set content [read $input]
    close $input
    return [regexp -all {\(VIOLATED} $content]
}

proc pt_write_signoff_summary {out_file setup_spef hold_spef setup_count hold_count setup_constraints hold_constraints} {
    global SPEF_SETUP_CORNER SPEF_HOLD_CORNER
    set out [open $out_file w]
    puts $out "PrimeTime signoff summary"
    puts $out "setup_corner: $SPEF_SETUP_CORNER"
    puts $out "setup_spef: $setup_spef"
    puts $out "setup_max_delay_violating_paths: $setup_count"
    puts $out "hold_corner: $SPEF_HOLD_CORNER"
    puts $out "hold_spef: $hold_spef"
    puts $out "hold_min_delay_violating_paths: $hold_count"
    puts $out "setup_constraint_violations: $setup_constraints"
    puts $out "hold_constraint_violations: $hold_constraints"
    close $out
}

pt_read_corner_parasitics $SETUP_SPEF setup $reports
redirect -file ${reports}/pt.check_timing.rpt {
    check_timing -verbose
}
redirect -file ${reports}/pt.qor.setup.rpt {
    report_qor
}
redirect -file ${reports}/pt.setup.rpt {
    report_timing -delay_type max -path_type full_clock_expanded \
        -max_paths 100 -slack_lesser_than 0.0 -input_pins -nets -transition_time -capacitance
}
redirect -file ${reports}/pt.constraints.setup.rpt {
    report_constraint -all_violators -nosplit
}
set setup_violation_count [sizeof_collection [get_timing_paths -delay_type max -slack_lesser_than 0.0 -max_paths 100000]]

pt_read_corner_parasitics $HOLD_SPEF hold $reports
redirect -file ${reports}/pt.qor.hold.rpt {
    report_qor
}
redirect -file ${reports}/pt.hold.rpt {
    report_timing -delay_type min -path_type full_clock_expanded \
        -max_paths 100 -slack_lesser_than 0.0 -input_pins -nets -transition_time -capacitance
}
redirect -file ${reports}/pt.constraints.hold.rpt {
    report_constraint -all_violators -nosplit
}
set hold_violation_count [sizeof_collection [get_timing_paths -delay_type min -slack_lesser_than 0.0 -max_paths 100000]]
set setup_constraint_count [pt_count_constraint_violations ${reports}/pt.constraints.setup.rpt]
set hold_constraint_count [pt_count_constraint_violations ${reports}/pt.constraints.hold.rpt]

pt_write_signoff_summary ${reports}/pt.signoff_summary.rpt \
    $SETUP_SPEF $HOLD_SPEF $setup_violation_count $hold_violation_count \
    $setup_constraint_count $hold_constraint_count

pt_write_combined_report ${reports}/pt.qor.rpt \
    [list ${reports}/pt.qor.setup.rpt ${reports}/pt.qor.hold.rpt]
pt_write_combined_report ${reports}/pt.parasitic_annotation.rpt \
    [list ${reports}/pt.setup.parasitic_annotation.rpt ${reports}/pt.hold.parasitic_annotation.rpt]
pt_write_combined_report ${reports}/pt.constraints.rpt \
    [list ${reports}/pt.constraints.setup.rpt ${reports}/pt.constraints.hold.rpt]

if {$setup_violation_count > 0 || $hold_violation_count > 0} {
    error "PrimeTime signoff has setup or hold violation"
}
if {$setup_constraint_count > 0 || $hold_constraint_count > 0} {
    if {$SIGNOFF_REQUIRE_CLEAN} {
        error "PrimeTime signoff has constraint violations: setup=$setup_constraint_count hold=$hold_constraint_count; see pt.constraints.*.rpt"
    }
    puts "Warning: PrimeTime constraint violations remain; SIGNOFF_REQUIRE_CLEAN=0 permits report-only completion"
}

if {[info exists env(FC_AUTO_EXIT)]} { exit }
