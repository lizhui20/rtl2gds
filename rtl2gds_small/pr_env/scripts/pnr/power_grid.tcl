puts "RM-Info: \[date\] Running power_grid.tcl"
source $env(ROOT_PATH)/scripts/pnr/layout_context.tcl

pnr_open_stage floorplan power_mesh

connect_pg_net -automatic

set pg_nets "$PG_POWER_NET $PG_GROUND_NET"

if {[get_ports -quiet $PG_POWER_NET]  eq ""} { create_port $PG_POWER_NET  -direction inout }
if {[get_ports -quiet $PG_GROUND_NET] eq ""} { create_port $PG_GROUND_NET -direction inout }
set_attribute [get_ports $PG_POWER_NET]  port_type power  -quiet
set_attribute [get_ports $PG_GROUND_NET] port_type ground -quiet
connect_pg_net -net [get_nets $PG_POWER_NET]  [get_ports $PG_POWER_NET]
connect_pg_net -net [get_nets $PG_GROUND_NET] [get_ports $PG_GROUND_NET]

create_pg_ring_pattern ring_pattern \
    -horizontal_layer $PG_RING_H_LAYER -horizontal_width $PG_RING_WIDTH \
    -horizontal_spacing $PG_RING_SPACING \
    -vertical_layer $PG_RING_V_LAYER -vertical_width $PG_RING_WIDTH \
    -vertical_spacing $PG_RING_SPACING
set_pg_strategy ring_strategy -core \
    -pattern "{name: ring_pattern} {nets: $pg_nets} {offset: {$PG_RING_OFFSET}}" \
    -extension "{{stop: design_boundary_and_generate_pin}}"
compile_pg -strategies ring_strategy

create_pg_mesh_pattern mesh_pattern \
    -layers [subst { \
        {{vertical_layer: $PG_MESH_V_LAYER} {width: $PG_MESH_WIDTH} {spacing: interleaving} {pitch: $PG_MESH_PITCH} {offset: $PG_MESH_OFFSET}} \
        {{horizontal_layer: $PG_MESH_H_LAYER} {width: $PG_MESH_WIDTH} {spacing: interleaving} {pitch: $PG_MESH_PITCH} {offset: $PG_MESH_OFFSET}} }]
set_pg_strategy mesh_strategy -core \
    -pattern "{name: mesh_pattern} {nets: $pg_nets}" \
    -extension "{{stop: design_boundary_and_generate_pin}}"
compile_pg -strategies mesh_strategy

if {[info exists PG_BRIDGE_LOW_LAYER] && [info exists PG_BRIDGE_MID_LAYER]} {
    create_pg_mesh_pattern bridge_pattern \
        -layers [subst { \
            {{vertical_layer: $PG_BRIDGE_LOW_LAYER} {width: $PG_BRIDGE_WIDTH} {spacing: interleaving} {pitch: $PG_BRIDGE_PITCH} {offset: $PG_BRIDGE_OFFSET}} \
            {{horizontal_layer: $PG_BRIDGE_MID_LAYER} {width: $PG_BRIDGE_WIDTH} {spacing: interleaving} {pitch: $PG_BRIDGE_PITCH} {offset: $PG_BRIDGE_OFFSET}} \
            {{vertical_layer: $PG_BRIDGE_LAYER} {width: $PG_BRIDGE_WIDTH} {spacing: interleaving} {pitch: $PG_BRIDGE_PITCH} {offset: $PG_BRIDGE_OFFSET}} }]
} else {
    create_pg_mesh_pattern bridge_pattern \
        -layers [subst {{{vertical_layer: $PG_BRIDGE_LAYER} {width: $PG_BRIDGE_WIDTH} {spacing: interleaving} {pitch: $PG_BRIDGE_PITCH} {offset: $PG_BRIDGE_OFFSET}}}]
}
set_pg_strategy bridge_strategy -core \
    -pattern "{name: bridge_pattern} {nets: $pg_nets}"
