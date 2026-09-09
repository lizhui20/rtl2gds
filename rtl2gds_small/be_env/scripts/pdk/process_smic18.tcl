set TECH_NODE                 "smic18"
set PDK_FC_CONFIGURED         1
set PDK_USE_AUTO_FLOORPLAN    1
set PDK_SKIP_TRACK_SCRIPT     1
set PDK_SKIP_PLACEMENT_RULES  1
set PDK_SET_TECHNOLOGY_NODE   ""
set PDK_PIN_COLOR_ALIGNMENT_LAYERS ""

set pdk_root "${root_path}/pdk/smic18"
set pdk_sc   "${pdk_root}/digital/sc"

set PDK_TIMING_CORNER         "ss"
set PDK_TIMING_DB             "${run_path}/ref/slow.db"
set PDK_TIMING_DBS            [list $PDK_TIMING_DB]
set PDK_TIMING_LIB            "${run_path}/ref/slow.lib"
set PDK_PVT_CORNER            "slow_125"
set PDK_PVT_VOLTAGE           1.62
set PDK_PVT_TEMPERATURE       125.0
set PDK_FC_PARASITIC_NAME     "typical"
set PDK_FC_PARASITIC_FILE     "${run_path}/tech/smic18_typical.tluplus"

set PDK_NDM_LIST              [list "${run_path}/ref/smic18_lib.ndm"]
set NDM_LIST                  $PDK_NDM_LIST
set ADDITIONAL_LINK_LIB_FILES [list $PDK_TIMING_DB]

set PDK_INPUT_LINKS [list \
    "${run_path}/ref/smic18_lib.ndm"       "${pdk_root}/smic18_lib.ndm" \
    "${run_path}/ref/slow.db"              "${pdk_sc}/synopsys/slow.db" \
    "${run_path}/ref/slow.lib"             "${pdk_sc}/synopsys/slow.lib" \
    "${run_path}/tech/smic18_6lm.tf"       "${pdk_sc}/apollo/tf/smic18_6lm.tf" \
    "${run_path}/tech/smic18_6lm.lef"      "${pdk_sc}/lef/smic18_6lm.lef" \
    "${run_path}/tech/smic18_6lm.gds.map"  "${pdk_sc}/apollo/gds2OutLayer_6lm.map" \
    "${run_path}/tech/smic18_typical.itf"  "${pdk_root}/smic18_typical.itf" \
    "${run_path}/tech/smic18_typical.tluplus" "${pdk_root}/smic18_typical.tluplus"]
set PDK_OBSOLETE_RUN_VIEWS [list \
    "${run_path}/ref/fast.db" "${run_path}/ref/fast.lib" \
    "${run_path}/ref/typical.db" "${run_path}/ref/typical.lib"]

set current_node                 "smic18"
set tech_layer_type              "6M"
set TECH_FILE                    "${run_path}/tech/smic18_6lm.tf"
set layer_map_starrc_file        ""
set write_gds_layer_map_file     "${run_path}/tech/smic18_6lm.gds.map"
set min_routing_layer            "METAL1"
set max_routing_layer            "METAL6"
set PDK_PIN_LAYERS               {METAL2 METAL3 METAL4 METAL5 METAL6}
set PDK_PIN_LAYERS_VERTICAL_EDGE {METAL3 METAL5}
set PDK_PIN_LAYERS_HORIZONTAL_EDGE {METAL2 METAL4 METAL6}

set PDK_DFT_TARGET_DB  $PDK_TIMING_DB
set PDK_ATPG_VERILOG   "${pdk_sc}/verilog/smic18.v"
set PDK_DFT_SEARCH_PATH [list "${pdk_sc}/synopsys" "${pdk_sc}/verilog"]
