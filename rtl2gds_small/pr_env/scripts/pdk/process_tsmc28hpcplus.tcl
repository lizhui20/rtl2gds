set TECH_FILE    ${TECH_DIR}/tsmcn28_9lm4X2Y2RUTRDL.tf
set GDS_MAP      ${TECH_DIR}/gdsout_4X2Y2R.map
set ANTENNA_RULE ${TECH_DIR}/antennaRule_n28_9lm.tcl
set CALIBRE_RC   ${TECH_DIR}/DFM_LVS_RC_CALIBRE_N28HP_1p9m_ALRDL.v1.0_3o

set SITE_NAME       core7T
set SITE_WIDTH      0.140
set SITE_HEIGHT     0.700
set SITE_SYMMETRY   {X Y}
set MIN_ROUTE_LAYER M1
set MAX_ROUTE_LAYER M9
set PIN_LAYERS      {M4 M5 M6}

set RVT_NDM ${REF_DIR}/tcbn28hpcplusbwp7t40p140.ndm
set HVT_NDM ${REF_DIR}/tcbn28hpcplusbwp7t40p140hvt.ndm
set LVT_NDM ${REF_DIR}/tcbn28hpcplusbwp7t40p140lvt.ndm
set REFERENCE_LIBS [list $RVT_NDM $HVT_NDM $LVT_NDM]

set STD_GDS [list \
    ${REF_DIR}/tcbn28hpcplusbwp7t40p140.gds \
    ${REF_DIR}/tcbn28hpcplusbwp7t40p140hvt.gds \
    ${REF_DIR}/tcbn28hpcplusbwp7t40p140lvt.gds]
set STD_CDL     ${REF_DIR}/tsmc28_7t_all.spi
set STD_VERILOG ${REF_DIR}/tsmc28_7t_all.v
set FORMALITY_DB_FILES [list \
    ${REF_DIR}/tcbn28hpcplusbwp7t40p140ssg0p81v125c_ccs.db \
    ${REF_DIR}/tcbn28hpcplusbwp7t40p140hvtssg0p81v125c_ccs.db \
    ${REF_DIR}/tcbn28hpcplusbwp7t40p140lvtssg0p81v125c_ccs.db]
set PDK_DFT_TARGET_DB $FORMALITY_DB_FILES
set PDK_ATPG_VERILOG  $STD_VERILOG
set PDK_DFT_SEARCH_PATH [list ${REF_DIR}]

