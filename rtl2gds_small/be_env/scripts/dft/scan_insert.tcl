source $env(ROOT_PATH)/scripts/dft/scan_context.tcl

puts "\[info] TestMAX-DFT (DFT Compiler) scan insertion: START  design=$DESIGN_NAME"

set DESIGN_SDC "${run_path}/inputs/${DESIGN_NAME}.sdc"

proc dft_has_pair_name {pairs name} {
    foreach {item value} $pairs {
        if {$item eq $name} {
            return 1
        }
    }
    return 0
}

proc dft_read_sdc_clocks {sdc} {
    set clocks {}
    if {![file exists $sdc]} {
        return $clocks
    }

    set fh [open $sdc r]
    set raw_lines [split [read $fh] "\n"]
    close $fh

    set lines {}
    set current ""
    foreach raw_line $raw_lines {
        set line [string trimright $raw_line]
        if {[string match {*\\} $line]} {
            append current [string range $line 0 end-1] " "
            continue
        }
        append current $line
        lappend lines $current
        set current ""
    }
    if {[string trim $current] ne ""} {
        lappend lines $current
    }

    foreach line $lines {
        set trimmed [string trim $line]
        if {$trimmed eq "" || [string match "#*" $trimmed]} {
            continue
        }
        if {![regexp {^[ \t]*create_clock} $line]} {
            continue
        }
        if {![regexp -- {-period[ \t]+([^ \t\]]+)} $line -> period]} {
            continue
        }

        set get_ports_pos [string first "get_ports" $line]
        if {$get_ports_pos < 0} {
            continue
        }
        set port_text [string trim [string range $line [expr {$get_ports_pos + 9}] end]]
        if {$port_text eq ""} {
            continue
        }

        set ports {}
        if {[string index $port_text 0] eq "\{"} {
            set close_pos [string first "\}" $port_text 1]
            if {$close_pos < 0} {
                continue
            }
            set ports [string range $port_text 1 [expr {$close_pos - 1}]]
        } else {
            set port [lindex [split $port_text " \t\]"] 0]
            set ports [list $port]
        }

        foreach port $ports {
            if {$port ne "" && ![dft_has_pair_name $clocks $port]} {
                lappend clocks $port $period
            }
        }
    }

    return $clocks
}

proc dft_infer_reset_ports {} {
    set resets {}
    foreach_in_collection port [get_ports -quiet *] {
        set name [get_object_name $port]
        set lower [string tolower $name]
        if {![regexp {(^|[_/])(rst|reset)(_?n)?($|[_/])} $lower]} {
            continue
        }

        set active_state 1
        if {[regexp {(^|[_/])(rst|reset)(_?n)($|[_/])} $lower]} {
            set active_state 0
        }
        lappend resets $name $active_state
    }
    return $resets
}

set search_path [concat "." $DFT_SEARCH_PATH $search_path]
dft_require_file $INPUT_NETLIST "Input netlist (INPUT_NETLIST)"
if {$TARGET_LIBRARY eq ""} { puts "\[DFT-ERROR] TARGET_LIBRARY empty (set it in scan_options.tcl)"; exit 1 }
set target_library $TARGET_LIBRARY
set link_library   [concat "*" $LINK_LIBRARY]

read_verilog $INPUT_NETLIST
current_design $DESIGN_NAME
link

