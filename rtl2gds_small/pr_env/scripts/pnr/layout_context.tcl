if {![info exists ::env(DESIGN_NAME)] && [info exists ::env(PR_DESIGN_NAME)]} {
    set ::env(DESIGN_NAME) $::env(PR_DESIGN_NAME)
}
set DESIGN_NAME $::env(DESIGN_NAME)
set ROOT_PATH   $::env(ROOT_PATH)
set run_path    ${ROOT_PATH}/${DESIGN_NAME}
set RESULTS_DIR ${run_path}/results
set REPORTS_DIR ${run_path}/reports
file mkdir $RESULTS_DIR $REPORTS_DIR

set INPUTS_DIR ${run_path}/inputs
set TECH_DIR   ${run_path}/tech
set REF_DIR    ${run_path}/ref

set PDK_DIR ${ROOT_PATH}/scripts/pdk
source ${PDK_DIR}/process_select.tcl
set pr_profile_file ${PDK_DIR}/process_${PDK_PROFILE}.tcl
if {![file exists $pr_profile_file]} {
    error "PR PDK profile not found: $pr_profile_file (set PDK_PROFILE in scripts/pdk/process_select.tcl)"
}

set user_setup_file ${ROOT_PATH}/scripts/utilities/layout_defaults.tcl
if {![file exists $user_setup_file]} {
    error "PR user setting template not found: $user_setup_file"
}
source $user_setup_file
set design_user_setup_file ${INPUTS_DIR}/${DESIGN_NAME}.pr_user_setting.tcl
if {[file exists $design_user_setup_file]} {
    puts "RM-info: design PR user setup = $design_user_setup_file"
    source $design_user_setup_file
}
puts "RM-info: user setup: max_transition=$MAX_TRANSITION max_transition_repair_target=$MAX_TRANSITION_REPAIR_TARGET max_fanout=$MAX_FANOUT extractor=$SPEF_EXTRACTOR io_placement=$ENABLE_IO_PLACEMENT io_library=$ENABLE_IO_LIBRARY clock_gating=$ENABLE_CLOCK_GATING vt_allowed=$VT_ALLOWED_GROUPS max_cap_repair=$ENABLE_MAX_CAP_REPAIR"
puts "RM-info: PnR process profile = $PDK_PROFILE"
source $pr_profile_file
set mmcm_file ${PDK_DIR}/rc_corners.tcl
if {![file exists $mmcm_file]} {
    error "PR MCMM setup not found: $mmcm_file"
}
puts "RM-info: MCMM setup = $mmcm_file"
source $mmcm_file

proc pnr_try_set_app_option {name value} {
    if {[catch {set_app_options -name $name -value $value} msg]} {
        puts "RM-warning: set_app_options $name=$value skipped: $msg"
    } else {
        puts "RM-info: set_app_options $name=$value"
    }
}

proc pnr_apply_route_drc_shape_controls {} {
    global ENABLE_ROUTE_DRC_SHAPE_CONTROLS ROUTE_DRC_APP_OPTIONS
    if {![info exists ENABLE_ROUTE_DRC_SHAPE_CONTROLS] || !$ENABLE_ROUTE_DRC_SHAPE_CONTROLS} {
        puts "RM-info: ENABLE_ROUTE_DRC_SHAPE_CONTROLS=0; using default router shape controls."
        return
    }
    if {![info exists ROUTE_DRC_APP_OPTIONS] || [llength $ROUTE_DRC_APP_OPTIONS] == 0} {
        puts "RM-info: no ROUTE_DRC_APP_OPTIONS configured."
        return
    }
    foreach opt $ROUTE_DRC_APP_OPTIONS {
        if {[llength $opt] != 2} {
            error "Bad ROUTE_DRC_APP_OPTIONS entry '$opt'; expected {option_name value}"
        }
        lassign $opt name value
        pnr_try_set_app_option $name $value
    }
}

set PNR_SVF ${RESULTS_DIR}/${DESIGN_NAME}.pnr.svf
set_svf -append $PNR_SVF

