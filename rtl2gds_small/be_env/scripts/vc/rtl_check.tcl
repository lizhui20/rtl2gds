puts "Start run vc_static_lint, [date]"

source -e -v $env(ROOT_PATH)/scripts/utilities/project_context.tcl

set REPORTS_DIR "${run_path}/reports/lint"
file mkdir ${REPORTS_DIR}
set VC_PATH [file join $root_path scripts vc]
if {[info exists env(VC_PATH)] && $env(VC_PATH) ne ""} {
    set VC_PATH $env(VC_PATH)
}
set search_path  ". ${ADDITIONAL_SEARCH_PATH} $search_path"
set_app_var link_library [concat $link_library $ADDITIONAL_LINK_LIB_FILES ]
set_app_var enable_lint true
if {[file exists ${root_path}/scripts/vc/rtl_rules.tcl]} {
    source ${root_path}/scripts/vc/rtl_rules.tcl
}
set design $DESIGN_NAME
set define_list [concat $DEFINE_LIST]
if {[file exists $TO_SOC/waiver/${DESIGN_NAME}_bb.tcl]} {
    source $TO_SOC/waiver/${DESIGN_NAME}_bb.tcl
}
analyze -verbose -define $define_list -format sverilog -vcs $RTL_SOURCE_SVFILES
elaborate $DESIGN_NAME
check_lint
report_lint -verbose -limit 0 -file  $REPORTS_DIR/${DESIGN_NAME}_vc_lint_verbose.rpt
report_lint -list -limit 0 -file     $REPORTS_DIR/${DESIGN_NAME}_vc_lint_simple.rpt
report_lint -list -limit 0 -severity error -file   $REPORTS_DIR/${DESIGN_NAME}_vc_lint_error.rpt
report_lint -list -limit 0 -severity warning -file $REPORTS_DIR/${DESIGN_NAME}_vc_lint_warning.rpt
checkpoint_session -incremental -session ${run_path}/results/check_lint_${DESIGN_NAME}
if {$EXIT_STATUS == 1} {
   exit
} else {
   start_gui -dock
}
