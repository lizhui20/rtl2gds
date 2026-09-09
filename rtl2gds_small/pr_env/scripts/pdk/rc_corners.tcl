if {![info exists PDK_PROFILE]} {
    error "PDK_PROFILE is not set before sourcing rc_corners.tcl"
}

proc mmcm_require_files {files label} {
    foreach f $files {
        if {![file exists $f]} {
            error "$label file missing: $f"
        }
    }
}

proc mmcm_corner_db_list {corner_name} {
    global REF_DIR MMCM_STD_VARIANTS MMCM_DB_SUFFIX
    if {![info exists MMCM_DB_SUFFIX($corner_name)]} {
        error "Unknown MMCM DB corner: $corner_name"
    }
    set suffix $MMCM_DB_SUFFIX($corner_name)
    set out [list]
    foreach variant $MMCM_STD_VARIANTS {
        lappend out ${REF_DIR}/${variant}${suffix}_ccs.db
    }
    return $out
}

proc mmcm_report_summary {} {
    global MCMM_MODE PNR_CORNERS PT_SIGNOFF_MAX_CORNER PT_SIGNOFF_MIN_CORNER PT_SETUP_DBS PT_HOLD_DBS
    puts "RM-info: MCMM mode = $MCMM_MODE"
    foreach c $PNR_CORNERS {
        lassign $c cname sname process volt temp pspec a_su a_ho a_dp a_lk
        puts "RM-info: MCMM corner $cname scenario=$sname pvt=${process}/${volt}V/${temp}C rc=$pspec setup=$a_su hold=$a_ho dyn=$a_dp leak=$a_lk"
    }
    if {[info exists PT_SIGNOFF_MAX_CORNER] && [info exists PT_SIGNOFF_MIN_CORNER]} {
        puts "RM-info: PT signoff max corner = $PT_SIGNOFF_MAX_CORNER"
        puts "RM-info: PT signoff min corner = $PT_SIGNOFF_MIN_CORNER"
    }
}

switch -- $PDK_PROFILE {
    tsmc28hpcplus {
        set MCMM_MODE func
        set MMCM_STD_VARIANTS [list \
            tcbn28hpcplusbwp7t40p140 \
            tcbn28hpcplusbwp7t40p140hvt \
            tcbn28hpcplusbwp7t40p140lvt]

        set SCEN_SS_HOT_LOWV    func_setup_ssg_0p81v_125c
        set SCEN_SS_COLD_LOWV   func_setup_ssg_0p81v_m40c
        set SCEN_FF_HOT_HIGHV   func_hold_ffg_0p99v_125c
        set SCEN_FF_COLD_HIGHV  func_hold_ffg_0p99v_m40c
        set SCEN_TT             func_tt_0p90v_25c

        array set MMCM_DB_SUFFIX {
            ss_hot_lowv     ssg0p81v125c
            ss_cold_lowv    ssg0p81vm40c
            ff_hot_highv    ffg0p99v125c
            ff_cold_highv   ffg0p99vm40c
            tt              tt0p9v25c
        }

        set PNR_CORNERS [list \
            [list ss_hot_lowv    $SCEN_SS_HOT_LOWV    "" 0.81 125 cworst true  false false false] \
            [list ss_cold_lowv   $SCEN_SS_COLD_LOWV   "" 0.81 -40 cworst true  false false false] \
            [list ff_hot_highv   $SCEN_FF_HOT_HIGHV   "" 0.99 125 cbest false true  false false] \
            [list ff_cold_highv  $SCEN_FF_COLD_HIGHV  "" 0.99 -40 cbest false true  false false] \
            [list tt             $SCEN_TT             "" 0.90  25 typical false false true  false]]

        set PT_SIGNOFF_MAX_CORNER ss_cold_lowv
        set PT_SIGNOFF_MIN_CORNER ff_cold_highv
        set PT_SETUP_DBS [mmcm_corner_db_list $PT_SIGNOFF_MAX_CORNER]
        set PT_HOLD_DBS  [mmcm_corner_db_list $PT_SIGNOFF_MIN_CORNER]
    }
    smic18 {
        set MCMM_MODE func
        set SCEN_SETUP func_ss_1p62v_125c
        set SCEN_HOLD  $SCEN_SETUP
        set SCEN_TT    $SCEN_SETUP
        set SCEN_LEAK  $SCEN_SETUP
        set PNR_CORNERS [list \
            [list ss $SCEN_SETUP "" 1.62 125 typical true true true true]]
        set PT_SIGNOFF_MAX_CORNER ss
        set PT_SIGNOFF_MIN_CORNER ss
        set PT_SETUP_DBS [list ${REF_DIR}/slow.db]
        set PT_HOLD_DBS  [list ${REF_DIR}/fast.db]
    }
    default {
        error "Unsupported PDK_PROFILE for shared MCMM: $PDK_PROFILE"
    }
}

mmcm_require_files $PT_SETUP_DBS "PT setup DB"
mmcm_require_files $PT_HOLD_DBS  "PT hold DB"
