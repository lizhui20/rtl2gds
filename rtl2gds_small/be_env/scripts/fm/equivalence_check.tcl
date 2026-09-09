puts "Start run Formality Verification, [date]"

source -e -v $env(ROOT_PATH)/scripts/utilities/project_context.tcl

set REPORTS_DIR "${run_path}/reports/fm"
set RESULTS_DIR "${run_path}/results"

file mkdir ${REPORTS_DIR}
source -e -v ${root_path}/scripts/fc_syn/output_names.tcl


set verification_failing_point_limit 0
set_host_options -max_cores 8
set_app_var synopsys_auto_setup true
set_app_var hdlin_ignore_parallel_case  false
set_app_var hdlin_ignore_full_case  false
set_app_var name_match_allow_subset_match true
set_app_var svf_ignore_unqualified_fsm_information false
set_app_var signature_analysis_match_compare_points true
set_app_var verification_verify_unread_compare_points false
set_app_var verification_datapath_effort_level high
set_app_var verification_inversion_push true
if {[info exists env(FM_UNDRIVEN_SIGNALS)] && $env(FM_UNDRIVEN_SIGNALS) ne ""} {
    set_app_var verification_set_undriven_signals $env(FM_UNDRIVEN_SIGNALS)
} else {
    set_app_var verification_set_undriven_signals synthesis
}
set_app_var verification_clock_gate_hold_mode none
set_app_var verification_clock_gate_edge_analysis true
set_app_var verification_clock_gate_reverse_gating true
set_app_var hdlin_dwroot [file dirname [file dirname [file normalize $env(FC_TOOL)]]]
set_app_var hdlin_unresolved_modules error
set_app_var upf_use_additional_db_attributes true
set_app_var search_path [concat $search_path ". $ADDITIONAL_SEARCH_PATH"]
if {[file exists ${RESULTS_DIR}/${DCRM_SVF_OUTPUT_FILE}]} {
    set_svf ${RESULTS_DIR}/${DCRM_SVF_OUTPUT_FILE}
} else {
    puts "RM-Warning: Can not find SVF file,please check!"
}
foreach tech_lib "${ADDITIONAL_LINK_LIB_FILES}" {
  read_db -technology_library $tech_lib
}
set define_list [concat $DEFINE_LIST]
read_sverilog -r ${RTL_SOURCE_SVFILES} -work_library WORK -define $define_list
set_top r:/WORK/${DESIGN_NAME}
set netlist_list ""
lappend netlist_list ${RESULTS_DIR}/${DCRM_FINAL_VERILOG_OUTPUT_FILE}
read_verilog -i ${netlist_list}
set_top i:/WORK/${DESIGN_NAME}
match
write_register_mapping -replace -rtlname -bbpin -port -prime_power ${RESULTS_DIR}/${DESIGN_NAME}_mapping_name.tcl
report_unmatched_points > ${REPORTS_DIR}/${FMRM_UNMATCHED_POINTS_REPORT}
set_dont_verify -directly_undriven_output
set verification_passed [verify]
save_session -replace ${RESULTS_DIR}/${FMRM_FAILING_SESSION_NAME}
report_failing_points > ${REPORTS_DIR}/${FMRM_FAILING_POINTS_REPORT}
report_aborted > ${REPORTS_DIR}/${FMRM_ABORTED_POINTS_REPORT}
analyze_points -all > ${REPORTS_DIR}/${FMRM_ANALYZE_POINTS_REPORT}
if {!$verification_passed} {
    puts "Error: RTL-to-synthesis equivalence verification failed"
    exit 1
}
if {$EXIT_STATUS == 1} {
    exit
}
