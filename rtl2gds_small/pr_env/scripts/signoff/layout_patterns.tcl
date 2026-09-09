set DESIGN_NAME $env(DESIGN_NAME)
set ROOT_PATH   $env(ROOT_PATH)
set run_path    ${ROOT_PATH}/${DESIGN_NAME}
set results     ${run_path}/results/signoff
set reports     ${run_path}/reports/signoff
set TECH_DIR    ${run_path}/tech
set REF_DIR     ${run_path}/ref
file mkdir $results
file mkdir $reports

set PDK_DIR ${ROOT_PATH}/scripts/pdk
source ${PDK_DIR}/process_select.tcl
source ${ROOT_PATH}/scripts/utilities/layout_defaults.tcl
set design_user_setup_file ${run_path}/inputs/${DESIGN_NAME}.pr_user_setting.tcl
if {[file exists $design_user_setup_file]} {
    source $design_user_setup_file
}
source ${PDK_DIR}/process_${PDK_PROFILE}.tcl

set CELL_V      $PDK_ATPG_VERILOG
set PNR_V       ${run_path}/results/${DESIGN_NAME}.pnr.v
set SPF         ${results}/${DESIGN_NAME}.postlayout.spf

proc atpg_require_file {f what} {
    if {$f eq "" || ![file exists $f]} {
        puts "\[ATPG-ERROR] $what not found: $f"
        exit 1
    }
}

atpg_require_file $CELL_V "ATPG Verilog cell model"
atpg_require_file $PNR_V "PnR post-layout netlist"
atpg_require_file $SPF "PR generated post-layout SPF"

read_netlist $CELL_V -library
puts "\[info] reading PnR netlist: $PNR_V"
read_netlist $PNR_V
run_build_model $DESIGN_NAME

run_drc $SPF
redirect ${reports}/${DESIGN_NAME}.postlayout_tmax_rules_fail.rpt { report_rules -fail -verbose }

add_faults -all
set_atpg -abort_limit $ATPG_ABORT_LIMIT
run_atpg

redirect ${reports}/${DESIGN_NAME}.atpg_postlayout_summary.rpt { report_summaries }
redirect ${reports}/${DESIGN_NAME}.atpg_postlayout_faults_summary.rpt { report_faults -summary -all }
redirect ${reports}/${DESIGN_NAME}.atpg_postlayout_faults_profile.rpt { report_faults -profile -all }
redirect ${reports}/${DESIGN_NAME}.atpg_postlayout_faults_unsuccessful.rpt { report_faults -unsuccessful -verbose }
redirect ${reports}/${DESIGN_NAME}.atpg_postlayout_faults_unsuccessful_hierarchy.rpt { report_faults -unsuccessful -level 3 10 }
redirect ${reports}/${DESIGN_NAME}.atpg_postlayout_faults_au.rpt { report_faults -class AU -verbose }
redirect ${reports}/${DESIGN_NAME}.atpg_postlayout_faults_au_hierarchy.rpt { report_faults -class AU -level 3 10 }
redirect ${reports}/${DESIGN_NAME}.atpg_postlayout_faults_nd.rpt { report_faults -class ND -verbose }
redirect ${reports}/${DESIGN_NAME}.atpg_postlayout_faults_nd_hierarchy.rpt { report_faults -class ND -level 3 10 }
redirect ${reports}/${DESIGN_NAME}.atpg_postlayout_faults_ud.rpt { report_faults -class UD -verbose }
redirect ${reports}/${DESIGN_NAME}.atpg_postlayout_faults_ud_hierarchy.rpt { report_faults -class UD -level 3 10 }
write_patterns ${results}/${DESIGN_NAME}.postlayout.patterns.stil -format stil -replace

puts "\[info] post-layout SPF      : $SPF"
puts "\[info] post-layout patterns : ${results}/${DESIGN_NAME}.postlayout.patterns.stil"
puts "\[info] coverage summary     : ${reports}/${DESIGN_NAME}.atpg_postlayout_summary.rpt"
puts "\[info] fault detail reports : ${reports}/${DESIGN_NAME}.atpg_postlayout_faults_*.rpt"
puts "\[info] TestMAX post-layout ATPG: END"
if {[info exists env(FC_AUTO_EXIT)]} { exit }
