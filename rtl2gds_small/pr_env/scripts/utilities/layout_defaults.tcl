set MAX_TRANSITION ""
set MAX_TRANSITION_REPAIR_TARGET 0.45
set MAX_FANOUT 16

set CORE_UTILIZATION 0.50
set FLOORPLAN_CORE_OFFSET {2 2}
set PG_RING_OFFSET {0.4 0.4}

set ENABLE_IO_PLACEMENT 0
set IO_PLACEMENT_FILE ""

set ENABLE_IO_LIBRARY 0

set ENABLE_CLOCK_GATING 0
set VT_ALLOWED_GROUPS {RVT}

set ENABLE_CTS_NDR 1
set CTS_NDR_LAYERS {M6 M7}
set CTS_NDR_WIDTH 0.10
set CTS_NDR_SPACING 0.10
set CTS_MIN_LAYER M6
set CTS_MAX_LAYER M7

set ENABLE_MAX_CAP_REPAIR 1
set MAX_CAP_REPAIR_MAX_ITERATIONS 4
set MAX_CAP_REPAIR_DRIVE_STRENGTHS {0 1 2 4 8 12 16 20 24 32}

set ENABLE_METAL_FILL 0
set METAL_FILL_TRACK_MODE "generic"
set METAL_FILL_LAYERS {}

set ENABLE_CALIBRE_DUMMY_FILL 1
set ENABLE_CALIBRE_TCD_FILL 0

set ENABLE_GFILL_STD_FILL 0

set ENABLE_ROUTE_DRC_SHAPE_CONTROLS 1
set ROUTE_DRC_APP_OPTIONS {}

set SPEF_EXTRACTOR "starrc"

set SPEF_SETUP_CORNER "cworst"
set SPEF_HOLD_CORNER  "cbest"

set N28_DRC_MODE "block"

set N28_FILLER_VT "rvt"

set SIGNOFF_REQUIRE_CLEAN 1

set DFT_CLOCKS {}
set DFT_RESETS {}
set SCAN_ENABLE_PORT "scan_en"
set SCAN_CHAIN_COUNT 1
set TEST_MODE_PORT "test_mode"
set DFT_CLOCK_MIXING "mix_edges"
set DFT_ADD_TEST_RETIMING_FLOPS "none"
set ATPG_ABORT_LIMIT 100

if {$SIGNOFF_REQUIRE_CLEAN ni {0 1}} {
    error "SIGNOFF_REQUIRE_CLEAN must be 0 or 1"
}

if {$MAX_TRANSITION ne "" && $MAX_TRANSITION <= 0} { error "MAX_TRANSITION must be greater than zero or empty" }
if {$MAX_TRANSITION_REPAIR_TARGET ne "" && $MAX_TRANSITION_REPAIR_TARGET <= 0} {
    error "MAX_TRANSITION_REPAIR_TARGET must be greater than zero or empty"
}
if {$MAX_FANOUT <= 0} { error "MAX_FANOUT must be greater than zero" }
if {$CORE_UTILIZATION <= 0 || $CORE_UTILIZATION >= 1} {
    error "CORE_UTILIZATION must be between zero and one"
}
if {$ENABLE_IO_PLACEMENT ni {0 1}} {
    error "ENABLE_IO_PLACEMENT must be 0 or 1"
}
if {$ENABLE_IO_LIBRARY ni {0 1}} {
    error "ENABLE_IO_LIBRARY must be 0 or 1"
}
if {$ENABLE_CLOCK_GATING ni {0 1}} {
    error "ENABLE_CLOCK_GATING must be 0 or 1"
}
if {[llength $VT_ALLOWED_GROUPS] == 0} {
    error "VT_ALLOWED_GROUPS must be a non-empty list, or {all}"
}
if {$ENABLE_CTS_NDR ni {0 1}} {
    error "ENABLE_CTS_NDR must be 0 or 1"
}
if {$ENABLE_CTS_NDR} {
    if {[llength $CTS_NDR_LAYERS] == 0} {
        error "CTS_NDR_LAYERS must not be empty when ENABLE_CTS_NDR=1"
    }
    if {$CTS_NDR_WIDTH <= 0 || $CTS_NDR_SPACING <= 0} {
        error "CTS_NDR_WIDTH and CTS_NDR_SPACING must be greater than zero"
    }
}
if {$ENABLE_MAX_CAP_REPAIR ni {0 1}} {
    error "ENABLE_MAX_CAP_REPAIR must be 0 or 1"
}
if {$MAX_CAP_REPAIR_MAX_ITERATIONS <= 0} {
    error "MAX_CAP_REPAIR_MAX_ITERATIONS must be greater than zero"
}
if {[llength $MAX_CAP_REPAIR_DRIVE_STRENGTHS] == 0} {
    error "MAX_CAP_REPAIR_DRIVE_STRENGTHS must be a non-empty list"
}
if {$ENABLE_METAL_FILL ni {0 1}} {
    error "ENABLE_METAL_FILL must be 0 or 1"
}
if {$METAL_FILL_TRACK_MODE ni {off generic tsmc28}} {
    error "METAL_FILL_TRACK_MODE must be off, generic, or tsmc28"
}
if {$ENABLE_GFILL_STD_FILL ni {0 1}} {
    error "ENABLE_GFILL_STD_FILL must be 0 or 1"
}
if {$ENABLE_ROUTE_DRC_SHAPE_CONTROLS ni {0 1}} {
    error "ENABLE_ROUTE_DRC_SHAPE_CONTROLS must be 0 or 1"
}
if {$SPEF_EXTRACTOR ne "starrc"} {
    error "SPEF_EXTRACTOR must be starrc"
}
if {$N28_DRC_MODE ni {block fullchip}} {
    error "N28_DRC_MODE must be block or fullchip"
}
if {$N28_FILLER_VT ni {rvt hvt lvt mixed}} {
    error "N28_FILLER_VT must be rvt, hvt, lvt, or mixed"
}
if {$SCAN_CHAIN_COUNT <= 0} {
    error "SCAN_CHAIN_COUNT must be greater than zero"
}
if {$ATPG_ABORT_LIMIT <= 0} {
    error "ATPG_ABORT_LIMIT must be greater than zero"
}