set DFT_NETLIST ${INPUTS_DIR}/${DESIGN_NAME}.scan.v
set SCAN_DEF    ${INPUTS_DIR}/${DESIGN_NAME}.scandef
set SYNTH_SDC   ${INPUTS_DIR}/${DESIGN_NAME}.mapped.sdc

set DESIGN_LIBRARY ${RESULTS_DIR}/${DESIGN_NAME}_pnr.ndm
set PNR_LIB_NAME   ${DESIGN_NAME}_pnr.ndm
set_host_options -max_cores 8

proc pnr_open_stage {prev_label new_label} {
    global DESIGN_LIBRARY PNR_LIB_NAME DESIGN_NAME
    open_lib $DESIGN_LIBRARY
    copy_block -from ${PNR_LIB_NAME}:${DESIGN_NAME}/${prev_label} \
               -to ${PNR_LIB_NAME}:${DESIGN_NAME}/${new_label}
    current_block ${DESIGN_NAME}/${new_label}
    link_block
    pnr_apply_implementation_controls
    pnr_enable_tie_cells
    pnr_apply_library_attributes
}

proc pnr_open_existing_signoff_block {} {
    global DESIGN_LIBRARY PNR_LIB_NAME DESIGN_NAME RESULTS_DIR run_path
    open_lib $DESIGN_LIBRARY
    set labels {chip_finish}
    set metal_fill_marker ${RESULTS_DIR}/${DESIGN_NAME}.metal_fill.done
    if {[file exists $metal_fill_marker]} {
        set chip_finish_done ${run_path}/logs/run_chip_finish.done
        if {[file exists $chip_finish_done] &&
            [file mtime $chip_finish_done] > [file mtime $metal_fill_marker]} {
            puts "RM-info: chip_finish is newer than completed metal_fill marker; using chip_finish for signoff stream/check stages."
        } else {
            set labels {metal_fill chip_finish}
        }
    } else {
        puts "RM-info: no completed metal-fill marker found; using chip_finish for signoff stream/check stages."
    }
    foreach label $labels {
        if {![catch {open_block ${PNR_LIB_NAME}:${DESIGN_NAME}/${label}}]} {
            puts "RM-info: using signoff block ${DESIGN_NAME}/${label}"
            link_block
            return $label
        }
    }
    error "No signoff block found: expected ${DESIGN_NAME}/chip_finish, or completed ${DESIGN_NAME}/metal_fill"
}

proc pnr_read_parasitic_tech {} {
    global PARASITIC_ENABLED TLU_SPECS TLU_MAP
    if {![info exists PARASITIC_ENABLED] || !$PARASITIC_ENABLED} {
        puts "RM-warning: PARASITIC_ENABLED=0; FC will run without an RC model."
        return
    }
    foreach spec $TLU_SPECS {
        lassign $spec name f
        if {![file exists $f]} { puts "RM-warning: TLUPlus missing ($name): $f"; continue }
        if {$TLU_MAP ne ""} {
            read_parasitic_tech -tlup $f -layermap $TLU_MAP -name $name
        } else {
            read_parasitic_tech -tlup $f -name $name
        }
        puts "RM-info: read_parasitic_tech -name $name <- $f"
    }
}

proc pnr_set_corner_pvt {corner process voltage temperature} {
    current_corner $corner
    if {$process ne ""} { set_process_label -late $process -early $process }
    set_voltage $voltage -min $voltage -object_list [get_supply_nets VDD*]
    set_voltage 0.0 -min 0.0 -object_list [get_supply_nets VSS*]
    set_temperature $temperature -min $temperature
}

