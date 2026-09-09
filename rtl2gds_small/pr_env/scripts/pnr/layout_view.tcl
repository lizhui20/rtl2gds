puts "RM-Info: \[date\] Running layout_view.tcl"
source $env(ROOT_PATH)/scripts/pnr/layout_context.tcl

open_lib $DESIGN_LIBRARY
open_block ${PNR_LIB_NAME}:${DESIGN_NAME}/chip_finish
link_block

file mkdir $REPORTS_DIR

redirect -file ${REPORTS_DIR}/fc_drc.rpt {
    check_routes -drc true -open_net true -antenna true
}
redirect -file ${REPORTS_DIR}/fc_lvs.rpt {
    check_lvs -checks all -open_reporting detailed -report_floating_pins true \
        -ignore_filler_cells true
}

puts "RM-Info: built-in DRC report : ${REPORTS_DIR}/fc_drc.rpt"
puts "RM-Info: built-in LVS report : ${REPORTS_DIR}/fc_lvs.rpt"
puts "RM-Info: launching GUI -- open the Error Browser to cross-probe DRC/LVS markers."

gui_start
