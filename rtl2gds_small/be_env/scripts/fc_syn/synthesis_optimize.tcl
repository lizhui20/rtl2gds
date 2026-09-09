puts "RM-Info: [date] Running script [info script]\n"

#set_early_data_check_policy -policy none -if_not_exist

if {![info exists PDK_PVT_CORNER] || $PDK_PVT_CORNER eq ""} {
    error "Selected PDK must define PDK_PVT_CORNER"
}
set COMPILE_ACTIVE_SCENARIO_LIST "func::${PDK_PVT_CORNER}"
if {$COMPILE_ACTIVE_SCENARIO_LIST != ""} {
	set_scenario_status -active false [get_scenarios -filter active]
	set_scenario_status -active true $COMPILE_ACTIVE_SCENARIO_LIST
}

if {[sizeof_collection [get_scenarios -filter "hold && active"]] == 0} {
	puts "RM-warning: No active hold scenario is found. Recommended to enable hold scenarios here such that CCD skewing can consider them." 
	puts "RM-info: Please activate hold scenarios for compile_fusion if they are available." 
}

#rm_source -file ${root_path}/scripts/fc_syn/non_persistent_script.tcl

if {[info exists EN_FC_AUTO_BOUNDARY_OPT] && $EN_FC_AUTO_BOUNDARY_OPT == 1} {
    set_boundary_optimization [get_modules] auto
} elseif {[info exists EN_FC_AUTO_BOUNDARY_OPT] && $EN_FC_AUTO_BOUNDARY_OPT == 0} {
    set_boundary_optimization [get_modules] none
}

set FLOW_STEP "compile_design"
rm_source -file  ${TCL_FC_SYN_SETTINGS}

set SET_QOR_STRATEGY_METRIC "timing"
set set_qor_strategy_cmd "set_qor_strategy -stage synthesis -metric \"${SET_QOR_STRATEGY_METRIC}\""
lappend set_qor_strategy_cmd -high_effort_timing

puts "RM-info: Running $set_qor_strategy_cmd" 
eval ${set_qor_strategy_cmd}


set set_stage_cmd "set_stage -step synthesis"
puts "RM-info: Running ${set_stage_cmd}"
eval ${set_stage_cmd}


rm_source -file ${root_path}/scripts/fc_syn/synthesis_controls.tcl

if {$max_routing_layer != ""} {set_ignored_layers -max_routing_layer $max_routing_layer}
if {$min_routing_layer != ""} {set_ignored_layers -min_routing_layer $min_routing_layer}

if {$SET_QOR_STRATEGY_METRIC == "leakage_power"} {
   set rm_dynamic_scenarios [get_object_name [get_scenarios -filter active==true&&dynamic_power==true]]

   if {[llength $rm_dynamic_scenarios] > 0} {
      puts "RM-info: Disabling dynamic analysis for $rm_dynamic_scenarios"
      set_scenario_status -dynamic_power false [get_scenarios $rm_dynamic_scenarios]
  }
}


#set_timing_paths_disabled_blocks -all_sub_blocks

rm_source -file ${root_path}/scripts/fc_syn/cell_usage.tcl

#if {$SAIF_FILE_LIST != ""} {
#	if {$SAIF_FILE_POWER_SCENARIO != ""} {
#		set read_saif_cmd "read_saif \"$SAIF_FILE_LIST\" -scenarios \"$SAIF_FILE_POWER_SCENARIO\""
#	} else {
#		set read_saif_cmd "read_saif \"$SAIF_FILE_LIST\""
#	}
#	if {$SAIF_FILE_SOURCE_INSTANCE != ""} {lappend read_saif_cmd -strip_path $SAIF_FILE_SOURCE_INSTANCE}
#	if {$SAIF_FILE_TARGET_INSTANCE != ""} {lappend read_saif_cmd -path $SAIF_FILE_TARGET_INSTANCE}
#	puts "RM-info: Running $read_saif_cmd"
#    	eval ${read_saif_cmd}
#}

if {0} {
	rm_source -file $TCL_VIA_LADDER_DEFINITION_FILE -optional -print "TCL_VIA_LADDER_DEFINITION_FILE"
	rm_source -file $TCL_SET_VIA_LADDER_CANDIDATE_FILE -optional -print "TCL_SET_VIA_LADDER_CANDIDATE_FILE"
}







# set_app_options -name opt.common.consider_port_direction -value true

puts "RM-info: Setting dft.insertion_post_logic_opto to true for in_compile DFT flow"
#set_app_options -name dft.insertion_post_logic_opto -value true
set_app_options -name dft.insertion_post_logic_opto -value false
#rm_source -file $TCL_DFT_PRE_IN_COMPILE_SETUP_FILE -optional -print "TCL_DFT_PRE_IN_COMPILE_SETUP_FILE"

# puts "RM-info: Running create_mv_cells"
# create_mv_cells -verbose

#puts "RM-info: Running compile_fusion -check_only"
#compile_fusion -check_only

