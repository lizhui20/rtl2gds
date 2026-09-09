puts "RM-Info: [date] Running script [info script]\n"



set_message_info -id NDMUI-736 -limit 100

define_name_rules slash -restricted "/" -replacement_char "."
define_name_rules exclamation_rule -restricted "!" -replacement_char "_"
define_name_rules open_bracket -restricted "(" -replacement_char "_"
define_name_rules close_bracket -restricted ")" -replacement_char "_"

change_names -hier -rules slash
change_names -hier -rules exclamation_rule
change_names -hier -rules open_bracket
change_names -hier -rules close_bracket

define_name_rules standard_names -allow "A-Za-z0-9_\[\]\." -first_restricted "0-9" -equal_ports_nets -remove_internal_net_bus \
                                 -last_restricted "_" -target_bus_naming_style "\[\]" -add_dummy_nets -max_length 400 \
                                 -flatten_multi_dimension_busses -case_insensitive -collapse_name_space

define_name_rules standard_netnames -allow "A-Za-z0-9_\." -first_restricted "0-9" -equal_ports_nets -remove_internal_net_bus \
                                    -last_restricted "_" -target_bus_naming_style "\[\]" -add_dummy_nets -type net
                                    
define_name_rules reg_names -type cell -map {{{"\]",""},{"\[","_"}}}

change_names -hier -rules standard_names
change_names -hier -rules standard_netnames
change_names -hier -rules reg_names

define_name_rules verilog -equal_ports_nets -inout_ports_equal_nets

change_names -rules verilog -hierarchy


#if {$TECH_FILE != "" || ($TECH_LIB != "" && !$TECH_LIB_INCLUDES_TECH_SETUP_INFO)} {
#    rm_source -file $TCL_TECH_SETUP_FILE -optional -print "TCL_TECH_SETUP_FILE"
#}

set DEF_FLOORPLAN_FILES "${run_path}/inputs/${DESIGN_NAME}.def.gz"
if {![file exists $DEF_FLOORPLAN_FILES]} {
    set DEF_FLOORPLAN_FILES "${run_path}/inputs/${DESIGN_NAME}.def"
}
if {[file exists $DEF_FLOORPLAN_FILES]} {
    puts "RM-info: Reading floorplan DEF: $DEF_FLOORPLAN_FILES"
    read_def $DEF_FLOORPLAN_FILES
    redirect -var x {catch {resolve_pg_nets}}
    puts $x
    if {[regexp ".*NDMUI-096.*" $x]} {
        puts "RM-error: UPF may have an issue. Please review and correct it."
    }
} elseif {[info exists PDK_USE_AUTO_FLOORPLAN] && $PDK_USE_AUTO_FLOORPLAN} {
    puts "RM-info: No DEF supplied; auto-floorplan builds the floorplan during compile."
} else {
    puts "RM-info: No DEF supplied; creating a fallback block floorplan"
    set _fp_site [expr {([info exists PDK_SITE_NAME] && $PDK_SITE_NAME ne "") ? $PDK_SITE_NAME : "unit"}]
    if {[sizeof_collection [get_site_defs -quiet $_fp_site]] == 0 &&
        [info exists PDK_SITE_WIDTH] && [info exists PDK_SITE_HEIGHT]} {
        set _fp_site_symmetry {}
        if {[info exists PDK_SITE_SYMMETRY]} {
            set _fp_site_symmetry $PDK_SITE_SYMMETRY
        }
        create_site_def -name $_fp_site \
            -width $PDK_SITE_WIDTH -height $PDK_SITE_HEIGHT \
            -type core -symmetry $_fp_site_symmetry -is_default
    }
    initialize_floorplan -control_type core -shape R -side_length {320 320} -core_offset {10 10} -site_def $_fp_site
}

rm_source -file ${TCL_PARASITIC_SETUP_FILE} -optional -print "TCL_PARASITIC_SETUP_FILE"

rm_source -file ${TCL_FC_SYN_MCMM_SETUP}


set unc_per 0.10

set clks [get_clocks *]
if {[sizeof_collection $clks] > 0} {
    foreach_in_collection clk $clks {
        set per [get_attribute $clk period]
        if {$per > 5} {
           set_clock_uncertainty 0.5                -setup -from $clk -to $clk   
           set_clock_uncertainty [expr 0.005 + 0.0] -hold  -from $clk -to $clk 
        } else {
           set_clock_uncertainty [expr $per * $unc_per] -setup -from $clk -to $clk   
           set_clock_uncertainty [expr 0.005 + 0.0] -hold  -from $clk -to $clk 
        }        
    }
}  



