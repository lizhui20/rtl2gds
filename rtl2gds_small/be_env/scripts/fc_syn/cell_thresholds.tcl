if {![info exists PDK_VT_GROUP_PATTERNS] || [llength $PDK_VT_GROUP_PATTERNS] == 0} {
    puts "INFO: Selected PDK has no Vt group configuration; skipping Vt-specific constraints."
    return
}

foreach group_spec $PDK_VT_GROUP_PATTERNS {
    lassign $group_spec vt_group patterns
    foreach pattern $patterns {
        set cells [get_lib_cells -quiet $pattern]
        if {[sizeof_collection $cells] > 0} {
            set_attribute -quiet $cells threshold_voltage_group $vt_group
        }
    }
}

set high_vt_groups $PDK_HIGH_VT_GROUPS
set normal_vt_groups $PDK_NORMAL_VT_GROUPS
set low_vt_groups $PDK_LOW_VT_GROUPS

set_threshold_voltage_group_type -type high_vt $high_vt_groups
set_threshold_voltage_group_type -type normal_vt $normal_vt_groups
set_threshold_voltage_group_type -type low_vt $low_vt_groups

set all_vt_groups [concat $high_vt_groups $normal_vt_groups $low_vt_groups]
if {[info exists VT_ALLOWED_GROUPS] &&
    [llength $VT_ALLOWED_GROUPS] > 0 &&
    [lsearch -exact $VT_ALLOWED_GROUPS all] < 0} {
    foreach vt $VT_ALLOWED_GROUPS {
        if {[lsearch -exact $all_vt_groups $vt] < 0} {
            error "Invalid VT_ALLOWED_GROUPS entry '$vt'. Valid groups are: $all_vt_groups, or all"
        }
    }
    echo "INFO: VT_ALLOWED_GROUPS = $VT_ALLOWED_GROUPS; disabling unlisted VT groups."
    foreach vt $all_vt_groups {
        if {[lsearch -exact $VT_ALLOWED_GROUPS $vt] >= 0} {
            continue
        }
        set cells [get_lib_cells -quiet -filter "threshold_voltage_group == $vt"]
        if {[sizeof_collection $cells] > 0} {
            set_attribute -quiet $cells -name dont_use -value true
            echo "INFO: marked VT group $vt dont_use for synthesis."
        }
    }
}

if {$low_vt_percentage < 0 || $low_vt_percentage >= 100} {
    echo "INFO: low_vt_percentage = $low_vt_percentage < 0 or >= 100; will NOT limit low-vt usage."
} elseif {$low_vt_percentage == 0} {
    echo "INFO: low_vt_percentage = 0; will NOT use low-vt groups: $low_vt_groups"
    foreach vt $low_vt_groups {
        set cells [get_lib_cells -quiet -filter "threshold_voltage_group == $vt"]
        if {[sizeof_collection $cells] > 0} {
            set_attribute -quiet $cells -name dont_use -value true
        }
    }
} else {
    echo "INFO: high_vt_groups = $high_vt_groups, normal_vt_groups = $normal_vt_groups, low_vt_groups = $low_vt_groups"
    echo "INFO: low_vt_percentage = $low_vt_percentage; limiting low-vt cell count."
    if {![info exists DIS_VT_CONSTRAIN] || $DIS_VT_CONSTRAIN == 0} {
        set_multi_vth_constraint -cost cell_count -low_vt_percentage $low_vt_percentage
    } else {
        echo "INFO: DIS_VT_CONSTRAIN = $DIS_VT_CONSTRAIN; low-vt percentage constraint disabled."
    }
}
