puts "RM-Info: [date] Running script [info script]\n"

rm_source -file ${FC_SYN_PROCS_FC}

rm_source -file ${TCL_FC_SYN_SETUP}
rm_source -file ${TCL_DC_SYN_SETUP_FILENAMES}


set define_list $DEFINE_LIST 

analyze -define $define_list -format sverilog ${RTL_SOURCE_SVFILES}
elaborate ${DESIGN_NAME}
set_top_module ${DESIGN_NAME}

if {[file exists [which ${TCL_FC_CHANGE_VIEW}]]} {
    rm_source -file ${TCL_FC_CHANGE_VIEW}
}

set FLOW_STEP "post_read_design"
rm_source -file  ${TCL_FC_SYN_SETTINGS}

write_verilog  -exclude {scalar_wire_declarations leaf_module_declarations pg_objects end_cap_cells well_tap_cells \
    filler_cells pad_spacer_cells physical_only_cells cover_cells diode_cells} -hierarchy all ${run_path}/results/${DESIGN_NAME}.fc.unmapped.v

#rename_module ${DESIGN_NAME_PARAM} ${DESIGN_NAME}
uniquify -force


save_block -as ${DESIGN_NAME}/elaborated

saif_map -start


puts "RM-Info: [date] Completed script [info script]"