if {[llength $DFT_CLOCKS] == 0} {
    set DFT_CLOCKS [dft_read_sdc_clocks $DESIGN_SDC]
    puts "\[DFT-WARN] DFT_CLOCKS empty; inferred from simple top-level create_clock commands in $DESIGN_SDC"
    puts "\[info] inferred DFT_CLOCKS: $DFT_CLOCKS"
}
set DFT_RESETS_INFERRED 0
if {[llength $DFT_RESETS] == 0} {
    set DFT_RESETS_INFERRED 1
    set DFT_RESETS [dft_infer_reset_ports]
    puts "\[DFT-WARN] DFT_RESETS empty; inferred from reset-like top-level port names"
    puts "\[info] inferred DFT_RESETS: $DFT_RESETS"
}
if {[llength $DFT_CLOCKS] == 0} {
    puts "\[DFT-ERROR] unable to infer DFT_CLOCKS from $DESIGN_SDC"
    exit 1
}
if {[expr {[llength $DFT_CLOCKS] % 2}] != 0} {
    puts "\[DFT-ERROR] DFT_CLOCKS must be a list of {clock period} pairs: $DFT_CLOCKS"
    exit 1
}
if {[expr {[llength $DFT_RESETS] % 2}] != 0} {
    puts "\[DFT-ERROR] DFT_RESETS must be a list of {reset active_state} pairs: $DFT_RESETS"
    exit 1
}

foreach {clk period} $DFT_CLOCKS {
    if {[sizeof_collection [get_ports -quiet $clk]] == 0} {
        puts "\[DFT-WARN] clock port '$clk' not found in design -- skipped"
        continue
    }
    set_dft_signal -view existing_dft -type MasterClock -port $clk -timing {45 55}
}

if {[sizeof_collection [get_ports -quiet $SCAN_ENABLE_PORT]] == 0} {
    create_port $SCAN_ENABLE_PORT -direction in
}
set_dft_signal -view spec -type ScanEnable -port $SCAN_ENABLE_PORT -active_state 1
if {$TEST_MODE_PORT ne ""} {
    if {[sizeof_collection [get_ports -quiet $TEST_MODE_PORT]] == 0} {
        create_port $TEST_MODE_PORT -direction in
        set_dft_signal -view spec -type TestMode -port $TEST_MODE_PORT -active_state 1
    } else {
        set_dft_signal -view existing_dft -type Constant -port $TEST_MODE_PORT -active_state 1
    }
}

foreach {rst astate} $DFT_RESETS {
    if {[sizeof_collection [get_ports -quiet $rst]]} {
        if {$DFT_RESETS_INFERRED} {
            set inactive_state [expr {$astate ? 0 : 1}]
            set_dft_signal -view existing_dft -type Constant -port $rst -active_state $inactive_state
            puts "\[info\] inferred reset-like port held inactive in DFT: $rst=$inactive_state"
        } else {
            set_dft_signal -view existing_dft -type Reset -port $rst -active_state $astate
        }
    }
}

set_scan_configuration -style multiplexed_flip_flop \
                       -chain_count $SCAN_CHAIN_COUNT \
                       -add_lockup true \
                       -clock_mixing $DFT_CLOCK_MIXING \
                       -add_test_retiming_flops $DFT_ADD_TEST_RETIMING_FLOPS

if {$DFT_INFER_ASYNCHRONOUS_CONTROLS} {
    create_test_protocol -infer_asynch
} else {
    create_test_protocol
}
redirect ${REPORTS_DIR}/${DESIGN_NAME}.predft_drc.rpt { dft_drc }

redirect ${REPORTS_DIR}/${DESIGN_NAME}.preview_dft.rpt { preview_dft }
insert_dft

redirect ${REPORTS_DIR}/${DESIGN_NAME}.postdft_drc.rpt { dft_drc }
redirect ${REPORTS_DIR}/${DESIGN_NAME}.scan_path.rpt   { report_scan_path -view existing_dft -chain all }

change_names -rules verilog -hierarchy
write -format verilog -hierarchy -output $SCAN_NETLIST
write_test_protocol -output $SCAN_PROTOCOL
write_scan_def -output $SCAN_DEF

puts "\[info] scan netlist : $SCAN_NETLIST"
puts "\[info] STIL protocol: $SCAN_PROTOCOL"
puts "\[info] scan DEF     : $SCAN_DEF"
puts "\[info] TestMAX-DFT (DFT Compiler) scan insertion: END"
exit
