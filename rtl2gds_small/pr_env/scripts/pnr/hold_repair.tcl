puts "RM-Info: \[date\] Running hold_repair.tcl"
source $env(ROOT_PATH)/scripts/pnr/layout_context.tcl

open_lib $DESIGN_LIBRARY
open_block ${PNR_LIB_NAME}:${DESIGN_NAME}/route
link_block
pnr_apply_implementation_controls
pnr_enable_tie_cells

proc hold_eco_empty_collection {class} {
    if {$class eq "net"} {
        return [get_nets -quiet __hold_eco_no_such_net__]
    }
    if {$class eq "cell"} {
        return [get_cells -quiet __hold_eco_no_such_cell__]
    }
    return [get_pins -quiet __hold_eco_no_such_pin__]
}

proc hold_eco_unique_list {items} {
    set out {}
    foreach item $items {
        if {$item ne "" && [lsearch -exact $out $item] < 0} {
            lappend out $item
        }
    }
    return $out
}

proc hold_eco_targets_from_pt_report {report_file} {
    if {![file exists $report_file]} {
        error "PrimeTime hold report not found: $report_file. Run run_pt_signoff first or set HOLD_ECO_TARGET_PINS/HOLD_ECO_TARGET_NETS."
    }

    set fh [open $report_file r]
    set targets {}
    set in_data_path 0
    set last_pin ""
    set last_net ""
    while {[gets $fh line] >= 0} {
        if {[regexp {^[ \t]*Startpoint:} $line]} {
            set in_data_path 1
            set last_pin ""
            set last_net ""
            continue
        }
        if {$in_data_path && [regexp {^[ \t]*data arrival time} $line]} {
            set in_data_path 0
            continue
        }
        if {$in_data_path && [regexp {^[ \t]*([^ \t]+/[A-Za-z0-9_\[\].]+)[ \t]+\(} $line -> pin_name]} {
            set last_pin $pin_name
            continue
        }
        if {$in_data_path && [regexp {^[ \t]*([^ \t]+)[ \t]+\(net\)} $line -> net_name]} {
            set last_net $net_name
            continue
        }
        if {[regexp {slack[ \t]+\(VIOLATED} $line]} {
            if {$last_pin ne ""} {
                lappend targets "pin:$last_pin"
            } elseif {$last_net ne ""} {
                lappend targets "net:$last_net"
            }
        }
    }
    close $fh
    return [hold_eco_unique_list $targets]
}

proc hold_eco_targets_from_constraint_report {report_file} {
    if {![file exists $report_file]} {
        return {}
    }

    set fh [open $report_file r]
    set targets {}
    set in_hold_section 0
    while {[gets $fh line] >= 0} {
        if {[regexp {^[ \t]*min_delay/hold} $line]} {
            set in_hold_section 1
            continue
        }
        if {$in_hold_section && [regexp {^[ \t]*(max_|min_|recovery|removal|clock|pulse_width|no_clock|unconstrained)} $line]} {
            break
        }
        if {!$in_hold_section} {
            continue
        }
        if {[regexp {^[ \t]*([^ \t]+/[A-Za-z0-9_\[\].]+)[ \t]+-[0-9.]+[ \t]+\(VIOLATED\)} $line -> pin_name]} {
            lappend targets "pin:$pin_name"
        }
    }
    close $fh
    return [hold_eco_unique_list $targets]
}

proc hold_eco_select_lib_cell {} {
    if {[info exists ::env(HOLD_ECO_LIB_CELL)] && $::env(HOLD_ECO_LIB_CELL) ne ""} {
        set cells [get_lib_cells -quiet $::env(HOLD_ECO_LIB_CELL)]
        if {[sizeof_collection $cells] == 0} {
            error "HOLD_ECO_LIB_CELL did not match any lib cell: $::env(HOLD_ECO_LIB_CELL)"
        }
        return $cells
    }

    if {[info exists ::env(HOLD_FIX_CELLS)] && $::env(HOLD_FIX_CELLS) ne ""} {
        set patterns $::env(HOLD_FIX_CELLS)
    } else {
        set patterns {
            */DEL150MD1BWP7T40P140
            */DEL100MD1BWP7T40P140
            */DEL075MD1BWP7T40P140
            */DEL050MD1BWP7T40P140
            */BUFFD1BWP7T40P140
            */BUFFD0BWP7T40P140
            */DEL*
            */BUFFD1*
            */BUFFD0*
            */BUFF*
        }
    }

    foreach pat $patterns {
        set cells [get_lib_cells -quiet $pat]
        if {[sizeof_collection $cells] > 0} {
            return [index_collection $cells 0]
        }
    }
    error "No hold ECO delay/buffer lib cell found from patterns: $patterns"
}

proc hold_eco_route_check_same_net_only {route_check} {
    set total 0
    set open_nets 0
    set antenna 0
    set same_net_spacing 0

    if {[regexp {@@@@@@@ TOTAL VIOLATIONS =[ \t]*([0-9]+)} $route_check -> value]} {
        set total $value
    }
    if {[regexp {Total number of open nets =[ \t]*([0-9]+)} $route_check -> value]} {
        set open_nets $value
    } elseif {[regexp {([0-9]+)[ \t]+open nets, of which} $route_check -> value]} {
        set open_nets $value
    }
    if {[regexp {Total number of antenna violations =[ \t]*([0-9]+)} $route_check -> value]} {
        set antenna $value
    }
    if {[regexp {Same net spacing[ \t]*:[ \t]*([0-9]+)} $route_check -> value]} {
        set same_net_spacing $value
    }

    return [expr {$open_nets == 0 && $antenna == 0 && $total > 0 && $total == $same_net_spacing}]
}

set hold_cell [hold_eco_select_lib_cell]
puts "RM-Info: hold ECO lib cell: [get_object_name $hold_cell]"
set_lib_cell_purpose -include optimization $hold_cell

set hold_targets {}
if {[info exists env(HOLD_ECO_TARGET_PINS)] && $env(HOLD_ECO_TARGET_PINS) ne ""} {
    foreach pin $env(HOLD_ECO_TARGET_PINS) { lappend hold_targets "pin:$pin" }
} elseif {[info exists env(HOLD_ECO_TARGET_NETS)] && $env(HOLD_ECO_TARGET_NETS) ne ""} {
    foreach net $env(HOLD_ECO_TARGET_NETS) { lappend hold_targets "net:$net" }
} else {
    set hold_targets [hold_eco_targets_from_pt_report ${REPORTS_DIR}/signoff/pt.hold.rpt]
    set constraint_targets [hold_eco_targets_from_constraint_report ${REPORTS_DIR}/signoff/pt.constraints.hold.rpt]
    if {[llength $constraint_targets] > 0} {
        puts "RM-Info: adding [llength $constraint_targets] hold ECO targets from pt.constraints.hold.rpt"
        set hold_targets [concat $hold_targets $constraint_targets]
    }
}
set hold_targets [hold_eco_unique_list $hold_targets]
if {[llength $hold_targets] == 0} {
    puts "RM-Info: no violated hold targets found; nothing to ECO."
    if {[info exists env(FC_AUTO_EXIT)]} { exit }
    return
}
puts "RM-Info: hold ECO targets: $hold_targets"

set hold_scenarios {}
foreach c $PNR_CORNERS {
    lassign $c cname sname process volt temp pspec a_su a_ho a_dp a_lk
    if {$a_ho} { lappend hold_scenarios $sname }
}
if {[llength $hold_scenarios] == 0} {
    error "No active hold scenarios found in PNR_CORNERS"
}
update_timing -full
redirect -file ${REPORTS_DIR}/hold_eco.before.rpt {
    report_qor
    report_timing -delay_type min -max_paths 50 -slack_lesser_than 0.0 -nosplit
}

if {[info exists env(HOLD_ECO_BUFFER_COUNT)] && $env(HOLD_ECO_BUFFER_COUNT) ne ""} {
    set hold_buffer_count $env(HOLD_ECO_BUFFER_COUNT)
} else {
    set hold_buffer_count 1
}
set eco_cells [hold_eco_empty_collection cell]
set eco_nets  [hold_eco_empty_collection net]
foreach target $hold_targets {
    if {[regexp {^pin:(.+)$} $target -> pin_name]} {
        set pins [get_pins -quiet $pin_name]
        if {[sizeof_collection $pins] == 0} {
            error "Hold ECO target pin not found: $pin_name"
        }
        puts "RM-Info: adding $hold_buffer_count hold ECO cell(s) at load pin $pin_name"
        set new_cells [add_buffer $pins -lib_cell $hold_cell -no_of_cells $hold_buffer_count \
            -new_cell_names hold_eco_dly -new_net_names hold_eco_net -snap]
    } elseif {[regexp {^net:(.+)$} $target -> net_name]} {
        set nets [get_nets -quiet $net_name]
        if {[sizeof_collection $nets] == 0} {
            error "Hold ECO target net not found: $net_name"
        }
        puts "RM-Info: adding $hold_buffer_count hold ECO cell(s) on net $net_name"
        set new_cells [add_buffer $nets -lib_cell $hold_cell -no_of_cells $hold_buffer_count \
            -new_cell_names hold_eco_dly -new_net_names hold_eco_net -snap]
    } else {
        error "Bad hold ECO target '$target'; expected pin:<pin> or net:<net>"
    }
    if {[sizeof_collection $new_cells] == 0} {
        error "add_buffer created no hold ECO cells for target $target"
    }
    set eco_cells [add_to_collection $eco_cells $new_cells]
    set eco_nets [add_to_collection $eco_nets [get_nets -quiet -of_objects [get_pins -quiet -of_objects $new_cells]]]
}

if {[sizeof_collection $eco_cells] > 0} {
    if {[catch {legalize_placement -cells $eco_cells -moveable_distance 10 -post_route} msg]} {
        puts "RM-warning: localized legalization failed, trying incremental legalization: $msg"
        legalize_placement -incremental -post_route
    }
}
pnr_apply_route_drc_shape_controls
route_eco -nets $eco_nets -cells $eco_cells -reroute modified_nets_first_then_others \
    -reuse_existing_global_route true -max_detail_route_iterations 200 -max_reported_nets -1
connect_pg_net

current_mode $MCMM_MODE
read_sdc $SYNTH_SDC
update_timing -full

redirect -variable route_check {check_routes}
set fh [open ${REPORTS_DIR}/hold_eco.check_routes.rpt w]
puts $fh $route_check
close $fh
if {[regexp {@@@@@@@ TOTAL VIOLATIONS =[ \t]*([0-9]+)} $route_check -> drc_count] && $drc_count != 0 &&
        ![hold_eco_route_check_same_net_only $route_check]} {
    puts "RM-Info: Hold ECO left $drc_count route DRC violation(s); running ECO route repair."
    set_app_options -name route.detail.drc_convergence_effort_level -value high
    set_app_options -name route.detail.eco_route_use_soft_spacing_for_timing_optimization -value false
    set_app_options -name route.detail.check_patchable_drc_from_fixed_shapes -value true
    pnr_apply_route_drc_shape_controls
    route_eco -reroute any_nets -reuse_existing_global_route false \
        -max_detail_route_iterations 300 -max_reported_nets -1
    connect_pg_net
    update_timing -full
    redirect -variable route_check {check_routes}
    set fh [open ${REPORTS_DIR}/hold_eco.check_routes.rpt w]
    puts $fh $route_check
    close $fh
}
if {[regexp {@@@@@@@ TOTAL VIOLATIONS =[ \t]*([0-9]+)} $route_check -> drc_count] && $drc_count != 0 &&
        ![hold_eco_route_check_same_net_only $route_check]} {
    error "Hold ECO left $drc_count route DRC violation(s); inspect ${REPORTS_DIR}/hold_eco.check_routes.rpt"
} elseif {[info exists drc_count] && $drc_count != 0} {
    puts "RM-Info: Hold ECO left only same-net spacing route warning(s); external Calibre signoff remains authoritative."
}
redirect -file ${REPORTS_DIR}/hold_eco.after.rpt {
    report_qor
    report_timing -delay_type min -max_paths 50 -slack_lesser_than 0.0 -nosplit
}

save_block
save_lib
set_svf -off
if {![file exists $PNR_SVF]} {
    error "PnR SVF was not written: $PNR_SVF"
}

puts "RM-Info: hold-fix ECO done; run_chip_finish must run next to write final outputs."
puts "RM-Info: \[date\] Completed hold_repair.tcl"
if {[info exists env(FC_AUTO_EXIT)]} { exit }