set PDK_VT_GROUP_PATTERNS [list \
    [list HVT [list */*BWP7T40P140HVT]] \
    [list RVT [list */*BWP7T40P140]] \
    [list LVT [list */*BWP7T40P140LVT]]]
set PDK_HIGH_VT_GROUPS   {HVT}
set PDK_NORMAL_VT_GROUPS {RVT}
set PDK_LOW_VT_GROUPS    {LVT}

if {![info exists N28_FILLER_VT]} { set N28_FILLER_VT rvt }
switch -- $N28_FILLER_VT {
    rvt {
        set GFILLER_CELLS { \
            tcbn28hpcplusbwp7t40p140/GFILL12BWP7T30P140 \
            tcbn28hpcplusbwp7t40p140/GFILL10BWP7T30P140 \
            tcbn28hpcplusbwp7t40p140/GFILL4BWP7T30P140 \
            tcbn28hpcplusbwp7t40p140/GFILL3BWP7T30P140 \
            tcbn28hpcplusbwp7t40p140/GFILL2BWP7T30P140 \
            tcbn28hpcplusbwp7t40p140/GFILLBWP7T30P140}
        set FILLER_CELLS  { \
            tcbn28hpcplusbwp7t40p140/FILL64BWP7T40P140 \
            tcbn28hpcplusbwp7t40p140/FILL32BWP7T40P140 \
            tcbn28hpcplusbwp7t40p140/FILL16BWP7T40P140 \
            tcbn28hpcplusbwp7t40p140/FILL8BWP7T40P140 \
            tcbn28hpcplusbwp7t40p140/FILL4BWP7T40P140 \
            tcbn28hpcplusbwp7t40p140/FILL3BWP7T40P140 \
            tcbn28hpcplusbwp7t40p140/FILL2BWP7T40P140}
    }
    hvt {
        set GFILLER_CELLS { \
            tcbn28hpcplusbwp7t40p140hvt/GFILL12BWP7T30P140HVT \
            tcbn28hpcplusbwp7t40p140hvt/GFILL10BWP7T30P140HVT \
            tcbn28hpcplusbwp7t40p140hvt/GFILL4BWP7T30P140HVT \
            tcbn28hpcplusbwp7t40p140hvt/GFILL3BWP7T30P140HVT \
            tcbn28hpcplusbwp7t40p140hvt/GFILL2BWP7T30P140HVT \
            tcbn28hpcplusbwp7t40p140hvt/GFILLBWP7T30P140HVT}
        set FILLER_CELLS  { \
            tcbn28hpcplusbwp7t40p140hvt/FILL64BWP7T40P140HVT \
            tcbn28hpcplusbwp7t40p140hvt/FILL32BWP7T40P140HVT \
            tcbn28hpcplusbwp7t40p140hvt/FILL16BWP7T40P140HVT \
            tcbn28hpcplusbwp7t40p140hvt/FILL8BWP7T40P140HVT \
            tcbn28hpcplusbwp7t40p140hvt/FILL4BWP7T40P140HVT \
            tcbn28hpcplusbwp7t40p140hvt/FILL3BWP7T40P140HVT \
            tcbn28hpcplusbwp7t40p140hvt/FILL2BWP7T40P140HVT}
    }
    lvt {
        set GFILLER_CELLS { \
            tcbn28hpcplusbwp7t40p140lvt/GFILL12BWP7T30P140LVT \
            tcbn28hpcplusbwp7t40p140lvt/GFILL10BWP7T30P140LVT \
            tcbn28hpcplusbwp7t40p140lvt/GFILL4BWP7T30P140LVT \
            tcbn28hpcplusbwp7t40p140lvt/GFILL3BWP7T30P140LVT \
            tcbn28hpcplusbwp7t40p140lvt/GFILL2BWP7T30P140LVT \
            tcbn28hpcplusbwp7t40p140lvt/GFILLBWP7T30P140LVT}
        set FILLER_CELLS  { \
            tcbn28hpcplusbwp7t40p140lvt/FILL64BWP7T40P140LVT \
            tcbn28hpcplusbwp7t40p140lvt/FILL32BWP7T40P140LVT \
            tcbn28hpcplusbwp7t40p140lvt/FILL16BWP7T40P140LVT \
            tcbn28hpcplusbwp7t40p140lvt/FILL8BWP7T40P140LVT \
            tcbn28hpcplusbwp7t40p140lvt/FILL4BWP7T40P140LVT \
            tcbn28hpcplusbwp7t40p140lvt/FILL3BWP7T40P140LVT \
            tcbn28hpcplusbwp7t40p140lvt/FILL2BWP7T40P140LVT}
    }
    mixed {
        set GFILLER_CELLS {*/GFILL12BWP7T30P140* */GFILL10BWP7T30P140* */GFILL4BWP7T30P140* */GFILL3BWP7T30P140* */GFILL2BWP7T30P140* */GFILLBWP7T30P140*}
        set FILLER_CELLS  {*/FILL64BWP7T40P140* */FILL32BWP7T40P140* */FILL16BWP7T40P140* */FILL8BWP7T40P140* */FILL4BWP7T40P140* */FILL3BWP7T40P140* */FILL2BWP7T40P140*}
    }
    default {
        error "N28_FILLER_VT must be rvt, hvt, lvt, or mixed"
    }
}
set TIE_CELLS     {*/TIEHBWP7T40P140* */TIELBWP7T40P140*}
set HOLD_FIX_CELLS { \
    */DEL100MD1BWP7T40P140 \
    */DEL075MD1BWP7T40P140 \
    */DEL050MD1BWP7T40P140 \
    */DEL150MD1BWP7T40P140 \
    */BUFFD1BWP7T40P140 \
    */BUFFD0BWP7T40P140}
