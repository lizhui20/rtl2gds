set root_path   "$env(ROOT_PATH)"
set DESIGN_NAME "$env(DESIGN_NAME)"
set run_path    "$env(RUN_PATH)/${DESIGN_NAME}"

set debug_path $root_path
if {[info exists env(DEBUG_PATH)] && $env(DEBUG_PATH) ne ""} {
    set debug_path $env(DEBUG_PATH)
}



if {[info exists env(TO_SOC)]} {
    set TO_SOC $env(TO_SOC)
} else {
    set TO_SOC ""
    puts "Warning: you need define variable \$TO_SOC"
}


switch $DESIGN_NAME {
    default { 
    set HIERARCHICAL_DESIGNS   ""
    }
}
set HIERARCHICAL_CELLS         ""

source ${root_path}/scripts/utilities/source_loader.tcl
rm_source -file $root_path/scripts/utilities/script_paths.tcl
rm_source -file ${TCL_COMMON_DEBUG}
if {![info exists PREPARE_INPUTS] || !$PREPARE_INPUTS} {
    rm_source -file ${TCL_FC_SYN_PROCEDURE}
}
if {![info exists USER_SETTING_GENERATED]} { set USER_SETTING_GENERATED 0 }
set user_setting_file ${run_path}/inputs/${DESIGN_NAME}.user_setting.tcl
if {[info exists PREPARE_INPUTS] && $PREPARE_INPUTS} {
    file delete -force $user_setting_file
    sh cp ${root_path}/scripts/utilities/design_defaults.tcl $user_setting_file
    set USER_SETTING_GENERATED 1
} elseif {![file exists $user_setting_file]} {
    sh cp ${root_path}/scripts/utilities/design_defaults.tcl $user_setting_file
    set USER_SETTING_GENERATED 1
}
rm_source -file $user_setting_file
if {[info exists env(FC_AUTO_EXIT)] && $env(FC_AUTO_EXIT) eq "1"} {
    set EXIT_STATUS 1
}

set pdk_selector_file "${root_path}/scripts/pdk/process_select.tcl"
if {[file exists $pdk_selector_file]} {
    rm_source -file $pdk_selector_file
}

if {[info exists PDK_PROFILE] && $PDK_PROFILE ne ""} {
    set pdk_profile_file "${root_path}/scripts/pdk/process_${PDK_PROFILE}.tcl"
    if {![file exists $pdk_profile_file]} {
        puts "Error: PDK profile does not exist: $pdk_profile_file"
        set EXIT_STATUS 1
    } else {
        rm_source -file $pdk_profile_file
        puts "RM-info: Selected PDK profile '$PDK_PROFILE'"
    }
}
