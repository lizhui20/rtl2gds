set dft_target_db $PDK_DFT_TARGET_DB
if {[info exists VT_ALLOWED_GROUPS] &&
    [llength $VT_ALLOWED_GROUPS] > 0 &&
    [lsearch -exact $VT_ALLOWED_GROUPS all] < 0 &&
    [info exists PDK_DFT_TARGET_DB_BY_VT]} {
    set dft_target_db {}
    foreach vt $VT_ALLOWED_GROUPS {
        if {![dict exists $PDK_DFT_TARGET_DB_BY_VT $vt]} {
            error "Invalid VT_ALLOWED_GROUPS entry '$vt' for DFT. Valid groups are: [dict keys $PDK_DFT_TARGET_DB_BY_VT], or all"
        }
        set dft_target_db [concat $dft_target_db [dict get $PDK_DFT_TARGET_DB_BY_VT $vt]]
    }
    puts "\[DFT-INFO] VT_ALLOWED_GROUPS=$VT_ALLOWED_GROUPS; DFT target DB=$dft_target_db"
}
set TARGET_LIBRARY    $dft_target_db
set LINK_LIBRARY      $dft_target_db
set ATPG_VERILOG_LIBS $PDK_ATPG_VERILOG
set DFT_SEARCH_PATH   $PDK_DFT_SEARCH_PATH

if {![info exists INPUT_NETLIST]} { set INPUT_NETLIST "${RESULTS_DIR}/${DESIGN_NAME}.mapped.v" }

if {![info exists SCAN_CHAIN_COUNT]} { set SCAN_CHAIN_COUNT 1 }
if {![info exists SCAN_ENABLE_PORT]} { set SCAN_ENABLE_PORT "scan_en" }
if {![info exists TEST_MODE_PORT]}   { set TEST_MODE_PORT   "" }
if {![info exists DFT_CLOCK_MIXING]} { set DFT_CLOCK_MIXING "mix_edges" }
if {![info exists DFT_ADD_TEST_RETIMING_FLOPS]} { set DFT_ADD_TEST_RETIMING_FLOPS "none" }

if {![info exists DFT_CLOCKS]} { set DFT_CLOCKS {} }

if {![info exists DFT_RESETS]} { set DFT_RESETS {} }
if {![info exists DFT_INFER_ASYNCHRONOUS_CONTROLS]} { set DFT_INFER_ASYNCHRONOUS_CONTROLS 0 }

if {![info exists ATPG_ABORT_LIMIT]}     { set ATPG_ABORT_LIMIT     100 }
if {![info exists ATPG_PATTERN_FORMATS]} { set ATPG_PATTERN_FORMATS { stil } }