if {[info exists PG_BRIDGE_TO_MESH_VIA] && $PG_BRIDGE_TO_MESH_VIA ne ""} {
    set bridge_via_rules {}
    lappend bridge_via_rules [subst {
        {{strategies: bridge_strategy} {layers: $PG_BRIDGE_LAYER}}
        {{existing: strap} {layers: $PG_MESH_H_LAYER}}
        {via_master: {$PG_BRIDGE_TO_MESH_VIA}}
    }]
    lappend bridge_via_rules [subst {
        {{strategies: bridge_strategy} {layers: $PG_BRIDGE_LAYER}}
        {{existing: ring} {layers: $PG_RING_H_LAYER}}
        {via_master: {$PG_BRIDGE_TO_MESH_VIA}}
    }]
    lappend bridge_via_rules {{intersection: undefined}{via_master: default}}
    set_pg_strategy_via_rule bridge_to_mesh_via_rule -via_rule $bridge_via_rules
    compile_pg -strategies bridge_strategy -via_rule bridge_to_mesh_via_rule
} else {
    compile_pg -strategies bridge_strategy
}

if {[info exists ENABLE_PG_DROP_PLACEMENT_BLOCKAGE] && $ENABLE_PG_DROP_PLACEMENT_BLOCKAGE} {
    set rows [get_site_rows -quiet *]
    if {[sizeof_collection $rows] == 0} {
        puts "RM-warning: ENABLE_PG_DROP_PLACEMENT_BLOCKAGE=1 but no site rows exist; skipping PG drop keepouts."
    } else {
        set core_xmin ""
        set core_xmax ""
        set core_ymin ""
        set core_ymax ""
        foreach_in_collection row $rows {
            set bbox [get_attribute $row bbox]
            set llx [lindex [lindex $bbox 0] 0]
            set lly [lindex [lindex $bbox 0] 1]
            set urx [lindex [lindex $bbox 1] 0]
            set ury [lindex [lindex $bbox 1] 1]
            if {$core_xmin eq "" || $llx < $core_xmin} { set core_xmin $llx }
            if {$core_xmax eq "" || $urx > $core_xmax} { set core_xmax $urx }
            if {$core_ymin eq "" || $lly < $core_ymin} { set core_ymin $lly }
            if {$core_ymax eq "" || $ury > $core_ymax} { set core_ymax $ury }
        }

        if {![info exists PG_DROP_BLOCKAGE_WIDTH] || $PG_DROP_BLOCKAGE_WIDTH <= 0} {
            set PG_DROP_BLOCKAGE_WIDTH [expr {$SITE_WIDTH * 6.0}]
        }
        if {![info exists PG_DROP_MIN_EDGE_FRAGMENT_WIDTH] || $PG_DROP_MIN_EDGE_FRAGMENT_WIDTH <= 0} {
            set PG_DROP_MIN_EDGE_FRAGMENT_WIDTH [expr {$SITE_WIDTH * 20.0}]
        }
        set col_idx 0
        if {![info exists PG_DROP_BLOCKAGE_OFFSETS] || [llength $PG_DROP_BLOCKAGE_OFFSETS] == 0} {
            set PG_DROP_BLOCKAGE_OFFSETS {primary}
        }
        set pg_drop_offsets {}
        foreach drop_sel $PG_DROP_BLOCKAGE_OFFSETS {
            switch -nocase -- $drop_sel {
                primary {
                    lappend pg_drop_offsets $PG_BRIDGE_OFFSET
                }
                interleaved {
                    if {$PG_BRIDGE_PITCH <= 0} {
                        error "PG_DROP_BLOCKAGE_OFFSETS includes interleaved but PG_BRIDGE_PITCH is not positive"
                    }
                    lappend pg_drop_offsets [expr {$PG_BRIDGE_OFFSET + ($PG_BRIDGE_PITCH / 2.0)}]
                }
                all {
                    lappend pg_drop_offsets $PG_BRIDGE_OFFSET
                    if {$PG_BRIDGE_PITCH <= 0} {
                        error "PG_DROP_BLOCKAGE_OFFSETS includes all but PG_BRIDGE_PITCH is not positive"
                    }
                    lappend pg_drop_offsets [expr {$PG_BRIDGE_OFFSET + ($PG_BRIDGE_PITCH / 2.0)}]
                }
                default {
                    if {![string is double -strict $drop_sel]} {
                        error "Unsupported PG_DROP_BLOCKAGE_OFFSETS entry '$drop_sel'; use primary, interleaved, all, or a numeric offset"
                    }
                    lappend pg_drop_offsets $drop_sel
                }
            }
        }
        array unset pg_drop_width_by_offset
        foreach drop_offset [lsort -real -unique $pg_drop_offsets] {
            set pg_drop_width_by_offset($drop_offset) $PG_DROP_BLOCKAGE_WIDTH
        }
        if {[info exists PG_DROP_NARROW_BLOCKAGE_OFFSETS] && [llength $PG_DROP_NARROW_BLOCKAGE_OFFSETS] > 0} {
            if {![info exists PG_DROP_NARROW_BLOCKAGE_WIDTH] || $PG_DROP_NARROW_BLOCKAGE_WIDTH <= 0} {
                error "PG_DROP_NARROW_BLOCKAGE_WIDTH must be positive when PG_DROP_NARROW_BLOCKAGE_OFFSETS is used"
            }
            foreach drop_offset $PG_DROP_NARROW_BLOCKAGE_OFFSETS {
                if {![string is double -strict $drop_offset]} {
                    error "PG_DROP_NARROW_BLOCKAGE_OFFSETS entry '$drop_offset' must be numeric"
                }
                if {![info exists pg_drop_width_by_offset($drop_offset)] ||
                    $PG_DROP_NARROW_BLOCKAGE_WIDTH > $pg_drop_width_by_offset($drop_offset)} {
                    set pg_drop_width_by_offset($drop_offset) $PG_DROP_NARROW_BLOCKAGE_WIDTH
                }
            }
        }
        foreach drop_offset [lsort -real [array names pg_drop_width_by_offset]] {
            set half_width [expr {$pg_drop_width_by_offset($drop_offset) / 2.0}]
            for {set x [expr {$core_xmin + $drop_offset}]} {$x < $core_xmax} {set x [expr {$x + $PG_BRIDGE_PITCH}]} {
                set llx [expr {$x - $half_width}]
                set urx [expr {$x + $half_width}]
                if {$llx < $core_xmin} { set llx $core_xmin }
                if {$urx > $core_xmax} { set urx $core_xmax }
                if {$llx > $core_xmin && [expr {$llx - $core_xmin}] < $PG_DROP_MIN_EDGE_FRAGMENT_WIDTH} {
                    puts "RM-info: extending PG drop keepout $col_idx to core left edge to avoid a short untapped row fragment."
                    set llx $core_xmin
                }
                if {$urx < $core_xmax && [expr {$core_xmax - $urx}] < $PG_DROP_MIN_EDGE_FRAGMENT_WIDTH} {
                    puts "RM-info: extending PG drop keepout $col_idx to core right edge to avoid a short untapped row fragment."
                    set urx $core_xmax
                }
                if {$urx <= $llx} { continue }
                create_placement_blockage -type hard -purpose user \
                    -name PG_DROP_KEEP_OUT_$col_idx \
                    -boundary [list [list $llx $core_ymin] [list $urx $core_ymax]]
                puts "RM-info: PG drop placement keepout PG_DROP_KEEP_OUT_$col_idx offset=$drop_offset width=$pg_drop_width_by_offset($drop_offset) boundary={{$llx $core_ymin} {$urx $core_ymax}}"
                incr col_idx
            }
        }
        puts "RM-info: created $col_idx PG drop placement keepout column(s)."
    }
}

connect_pg_net

redirect -file ${REPORTS_DIR}/power_mesh.check_pg_drc.rpt          {check_pg_drc}
redirect -file ${REPORTS_DIR}/power_mesh.check_pg_connectivity.rpt {check_pg_connectivity}

save_block -as ${DESIGN_NAME}/power_mesh
save_lib

puts "RM-Info: \[date\] Completed power_grid.tcl"
if {[info exists env(FC_AUTO_EXIT)]} { exit }