proc pnr_setup_mcmm {} {
    global MCMM_MODE SYNTH_SDC MAX_TRANSITION MAX_FANOUT PNR_CORNERS PARASITIC_ENABLED
    remove_modes -all
    remove_corners -all
    remove_scenarios -all
    create_mode $MCMM_MODE
    set first_scen ""
    foreach c $PNR_CORNERS {
        lassign $c cname sname process volt temp pspec a_su a_ho a_dp a_lk
        create_corner $cname
        create_scenario -mode $MCMM_MODE -corner $cname -name $sname
        if {$first_scen eq ""} { set first_scen $sname }
    }
    current_mode $MCMM_MODE
    foreach c $PNR_CORNERS {
        current_scenario [lindex $c 1]
        read_sdc $SYNTH_SDC
    }
    current_scenario $first_scen
    if {[info exists MAX_TRANSITION] && $MAX_TRANSITION ne ""} {
        pnr_set_design_max_transition $MAX_TRANSITION "MCMM design electrical rule"
    } else {
        puts "RM-info: MAX_TRANSITION is empty; using library max_transition limits."
    }
    if {[info exists MAX_FANOUT] && $MAX_FANOUT ne ""} {
        puts "RM-info: Fusion Compiler ignores max fanout constraints; MAX_FANOUT=$MAX_FANOUT is left for synthesis/PT signoff."
    }
    foreach c $PNR_CORNERS {
        lassign $c cname sname process volt temp pspec a_su a_ho a_dp a_lk
        pnr_set_corner_pvt $cname $process $volt $temp
        if {[info exists PARASITIC_ENABLED] && $PARASITIC_ENABLED} {
            set_parasitic_parameters -corners $cname -late_spec $pspec -early_spec $pspec
        }
        set_scenario_status $sname -active true \
            -setup $a_su -hold $a_ho -leakage_power $a_lk -dynamic_power $a_dp
    }
}

proc pnr_write_signoff_sdc {output} {
    global PNR_CORNERS
    foreach c $PNR_CORNERS {
        if {[lindex $c 6]} {
            current_scenario [lindex $c 1]
            write_sdc -nosplit -output $output
            return
        }
    }
    error "No setup scenario is configured for signoff SDC export"
}

proc pnr_apply_library_attributes {} {
    global FILLER_CELLS
    if {![info exists FILLER_CELLS] || [llength $FILLER_CELLS] == 0} {
        return
    }

    set fillers [get_lib_cells -quiet $FILLER_CELLS]
    if {[sizeof_collection $fillers] == 0} {
        return
    }

    set sample [index_collection $fillers 0]
    set dtype ""
    catch {set dtype [get_attribute $sample design_type]}
    if {$dtype ne "filler"} {
        puts "RM-warning: filler lib cells are not marked design_type=filler in the loaded NDM; rebuild/install the PDK NDM with filler attributes."
    } else {
        puts "RM-info: filler lib cells are marked design_type=filler in the loaded NDM."
    }
}

proc pnr_restore_scenario_status {} {
    global PNR_CORNERS
    foreach c $PNR_CORNERS {
        lassign $c cname sname process volt temp pspec a_su a_ho a_dp a_lk
        set_scenario_status $sname -active true \
            -setup $a_su -hold $a_ho -leakage_power $a_lk -dynamic_power $a_dp
    }
}

