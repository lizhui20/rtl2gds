if {[file exists ${main_inputs_dir}/${DESIGN_NAME}.ungroup.tcl]} {
    source -e -v ${main_inputs_dir}/${DESIGN_NAME}.ungroup.tcl
}
if {[info exists ungroup_hier_list]} {
    foreach hierarchy $ungroup_hier_list { 
        set_ungroup [get_cells -quiet -hier -filter "is_hierarchical&&full_name=~$hierarchy"] true
    }
}

if {[info exists keep_hier_list]} {
    foreach hierarchy $keep_hier_list { 
    set_ungroup [get_cells -quiet -hier -filter "is_hierarchical&&full_name=~$hierarchy"] false
   }
}

if {0} {
set no_mb_cells [list \
]

foreach no_mb_cell $no_mb_cells {
  echo "INFO: Removing multibit specification for $no_mb_cell cells"
  set_multibit_options -exclude [get_cells -hier -filter "is_sequential && full_name=~${no_mb_cell}*"]
}

set no_clk_gate_regs [get_cells -hier -filter "full_name=~u_vcpu*wptr*"]
set_clock_gating_objects -exclude $no_clk_gate_regs

set architectural_icgs [get_cells -hier -filter "full_name=~*HANDINST*&&ref_name=~PRE*"]
set_size_only $architectural_icgs
}
