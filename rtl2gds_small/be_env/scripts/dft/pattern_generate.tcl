source $env(ROOT_PATH)/scripts/dft/scan_context.tcl

puts "\[info] TestMAX ATPG: START  design=$DESIGN_NAME"

dft_require_file $SCAN_NETLIST  "Scan netlist (run 'gmake run_dft_insert' first)"
dft_require_file $SCAN_PROTOCOL "STIL protocol/SPF (run 'gmake run_dft_insert' first)"
if {$ATPG_VERILOG_LIBS eq ""} {
    puts "\[DFT-ERROR] ATPG_VERILOG_LIBS empty -- set Verilog cell models in scan_options.tcl"
    exit 1
}

foreach lib $ATPG_VERILOG_LIBS {
    set f $lib
    if {![file exists $f]} {
        foreach d $DFT_SEARCH_PATH { if {[file exists $d/$lib]} { set f $d/$lib; break } }
    }
    dft_require_file $f "ATPG Verilog library '$lib'"
    read_netlist $f -library
}

read_netlist $SCAN_NETLIST
run_build_model $DESIGN_NAME

run_drc $SCAN_PROTOCOL

add_faults -all
set_atpg -abort_limit $ATPG_ABORT_LIMIT
run_atpg

redirect ${REPORTS_DIR}/${DESIGN_NAME}.atpg_summary.rpt { report_summaries }
foreach fmt $ATPG_PATTERN_FORMATS {
    write_patterns ${RESULTS_DIR}/${DESIGN_NAME}.patterns.${fmt} -format $fmt -replace
}

puts "\[info] patterns written to $RESULTS_DIR (formats: $ATPG_PATTERN_FORMATS)"
puts "\[info] TestMAX ATPG: END"
exit
