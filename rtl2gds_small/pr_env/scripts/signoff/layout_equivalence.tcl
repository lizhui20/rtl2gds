set DESIGN_NAME $env(DESIGN_NAME)
set ROOT_PATH   $env(ROOT_PATH)
set run_path    ${ROOT_PATH}/${DESIGN_NAME}
set reports     ${run_path}/reports/signoff
file mkdir $reports
set PDK_DIR  ${ROOT_PATH}/scripts/pdk
set TECH_DIR ${run_path}/tech
set REF_DIR  ${run_path}/ref
source ${PDK_DIR}/process_select.tcl
source ${PDK_DIR}/process_${PDK_PROFILE}.tcl

set REF_NETLIST  ${run_path}/inputs/${DESIGN_NAME}.scan.v
if {![file exists $REF_NETLIST]} {
    error "Reference scan netlist not found: $REF_NETLIST"
}
set IMP_NETLIST  ${run_path}/results/${DESIGN_NAME}.pnr.v

set_app_var synopsys_auto_setup true

set PNR_SVF ${run_path}/results/${DESIGN_NAME}.pnr.svf
if {[file exists $PNR_SVF]} {
    puts "Info: applying PnR setup guidance: $PNR_SVF"
    set_svf $PNR_SVF
}

foreach cell_db $FORMALITY_DB_FILES { read_db -container r $cell_db }
read_verilog -container r -libname WORK $REF_NETLIST
set_top r:/WORK/$DESIGN_NAME

foreach cell_db $FORMALITY_DB_FILES { read_db -container i $cell_db }
read_verilog -container i -libname WORK $IMP_NETLIST
set_top i:/WORK/$DESIGN_NAME

foreach c {r i} {
    if {[sizeof_collection [get_ports -quiet ${c}:/WORK/$DESIGN_NAME/scan_en]]} {
        set_constant ${c}:/WORK/$DESIGN_NAME/scan_en 0
    }
}

foreach c {r i} {
    set scan_out_ports [get_ports -quiet ${c}:/WORK/$DESIGN_NAME/test_so*]
    if {[sizeof_collection $scan_out_ports] > 0} {
        set_dont_verify_points $scan_out_ports
    }
}

redirect -file ${reports}/fm.setup.rpt { report_setup_status }
match
redirect -file ${reports}/fm.match.rpt { report_matched_points }
set verified [verify]
if {!$verified} {
    catch { redirect -file ${reports}/fm.failing_points.rpt { report_failing_points } }
    save_session ${run_path}/results/signoff/${DESIGN_NAME}.fm_fail
    error "Formality verification failed; see $reports/fm.verify.rpt"
}
redirect -file ${reports}/fm.verify.rpt {
    puts "Verification SUCCEEDED"
    puts "Reference: $REF_NETLIST"
    puts "Implementation: $IMP_NETLIST"
}
if {[info exists env(FC_AUTO_EXIT)]} { quit }
