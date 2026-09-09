set TECH_NODE                 "tsmc28hpcplus"
set PDK_FC_CONFIGURED         1
set PDK_USE_AUTO_FLOORPLAN    1
set PDK_SKIP_TRACK_SCRIPT     1
set PDK_SKIP_PLACEMENT_RULES  1
set PDK_SET_TECHNOLOGY_NODE   ""
set PDK_PIN_COLOR_ALIGNMENT_LAYERS ""

set PDK_VT_GROUP_PATTERNS [list \
    [list HVT [list */*BWP7T40P140HVT]] \
    [list RVT [list */*BWP7T40P140]] \
    [list LVT [list */*BWP7T40P140LVT]]]
set PDK_HIGH_VT_GROUPS   {HVT}
set PDK_NORMAL_VT_GROUPS {RVT}
set PDK_LOW_VT_GROUPS    {LVT}

if {[info exists ::env(PDK_ROOT)] && $::env(PDK_ROOT) ne ""} {
    set pdk_root [file join $::env(PDK_ROOT) tsmc28hpcplus]
} else {
    set pdk_root [file normalize ~/PDK/tsmc28hpcplus]
}
set pdk_tsmchome $pdk_root/TSMCHOME
set pdk_ccs $pdk_tsmchome/digital/Front_End/timing_power_noise/CCS
set pdk_lef $pdk_tsmchome/digital/Back_End/lef
set pdk_tech $pdk_root/installed/tech

set PDK_TIMING_CORNER "ssg0p81v125c"
set PDK_TIMING_DB "${run_path}/ref/tcbn28hpcplusbwp7t40p140ssg0p81v125c_ccs.db"
set PDK_TIMING_DBS [list \
    $PDK_TIMING_DB \
    "${run_path}/ref/tcbn28hpcplusbwp7t40p140hvtssg0p81v125c_ccs.db" \
    "${run_path}/ref/tcbn28hpcplusbwp7t40p140lvtssg0p81v125c_ccs.db"]
set PDK_TIMING_LIB "${run_path}/ref/tcbn28hpcplusbwp7t40p140ssg0p81v0p81v125c_ccs.lib"
set PDK_PVT_CORNER "func_setup_ssg_0p81v_125c"
set PDK_PVT_VOLTAGE 0.81
set PDK_PVT_TEMPERATURE 125.0

set PDK_SKIP_FC_PARASITICS  0
set PDK_FC_PARASITIC_NAME  "cworst"
set PDK_FC_PARASITIC_FILE  "${run_path}/tech/tsmcn28_9lm_cworst.nxtgrd"
set layer_map_starrc_file   ""

set PDK_NDM_LIST [list \
    "${run_path}/ref/tcbn28hpcplusbwp7t40p140.ndm" \
    "${run_path}/ref/tcbn28hpcplusbwp7t40p140hvt.ndm" \
    "${run_path}/ref/tcbn28hpcplusbwp7t40p140lvt.ndm"]
set NDM_LIST $PDK_NDM_LIST
set TECH_LIB [lindex $PDK_NDM_LIST 0]
set PDK_PREFER_NDM_TECH 1

set ADDITIONAL_LINK_LIB_FILES {}
foreach vt {tcbn28hpcplusbwp7t40p140 tcbn28hpcplusbwp7t40p140hvt tcbn28hpcplusbwp7t40p140lvt} {
    foreach src [lsort [glob $pdk_ccs/${vt}_180a/*.db]] {
        lappend ADDITIONAL_LINK_LIB_FILES "${run_path}/ref/[file tail $src]"
    }
}

set TECH_FILE "${run_path}/tech/tsmcn28_9lm4X2Y2RUTRDL.tf"
set current_node "tsmc28hpcplus"
set tech_layer_type "9LM_4X2Y2R_UTRDL_VHV"
set write_gds_layer_map_file "${run_path}/tech/gdsout_4X2Y2R.map"
set min_routing_layer "M1"
set max_routing_layer "M9"
set PDK_SITE_NAME "core7T"
set PDK_SITE_WIDTH 0.140
set PDK_SITE_HEIGHT 0.700
set PDK_SITE_SYMMETRY {X Y}
set PDK_SITE_VIA_LEF "${run_path}/tech/tsmc28_7t_site_via.lef"
set PDK_PIN_LAYERS {M2 M3 M4 M5 M6}
set PDK_PIN_LAYERS_VERTICAL_EDGE {M2 M4 M6}
set PDK_PIN_LAYERS_HORIZONTAL_EDGE {M3 M5}

set pdk_rc   "$pdk_tech/rc_1p9m_4x2y2r"
set tlu_base "cln28hpc+_1p09m+ut-alrdl_4x2y2r"

set PDK_INPUT_LINKS [list \
    "${run_path}/tech/tsmcn28_9lm4X2Y2RUTRDL.tf" "$pdk_tech/synopsys_pr/N28_PRTF_Syn_v1d5a/PR_tech/Synopsys/TechFile/VHV/tsmcn28_9lm4X2Y2RUTRDL.tf" \
    "${run_path}/tech/antennaRule_n28_9lm.tcl" "$pdk_tech/synopsys_pr/N28_PRTF_Syn_v1d5a/PR_tech/Synopsys/SCM/antennaRule_n28_9lm.tcl" \
    "${run_path}/tech/gdsout_4X2Y2R.map" "$pdk_tech/synopsys_pr/N28_PRTF_Syn_v1d5a/PR_tech/Synopsys/GdsOutMap/gdsout_4X2Y2R.map" \
    "${run_path}/tech/tsmc28_7t_site_via.lef" "$pdk_tech/tsmc28_7t_site_via.lef" \
    "${run_path}/tech/tsmcn28_9lm_cworst.nxtgrd"  "$pdk_rc/${tlu_base}_cworst_T.nxtgrd"]

set PDK_OPTIONAL_INPUT_LINKS [list \
    "${run_path}/tech/tsmcn28_9lm_cbest.nxtgrd"   "$pdk_rc/${tlu_base}_cbest.nxtgrd"]

foreach vt {tcbn28hpcplusbwp7t40p140 tcbn28hpcplusbwp7t40p140hvt tcbn28hpcplusbwp7t40p140lvt} {
    lappend PDK_INPUT_LINKS "${run_path}/ref/${vt}.ndm" "$pdk_root/ndm/${vt}.ndm"
    foreach src [lsort [glob $pdk_ccs/${vt}_180a/*.{db,lib}]] {
        lappend PDK_INPUT_LINKS "${run_path}/ref/[file tail $src]" $src
    }
    foreach src [glob $pdk_lef/${vt}_110a/lef/*.lef] {
        lappend PDK_INPUT_LINKS "${run_path}/ref/[file tail $src]" $src
    }
    foreach src [glob $pdk_tsmchome/digital/Back_End/gds/${vt}_110a/*.gds] {
        lappend PDK_INPUT_LINKS "${run_path}/ref/[file tail $src]" $src
    }
}

lappend PDK_INPUT_LINKS \
    "${run_path}/ref/tsmc28_7t_all.spi" "$pdk_tsmchome/digital/Back_End/spice/tsmc28_7t_all.spi" \
    "${run_path}/ref/tsmc28_7t_all.v" "$pdk_tsmchome/digital/Front_End/verilog/tsmc28_7t_all.v"

set PDK_DFT_TARGET_DB [list \
    "${run_path}/ref/tcbn28hpcplusbwp7t40p140ssg0p81v125c_ccs.db" \
    "${run_path}/ref/tcbn28hpcplusbwp7t40p140hvtssg0p81v125c_ccs.db" \
    "${run_path}/ref/tcbn28hpcplusbwp7t40p140lvtssg0p81v125c_ccs.db"]
set PDK_DFT_TARGET_DB_BY_VT [dict create \
    RVT [list "${run_path}/ref/tcbn28hpcplusbwp7t40p140ssg0p81v125c_ccs.db"] \
    HVT [list "${run_path}/ref/tcbn28hpcplusbwp7t40p140hvtssg0p81v125c_ccs.db"] \
    LVT [list "${run_path}/ref/tcbn28hpcplusbwp7t40p140lvtssg0p81v125c_ccs.db"]]
set PDK_ATPG_VERILOG "${run_path}/ref/tsmc28_7t_all.v"
set PDK_DFT_SEARCH_PATH [list "${run_path}/ref" [file dirname $PDK_ATPG_VERILOG]]
