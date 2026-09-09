set DESIGN_NAME  $env(DESIGN_NAME)
set ROOT_PATH    $env(ROOT_PATH)
set run_path     "$env(RUN_PATH)/${DESIGN_NAME}"

source -e -v ${ROOT_PATH}/scripts/utilities/project_context.tcl

set RESULTS_DIR  "${run_path}/results"
set REPORTS_DIR  "${run_path}/reports/dft"
set LOGS_DIR     "${run_path}/logs"
file mkdir $RESULTS_DIR
file mkdir $REPORTS_DIR

set SCAN_NETLIST  "${RESULTS_DIR}/${DESIGN_NAME}.scan.v"
set SCAN_PROTOCOL "${RESULTS_DIR}/${DESIGN_NAME}.spf"
set SCAN_DEF      "${RESULTS_DIR}/${DESIGN_NAME}.scandef"

source ${ROOT_PATH}/scripts/dft/scan_options.tcl

proc dft_require_file {f what} {
    if {$f eq "" || ![file exists $f]} {
        puts "\[DFT-ERROR] $what not found: '$f'"
        puts "\[DFT-ERROR] Set the correct path in scripts/dft/scan_options.tcl"
        exit 1
    }
}
