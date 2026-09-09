puts "RM-Info: \[date\] Running floorplan_build.tcl"
file delete -force [file join $env(ROOT_PATH) $env(DESIGN_NAME) results $env(DESIGN_NAME).pnr.svf]
source $env(ROOT_PATH)/scripts/pnr/layout_context.tcl

if {[file exists $DESIGN_LIBRARY]} { file delete -force $DESIGN_LIBRARY }
create_lib $DESIGN_LIBRARY -tech $TECH_FILE -ref_libs $REFERENCE_LIBS
if {[sizeof_collection [get_site_defs -quiet $SITE_NAME]] == 0} {
    puts "RM-info: creating placement site '$SITE_NAME' in PnR technology"
    create_site_def -name $SITE_NAME -width $SITE_WIDTH -height $SITE_HEIGHT \
        -type core -symmetry $SITE_SYMMETRY
}

if {![file exists $DFT_NETLIST]} {
    error "DFT scan netlist not found: $DFT_NETLIST\n  Generate it with 'gmake run_dft_insert b=${DESIGN_NAME}' in be_env, then re-run."
}
puts "RM-Info: importing DFT scan netlist $DFT_NETLIST"
read_verilog -library $DESIGN_LIBRARY -design ${DESIGN_NAME}/floorplan \
    -top $DESIGN_NAME $DFT_NETLIST
open_lib $DESIGN_LIBRARY

current_block ${DESIGN_NAME}/floorplan
link_block
pnr_apply_implementation_controls

if {![file exists $SCAN_DEF]} {
    error "Scan DEF not found: $SCAN_DEF\n  Generate it with 'gmake run_dft_insert b=${DESIGN_NAME}' in be_env, then re-run."
}
puts "RM-Info: reading scan DEF $SCAN_DEF"
read_def $SCAN_DEF

pnr_read_parasitic_tech
pnr_setup_mcmm

set_ignored_layers -min_routing_layer $MIN_ROUTE_LAYER -max_routing_layer $MAX_ROUTE_LAYER

initialize_floorplan \
    -core_utilization $CORE_UTILIZATION \
    -side_ratio       {1 1} \
    -core_offset      $FLOORPLAN_CORE_OFFSET \
    -site_def         $SITE_NAME

if {$ENABLE_IO_PLACEMENT} {
    if {$IO_PLACEMENT_FILE ne ""} {
        if {![file exists $IO_PLACEMENT_FILE]} {
            error "ENABLE_IO_PLACEMENT=1 but IO_PLACEMENT_FILE does not exist: $IO_PLACEMENT_FILE"
        }
        puts "RM-Info: sourcing IO placement file $IO_PLACEMENT_FILE"
        source $IO_PLACEMENT_FILE
    } else {
        puts "RM-Info: ENABLE_IO_PLACEMENT=1; using flow-generated automatic block pin placement"
        set_block_pin_constraints -self -allowed_layers $PIN_LAYERS
        place_pins -self
    }
} else {
    puts "RM-Info: ENABLE_IO_PLACEMENT=0; using automatic block pin placement"
    set_block_pin_constraints -self -allowed_layers $PIN_LAYERS
    place_pins -self
}
redirect -file ${REPORTS_DIR}/floorplan.check_pin_placement.rpt \
    {check_pin_placement -self}

if {[get_nets -quiet $PG_POWER_NET]  eq ""} { create_net -power  $PG_POWER_NET }
if {[get_nets -quiet $PG_GROUND_NET] eq ""} { create_net -ground $PG_GROUND_NET }
connect_pg_net -automatic

report_design                 > ${REPORTS_DIR}/floorplan.report_design.rpt
redirect -file ${REPORTS_DIR}/floorplan.report_utilization.rpt {report_utilization}

save_block -as ${DESIGN_NAME}/floorplan
save_lib

puts "RM-Info: \[date\] Completed floorplan_build.tcl"
if {[info exists env(FC_AUTO_EXIT)]} { exit }
