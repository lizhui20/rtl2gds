set EXIT_STATUS         0

set LOGIC_SYN           0
set DIRTY_LINK          0
set NO_BOUNDARY_OPT     0
set corner              2           ;
set process_corner      "ss"        ;
set LVTH_PERCENT        20.0
set VT_ALLOWED_GROUPS   {RVT}
set MAX_TRANSITION      0.3
set ENABLE_CLOCK_GATING 0
set MAX_ICG             99999
set DIS_VT_CONSTRAIN        0
set EN_FC_AUTO_BOUNDARY_OPT 1
set FINAL_OPT_2ND           0

set mode                "func"
set LINK_ONLY           "0"
set IS_FLATTEN          "1"

set FM_MODE             "SYN2DFT"

set DFT_CLOCKS          {}
set DFT_RESETS          {}
set SCAN_ENABLE_PORT    "scan_en"
set SCAN_CHAIN_COUNT    1
set TEST_MODE_PORT      "test_mode"
set DFT_CLOCK_MIXING    "mix_edges"
set DFT_ADD_TEST_RETIMING_FLOPS "none"
