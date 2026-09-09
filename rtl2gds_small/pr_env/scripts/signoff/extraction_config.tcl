set design $env(DESIGN_NAME)
set root $env(ROOT_PATH)
set ROOT_PATH $root
set run ${root}/${design}
set TECH_DIR ${run}/tech
set REF_DIR ${run}/ref
source ${root}/scripts/pdk/process_select.tcl
source ${root}/scripts/pdk/process_${PDK_PROFILE}.tcl
source ${root}/scripts/pdk/rc_corners.tcl
source ${root}/scripts/utilities/layout_defaults.tcl
set design_user_setup_file ${run}/inputs/${design}.pr_user_setting.tcl
if {[file exists $design_user_setup_file]} {
    source $design_user_setup_file
}

proc starrc_corner_info {run corner} {
    switch -- $corner {
        typical { return [list ${run}/work/signoff/starrc/tsmcn28_9lm_typical.nxtgrd 25] }
        cworst  { return [list ${run}/work/signoff/starrc/tsmcn28_9lm_cworst.nxtgrd 125] }
        cbest   { return [list ${run}/work/signoff/starrc/tsmcn28_9lm_cbest.nxtgrd -40] }
        default { error "unsupported StarRC corner: $corner" }
    }
}

proc starrc_lappend_unique {list_name value} {
    upvar $list_name values
    if {[lsearch -exact $values $value] < 0} {
        lappend values $value
    }
}

proc starrc_defined_vias_from_lefs {lef_files} {
    set vias {}
    foreach lef $lef_files {
        if {![file exists $lef]} {
            error "StarRC LEF missing: $lef"
        }
        set fh [open $lef r]
        while {[gets $fh line] >= 0} {
            if {[regexp {^\s*VIA\s+(\S+)} $line -> via]} {
                starrc_lappend_unique vias $via
            }
        }
        close $fh
    }
    return $vias
}

proc starrc_vias_from_def {def_file} {
    if {![file exists $def_file]} {
        error "StarRC DEF missing: $def_file"
    }
    set defined {}
    set used {}
    set in_vias 0
    set fh [open $def_file r]
    while {[gets $fh line] >= 0} {
        if {[regexp {^\s*VIAS\s+[0-9]+\s*;} $line]} {
            set in_vias 1
        } elseif {$in_vias && [regexp {^\s*END\s+VIAS\b} $line]} {
            set in_vias 0
        } elseif {$in_vias && [regexp {^\s*-\s+(\S+)} $line -> via]} {
            starrc_lappend_unique defined $via
        }

        foreach via [regexp -all -inline {\mVIA[0-9][0-9][A-Za-z0-9_]*\M} $line] {
            starrc_lappend_unique used $via
        }
    }
    close $fh
    return [list $defined $used]
}

proc starrc_assert_def_vias_defined {def_file lef_files} {
    lassign [starrc_vias_from_def $def_file] def_defined def_used
    set lef_defined [starrc_defined_vias_from_lefs $lef_files]
    set known [concat $def_defined $lef_defined]
    set missing {}
    foreach via $def_used {
        if {[lsearch -exact $known $via] < 0} {
            starrc_lappend_unique missing $via
        }
    }
    if {[llength $missing] > 0} {
        error "StarRC DEF uses via(s) not defined in DEF VIAS or STARRC_LEF_FILES: [lsort $missing]"
    }
}

set mode mmcm
if {[info exists env(RC_CORNER)]} { set mode $env(RC_CORNER) }
switch -- $mode {
    mmcm {
        set corners [list $SPEF_SETUP_CORNER $SPEF_HOLD_CORNER]
    }
    default {
        set corners [list $mode]
    }
}
set unique_corners {}
foreach corner $corners {
    if {[lsearch -exact $unique_corners $corner] < 0} {
        lappend unique_corners $corner
    }
}
set corners $unique_corners
if {[llength $corners] < 2} {
    error "StarRC SMC requires at least two RC corners; got: $corners"
}

set out ${run}/work/signoff/starrc/${design}.mmcm.cmd
set corners_file ${run}/work/signoff/starrc/${design}.mmcm.corners
set spef ${run}/results/signoff/${design}.spef
set top_def ${run}/work/signoff/starrc/${design}.pnr.def
starrc_assert_def_vias_defined $top_def $STARRC_LEF_FILES

set cfh [open $corners_file w]
foreach corner $corners {
    lassign [starrc_corner_info $run $corner] grd temp
    if {![file exists $grd]} {
        error "StarRC grid file missing for $corner: $grd"
    }
    puts $cfh "CORNER_NAME: $corner"
    puts $cfh "TCAD_GRD_FILE: $grd"
    puts $cfh "OPERATING_TEMPERATURE: $temp"
}
close $cfh

set fh [open $out w]
puts $fh "BLOCK: $design"
foreach lef $STARRC_LEF_FILES { puts $fh "LEF_FILE: $lef" }
puts $fh "TOP_DEF_FILE: $top_def"
puts $fh "CORNERS_FILE: $corners_file"
puts $fh "SELECTED_CORNERS: $corners"
if {$STARRC_MAP ne ""} { puts $fh "MAPPING_FILE: $STARRC_MAP" }
puts $fh "EXTRACTION: RC"
puts $fh "COUPLE_TO_GROUND: NO"
puts $fh "REDUCTION: NO"
puts $fh "NETLIST_FORMAT: SPEF"
puts $fh "NETLIST_FILE: $spef"
puts $fh "NETLIST_NAME_MAP: YES"
puts $fh "SIMULTANEOUS_MULTI_CORNER: YES"
puts $fh "NUM_CORES: 1"
close $fh
puts $out
exit