redirect -tee -file ${REPORTS_DIR}/${DESIGN_NAME}.report_app_options.start.rpt {report_app_options -non_default *}
redirect -file ${REPORTS_DIR}/${DESIGN_NAME}.report_lib_cell_purpose.rpt {report_lib_cell -objects [get_lib_cells] -column {full_name:20 valid_purposes}}
redirect -file ${REPORTS_DIR}/${DESIGN_NAME}.report_activity.driver.start.rpt {report_activity -driver}

#redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.check_variants.start {check_variants -dont_use -included_purposes}

set check_stage_settings_cmd "check_stage_settings -stage synthesis -metric \"${SET_QOR_STRATEGY_METRIC}\" -step synthesis"
lappend check_stage_settings_cmd -high_effort_timing
if {[info exists RESET_CHECK_STAGE_SETTINGS] && $RESET_CHECK_STAGE_SETTINGS} {
    lappend check_stage_settings_cmd -reset_app_options
}

redirect -file ${REPORTS_DIR}/${DESIGN_NAME}.check_stage_settings.rpt {eval ${check_stage_settings_cmd}}


puts "RM-info: Marking clock network as ideal"
set currentMode [current_mode]
foreach_in_collection mode [all_modes] {
    current_mode $mode
    set clock_tree [remove_from_collection [all_fanout -flat -clock_tree] [all_registers -clock_pins]]
    if { [sizeof_collection $clock_tree] > 0 } {
        set_ideal_network $clock_tree
        remove_propagated_clock [get_pins -hierarchical]
        remove_propagated_clock [get_ports]
        remove_propagated_clock [all_clocks]
    }
}
current_mode $currentMode

# set_optimize_registers -modules [get_modules ...]

rm_source -file ${root_path}/scripts/fc_syn/cell_thresholds.tcl -optional -print "source set_vt_percentage.tcl"
#set_app_options -name compile.auto_floorplan.enable -value false

if {[info exists PDK_USE_AUTO_FLOORPLAN] && $PDK_USE_AUTO_FLOORPLAN} {
    if {[info exists PDK_SITE_NAME] && $PDK_SITE_NAME ne ""} {
        set _site [get_site_defs -quiet $PDK_SITE_NAME]
        if {[sizeof_collection $_site] == 0 &&
            [info exists PDK_SITE_WIDTH] && [info exists PDK_SITE_HEIGHT]} {
            set _site_symmetry {}
            if {[info exists PDK_SITE_SYMMETRY]} {
                set _site_symmetry $PDK_SITE_SYMMETRY
            }
            puts "RM-info: creating placement site '$PDK_SITE_NAME' in design technology"
            set _site [create_site_def -name $PDK_SITE_NAME \
                -width $PDK_SITE_WIDTH -height $PDK_SITE_HEIGHT \
                -type core -symmetry $_site_symmetry -is_default]
            set _site [get_site_defs -quiet $PDK_SITE_NAME]
        }
        if {[sizeof_collection $_site] > 0} {
            puts "RM-info: default placement site = $PDK_SITE_NAME"
        } else {
            puts "RM-warning: site '$PDK_SITE_NAME' not found in libraries."
        }
    }
    set_app_options -name compile.auto_floorplan.initialize -value true
    set_auto_floorplan_constraints -core_utilization 0.60 -side_ratio {1 1} -core_offset {2 2}
    set_app_options -name compile.auto_floorplan.place_pins -value all
    create_block_pin_constraint -allowed_layers [get_layers $PDK_PIN_LAYERS] -pin_spacing_track_count 1 -stacking_type none
}

set tmp_pb [get_placement_blockages -quiet *]
if {$tmp_pb != ""} {
    remove_placement_blockages *
}
set tmp_rb [get_routing_blockages -quiet *]
if {$tmp_rb != ""} {
    remove_routing_blockages *
}

set compile_cmd "compile_fusion -from initial_map -to initial_map"

puts "RM-info: Running ${compile_cmd} [date]"
eval ${compile_cmd}
save_block
save_block -as ${DESIGN_NAME}/initial_map

set compile_cmd "compile_fusion -from logic_opto -to logic_opto"
puts "RM-info: Running ${compile_cmd} [date]"
eval ${compile_cmd}
if {[info exists PDK_USE_AUTO_FLOORPLAN] && $PDK_USE_AUTO_FLOORPLAN} {
    place_pins -self
    redirect -file ${REPORTS_DIR}/${DESIGN_NAME}.check_pin_placement.rpt {
        check_pin_placement -self -pin_type SIGNAL_PINS -sides true -order true \
            -pin_spacing true -technology_spacing_rules true -wire_track true
    }
}
save_block
save_block -as ${DESIGN_NAME}/logic_opto

set write_verilog_logic_opto_cmd "write_verilog  -exclude {scalar_wire_declarations leaf_module_declarations pg_objects end_cap_cells well_tap_cells filler_cells pad_spacer_cells physical_only_cells cover_cells diode_cells} -hierarchy all ${RESULTS_DIR}/${DESIGN_NAME}.logic_opto.v"
puts "RM-info: running $write_verilog_logic_opto_cmd"
eval $write_verilog_logic_opto_cmd

