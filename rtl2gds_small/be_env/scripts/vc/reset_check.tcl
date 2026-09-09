puts "Start run vc_static_rdc, [date]"

source -e -v $env(ROOT_PATH)/scripts/utilities/project_context.tcl

set REPORTS_DIR "${run_path}/reports/rdc"
file mkdir ${REPORTS_DIR}
set search_path  ". ${ADDITIONAL_SEARCH_PATH} $search_path"
set_app_var link_library [concat $link_library $ADDITIONAL_LINK_LIB_FILES ]
set_app_var enable_rdc true
set design $DESIGN_NAME
set define_list [concat $DEFINE_LIST]
analyze -verbose -define $define_list -format sverilog -vcs $RTL_SOURCE_SVFILES
elaborate $DESIGN_NAME
read_sdc ${run_path}/inputs/${DESIGN_NAME}.sdc
infer_setup -type clock -incremental
write_inferred_setup -file inferred_setup_clock.sdc -type clock
read_sdc inferred_setup_clock.sdc
infer_setup -type reset -incremental -sync_resets true
write_inferred_setup -file inferred_setup_reset.sdc -type reset
read_sdc inferred_setup_reset.sdc
configure_rdc_nff_sync -enable
configure_rdc_corrupt -report_rdc_on_cdc true
redirect -file $REPORTS_DIR/${DESIGN_NAME}_vc_rdc_setup.rpt {
    check_rdc -type setup
}
redirect -file $REPORTS_DIR/${DESIGN_NAME}_vc_rdc_corrupt.rpt {
    check_rdc -type corruption
}
report_rdc -verbose -limit 0 -file $REPORTS_DIR/${DESIGN_NAME}_vc_rdc_verbose.rpt
report_rdc -list -limit 0 -file $REPORTS_DIR/${DESIGN_NAME}_vc_rdc_simple.rpt
report_rdc -list -limit 0 -severity error -file $REPORTS_DIR/${DESIGN_NAME}_vc_rdc_error.rpt
report_rdc -list -limit 0 -severity warning -file $REPORTS_DIR/${DESIGN_NAME}_vc_rdc_warning.rpt
checkpoint_session -incremental -session  ${run_path}/results/check_rdc_${DESIGN_NAME}
if {$EXIT_STATUS == 1} {
   exit
} else {
   start_gui -dock
}