proc pnr_apply_implementation_controls {} {
    global ENABLE_CLOCK_GATING VT_ALLOWED_GROUPS HOLD_FIX_CELLS
    global PDK_VT_GROUP_PATTERNS PDK_HIGH_VT_GROUPS PDK_NORMAL_VT_GROUPS PDK_LOW_VT_GROUPS

    if {[info exists PDK_VT_GROUP_PATTERNS]} {
        foreach group_spec $PDK_VT_GROUP_PATTERNS {
            lassign $group_spec vt_group patterns
            foreach pattern $patterns {
                set cells [get_lib_cells -quiet $pattern]
                if {[sizeof_collection $cells] > 0} {
                    set_attribute -quiet $cells threshold_voltage_group $vt_group
                }
            }
        }
    }

    set all_vt_groups {}
    foreach group_var {PDK_HIGH_VT_GROUPS PDK_NORMAL_VT_GROUPS PDK_LOW_VT_GROUPS} {
        if {[info exists $group_var]} {
            foreach vt [set $group_var] {
                if {[lsearch -exact $all_vt_groups $vt] < 0} {
                    lappend all_vt_groups $vt
                }
            }
        }
    }

    if {[info exists VT_ALLOWED_GROUPS] &&
        [llength $VT_ALLOWED_GROUPS] > 0 &&
        [lsearch -exact $VT_ALLOWED_GROUPS all] < 0} {
        foreach vt $VT_ALLOWED_GROUPS {
            if {[lsearch -exact $all_vt_groups $vt] < 0} {
                error "Invalid VT_ALLOWED_GROUPS entry '$vt'. Valid groups are: $all_vt_groups, or all"
            }
        }

        foreach vt $all_vt_groups {
            if {[lsearch -exact $VT_ALLOWED_GROUPS $vt] >= 0} {
                continue
            }
            set cells [get_lib_cells -quiet -filter "threshold_voltage_group == $vt"]
            if {[sizeof_collection $cells] > 0} {
                set_attribute -quiet $cells dont_use true
                catch {set_lib_cell_purpose -exclude {optimization hold cts power} $cells}
                puts "RM-info: VT_ALLOWED_GROUPS=$VT_ALLOWED_GROUPS; disabled VT group $vt for PnR optimization/CTS."
            }
        }
    }

    if {[info exists ENABLE_CLOCK_GATING] && !$ENABLE_CLOCK_GATING} {
        set regs [all_registers]
        if {[sizeof_collection $regs] > 0} {
            catch {set_clock_gating_objects -exclude $regs}
        }

        set icg_cells [get_lib_cells -quiet {*/CKLNQ* */CKLHQ* */*ICG* */*GCK*}]
        if {[sizeof_collection $icg_cells] > 0} {
            set_attribute -quiet $icg_cells dont_use true
            catch {set_lib_cell_purpose -exclude {optimization hold cts power} $icg_cells}
        }
        puts "RM-info: ENABLE_CLOCK_GATING=0; excluded registers from clock-gating and disabled ICG cells for PnR."
    }

    if {[info exists HOLD_FIX_CELLS] && [llength $HOLD_FIX_CELLS] > 0} {
        set hold_cells [get_lib_cells -quiet $HOLD_FIX_CELLS]
        if {[sizeof_collection $hold_cells] > 0} {
            set_attribute -quiet $hold_cells dont_use false
            set_lib_cell_purpose -include hold $hold_cells
            puts "RM-info: enabled hold-fix cells: [get_object_name $hold_cells]"
        } else {
            puts "RM-warning: HOLD_FIX_CELLS did not match any lib cells: $HOLD_FIX_CELLS"
        }
    }
}

proc pnr_report_constraint_violators {file_name} {
    if {[catch {
        redirect -file $file_name {report_constraints -all_violators -scenarios [all_scenarios]}
    } msg]} {
        puts "RM-warning: report_constraints -all_violators -scenarios [all_scenarios] failed for $file_name: $msg"
    }
}

proc pnr_assert_no_constraint_violations {file_name} {
    if {![file exists $file_name]} {
        error "Constraint report does not exist: $file_name"
    }
    set fh [open $file_name r]
    set text [read $fh]
    close $fh
    if {[regexp {\(VIOLATED\)} $text]} {
        error "Constraint violations remain; inspect $file_name"
    }
    puts "RM-info: no constraint violations in $file_name"
}

proc pnr_lunique {items} {
    set out {}
    foreach item $items {
        if {[lsearch -exact $out $item] < 0} {
            lappend out $item
        }
    }
    return $out
}

proc pnr_route_open_net_count {route_check} {
    set open_nets 0
    if {[regexp {Total number of open nets =[ \t]*([0-9]+)} $route_check -> value]} {
        set open_nets $value
    } elseif {[regexp {([0-9]+)[ \t]+open nets, of which} $route_check -> value]} {
        set open_nets $value
    }
    return $open_nets
}

proc pnr_assert_no_route_open_nets {file_name} {
    if {![file exists $file_name]} {
        error "Route check report does not exist: $file_name"
    }
    set fh [open $file_name r]
    set text [read $fh]
    close $fh

    set open_nets [pnr_route_open_net_count $text]
    if {$open_nets != 0} {
        error "Route check has $open_nets open net(s); inspect $file_name"
    }
    puts "RM-info: no open nets in $file_name"
}

