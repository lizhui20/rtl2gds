set REPORTS_DIR                                 "${run_path}/reports/fc"
set RESULTS_DIR                                 "${run_path}/results"
set main_inputs_dir                             "${run_path}/inputs"

file mkdir                                      $REPORTS_DIR
set SET_HOST_OPTIONS_MAX_CORE		            16
set DESIGN_LIBRARY 	                            "${run_path}/results/${DESIGN_NAME}.ndm"
set ref_lib_format 		                        "ndm"


if {[info exists LVTH_PERCENT]} {
    set percent_value $LVTH_PERCENT
} else {
    set percent_value 20.0
}
set low_vt_percentage $percent_value


rm_source -file ${TCL_FC_SYN_PROCEDURE}
if {[info exists PDK_NDM_LIST]} {
    set NDM_LIST $PDK_NDM_LIST
}

set ADDITIONAL_SEARCH_PATH [concat ${run_path}/inputs/ ${run_path}/ref ${run_path}/tech  $ADDITIONAL_SEARCH_PATH]

set search_path [concat $search_path "." $ADDITIONAL_SEARCH_PATH ${debug_path}/scripts ${root_path}/scripts]
set REFERENCE_LIBRARY $NDM_LIST



set std_placement_constraint_files ""
