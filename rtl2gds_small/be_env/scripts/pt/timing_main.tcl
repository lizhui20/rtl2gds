puts "Information: Begin running PrimeTime, [date]"
source -e -v $env(ROOT_PATH)/scripts/utilities/project_context.tcl
set scripts_path "${root_path}/scripts/pt"
set REPORTS_DIR "${run_path}/reports/pt"
set RESULTS_DIR "${run_path}/results"
sh mkdir -p ${REPORTS_DIR}
rm_source -file ${TCL_PT_VARIABLE}
rm_source -file  ${scripts_path}/netlist_load.tcl
link_design $DESIGN_NAME

set PT_SDF_FILE "${netlist_path_syn}/${DESIGN_NAME}.mapped.sdf"
if {![file isfile $PT_SDF_FILE]} {
    error "Required synthesis SDF does not exist: $PT_SDF_FILE"
}
puts "RM-info: Reading synthesis SDF: $PT_SDF_FILE"
read_sdf $PT_SDF_FILE
redirect -file ${REPORTS_DIR}/${DESIGN_NAME}_report_annotated_delay.pt.rpt \
    {report_annotated_delay}
redirect -file ${REPORTS_DIR}/${DESIGN_NAME}_report_annotated_check.pt.rpt \
    {report_annotated_check}

source -e -v ${run_path}/inputs/${DESIGN_NAME}.sdc
rm_source -file ${TCL_PT_MAX_TRANSITION}
rm_source -file ${TCL_PT_CLOCK_UNCERTAINTY}
update_timing -full
write_sdc -nosplit ${REPORTS_DIR}/${DESIGN_NAME}_pt_export.sdc
save_session ${RESULTS_DIR}/${DESIGN_NAME}_${current_scenario_name}.pt.session
report_qor > ${REPORTS_DIR}/${DESIGN_NAME}_report_qor.pt.rpt

set_app_var extract_model_capacitance_limit 5.0
extract_model -output ${RESULTS_DIR}/${DESIGN_NAME} -format {lib}

if {$EXIT_STATUS == 1} { exit }
