set DESIGN_NAME $env(DESIGN_NAME)
set ROOT_PATH   $env(ROOT_PATH)
set run_path    ${ROOT_PATH}/${DESIGN_NAME}
set results     ${run_path}/results
set signoff_results ${results}/signoff
set reports     ${run_path}/reports/signoff
set TECH_DIR    ${run_path}/tech
set REF_DIR     ${run_path}/ref
file mkdir $signoff_results
file mkdir $reports

set PDK_DIR ${ROOT_PATH}/scripts/pdk
source ${PDK_DIR}/process_select.tcl
source ${ROOT_PATH}/scripts/utilities/layout_defaults.tcl
set design_user_setup_file ${run_path}/inputs/${DESIGN_NAME}.pr_user_setting.tcl
if {[file exists $design_user_setup_file]} {
    source $design_user_setup_file
}
source ${PDK_DIR}/process_${PDK_PROFILE}.tcl

set PNR_V ${results}/${DESIGN_NAME}.pnr.v
set MAPPED_SDC ${run_path}/inputs/${DESIGN_NAME}.mapped.sdc
set SCAN_PATH_RPT ${run_path}/inputs/${DESIGN_NAME}.scan_path.rpt
set POSTLAYOUT_SPF ${signoff_results}/${DESIGN_NAME}.postlayout.spf

proc atpg_require_file {f what} {
    if {$f eq "" || ![file exists $f]} {
        puts "\[ATPG-ERROR] $what not found: $f"
        exit 1
    }
}

proc atpg_pair_names {pairs} {
    set names {}
    foreach {name value} $pairs {
        lappend names $name
    }
    return $names
}

proc atpg_has_pair_name {pairs name} {
    foreach {item value} $pairs {
        if {$item eq $name} {
            return 1
        }
    }
    return 0
}

proc atpg_read_sdc_clocks {sdc} {
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

    set open_brace "\{"
    set close_brace "\}"
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
        set open_pos [string first $open_brace $line $get_ports_pos]
        set close_pos [string first $close_brace $line $open_pos]
        if {$open_pos < 0 || $close_pos <= $open_pos} {
            continue
        }
        set ports [string range $line [expr {$open_pos + 1}] [expr {$close_pos - 1}]]
        foreach port $ports {
            if {$port ne "" && ![atpg_has_pair_name $clocks $port]} {
                lappend clocks $port $period
            }
        }
    }

    return $clocks
}