proc pnr_max_cap_violator_pins {} {
    set text ""
    if {[catch {
        redirect -variable text {report_constraints -max_capacitance -all_violators -scenarios [all_scenarios]}
    } msg]} {
        error "report_constraints -max_capacitance failed: $msg"
    }

    set pins {}
    foreach line [split $text "\n"] {
        if {[regexp {^[ \t]*PIN[ \t]*:[ \t]*([^ \t]+)} $line -> pin_name]} {
            if {[lsearch -exact $pins $pin_name] < 0} {
                lappend pins $pin_name
            }
        }
    }
    return $pins
}

proc pnr_drive_strength_candidates {ref_name} {
    global MAX_CAP_REPAIR_DRIVE_STRENGTHS
    if {![regexp {^(.*D)([0-9]+)(BWP.*)$} $ref_name -> prefix drive suffix]} {
        return {}
    }

    set out {}
    foreach strength $MAX_CAP_REPAIR_DRIVE_STRENGTHS {
        if {$strength > $drive} {
            lappend out ${prefix}${strength}${suffix}
        }
    }
    return $out
}

proc pnr_pick_usable_lib_cell {ref_names} {
    foreach ref_name $ref_names {
        set lib_cells [get_lib_cells -quiet */$ref_name]
        foreach_in_collection lib_cell $lib_cells {
            set dont_use false
            catch {set dont_use [get_attribute $lib_cell dont_use]}
            if {$dont_use eq "true" || $dont_use eq "1"} {
                continue
            }
            return [get_object_name $lib_cell]
        }
    }
    return ""
}

proc pnr_repair_max_cap_violations {} {
    global ENABLE_MAX_CAP_REPAIR MAX_CAP_REPAIR_MAX_ITERATIONS
    if {![info exists ENABLE_MAX_CAP_REPAIR] || !$ENABLE_MAX_CAP_REPAIR} {
        puts "RM-info: ENABLE_MAX_CAP_REPAIR=0; skipping post-route max_cap repair."
        return
    }

    for {set iter 1} {$iter <= $MAX_CAP_REPAIR_MAX_ITERATIONS} {incr iter} {
        set violator_pins [pnr_max_cap_violator_pins]
        if {[llength $violator_pins] == 0} {
            puts "RM-info: max_cap repair clean after [expr {$iter - 1}] iteration(s)."
            return
        }

        puts "RM-info: max_cap repair iteration $iter: [llength $violator_pins] driver pin(s): $violator_pins"
        set changed_cells {}
        set changed_nets {}

        foreach pin_name $violator_pins {
            set pin_obj [get_pins -quiet $pin_name]
            if {[sizeof_collection $pin_obj] == 0} {
                puts "RM-warning: max_cap repair cannot find pin $pin_name; skipping."
                continue
            }

            set net_obj [get_nets -quiet -of_objects $pin_obj]
            foreach_in_collection net $net_obj {
                lappend changed_nets [get_object_name $net]
            }

            set cell_name $pin_name
            regsub {/[^/]+$} $cell_name "" cell_name
            set cell_obj [get_cells -quiet $cell_name]
            if {[sizeof_collection $cell_obj] == 0} {
                puts "RM-warning: max_cap repair cannot find cell for pin $pin_name; skipping."
                continue
            }

            set ref_name [get_attribute [index_collection $cell_obj 0] ref_name]
            set candidates [pnr_drive_strength_candidates $ref_name]
            if {[llength $candidates] == 0} {
                puts "RM-warning: max_cap repair has no drive-strength pattern for $cell_name ref=$ref_name; skipping."
                continue
            }

            set lib_cell [pnr_pick_usable_lib_cell $candidates]
            if {$lib_cell eq ""} {
                puts "RM-warning: max_cap repair found no usable larger cell for $cell_name ref=$ref_name candidates=$candidates; skipping."
                continue
            }

            if {[catch {size_cell $cell_obj $lib_cell} msg]} {
                puts "RM-warning: max_cap repair failed to size $cell_name from $ref_name to $lib_cell: $msg"
                continue
            }

            lappend changed_cells $cell_name
            puts "RM-info: max_cap repair upsized $cell_name from $ref_name to $lib_cell."
        }

        set changed_cells [pnr_lunique $changed_cells]
        set changed_nets  [pnr_lunique $changed_nets]
        if {[llength $changed_cells] == 0} {
            error "max_cap repair could not modify any violator driver; remaining pins: $violator_pins"
        }

        legalize_placement
        if {[llength $changed_nets] > 0} {
            foreach cell_name $changed_cells {
                set cell_obj [get_cells -quiet $cell_name]
                if {[sizeof_collection $cell_obj] == 0} {
                    continue
                }
                set cell_nets [get_nets -quiet -of_objects [get_pins -quiet -of_objects $cell_obj]]
                foreach_in_collection net $cell_nets {
                    lappend changed_nets [get_object_name $net]
                }
            }
            set changed_nets [pnr_lunique $changed_nets]
            set repair_nets [get_nets -quiet $changed_nets]
            if {[sizeof_collection $repair_nets] > 0} {
                route_eco -nets $repair_nets -reroute modified_nets_first_then_others \
                    -reuse_existing_global_route false -max_detail_route_iterations 100 \
                    -max_reported_nets -1
            } else {
                puts "RM-warning: max_cap repair changed cells but could not resolve changed nets; rerouting affected detail routes without an explicit net list."
                route_eco
            }
        } else {
            route_eco
        }
        connect_pg_net
        update_timing -full

        redirect -variable route_check {check_routes}
        set open_nets [pnr_route_open_net_count $route_check]
        if {$open_nets != 0} {
            puts "RM-warning: max_cap repair left $open_nets open net(s); running full ECO route repair."
            route_eco -reroute any_nets -reuse_existing_global_route false \
                -max_detail_route_iterations 300 -max_reported_nets -1
            connect_pg_net
            update_timing -full
            redirect -variable route_check {check_routes}
            set open_nets [pnr_route_open_net_count $route_check]
        }
        if {$open_nets != 0} {
            error "max_cap repair left $open_nets open net(s) after full ECO route repair"
        }
    }

    set remaining [pnr_max_cap_violator_pins]
    if {[llength $remaining] > 0} {
        error "max_cap repair reached MAX_CAP_REPAIR_MAX_ITERATIONS=$MAX_CAP_REPAIR_MAX_ITERATIONS; remaining pins: $remaining"
    }
}