if {[info exists LOGIC_SYN] && $LOGIC_SYN == 1} {
    change_names -rules verilog -hierarchy -skip_physical_only_cells
    set_svf  -off
    set_vsdc -off
    return    
}

#if {[rm_source -file $TCL_DFT_SETUP_FILE -optional -print "TCL_DFT_SETUP_FILE"]} {
# 	puts "RM-info: Running create_test_protocol"
#    	create_test_protocol    
#    	redirect -tee ${REPORTS_DIR}/${REPORT_PREFIX}.initial_opto.pre-insert_dft.dft_drc {dft_drc -test_mode all_dft}
#    	redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.pre-insert_dft.report_dft { report_dft }
#    	if { !($DESIGN_STYLE == "hier" && $PHYSICAL_HIERARCHY_LEVEL == "bottom" || $PHYSICAL_HIERARCHY_LEVEL == "intermediate" ) } {
#		redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.preview_dft { preview_dft }
#		puts "RM-info: Running insert_dft"
#		if {$skip_insert_dft == "true"} {
#			echo "INFO: We may skip insert_dft if the netlist is pre-dft"
#		} else {
#			insert_dft
#		} 
#		save_block -as ${DESIGN_NAME}/${INSERT_DFT_BLOCK_NAME}
#    	}
#}

#if {$PREROUTE_CTS_PRIMARY_CORNER != ""} {
#	puts "RM-info: Setting cts.compile.primary_corner to $PREROUTE_CTS_PRIMARY_CORNER (tool default unspecified)"
#	set_app_options -name cts.compile.primary_corner -value $PREROUTE_CTS_PRIMARY_CORNER
#}

#redirect -file ${REPORTS_DIR}/${DESIGN_NAME}.report_routing_rules.rpt {report_routing_rules -verbose}
#redirect -file ${REPORTS_DIR}/${DESIGN_NAME}.report_clock_routing_rules.rpt {report_clock_routing_rules}
#redirect -file ${REPORTS_DIR}/${DESIGN_NAME}.report_clock_settings.rpt {report_clock_settings}

puts "RM-info: Running mark_clock_trees -routing_rules to model clock NDR impact during compile_fusion"
mark_clock_trees -routing_rules

set FLOW_STEP "compile_place_design"
rm_source -file ${root_path}/scripts/fc_syn/synthesis_options.tcl

if {![info exists PDK_SKIP_TRACK_SCRIPT] || !$PDK_SKIP_TRACK_SCRIPT} {
    if {$TCL_FC_SYN_MAKE_TRACK eq ""} {
        error "Track setup is enabled: set TRACK_SETUP_FILE or TCL_FC_SYN_MAKE_TRACK."
    }
    rm_source -file ${TCL_FC_SYN_MAKE_TRACK}
}

set compile_cmd "compile_fusion -from initial_place -to initial_opto"
puts "RM-info: Running ${compile_cmd}"
eval ${compile_cmd}
save_block
save_block -as ${DESIGN_NAME}/compile_initial_opto

#    redirect -tee $REPORTS_DIR/$COMPILE_BLOCK_NAME.initial_opto.$mode.dft_drc {dft_drc -test_mode $mode}
#    write_test_protocol -test_mode $mode -output $OUTPUTS_DIR/$COMPILE_BLOCK_NAME.initial_opto.$mode.spf
#}
#if {$CTS_STYLE == "MSCTS"} {
#	if {[rm_source -file $TCL_REGULAR_MSCTS_FILE]} {
#		set_app_options -name compile.flow.enable_multisource_clock_trees -value true
#                save_block -as ${DESIGN_NAME}/${COMPILE_BLOCK_NAME}_MSCTS
#	}
#} elseif {$CTS_STYLE != "standard"} {
#	puts "RM-error: Specified CTS_STYLE($CTS_STYLE) is not supported, standard will be used." 
#}
set set_stage_cmd "set_stage -step compile_place"
puts "RM-info: Running ${set_stage_cmd}"
eval ${set_stage_cmd}



set compile_cmd "compile_fusion -from final_place -to final_opto"
puts "RM-info: Running ${compile_cmd}"
eval ${compile_cmd}
save_block
save_block -as ${DESIGN_NAME}/compile_final_opto

if {[info exists FINAL_OPT_2ND] && $FINAL_OPT_2ND == 1} {
    puts "RM-info: Running 2ND ${compile_cmd}"
    eval ${compile_cmd}
    save_block
    save_block -as ${DESIGN_NAME}/compile_final_opto_2ND
}

change_names -rules verilog -hierarchy -skip_physical_only_cells

save_block
save_block -as ${DESIGN_NAME}/compile
save_block -as ${DESIGN_NAME}

set_svf  -off
set_vsdc -off

puts "RM-Info: [date] Completed script [info script]"