proc atpg_infer_reset_ports {} {
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

proc atpg_read_scan_path_report {rpt} {
    set chains {}
    set fh [open $rpt r]
    set lines [split [read $fh] "\n"]
    close $fh

    foreach line $lines {
        if {[regexp {^[ \t]*I[ \t]+([^ \t]+)[ \t]+([0-9]+)[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]+([^ \t]+)} $line -> id length scan_in scan_out scan_enable master_clock]} {
            lappend chains [list $id $length $scan_in $scan_out $scan_enable $master_clock]
        }
    }
    return $chains
}

proc atpg_scan_clocks_from_chains {chains} {
    set clocks {}
    foreach chain $chains {
        lassign $chain id length scan_in scan_out scan_enable master_clock
        if {$master_clock ne "-" && ![atpg_has_pair_name $clocks $master_clock]} {
            lappend clocks $master_clock 100
        }
    }
    return $clocks
}

proc atpg_scan_enable_from_chains {chains fallback} {
    foreach chain $chains {
        lassign $chain id length scan_in scan_out scan_enable master_clock
        if {$scan_enable ne "-"} {
            return $scan_enable
        }
    }
    return $fallback
}

proc atpg_spf_scanstructures_block {chains} {
    set block [list "ScanStructures \{"]
    foreach chain $chains {
        lassign $chain id length scan_in scan_out scan_enable master_clock
        lappend block "    ScanChain \"$id\" \{"
        lappend block "        ScanLength $length;"
        lappend block "        ScanIn \"$scan_in\";"
        lappend block "        ScanOut \"$scan_out\";"
        lappend block "        ScanEnable \"$scan_enable\";"
        if {$master_clock ne "-"} {
            lappend block "        ScanMasterClock \"$master_clock\";"
        }
        lappend block "    \}"
    }
    lappend block "\}"
    return $block
}

proc atpg_spf_scan_io_terms {chains index} {
    set terms {}
    foreach chain $chains {
        set name [lindex $chain $index]
        if {$name ne "-" && [lsearch -exact $terms "\"$name\""] < 0} {
            lappend terms "\"$name\""
        }
    }
    return [join $terms " + "]
}

proc atpg_add_spf_scan_io_groups {spf chains} {
    set si_group [atpg_spf_scan_io_terms $chains 2]
    set so_group [atpg_spf_scan_io_terms $chains 3]
    if {$si_group eq "" || $so_group eq ""} {
        puts "\[ATPG-WARN] no scan-in/out ports found for SPF _si/_so groups"
        return
    }

    set fh [open $spf r]
    set lines [split [read $fh] "\n"]
    close $fh

    set out {}
    set in_signal_groups 0
    set skip 0
    set depth 0
    set inserted 0
    set signal_start "SignalGroups \{"
    set si_start "\"_si\""
    set so_start "\"_so\""

    set block [list \
        "    \"_si\" = '$si_group' \{" \
        "        ScanIn;" \
        "    \}" \
        "    \"_so\" = '$so_group' \{" \
        "        ScanOut;" \
        "    \}" \
    ]

    foreach line $lines {
        set trimmed [string trim $line]

        if {$skip} {
            set open_count [regexp -all {\{} $line]
            set close_count [regexp -all {\}} $line]
            incr depth [expr {$open_count - $close_count}]
            if {$depth <= 0} {
                set skip 0
                set depth 0
            }
            continue
        }

        if {[string equal $trimmed $signal_start]} {
            set in_signal_groups 1
            set depth 0
            lappend out $line
            set open_count [regexp -all {\{} $line]
            set close_count [regexp -all {\}} $line]
            incr depth [expr {$open_count - $close_count}]
            continue
        }
        if {$in_signal_groups && ([string first $si_start $trimmed] == 0 || [string first $so_start $trimmed] == 0)} {
            set skip 1
            set open_count [regexp -all {\{} $line]
            set close_count [regexp -all {\}} $line]
            set depth [expr {$open_count - $close_count}]
            if {$depth <= 0} {
                set skip 0
                set depth 0
            }
            continue
        }
        if {$in_signal_groups && !$inserted && $depth == 1 && $trimmed eq "\}"} {
            foreach block_line $block {
                lappend out $block_line
            }
            set inserted 1
        }

        lappend out $line

        if {$in_signal_groups} {
            set open_count [regexp -all {\{} $line]
            set close_count [regexp -all {\}} $line]
            incr depth [expr {$open_count - $close_count}]
            if {$depth <= 0} {
                set in_signal_groups 0
            }
        }
    }

    set fh [open $spf w]
    puts -nonewline $fh [join $out "\n"]
    close $fh
    puts "\[info] PR post-layout SPF scan IO groups written: _si='$si_group', _so='$so_group'"
}

proc atpg_add_spf_load_unload {spf scan_enable} {
    set fh [open $spf r]
    set text [read $fh]
    close $fh
    if {[string first "\"load_unload\"" $text] >= 0} {
        return
    }

    set lines [split $text "\n"]
    set out {}
    set in_procedures 0
    set depth 0
    set inserted 0
    set procedures_start "Procedures \{"
    set block [list \
        "    \"load_unload\" \{" \
        "        W \"_default_WFT_\";" \
        "        \"Internal_scan_pre_shift\" : V \{" \
        "            \"$scan_enable\" = 1;" \
        "        \}" \
        "        Shift \{" \
        "            V \{" \
        "                \"_clk\" = P1;" \
        "                \"_si\" = #;" \
        "                \"_so\" = #;" \
        "            \}" \
        "        \}" \
        "    \}" \
    ]

    foreach line $lines {
        set trimmed [string trim $line]
        if {[string equal $trimmed $procedures_start]} {
            set in_procedures 1
        }

        if {$in_procedures && !$inserted && $depth == 1 && $trimmed eq "\}"} {
            foreach block_line $block {
                lappend out $block_line
            }
            set inserted 1
        }

        lappend out $line

        if {$in_procedures} {
            set open_count [regexp -all {\{} $line]
            set close_count [regexp -all {\}} $line]
            incr depth [expr {$open_count - $close_count}]
            if {$depth <= 0 && $inserted} {
                set in_procedures 0
            }
        }
    }

    set fh [open $spf w]
    puts -nonewline $fh [join $out "\n"]
    close $fh
    puts "\[info] PR post-layout SPF load_unload procedure written"
}

proc atpg_replace_spf_scanstructures {spf chains} {
    if {[llength $chains] == 0} {
        puts "\[ATPG-WARN] no scan chains found for SPF ScanStructures"
        return
    }

    set fh [open $spf r]
    set lines [split [read $fh] "\n"]
    close $fh

    set block [atpg_spf_scanstructures_block $chains]
    set out {}
    set skip 0
    set depth 0
    set replaced 0
    set inserted 0
    set scan_start "ScanStructures \{"
    set timing_start "Timing \{"

    foreach line $lines {
        set trimmed [string trim $line]

        if {$skip} {
            set open_count [regexp -all {\{} $line]
            set close_count [regexp -all {\}} $line]
            incr depth [expr {$open_count - $close_count}]
            if {$depth <= 0} {
                set skip 0
                set depth 0
            }
            continue
        }

        if {[string equal $trimmed $scan_start]} {
            foreach block_line $block {
                lappend out $block_line
            }
            set replaced 1
            set skip 1
            set open_count [regexp -all {\{} $line]
            set close_count [regexp -all {\}} $line]
            set depth [expr {$open_count - $close_count}]
            if {$depth <= 0} {
                set skip 0
                set depth 0
            }
            continue
        }

        if {!$replaced && !$inserted && [string equal $trimmed $timing_start]} {
            foreach block_line $block {
                lappend out $block_line
            }
            set inserted 1
        }

        lappend out $line
    }

    set fh [open $spf w]
    puts -nonewline $fh [join $out "\n"]
    close $fh
    puts "\[info] PR post-layout SPF ScanStructures written from scan-path report: [llength $chains] chains"
}

proc atpg_rewrite_spf_clock_group {spf clocks} {
    set clock_terms {}
    foreach {clk period} $clocks {
        lappend clock_terms "\"$clk\""
    }
    if {[llength $clock_terms] == 0} {
        return
    }

    set fh [open $spf r]
    set lines [split [read $fh] "\n"]
    close $fh

    set clock_group [join $clock_terms " + "]
    set changed 0
    set out {}
    foreach line $lines {
        if {[regexp {^([ \t]*)"_clk"[ \t]*=} $line -> indent]} {
            lappend out "${indent}\"_clk\" = '$clock_group';"
            set changed 1
        } else {
            lappend out $line
        }
    }

    if {$changed} {
        set fh [open $spf w]
        puts -nonewline $fh [join $out "\n"]
        close $fh
        puts "\[info] PR post-layout SPF clock group rewritten: _clk = '$clock_group'"
    } else {
        puts "\[ATPG-WARN] no _clk group found in $spf"
    }
}

proc atpg_remove_spf_reset_waveforms {spf resets} {
    set reset_names {}
    foreach {rst active_state} $resets {
        lappend reset_names $rst
    }
    if {[llength $reset_names] == 0} {
        return
    }

    set fh [open $spf r]
    set lines [split [read $fh] "\n"]
    close $fh

    set out {}
    set in_timing 0
    set skip 0
    set depth 0
    set removed {}
    set timing_start "Timing \{"
    set procedures_start "Procedures \{"

    foreach line $lines {
        set trimmed [string trim $line]

        if {[string equal $trimmed $timing_start]} {
            set in_timing 1
        } elseif {[string equal $trimmed $procedures_start]} {
            set in_timing 0
        }

        if {$skip} {
            set open_count [regexp -all {\{} $line]
            set close_count [regexp -all {\}} $line]
            incr depth [expr {$open_count - $close_count}]
            if {$depth <= 0} {
                set skip 0
                set depth 0
            }
            continue
        }

        set remove_this 0
        if {$in_timing} {
            foreach rst $reset_names {
                set rst_waveform_block "\"$rst\" \{"
                if {[string equal $trimmed $rst_waveform_block]} {
                    set remove_this 1
                    lappend removed $rst
                    break
                }
            }
        }

        if {$remove_this} {
            set skip 1
            set open_count [regexp -all {\{} $line]
            set close_count [regexp -all {\}} $line]
            set depth [expr {$open_count - $close_count}]
            if {$depth <= 0} {
                set skip 0
                set depth 0
            }
            continue
        }

        lappend out $line
    }

    if {[llength $removed] > 0} {
        set fh [open $spf w]
        puts -nonewline $fh [join $out "\n"]
        close $fh
        puts "\[info] PR post-layout SPF reset pulse waveforms removed: [lsort -unique $removed]"
    } else {
        puts "\[ATPG-WARN] no reset pulse waveform blocks removed from $spf"
    }
}

if {![info exists PDK_DFT_TARGET_DB]} {
    set PDK_DFT_TARGET_DB $FORMALITY_DB_FILES
}
if {![info exists PDK_DFT_SEARCH_PATH]} {
    set PDK_DFT_SEARCH_PATH [list $REF_DIR]
}

foreach f $PDK_DFT_TARGET_DB {
    atpg_require_file $f "DFT target DB"
}
atpg_require_file $PNR_V "PnR post-layout netlist"
atpg_require_file $MAPPED_SDC "Mapped SDC"
atpg_require_file $SCAN_PATH_RPT "BE DFT scan-path report"
set SCAN_CHAINS [atpg_read_scan_path_report $SCAN_PATH_RPT]
if {[llength $SCAN_CHAINS] == 0} {
    puts "\[ATPG-ERROR] no scan chains found in $SCAN_PATH_RPT"
    exit 1
}
set SCAN_CHAIN_COUNT [llength $SCAN_CHAINS]

set search_path [concat "." $PDK_DFT_SEARCH_PATH $search_path]
set target_library $PDK_DFT_TARGET_DB
set link_library [concat "*" $PDK_DFT_TARGET_DB]

read_verilog $PNR_V
current_design $DESIGN_NAME
link

if {[llength $DFT_CLOCKS] == 0} {
    set DFT_CLOCKS [atpg_read_sdc_clocks $MAPPED_SDC]
    if {[llength $DFT_CLOCKS] == 0} {
        set DFT_CLOCKS [atpg_scan_clocks_from_chains $SCAN_CHAINS]
    }
    puts "\[ATPG-WARN] DFT_CLOCKS empty; inferred from simple SDC create_clock commands or scan-path fallback"
    puts "\[info] inferred DFT_CLOCKS: $DFT_CLOCKS"
}
set DFT_RESETS_INFERRED 0
if {[llength $DFT_RESETS] == 0} {
    set DFT_RESETS_INFERRED 1
    set DFT_RESETS [atpg_infer_reset_ports]
    puts "\[ATPG-WARN] DFT_RESETS empty; inferred from reset-like top-level port names"
    puts "\[info] inferred DFT_RESETS: $DFT_RESETS"
}
if {![info exists DFT_INFER_ASYNCHRONOUS_CONTROLS]} {
    set DFT_INFER_ASYNCHRONOUS_CONTROLS 0
}
if {[sizeof_collection [get_ports -quiet $SCAN_ENABLE_PORT]] == 0} {
    set SCAN_ENABLE_PORT [atpg_scan_enable_from_chains $SCAN_CHAINS $SCAN_ENABLE_PORT]
    puts "\[info] inferred SCAN_ENABLE_PORT: $SCAN_ENABLE_PORT"
}
if {[llength $DFT_CLOCKS] == 0} {
    puts "\[ATPG-ERROR] unable to infer DFT_CLOCKS from $MAPPED_SDC or $SCAN_PATH_RPT"
    exit 1
}
if {[expr {[llength $DFT_CLOCKS] % 2}] != 0} {
    puts "\[ATPG-ERROR] DFT_CLOCKS must be a list of {clock period} pairs: $DFT_CLOCKS"
    exit 1
}
if {[expr {[llength $DFT_RESETS] % 2}] != 0} {
    puts "\[ATPG-ERROR] DFT_RESETS must be a list of {reset active_state} pairs: $DFT_RESETS"
    exit 1
}

foreach {clk period} $DFT_CLOCKS {
    if {[sizeof_collection [get_ports -quiet $clk]] == 0} {
        puts "\[ATPG-WARN] clock port '$clk' not found in design -- skipped"
        continue
    }
    set_dft_signal -view existing_dft -type MasterClock -port $clk -timing {45 55}
}

if {[sizeof_collection [get_ports -quiet $SCAN_ENABLE_PORT]] == 0} {
    puts "\[ATPG-ERROR] scan enable port '$SCAN_ENABLE_PORT' not found in post-layout netlist"
    exit 1
}
set_dft_signal -view existing_dft -type ScanEnable -port $SCAN_ENABLE_PORT -active_state 1

if {$TEST_MODE_PORT ne "" && [sizeof_collection [get_ports -quiet $TEST_MODE_PORT]] > 0} {
    set_dft_signal -view existing_dft -type Constant -port $TEST_MODE_PORT -active_state 1
}

foreach {rst astate} $DFT_RESETS {
    if {[sizeof_collection [get_ports -quiet $rst]] > 0} {
        if {$DFT_RESETS_INFERRED} {
            set inactive_state [expr {$astate ? 0 : 1}]
            set_dft_signal -view existing_dft -type Constant -port $rst -active_state $inactive_state
            puts "\[info] inferred reset-like port held inactive in DFT: $rst=$inactive_state"
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
redirect ${reports}/${DESIGN_NAME}.postlayout_protocol_drc.rpt { dft_drc }
write_test_protocol -output $POSTLAYOUT_SPF
atpg_rewrite_spf_clock_group $POSTLAYOUT_SPF $DFT_CLOCKS
atpg_remove_spf_reset_waveforms $POSTLAYOUT_SPF $DFT_RESETS
atpg_add_spf_scan_io_groups $POSTLAYOUT_SPF $SCAN_CHAINS
atpg_replace_spf_scanstructures $POSTLAYOUT_SPF $SCAN_CHAINS
atpg_add_spf_load_unload $POSTLAYOUT_SPF $SCAN_ENABLE_PORT

puts "\[info] PR post-layout SPF: $POSTLAYOUT_SPF"
exit