set TIE_MAX_FANOUT 8
set ANTENNA_CELLS {*/ANTENNABWP7T40P140*}
set TAP_CELL      tcbn28hpcplusbwp7t40p140/TAPCELLBWP7T40P140
set TAP_DISTANCE  60.0
set TAP_PATTERN   every_other_row
set LEFT_BOUNDARY_CELL  tcbn28hpcplusbwp7t40p140/BOUNDARY_LEFTBWP7T40P140
set RIGHT_BOUNDARY_CELL tcbn28hpcplusbwp7t40p140/BOUNDARY_RIGHTBWP7T40P140

set PG_POWER_NET  VDD
set PG_GROUND_NET VSS
set PG_RING_H_LAYER M5
set PG_RING_V_LAYER M6
set PG_RING_WIDTH 0.40
set PG_RING_SPACING 0.40
set PG_MESH_H_LAYER M5
set PG_MESH_V_LAYER M6
set PG_MESH_WIDTH 0.20
set PG_MESH_PITCH 10
set PG_MESH_OFFSET 2
set PG_BRIDGE_LAYER M4
set PG_BRIDGE_WIDTH 0.14
set PG_BRIDGE_PITCH 10
set PG_BRIDGE_OFFSET 2
set PG_BRIDGE_TO_MESH_VIA VIA45_FBD20
set PG_RAIL_TO_BRIDGE_VIAS {VIA12_FBS25}
set PG_RAIL_LAYER M1
set PG_RAIL_CONNECT_LAYER M4
set ENABLE_PG_DROP_PLACEMENT_BLOCKAGE 1
set PG_DROP_BLOCKAGE_WIDTH 0.84
set PG_DROP_BLOCKAGE_OFFSETS {primary}
set PG_DROP_NARROW_BLOCKAGE_WIDTH 0.14
set PG_DROP_NARROW_BLOCKAGE_OFFSETS {}
set PG_DROP_MIN_EDGE_FRAGMENT_WIDTH 3.00
if {![info exists ROUTE_DRC_APP_OPTIONS] || [llength $ROUTE_DRC_APP_OPTIONS] == 0} {
	    set ROUTE_DRC_APP_OPTIONS {
	        {route.detail.drc_convergence_effort_level high}
	        {route.detail.detail_route_special_design_rule_fixing_stage early_routing}
	        {route.detail.use_default_width_for_min_area_min_len_stub true}
	        {route.detail.optimize_wire_via_effort_level high}
	        {route.common.connect_within_pins_by_layer_name {{M2 via_wire_standard_cell_pins}}}
	        {route.detail.generate_extra_off_grid_pin_tracks true}
	        {route.detail.use_wide_wire_effort_level high}
	        {route.detail.use_wide_wire_to_input_pin true}
	        {route.detail.use_wide_wire_to_output_pin true}
	    }
	}
if {![info exists ENABLE_CTS_NDR]} { set ENABLE_CTS_NDR 1 }
if {![info exists CTS_NDR_LAYERS]} { set CTS_NDR_LAYERS {M6 M7} }
if {![info exists CTS_NDR_WIDTH]} { set CTS_NDR_WIDTH 0.10 }
if {![info exists CTS_NDR_SPACING]} { set CTS_NDR_SPACING 0.10 }
if {![info exists CTS_MIN_LAYER]} { set CTS_MIN_LAYER M6 }
if {![info exists CTS_MAX_LAYER]} { set CTS_MAX_LAYER M7 }
if {![info exists MAX_TRANSITION]} { set MAX_TRANSITION "" }

