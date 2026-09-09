rm_source -file ${root_path}/scripts/fc_syn/synthesis_context.tcl

set FLOW_STEP       "pre_read_design"
rm_source -file ${root_path}/scripts/fc_syn/synthesis_options.tcl


if {[file exists $DESIGN_LIBRARY]} {
    file delete -force $DESIGN_LIBRARY
}

set create_lib_cmd "create_lib $DESIGN_LIBRARY"

if {[info exists PDK_PREFER_NDM_TECH] && $PDK_PREFER_NDM_TECH && [info exists TECH_LIB] && $TECH_LIB != ""} {
    lappend create_lib_cmd -use_technology_lib $TECH_LIB
} elseif {[file exists [which $TECH_FILE]]} {
    lappend create_lib_cmd -tech $TECH_FILE
} elseif {[info exists TECH_LIB] && $TECH_LIB != ""} {
    lappend create_lib_cmd -use_technology_lib $TECH_LIB
}

#if {[info exists DESIGN_LIBRARY_SCALE_FACTOR] && $DESIGN_LIBRARY_SCALE_FACTOR != ""} {
#    lappend create_lib_cmd -scale_factor $DESIGN_LIBRARY_SCALE_FACTOR
#}


if {[info exists LIBRARY_CONFIGURATION_FLOW] && $LIBRARY_CONFIGURATION_FLOW} {
    set link_library $LINK_LIBRARY
}

lappend create_lib_cmd -ref_libs $REFERENCE_LIBRARY
puts "RM-info: $create_lib_cmd"
eval ${create_lib_cmd}

set_svf             ${run_path}/results/${DESIGN_NAME}.mapped.svf
set_vsdc -replace   ${run_path}/results/${DESIGN_NAME}.mapped.vsdc


