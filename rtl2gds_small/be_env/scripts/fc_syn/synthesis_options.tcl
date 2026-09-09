switch ${FLOW_STEP} {
    pre_read_design {
        puts "RM_INFO:pre_read_design --> set_app_options..."
        set_app_options -name hdlin.naming.upf_compatible           -value true
        set_app_options -name hdlin.report.check_no_latch           -value true
        set_app_options -name hdlin.naming.template_naming_style    -value "%s"
        set_app_options -name hdlin.naming.template_parameter_style -value ""
        set_app_options -name hdlin.naming.template_separator_style -value ""
        set_app_options -name hdlin.naming.shorten_long_module_name -value true
        set_app_options -name hdlin.naming.module_name_limit        -value 64
        set_app_options -name hdlin.dcrt_infer_bus_wide_gate        -value true
        
        # set_app_options -name hdlin.elaborate.ff_infer_async_set_reset -value true
        # set_app_options -name hdlin.elaborate.ff_infer_sync_set_reset  -value false
        
        
        
        set_host_options -max_cores ${SET_HOST_OPTIONS_MAX_CORE}
        
        set_app_options -name lib.configuration.icc_shell_exec -value ""
        set_app_options -name link.error_on_net_port_width_mismatch -value true
        set_app_options -name link.do_bus_width_mismatch -value true
        set sh_continue_on_error false
        if {[info exists DIRTY_LINK] && $DIRTY_LINK == 1} {
            set_current_mismatch_config auto_fix
        }
    }
    post_read_design {
        puts "RM_INFO:post_read_design --> set_app_options..."
        if {[info exists PDK_SET_TECHNOLOGY_NODE] && $PDK_SET_TECHNOLOGY_NODE ne ""} {
            set_technology -node $PDK_SET_TECHNOLOGY_NODE
        }
        set_app_options -name place.legalize.filler_lib_cells -value [get_attribute [get_lib_cells {*/*FILL* */*DCAP*}] name]
        if {[sizeof_collection [get_flat_pins -quiet -of_objects [get_flat_cells -quiet -filter "design_type==macro"] -filter "layer_name==M1"]] > 0} {
            set m1_macro_pins [get_flat_pins -quiet -of_objects [get_flat_cells -quiet -filter "design_type==macro"] -filter "layer_name==M1"]
            set_attribute -objects [get_terminals -of_objects $m1_macro_pins] -name port.connect_within_pin -value via_wire
            set_app_options -name route.common.derive_connect_within_pin_via_region -value true
        }
        
        set_app_options -name time.remove_clock_reconvergence_pessimism         -value true
        set_app_options -name time.enable_clock_to_data_analysis                -value true
        set_app_options -name time.si_enable_analysis                           -value true
        set_app_options -name opt.port.eliminate_verilog_assign                 -value true
        set_app_options -name opt.common.allow_physical_feedthrough             -value true
        set_app_options -name opt.area.effort                                   -value high
        set_app_options -name opt.common.buffer_area_effort                     -value ultra
        set_app_options -name opt.power.effort                                  -value high
        set_app_options -name opt.timing.effort                                 -value high
        set_app_options -name compile.flow.scenario_optimization                -value false
        set_app_options -name place.coarse.continue_on_missing_scandef          -value true
        set_app_options -name place.coarse.pin_density_aware                    -value false
        set_app_options -name place.legalize.enable_variant_aware               -value true
        set_app_options -name place.legalize.advanced_legalizer_effort          -value high
        set_app_options -name place_opt.final_place.effort                      -value high
        set_app_options -name place_opt.initial_place.effort                    -value high
        set_app_options -name place_opt.congestion.effort                       -value high
        set_app_options -name place_opt.flow.estimate_clock_gate_latency        -value false
        set_app_options -name opt.common.estimate_clock_gate_latency            -value false
        set_app_options -name refine_opt.flow.estimate_clock_gate_latency       -value false
        set_app_options -name compile.clockgate.use_clock_latency               -value false
        set_app_options -name place.coarse.congestion_layer_aware               -value false
        set_app_options -name time.disable_recovery_removal_checks              -value true 
        set_app_options -name refine_opt.place.effort                           -value high
        set_app_options -name refine_opt.congestion.effort                      -value high
        set_app_options -name cts.compile.enable_global_route                   -value true
        set_app_options -name place_opt.flow.do_path_opt                        -value false
        set_app_options -name refine_opt.flow.do_path_opt                       -value false
        set_app_options -name route.common.global_max_layer_mode                -value hard
        set_app_options -name route.global.effort_level                         -value high
        set_app_options -name route.global.timing_driven                        -value true
        set_app_options -name route.track.crosstalk_driven                      -value true
        set_app_options -name route.track.timing_driven                         -value true
        set_app_options -name route.detail.timing_driven                        -value true
        set_app_options -name compile.flow.enable_ccd                           -value false
        set_app_options -name place_opt.flow.enable_ccd                         -value false
        set_app_options -name clock_opt.flow.enable_ccd                         -value false
        set_app_options -name route_opt.flow.enable_ccd                         -value false

        set_app_options -name route.common.assert_mode -value warn 
        set_app_options -name opt.tie_cell.max_fanout -value 256
        
        if {[info exists PDK_PIN_COLOR_ALIGNMENT_LAYERS] && $PDK_PIN_COLOR_ALIGNMENT_LAYERS ne ""} {
            set_app_options -name place.legalize.pin_color_alignment_layers -value $PDK_PIN_COLOR_ALIGNMENT_LAYERS
        } elseif {![info exists PDK_FC_CONFIGURED]} {
            set_app_options -name place.legalize.pin_color_alignment_layers -value {M1 M2}
        }
        set_app_options -name place.legalize.enable_via_ladder_checks           -value true
        set_app_options -name plan.mtcmos.placement_constraints_vertical_abutment -value 2 
        set_app_options -name plan.mtcmos.honor_pin_color_alignment             -value true 
        
        set_app_options -block [current_block] -list {route.detail.default_port_external_gate_size 0.0}
        set_app_options -block [current_block] -list {route.detail.default_gate_size 0.0}
        
        set_app_options -name shell.common.report_default_significant_digits -value 4

        set_app_options -name compile.flow.autoungroup                              -value false
        set_app_options -name compile.flow.propagate_constants_through_registers    -value true

        set_app_options -name design.uniquify_naming_style -value ${DESIGN_NAME}_%s_%d


        set_app_options -name place.legalize.enable_prerouted_net_check -value false
        set_app_options -name place.legalize.num_tracks_for_access_check -value 0
        set_app_options -name place.legalize.allow_touch_track_for_access_check -value false
        set_app_options -name place.legalize.enable_color_aware_placement -value false
        set_app_options -name place.legalize.enable_advanced_legalizer -value false
        set_app_options -name place.legalize.enable_advanced_legalizer_cellmap -value false
        set_app_options -name place.legalize.enable_prerouted_net_check -value false
        set_app_options -name place.legalize.enable_advanced_prerouted_net_check -value false
        set_app_options -name place.legalize.enable_variant_aware -value false
        set_app_options -name place.legalize.limit_legality_checks -value false

    }
    compile_design {
        puts "RM_INFO:compile_design --> set_app_options..."
        set_fix_multiple_port_nets -all -buffer_constants -exclude_clock_network

        set ENABLE_MULTIBIT false
        set PWR_OPT         false
        set ENABLE_DPS      false

        if { $ENABLE_MULTIBIT } {
          	set_app_options -name compile.flow.enable_multibit -value false
        	set_app_options -name compile.flow.enable_rtl_multibit_banking -value false
        	set_app_options -name multibit.naming.name_prefix -value MBIT_	
        	set_app_options -name compile.flow.enable_second_pass_multibit_banking -value true
        
          	#rm_source -file $DONT_BANK_SYNTHESIS_SCRIPT -label DONT_BANK_SYNTHESIS_SCRIPT
        }
        
        if {$PWR_OPT} {
            set_app_option -name power.propagation_effort -value high
            set_app_option -name power.use_ccs_rcv_cap -value true
            set_app_option -name power.use_enhanced_multidriven_net_driver_type -value true
            set_app_option -name power.include_primary_input_swcap -value true
            set_app_options -name compile.total_power.mode -value 2
        }
        
        if {$ENABLE_DPS} {
           set_app_options -name compile.flow.enable_dps -value true
           set_app_options -name compile.flow.dps_injection_point -value pre_cus
           set_app_options -name ccd.dps.flow_reporting -value {*}
           set_app_options -name ccd.dps.partition_base_count -value 200
           set_app_options -name opt.common.power_integrity -value true
        }

        set_app_options -name opt.common.user_instance_name_prefix -value compile_
        set_app_options -name cts.common.user_instance_name_prefix -value compile_cts_

        #set_app_options -name mpn.fixHierConstVerilogAssign                 -value false
        set_app_options -name compile.seqmap.enable_register_merging        -value false
        set_app_options -name compile.congestion.enable_rplace_before_lgl   -value true
        set_app_options -name compile.flow.layer_aware_optimization         -value false
        
        catch {set_app_options -name compile.clockgate.physically_aware -value true}
        catch {set_app_options -name compile.clockgate.physically_aware_split_for_max_fanout_only -value true}
        catch {set_app_options -name compile.clockgate.physically_aware_split_immediately_after_dtdp -value true}
        set_app_options -name time.use_special_default_path_groups                              -value true
        
        set_app_options -name place.coarse.max_density -value 0.75
        
        #set_app_options -name opt.area.effort -value high
        #set_app_options -name opt.power.effort -value high 
    }
    compile_place_design {
        puts "RM_INFO:compile_place_design --> set_app_options..."
        
        set_app_options -name place.coarse.enhanced_low_power_effort             -value none
        set_app_options -name place.legalize.avoid_pins_under_preroute_layers    -value {  M3  }
        set_app_options -name place.coarse.enhanced_auto_density_control -value true
        
        #set_app_options -name opt.area.effort                                    -value medium
        #set_app_options -name opt.common.buffer_area_effort                      -value high
        
        reset_app_options opt.common.use_route_aware_estimation
        set_app_options -name opt.common.enable_rde                              -value true
        set_app_options -name route.common.ignore_var_spacing_to_pg              -value true
        set_app_options -name route.common.net_min_layer_mode                    -value allow_pin_connection
        set_app_options -name route.common.global_max_layer_mode                 -value hard
        set_app_options -name route.common.via_array_mode                        -value rotate
        set_app_options -name route.common.derive_connect_within_pin_via_region  -value true
        
        # set_app_options -name opt.dft.optimize_scan_chain -value false
        
        set_app_options -name power.enable_activity_persistency                  -value on
        
        #set_app_option -name route.global.focus_scenario -value [ get_object_name [ get_scenarios $SYN_SETUP_SCENARIO ]]
        
        set_app_options -name opt.dft.clock_aware_scan_reorder -value true
        set_app_options -name opt.dft.clock_aware_scan_repartition_reorder -value true
        
        if { $ENABLE_MULTIBIT } {
        	set_app_options -name compile.flow.enable_multibit                  -value true
          	set_app_options -name mv.cells.enable_multibit_pm_cells 	    -value true
        	set_app_options -name compile.flow.enable_second_pass_multibit_banking -value true
        	set_multibit_options -slack_threshold 0.0
        }
        
        set_app_options -name  route.auto_via_ladder.report_all_via_ladders -value false
        set_app_option -name route.auto_via_ladder.user_debug -value false
        set_app_option -name route.auto_via_ladder.verbose -value false
        
        


    }
    default {
        puts "RM-warning: Undefine FLOW_STEP!"
    }

}