proc pnr_set_design_max_transition {value {reason ""}} {
    set scenarios [all_scenarios]
    if {[sizeof_collection $scenarios] == 0} {
        set_max_transition $value [current_design]
    } else {
        catch {remove_max_transition -scenarios $scenarios [current_design]}
        set_max_transition $value [current_design] -scenarios $scenarios
    }
    if {$reason ne ""} {
        puts "RM-info: $reason: set_max_transition $value on [get_object_name [current_design]] for all scenarios."
    } else {
        puts "RM-info: set_max_transition $value on [get_object_name [current_design]] for all scenarios."
    }
}

proc pnr_run_max_transition_repair {} {
    global MAX_TRANSITION_REPAIR_TARGET MAX_TRANSITION
    if {![info exists MAX_TRANSITION_REPAIR_TARGET] || $MAX_TRANSITION_REPAIR_TARGET eq ""} {
        return
    }

    set scenarios [all_scenarios]
    if {[sizeof_collection $scenarios] == 0} {
        puts "RM-warning: MAX_TRANSITION_REPAIR_TARGET requested before scenarios exist; skipping."
        return
    }

    set_max_transition $MAX_TRANSITION_REPAIR_TARGET [current_design] -scenarios $scenarios
    puts "RM-info: temporary max_transition repair target ${MAX_TRANSITION_REPAIR_TARGET}ns applied for route_opt only."
    route_opt
    catch {remove_max_transition -scenarios $scenarios [current_design]}
    if {[info exists MAX_TRANSITION] && $MAX_TRANSITION ne ""} {
        pnr_set_design_max_transition $MAX_TRANSITION "restored configured MCMM design electrical rule after repair"
    } else {
        puts "RM-info: removed temporary max_transition repair target; final checks use library limits."
    }
}