set driving_cell "BUFFD4BWP7T40P140LVT"

set driving_cell [get_lib_cells */${driving_cell}]

if {[sizeof_collection $driving_cell] == 1} {
    set drv_cell [get_object_name $driving_cell]
    set lib      [lindex [split $drv_cell "/"] 0]
    set cell     [lindex [split $drv_cell "/"] 1]
    set_driving_cell -no_design_rule -lib_cell ${cell}  [all_inputs]
} else {
    set_input_transition 0.035 [all_inputs]
}

set_load -pin_load 0.01 [all_outputs]
if {[info exists MAX_TRANSITION]} {
    set max_tran $MAX_TRANSITION
} else {
    set max_tran 0.065
}
set_max_transition $max_tran [current_design]

set dont_touch_design_cells [get_cells -quiet -hier *CTECH_DONT_TOUCH]
if {[sizeof_collection $dont_touch_design_cells] > 0} {
#    set_dont_touch $dont_touch_design_cells true
}

#set size_only_design_cells  [get_cells -quiet -hier *CTECH_SIZE_ONLY]
#if {[sizeof_collection $size_only_design_cells] > 0} {
#    set_size_only -all_instances $size_only_design_cells true
#}

set_app_options -name design.high_fanout_net_threshold      -value  100
set_app_options -name time.high_fanout_net_pin_capacitance  -value  0.000001pF
foreach_in_collection net [all_high_transitive_fanout -nets -threshold 100] {
    set_ideal_network $net -no_propagate
}
if {[info exists MAX_ICG]} {
    set max_icg $MAX_ICG
} else {
    set max_icg 99999
}

if {![info exists ENABLE_CLOCK_GATING]} {
    set ENABLE_CLOCK_GATING 0
}
if {$ENABLE_CLOCK_GATING} {
    puts "INFO: ENABLE_CLOCK_GATING=1; synthesis clock gating enabled, MAX_ICG=$max_icg"
    set_clock_gating_options -minimum_bitwidth 5 -max_fanout $max_icg
    set_clock_gate_style -target { pos_edge_flip_flop neg_edge_flip_flop} -test_point before
} else {
    puts "INFO: ENABLE_CLOCK_GATING=0; synthesis clock gating disabled for DFT-clean default flow"
    set_clock_gating_options -minimum_bitwidth 1000000 -max_fanout 1000000
    set_clock_gating_objects -exclude [all_registers]
}


#rm_source -file $my_connect_pg_nets_file -optional -print "my_connect_pg_nets_file"
rm_source -file ${my_pvt_file} -optional -print "my_pvt_file"

set_app_options -name time.pocvm_enable_analysis -value true
reset_app_options time.aocvm_enable_analysis

set_app_options -name time.ocvm_enable_distance_analysis -value true

set_app_options -name time.enable_constraint_variation -value true
set_app_options -name time.enable_slew_variation -value true



#	group_path -name clk_gate_enable -weight 15
#	group_path -name xyz -weight 15
if {[file exists ${run_path}/inputs/${DESIGN_NAME}.group_path.tcl]} {
    rm_source -file ${run_path}/inputs/${DESIGN_NAME}.group_path.tcl
} else {
    rm_source -file ${my_regroup_file} -optional -print "INFO: sourcing my regroup file"
}

if {$std_placement_constraint_files != ""} {
	foreach file $std_placement_constraint_files {
	    rm_source -file $file
	}
} elseif {![info exists PDK_SKIP_PLACEMENT_RULES] || !$PDK_SKIP_PLACEMENT_RULES} {
	puts "RM-error : std_placement_constraint_files is required. Please correct it."
}

#remove_placement_spacing_rules -all

if {$min_routing_layer != "" && $max_routing_layer != ""} {
	if {[info exists PDK_FC_CONFIGURED] && $PDK_FC_CONFIGURED} {
	    set_ignored_layers -min_routing_layer $min_routing_layer -max_routing_layer $max_routing_layer
	} else {
	    set_ignored_layers -min_routing_layer $min_routing_layer -max_routing_layer $max_routing_layer -rc_congestion_ignored_layers { AP }
	}
} else {
    echo "INFO: We do not set routing layers allowed for the design. All layers can be used while routing"
}

#rm_source -file $TCL_USER_INIT_DESIGN_POST_SCRIPT -optional -print "TCL_USER_INIT_DESIGN_POST_SCRIPT"

save_block
save_block -as ${DESIGN_NAME}/init_design
save_block -as ${DESIGN_NAME}

puts "RM-Info: [date] Completed script [info script]"
