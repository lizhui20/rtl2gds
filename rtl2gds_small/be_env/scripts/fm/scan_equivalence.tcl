source -e -v $env(ROOT_PATH)/scripts/utilities/project_context.tcl
set DESIGN_NAME $env(DESIGN_NAME)
set ROOT_PATH   $env(ROOT_PATH)
set run_path    ${ROOT_PATH}/${DESIGN_NAME}
set RESULTS_DIR ${run_path}/results
set reports     ${run_path}/reports/fm_dft
file mkdir $reports
source -e -v ${root_path}/scripts/fc_syn/output_names.tcl
set REF_NETLIST  ${RESULTS_DIR}/${DESIGN_NAME}.mapped.v
set IMP_NETLIST  ${RESULTS_DIR}/${DESIGN_NAME}.scan.v

set CELL_DBS $ADDITIONAL_LINK_LIB_FILES

set SCAN_ENABLE_PORT scan_en
set SCAN_OUT_PORT    test_so
set SCAN_OUT_EXCLUDED 0

foreach f [concat [list $REF_NETLIST $IMP_NETLIST] $CELL_DBS] {
    if {![file exists $f]} {
        puts "\[FM-DFT-FAIL\] missing input $f (run 'gmake run_dft_insert b=$DESIGN_NAME' first)"
        exit 1
    }
}
set_host_options -max_cores 8
set_app_var synopsys_auto_setup true

foreach cell_db $CELL_DBS { read_db -technology_library $cell_db }

read_verilog -container r -libname WORK $REF_NETLIST
set_top r:/WORK/$DESIGN_NAME

read_verilog -container i -libname WORK $IMP_NETLIST
set_top i:/WORK/$DESIGN_NAME

set_constant -type port i:/WORK/$DESIGN_NAME/$SCAN_ENABLE_PORT 0
set impl_scan_out [get_ports -quiet i:/WORK/$DESIGN_NAME/$SCAN_OUT_PORT]
set ref_scan_out  [get_ports -quiet r:/WORK/$DESIGN_NAME/$SCAN_OUT_PORT]
if {[sizeof_collection $impl_scan_out] > 0 && [sizeof_collection $ref_scan_out] == 0} {
    set_dont_verify_points $impl_scan_out
    set SCAN_OUT_EXCLUDED 1
}

match
redirect -file ${reports}/fm_dft.matched.rpt   { report_matched_points }
redirect -file ${reports}/fm_dft.unmatched.rpt { report_unmatched_points }

set verified [verify]
if {!$verified} {
    catch { redirect -file ${reports}/fm_dft.failing_points.rpt { report_failing_points } }
    save_session ${RESULTS_DIR}/${DESIGN_NAME}.fm_dft_fail
    puts "\[FM-DFT-FAIL\] scan-insertion equivalence failed; see ${reports}/fm_dft.failing_points.rpt"
    exit 1
}
redirect -file ${reports}/fm_dft.verify.rpt {
    puts "Verification SUCCEEDED -- DFT scan insertion is equivalent in functional mode."
    puts "Reference (pre-DFT) : $REF_NETLIST"
    puts "Implementation      : $IMP_NETLIST"
    puts "Setup               : $SCAN_ENABLE_PORT = 0, scan-out excluded = $SCAN_OUT_EXCLUDED"
}
if {$EXIT_STATUS == 1} {
    exit
}