set IO_REFERENCE_LIBS {}
set IO_GDS_FILES {}
set IO_LEF_FILES {}
if {![info exists ENABLE_IO_LIBRARY]} { set ENABLE_IO_LIBRARY 0 }
if {$ENABLE_IO_LIBRARY} {
    foreach pat [list *io*.ndm *IO*.ndm *pad*.ndm *PAD*.ndm *tpbn*.ndm *tpio*.ndm *gpio*.ndm *tphn*.ndm *pgv*.ndm] {
        foreach f [glob -nocomplain ${REF_DIR}/$pat] { lappend IO_REFERENCE_LIBS $f }
    }
    foreach pat [list *io*.gds *IO*.gds *pad*.gds *PAD*.gds *tpbn*.gds *tpio*.gds *gpio*.gds *tphn*.gds *pgv*.gds] {
        foreach f [glob -nocomplain ${REF_DIR}/$pat] { lappend IO_GDS_FILES $f }
    }
    foreach pat [list *io*.lef *IO*.lef *pad*.lef *PAD*.lef *tpbn*.lef *tpio*.lef *gpio*.lef *tphn*.lef *pgv*.lef] {
        foreach f [glob -nocomplain ${REF_DIR}/$pat] { lappend IO_LEF_FILES $f }
    }
    set IO_REFERENCE_LIBS [lsort -unique $IO_REFERENCE_LIBS]
    set IO_GDS_FILES [lsort -unique $IO_GDS_FILES]
    set IO_LEF_FILES [lsort -unique $IO_LEF_FILES]
    if {[llength $IO_REFERENCE_LIBS] > 0} {
        set REFERENCE_LIBS [concat $REFERENCE_LIBS $IO_REFERENCE_LIBS]
        puts "RM-info: IO reference NDM enabled: $IO_REFERENCE_LIBS"
    } else {
        puts "RM-warning: ENABLE_IO_LIBRARY=1 but no IO/pad NDM views were linked in ${REF_DIR}; continuing with std-cell refs."
    }
    if {[llength $IO_GDS_FILES] > 0} {
        set STD_GDS [concat $STD_GDS $IO_GDS_FILES]
        puts "RM-info: IO GDS enabled: $IO_GDS_FILES"
    }
}


set PARASITIC_ENABLED 1
set TLU_MAP     ""
set PDK_TSMC_ROOT ${ROOT_PATH}/pdk/tsmc28hpcplus
set PDK_RC_DIR    ${PDK_TSMC_ROOT}/installed/tech/rc_1p9m_4x2y2r
set TLU_BASE      cln28hpc+_1p09m+ut-alrdl_4x2y2r
set TLU_TYPICAL   ${PDK_RC_DIR}/${TLU_BASE}_typical.tluplus
set TLU_CWORST    ${PDK_RC_DIR}/${TLU_BASE}_cworst_T.tluplus
set TLU_CBEST     ${PDK_RC_DIR}/${TLU_BASE}_cbest.tluplus
set STARRC_NXTGRD_CWORST ${TECH_DIR}/tsmcn28_9lm_cworst.nxtgrd
set STARRC_NXTGRD_CBEST  ${TECH_DIR}/tsmcn28_9lm_cbest.nxtgrd
set STARRC_ITF_TYPICAL ${PDK_RC_DIR}/${TLU_BASE}_typical.itf
set STARRC_ITF_CWORST  ${PDK_RC_DIR}/${TLU_BASE}_cworst_T.itf
set STARRC_ITF_CBEST   ${PDK_RC_DIR}/${TLU_BASE}_cbest.itf
set RC_CBEST_NOTE "cbest parasitic technology uses the foundry cbest ITF/TLUPlus/NXTGRD"
set STARRC_LEF_FILES [list \
    ${ROOT_PATH}/scripts/signoff/tsmc28hpcplus_starrc_tech.lef \
    ${REF_DIR}/tcbn28hpcplusbwp7t40p140.lef \
    ${REF_DIR}/tcbn28hpcplusbwp7t40p140hvt.lef \
    ${REF_DIR}/tcbn28hpcplusbwp7t40p140lvt.lef]
if {[info exists IO_LEF_FILES] && [llength $IO_LEF_FILES] > 0} {
    set STARRC_LEF_FILES [concat $STARRC_LEF_FILES $IO_LEF_FILES]
}
set CALIBRE_LVS_RC_DECK $CALIBRE_RC
set STARRC_MAP ${ROOT_PATH}/scripts/signoff/tsmc28hpcplus_starrc_1p9m.map
set TLU_SPECS [list \
    [list typical $TLU_TYPICAL] \
    [list cworst  $TLU_CWORST] \
    [list cbest   $TLU_CBEST]]
