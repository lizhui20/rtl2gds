puts "Information: Begin running GCA, [date]"
source -e -v $env(ROOT_PATH)/scripts/utilities/project_context.tcl
set scripts_path "${root_path}/scripts/pt"
set REPORTS_DIR "${run_path}/reports/gca"
set RESULTS_DIR "${run_path}/results"
file mkdir ${REPORTS_DIR}
set_app_var search_path [concat $search_path ${run_path}/ref]
set_app_var link_library [concat "*" $PDK_TIMING_DBS]
source -e -v ${scripts_path}/netlist_load.tcl
link_design $DESIGN_NAME
read_sdc ${run_path}/inputs/${DESIGN_NAME}.sdc
analyze_design -verbose
save_session ${RESULTS_DIR}/${DESIGN_NAME}.gca.session
if {$EXIT_STATUS == 1} { exit }