proc pnr_run_post_cts_hold_repair {} {
    set hold_scenarios [get_scenarios -quiet -filter "hold"]
    if {[sizeof_collection $hold_scenarios] == 0} {
        puts "RM-warning: no hold scenarios are available for post-CTS hold repair."
        return
    }

    pnr_restore_scenario_status
    update_timing -full
    redirect -file ${::REPORTS_DIR}/cts.post_hold_repair.before.rpt {
        report_qor
        report_timing -delay_type min -max_paths 50 -slack_lesser_than 0.0 -nosplit
        report_timing -delay_type max -max_paths 50 -slack_lesser_than 0.0 -nosplit
    }

    set hold_paths [get_timing_paths -delay_type min -slack_lesser_than 0.0 -max_paths 1]
    if {[sizeof_collection $hold_paths] == 0} {
        puts "RM-info: post-CTS hold is clean after clock_opt; no extra final_opto repair needed."
        return
    }

    puts "RM-info: running post-CTS final_opto timing repair with setup and hold scenarios active."
    pnr_try_set_app_option opt.timing.effort high
    pnr_try_set_app_option clock_opt.flow.enable_ccd true
    if {[catch {clock_opt -from final_opto -to final_opto} msg]} {
        puts "RM-warning: post-CTS final_opto hold repair skipped/failed ($msg); route_opt will continue hold closure."
    }

    pnr_restore_scenario_status
    update_timing -full
    redirect -file ${::REPORTS_DIR}/cts.post_hold_repair.after.rpt {
        report_qor
        report_timing -delay_type min -max_paths 50 -slack_lesser_than 0.0 -nosplit
        report_timing -delay_type max -max_paths 50 -slack_lesser_than 0.0 -nosplit
    }
}

proc pnr_enable_tie_cells {} {
    global TIE_CELLS
    set tie [get_lib_cells -quiet $TIE_CELLS]
    if {[sizeof_collection $tie] > 0} {
        set_lib_cell_purpose -include optimization $tie
    } else {
        puts "RM-warning: no tie cells found ($TIE_CELLS)."
    }
}

proc pnr_source_antenna_rules {} {
    global ANTENNA_RULE
    if {[info exists ANTENNA_RULE] && $ANTENNA_RULE ne "" && [file exists $ANTENNA_RULE]} {
        puts "RM-info: sourcing antenna rules $ANTENNA_RULE"
        if {![info exists synopsys_program_name]} {
            set synopsys_program_name fc_shell
        }
        source $ANTENNA_RULE
    } else {
        puts "RM-warning: antenna rule file is not available; router antenna repair may be limited."
    }
}

proc pnr_apply_clock_routing_rules {} {
    global ENABLE_CTS_NDR CTS_NDR_LAYERS CTS_NDR_WIDTH CTS_NDR_SPACING CTS_MIN_LAYER CTS_MAX_LAYER
    if {[info exists ENABLE_CTS_NDR] && !$ENABLE_CTS_NDR} {
        puts "RM-info: ENABLE_CTS_NDR=0; clock routing uses default routing rules."
        return
    }
    if {![info exists CTS_NDR_LAYERS] || [llength $CTS_NDR_LAYERS] == 0} {
        puts "RM-warning: CTS_NDR_LAYERS is empty; clock routing rules were not applied."
        return
    }

    set cts_widths {}
    set cts_spacings {}
    foreach layer $CTS_NDR_LAYERS {
        lappend cts_widths $layer $CTS_NDR_WIDTH
        lappend cts_spacings $layer $CTS_NDR_SPACING
    }
    if {[sizeof_collection [get_routing_rules -quiet cts_ndr]] == 0} {
        create_routing_rule cts_ndr -widths $cts_widths -spacings $cts_spacings
    } else {
        puts "RM-info: clock routing rule cts_ndr already exists; reusing it."
    }
    set_clock_routing_rules -rules cts_ndr \
        -min_routing_layer $CTS_MIN_LAYER -max_routing_layer $CTS_MAX_LAYER
    puts "RM-info: clock routing uses cts_ndr on $CTS_MIN_LAYER-$CTS_MAX_LAYER ($CTS_NDR_WIDTH width / $CTS_NDR_SPACING spacing)."
}
