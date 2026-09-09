puts "Start run vc_static_cdc, [date]"

source -e -v $env(ROOT_PATH)/scripts/utilities/project_context.tcl

set REPORTS_DIR "${run_path}/reports/cdc"
file mkdir ${REPORTS_DIR}
set search_path  ". ${ADDITIONAL_SEARCH_PATH} $search_path"
set_app_var link_library [concat $link_library $ADDITIONAL_LINK_LIB_FILES ]
set_app_var enable_cdc                           true
set_app_var case_analysis_sequential_propagation true
set design $DESIGN_NAME
set define_list [concat $DEFINE_LIST]
analyze -verbose -define $define_list -format sverilog -vcs $RTL_SOURCE_SVFILES
elaborate $DESIGN_NAME
read_sdc ${run_path}/inputs/${DESIGN_NAME}.sdc
infer_setup -type reset -incremental -sync_resets true
write_inferred_setup -file inferred_cdc_reset.sdc -type reset
read_sdc inferred_cdc_reset.sdc
check_cdc -type setup
check_cdc -type sync
check_cdc -type struct
report_cdc -verbose -limit 0 -file $REPORTS_DIR/${DESIGN_NAME}_vc_cdc_verbose.rpt
report_cdc -list    -limit 0 -file $REPORTS_DIR/${DESIGN_NAME}_vc_cdc_simple.rpt
report_cdc -list    -limit 0 -severity error    -file $REPORTS_DIR/${DESIGN_NAME}_vc_cdc_error.rpt
report_cdc -list    -limit 0 -severity warning  -file $REPORTS_DIR/${DESIGN_NAME}_vc_cdc_warning.rpt
checkpoint_session -incremental -session ${run_path}/results/check_cdc_${DESIGN_NAME}
if {$EXIT_STATUS == 1} {
   exit
} else {
   start_gui -dock
}
