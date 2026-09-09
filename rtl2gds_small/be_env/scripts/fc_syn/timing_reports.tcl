proc rm_generate_variables_for_report_parallel { args } {

  parse_proc_arguments -args $args options

  if {[info exists options(-work_directory)]} { set work_directory $options(-work_directory) }
  if {[info exists options(-file_name)]} { set file_name $options(-file_name) }

  set the_file_for_report_parallel	[file normalize "$work_directory/$file_name"]

  global REPORT_PREFIX REPORT_PARALLEL_SUBMIT_COMMAND REPORTS_DIR REPORT_QOR_REPORT_POWER REPORT_QOR_REPORT_CONGESTION EARLY_DATA_CHECK_POLICY REPORT_POWER_SAIF_FILE REPORT_POWER_SAIF_MAP SAIF_FILE_SOURCE_INSTANCE
  global WRITE_QOR_DATA WRITE_QOR_DATA_DIR COMPARE_QOR_DATA_DIR
  global INIT_DESIGN_BLOCK_NAME PLACE_OPT_BLOCK_NAME CLOCK_OPT_CTS_BLOCK_NAME CLOCK_OPT_OPTO_BLOCK_NAME ROUTE_AUTO_BLOCK_NAME ROUTE_OPT_BLOCK_NAME CHIP_FINISH_BLOCK_NAME ICV_IN_DESIGN_BLOCK_NAME TIMING_ECO_BLOCK_NAME FUNCTIONAL_ECO_BLOCK_NAME ENDPOINT_OPT_BLOCK_NAME
  global READ_RTL_BLOCK_NAME COMPILE_BLOCK_NAME COMPILE_INITIAL_BLOCK_NAME COMPILE_INCREMENTAL_BLOCK_NAME INSERT_DFT_BLOCK_NAME READ_DATA_BLOCK_NAME UNIFIED_FLOW
  global USE_ABSTRACTS_FOR_BLOCKS USE_ABSTRACTS_FOR_POWER_ANALYSIS CHECK_HIER_TIMING_CONSTRAINTS_CONSISTENCY

  if {[info exists REPORT_PREFIX]} {
    set fid [ open ${the_file_for_report_parallel} "w" ]

    puts $fid "source [pwd]/rm_utilities/source_loader.tcl"
    if {$::synopsys_program_name == "fc_shell"} {
      puts $fid "source [pwd]/rm_utilities/procs_fc.tcl"
    } else {
      puts $fid "source [pwd]/rm_utilities/procs_icc2.tcl"
    }

    puts $fid "## RM Tcl variables required by report_parallel"
    puts $fid "set REPORT_PREFIX $REPORT_PREFIX"
    puts $fid "set REPORT_PARALLEL_SUBMIT_COMMAND \"$REPORT_PARALLEL_SUBMIT_COMMAND\""
    puts $fid "set REPORTS_DIR [which $REPORTS_DIR]"
    puts $fid "set REPORT_QOR_REPORT_POWER $REPORT_QOR_REPORT_POWER"
    puts $fid "set REPORT_POWER_SAIF_FILE \"$REPORT_POWER_SAIF_FILE\""
    puts $fid "set REPORT_POWER_SAIF_MAP \"$REPORT_POWER_SAIF_MAP\""
    puts $fid "set SAIF_FILE_SOURCE_INSTANCE \"$SAIF_FILE_SOURCE_INSTANCE\""
    puts $fid "set REPORT_QOR_REPORT_CONGESTION $REPORT_QOR_REPORT_CONGESTION"
    puts $fid "set EARLY_DATA_CHECK_POLICY $EARLY_DATA_CHECK_POLICY"

    puts $fid "set WRITE_QOR_DATA $WRITE_QOR_DATA"
    puts $fid "set WRITE_QOR_DATA_DIR [file normalize $WRITE_QOR_DATA_DIR]"
    puts $fid "set COMPARE_QOR_DATA_DIR [file normalize $COMPARE_QOR_DATA_DIR]"

    puts $fid "set INIT_DESIGN_BLOCK_NAME $INIT_DESIGN_BLOCK_NAME"
    puts $fid "set PLACE_OPT_BLOCK_NAME $PLACE_OPT_BLOCK_NAME"
    puts $fid "set CLOCK_OPT_CTS_BLOCK_NAME $CLOCK_OPT_CTS_BLOCK_NAME"
    puts $fid "set CLOCK_OPT_OPTO_BLOCK_NAME $CLOCK_OPT_OPTO_BLOCK_NAME"
    puts $fid "set ROUTE_AUTO_BLOCK_NAME $ROUTE_AUTO_BLOCK_NAME"
    puts $fid "set ROUTE_OPT_BLOCK_NAME $ROUTE_OPT_BLOCK_NAME"
    puts $fid "set CHIP_FINISH_BLOCK_NAME $CHIP_FINISH_BLOCK_NAME"
    puts $fid "set ICV_IN_DESIGN_BLOCK_NAME $ICV_IN_DESIGN_BLOCK_NAME"
    puts $fid "set TIMING_ECO_BLOCK_NAME $TIMING_ECO_BLOCK_NAME"
    puts $fid "set FUNCTIONAL_ECO_BLOCK_NAME $FUNCTIONAL_ECO_BLOCK_NAME"
    puts $fid "set ENDPOINT_OPT_BLOCK_NAME $ENDPOINT_OPT_BLOCK_NAME"

    if {$::synopsys_program_name == "fc_shell"} {
      if {[info exists COMPILE_BLOCK_NAME]} {
        puts $fid "set READ_RTL_BLOCK_NAME $READ_RTL_BLOCK_NAME"
        puts $fid "set COMPILE_BLOCK_NAME $COMPILE_BLOCK_NAME"
        puts $fid "set COMPILE_INITIAL_BLOCK_NAME $COMPILE_INITIAL_BLOCK_NAME"
        puts $fid "set COMPILE_INCREMENTAL_BLOCK_NAME $COMPILE_INCREMENTAL_BLOCK_NAME"
        puts $fid "set INSERT_DFT_BLOCK_NAME $INSERT_DFT_BLOCK_NAME"
        puts $fid "set READ_DATA_BLOCK_NAME $READ_DATA_BLOCK_NAME"
        puts $fid "set UNIFIED_FLOW $UNIFIED_FLOW"
      } else {
        puts "RM-error: rm_generate_variables_for_report_parallel : Since you are running fc_shell, this program expects FC-RM is used, but specific variables such as COMPILE_BLOCK_NAME is missing. Please double check."
      }
    }

    if {[info exists USE_ABSTRACTS_FOR_BLOCKS]} {
      puts $fid "set USE_ABSTRACTS_FOR_BLOCKS \"$USE_ABSTRACTS_FOR_BLOCKS\""
      puts $fid "set USE_ABSTRACTS_FOR_POWER_ANALYSIS $USE_ABSTRACTS_FOR_POWER_ANALYSIS"
      puts $fid "set CHECK_HIER_TIMING_CONSTRAINTS_CONSISTENCY $CHECK_HIER_TIMING_CONSTRAINTS_CONSISTENCY"
    }

    close $fid
  }

}

define_proc_attributes rm_generate_variables_for_report_parallel \
        -info "Generate and pass necessary RM variables for the report_parallel command" \
   	-define_args {
  	{-work_directory "Destination directory for the output file." AString string optional}
  	{-file_name "Name of the output file." AString string required}
	}

proc check_clock_transition { args } {

   parse_proc_arguments -args $args results
   set threshold $results(-threshold)

   set currentScenario [current_scenario]
   set i 1
   foreach_in_collection scenario [get_scenarios -filter "setup || hold && active"] {
      current_scenario $scenario 
      set time_unit [get_user_units -type time -output]
      set time_input [get_user_units -type time -input -numeric]
      set time_output [get_user_units -type time -output -numeric]
      set time_factor [expr $time_input / $time_output] 
      set fastest_clk [lindex [lsort -inc -real [get_attribute   [get_clock -filter "is_virtual==false" ] period ] ] 0]
      if {[string equal 1.00ns $time_unit]} {
         set clk_thresh 5.0
         set tran_limit 0.5
         set tran_limit_unit [expr $tran_limit / $time_factor]
         } else {
         set clk_thresh 5000
         set tran_limit 500
         set tran_limit_unit [expr $tran_limit / $time_factor]
      } 
      if {[expr $threshold * $fastest_clk] > $tran_limit} {
         set target_tran $tran_limit
         set target_tran_unit [expr $target_tran / $time_factor]
      } else {
         set target_tran [expr $threshold * $fastest_clk]
         set target_tran_unit [expr $target_tran / $time_factor]
      }
      if {$fastest_clk < $clk_thresh} {
         set clk_collection [get_clock -filter "is_virtual==false && period==$fastest_clk"]
         foreach_in_collection clk $clk_collection {
            set clock_sinks [sort_collection [get_clock_tree_pins -clock $clk -filter "is_sink" -quiet] constraining_max_transition]
            if {[sizeof_collection $clock_sinks]} {
               set clk_tran [get_attribute [index_collection $clock_sinks 0] constraining_max_transition]
               set clk_tran_unit [expr $clk_tran / $time_factor] 
                  #puts "DEBUG: [get_object_name $scenario] [get_object_name $clk] $clk_tran_unit $target_tran_unit"
               if {$clk_tran_unit >= $target_tran_unit} {
                   puts "RM-Info: Relaxed clock max transition detected, constraining max_transition of $clk_tran_unit for clock [get_object_name $clk] in scenario [get_object_name $scenario]"
                   if {[info exists results(-apply_max_transition)]} {
                      set_max_transition $target_tran_unit [get_clocks $clk -mode [get_attribute [get_scenarios $scenario] mode]] -clock_path -scenario [get_scenarios $scenario]
                      puts "RM-Info: Relaxed clock max transition detected, setting max_transition to $target_tran_unit for clock [get_object_name $clk] in scenario [get_object_name $scenario]"
                      global rm_clock
                      set rm_clock(name$i) $clk
                      set rm_clock(scenario$i) [current_scenario]
                      set rm_clock(orig_tran$i)  $clk_tran_unit
                   incr i
                   }
               }
            }
         }
     }
   }
   current_scenario $currentScenario
}

define_proc_attributes check_clock_transition \
        -info "check_clock_transition  #Command checks the max_transtition constraint for the fastest clock per active scenario" \
        -define_args {
        {-threshold "Value between 0 and 1" "#percent of clock period" float required }
        {-apply_max_transition  "Applies max transition based on the threshold to the fastest clock" "" boolean optional}
        }

proc restore_clock_transition {args} {
   global rm_clock
   for {set i 1} {$i <= [expr [array size rm_clock] / 3]} {incr i} {
      current_scenario $rm_clock(scenario$i)
      set_max_transition $rm_clock(orig_tran$i) [get_clocks [get_object_name $rm_clock(name$i)]] -scenario $rm_clock(scenario$i) -clock_path
      puts "RM-Info: Restoring clock max transition to $rm_clock(orig_tran$i) for clock [get_object_name $rm_clock(name$i)] in scenario [get_object_name $rm_clock(scenario$i)]" 
   }
}

proc targeted_ep_ropt_pba_ccd {args} {

  parse_proc_arguments -args $args args_array

  if [info exists args_array(-scenarios)] {
    set scenarios [ get_object_name [ get_scenarios -filter active&&setup $args_array(-scenarios) ]]
  } else {
    set scenarios [ get_object_name [ get_scenarios -filter active&&setup *]]
  }
  puts "RM-info: Operating on scenario(s): $scenarios"

  current_scenario [ lindex $scenarios 0 ]
  
  set path_group_filter $args_array(-path_group_filter)
  set target_groups ""
  if {$path_group_filter != ""} {
    foreach scenario [get_object_name [get_scenarios $scenarios -filter active&&setup]] {
      set target_groups [lsort -uniq [concat $target_groups [get_object_name [get_path_groups -mode [get_attribute [get_scenarios $scenario] mode] -filter $path_group_filter]]]]
    }
    set target_groups [get_object_name [get_path_groups $target_groups]] 
    puts "RM-info: Operating on path group(s): $target_groups"
  } else {
    foreach scenario [get_object_name [get_scenarios $scenarios -filter active&&setup]] {
      set target_groups [lsort -uniq [concat $target_groups [get_object_name [get_path_groups -mode [get_attribute [get_scenarios $scenario] mode]]]]]
    }
    puts "RM-info: Operating on all path group(s): $target_groups"
  }

  set max_paths $args_array(-max_paths)
  puts "RM-info: max_paths set to $max_paths"

  set slack_threshold $args_array(-slack_lesser_than)

  set user_unit [get_user_unit -type time -input -numeric]
  set threshold_in_ps [expr $slack_threshold*$user_unit/(1e-12)]
  
  if {$threshold_in_ps > -1.0} {
    puts "RM-warning: slack_lesser_than threshold too small. Set to -1 ps"
    set threshold_in_ps -1.0
  }
  set_user_unit -type time -value 1ps -input
  
  puts "RM-info: slack_lesser_than threshold set to $threshold_in_ps ps"

  reset_app_options ccd.targeted_ccd*
  set_app_options -name route_opt.flow.enable_ccd -value true
  set_app_options -name time.pba_optimization_mode -value path
  set_app_options -name time.report_use_pba_optimization_mode -value true
  set_app_options -name route_opt.flow.enable_targeted_ccd_wns_optimization -value true
  
  if {$path_group_filter !=""} {
    set target_endpoints [get_attribute [get_timing_paths -scenario $scenarios -pba_mode path -groups $target_groups -max_paths $max_paths -from [all_register -clock_pin] -to [all_register -data_pin] -slack_lesser_than $threshold_in_ps] endpoint ]
  } else {
    set target_endpoints [get_attribute [get_timing_paths -scenario $scenarios -pba_mode path -max_paths $max_paths -from [all_register -clock_pin] -to [all_register -data_pin] -slack_lesser_than $threshold_in_ps] endpoint ]
  } 

  set_user_unit -type time -value $user_unit -input

  if {[sizeof_collection $target_endpoints ] != 0 } { 
    puts "RM-info: PBA-CCD route_opt working on [sizeof $target_endpoints] target endpoints"
    set_route_opt_target_endpoints -setup_endpoints_collection $target_endpoints
    route_opt
  } else {
    puts "RM-info: No qualified endpoints found. Skip PBA-CCD route_opt"
  }
}

define_proc_attributes targeted_ep_ropt_pba_ccd -info {Run loop of targeted endpoint recipe on endpoints in given path groups} \
  -define_args { \
                       {-scenarios {Scenarios to target endpoints in, default all active setup scenarios} {<scenarios>} {string} {optional {default "*"}}} \
                       {-path_group_filter {Path group filter to collect paths for endpoint optimization, default "" no filtering } {<path_group_filter>} {string} {optional {default ""}}} \
                       {-max_paths {Number of paths to collect, default 10000} {<integer>} {int} {optional {default 10000}}} \
                       {-slack_lesser_than {Collect paths with slack worse than, default -0.001 ns} {<float>} {string} {optional {default -0.001}}} \
               }

proc report_drc {args} {
  set arg(-err_data) zroute.err
	parse_proc_arguments -args $args arg

	if {[info exists arg(-output_file)]} {
    if {[catch {open $arg(-output_file) w} FH]} {
      puts stderr "Error:  Can't open file $arg(-output_file) for write"
      return
    }
  } else {
    set FH stdout
  }

  set closeFile false
  if {[set errData [get_drc_error_data -quiet $arg(-err_data)]] eq ""} {
    set errData [open_drc_error_data $arg(-err_data)]
    if {$errData eq ""} {
      puts stderr "Error: Can't open DRC error data file $arg(-err_data)"
      return
    }
    set closeFile true
  }

	if {[info exists arg(-type)]} {
    foreach type $arg(-type) {set typ($type) ""}
	} else {
    foreach_in_collection itm [get_drc_error_types -error_data $errData] {set typ([get_attribute $itm name]) ""}
	}

	if {[info exists arg(-ignore_type)]} {
		foreach type $arg(-ignore_type) {array unset typ($type)}
	}
	if {[array size typ] == 0} {
		puts $FH "\n#################\nNo DRCs to report\n#################\n"
    return
  }

	if {[info exists arg(-layer)]} {
    foreach layer $arg(-layer) {set lyr($layer) ""}
    set lyr_order $arg(-layer)
  } else {
    if {[info exists arg(-ignore_vias)]} {
      set lst [get_object_name [get_layers -filter layer_type==interconnect]]
    } else {
      set lst [get_object_name [get_layers -filter {layer_type==interconnect || layer_type==via_cut}]]
    }
    if {![info exists arg(-include_nonrouting)]} {
      redirect -variable tmp {report_ignored_layers}
      set min [lindex [regsub {.*Min Routing Layer\s+} $tmp ""] 0]
      set max [lindex [regsub {.*Max Routing Layer\s+} $tmp ""] 0]
      set lst [lrange $lst [lsearch -exact $lst $min] [lsearch -exact $lst $max]]
    }
    foreach layer $lst {set lyr($layer) ""}
    set lyr_order $lst
	}

	if {[info exists arg(-ignore_layer)]} {
		foreach layer $arg(-ignore_layer) {array unset lyr($layer)}
    set lyr_order [lsearch -all -inline -not -exact $lyr_order $layer]
	}
	if {[array size lyr] == 0} {
		puts $FH "\n#################\nNo DRCs to report\n#################\n"
    return
  }

  array unset cnt
  array unset totals
  set maxlen 17
  foreach type [array names typ] {
    foreach layer [array names lyr] {
      set cnt($type,$layer) 0
      set totals($layer) 0
    }
    set totals($type) 0
    if {[set new [string length $type]] > $maxlen} {set maxlen $new}
  }
  set totals(all) 0

  foreach_in_collection mkr [get_drc_errors -error_data $errData] {
    set type [get_attribute $mkr type_name]
    if {![info exists typ($type)]} {continue} 
    foreach_in_collection itm [get_attribute $mkr layers] {
      set layer [get_object_name $itm]
      if {![info exists lyr($layer)]} {continue} 
      incr cnt($type,$layer)
    }
    incr totals($layer)
    incr totals($type)
    incr totals(all)
  }

  if {$closeFile} {close_drc_error_data -force $arg(-err_data)}

  set layer_count 0
  puts $FH "DRC Violation Summary Report for $arg(-err_data)"
  puts -nonewline $FH [format "%${maxlen}s |" ""]
  foreach layer $lyr_order {
    if {$totals($layer) > 0} {puts -nonewline $FH [format "%6s" $layer]; incr layer_count}
  }
  puts $FH [format " |%17s" "TOTALS BY MARKER"]
  set sep [string repeat "-" [expr $maxlen + ($layer_count*6) + 21]]
  puts $FH $sep

  foreach type [lsort [array name typ]] {
    if {$totals($type) > 0} {
    puts -nonewline $FH [format "%${maxlen}s |" $type]  
      foreach layer $lyr_order {
        if {$totals($layer) == 0} {continue}
        if {$cnt($type,$layer) > 0} {
          puts -nonewline $FH [format "%6d" $cnt($type,$layer)]
        } else {
          puts -nonewline $FH [format "%6s" "-"]
        }
      }
    puts -nonewline $FH [format " |%6d" $totals($type)]
    puts $FH ""
    }
  }

  puts $FH $sep
  puts -nonewline $FH [format "%${maxlen}s |" ""]
  foreach layer $lyr_order {
    if {$totals($layer) > 0} {puts -nonewline $FH [format "%6s" $layer]; incr layer_count}
  }
  puts $FH [format " |%6d" $totals(all)]

  puts -nonewline $FH [format "%${maxlen}s |" "TOTALS BY LAYER"]
  foreach layer $lyr_order {
    if {$totals($layer) > 0} {puts -nonewline $FH [format "%6s" $totals($layer)]}
  }
  puts -nonewline $FH [format " |"]

  puts $FH "\n"

	if {[info exists arg(-output_file)]} {close $FH}

}

define_proc_attributes report_drc \
	-info "Report routing DRCs by Layer and/or DRC_type\n" \
	-define_args {
		{-layer "Layer list on which to report DRCs.  Default all routing and all via layers." layer list optional}
		{-type "List of DRC violation types to report. eg: -type {{Short} {Less than NDR width}}" type list optional}
		{-ignore_layer "Layers to exclude from report. eg: -ignore_layer {M2 M7} " ignore_layer list optional}
		{-ignore_type "DRC violation types to ignore. eg: -ignore_type {{Short} {Less than NDR width}}" ignore_type list optional}
		{-ignore_vias "Remove via cut layers in default reporting layers." "" boolean optional}
		{-include_nonrouting "Include non-routing layers in default reporting layers." "" boolean optional}
		{-err_data "Source error data file.  Default: zroute.err" err_data string optional}
		{-output_file "Write results to file.  Default: stdout" output_file string optional}
	}

proc proc_qor {args} {

  proc proc_mysort_hash {args} {

    parse_proc_arguments -args ${args} opt

    upvar $opt(hash) myarr

    set given    "[info exists opt(-values)][info exists opt(-dict)][info exists opt(-reverse)]"

    set key_list  [array names myarr]

    switch $given {
      000 { return [lsort -real $key_list] }
      001 { return [lsort -real -decreasing $key_list] }
      010 { return [lsort -dictionary $key_list] }
      011 { return [lsort -dictionary -decreasing $key_list] }
    }
  
    foreach {a b} [array get myarr] { lappend full_list [list $a $b] }

    switch $given {
      100 { set sfull_list [lsort -real -index 1 $full_list] }
      101 { set sfull_list [lsort -real -index 1 -decreasing $full_list] }
      110 { set sfull_list [lsort -index 1 -dictionary $full_list] }
      111 { set sfull_list [lsort -index 1 -dictionary -decreasing $full_list] }

    }

    foreach i $sfull_list { lappend sorted_key_list [lindex $i 0] }
    return $sorted_key_list
  }

  define_proc_attributes proc_mysort_hash -info "USER PROC:sorts a hash based on options and returns sorted keys list\nUSAGE: set sorted_keys \[proc_mysort_hash hash_name_without_dollar\]" \
        -define_args { \
                    { -reverse 	"reverse sort"      			""              	boolean optional }
                    { -dict 	"dictionary sort, default numerical"	""              	boolean optional }
                    { -values 	"sort values, default keys"      	""              	boolean optional }
                    { hash   	"hash"         				"hash"            	list    required }
                    }

  parse_proc_arguments -args $args results
  set skew_flag [info exists results(-skew)]
  set scenario_flag [info exists results(-scenarios)]
  set pba_flag  [info exists results(-pba_mode)]
  set file_flag [info exists results(-existing_qor_file)]
  set no_hist_flag [info exists results(-no_histogram)]
  set unit_flag [info exists results(-units)]
  set no_pg_flag   [info exists results(-no_pathgroup_info)]
  set sort_by_tns_flag   [info exists results(-sort_by_tns)]
  set uncert_flag [info exists results(-signoff_uncertainty_adjustment)]
  if {[info exists results(-tee)]} {set tee "-tee -var" } else { set tee "-var" }
  if {[info exists results(-csv_file)]} {set csv_file $results(-csv_file)} else { set csv_file "qor.csv" }
  if {$file_flag&&$skew_flag} { echo "Error!! -skew cannot be used with -existing_qor_file" ; return }
  if {$file_flag&&$no_hist_flag} { echo "Warning!! -no_histogram flag is ignored when -existing_qor_file is used" }
  if {$file_flag} { 
    if {[file exists $results(-existing_qor_file)]} { 
      set qor_file  $results(-existing_qor_file) 
    } else { 
      echo "Error!! Cannot find given -existing_qor_file $results(-existing_qor_file)" 
      return
    }
  }
  if {[info exists results(-units)]} {set unit $results(-units)}
  if {[info exists results(-pba_mode)]} {
    if { $::synopsys_program_name != "pt_shell" && $::synopsys_program_name != "icc2_shell" && $::synopsys_program_name != "fc_shell" } { echo "Error!! -pba_mode supported only in pt_shell, icc2_shell, and fc_shell" ; return}
  }
  if {[info exists results(-pba_mode)]} {set pba_mode $results(-pba_mode)} else { set pba_mode "none" }
  if {[info exists results(-pba_mode)]&&$file_flag} { echo "-pba_mode ignored when -existing_qor_file is used" }


  set nil "~"

  #set ::collection_deletion_effort low

  if {$uncert_flag} {
    echo "-signoff_uncertainty_adjustment only changes Frequency Column, report still sorted by WNS"
    set signoff_uncert $results(-signoff_uncertainty_adjustment)
  }

  if {$file_flag} {
    set tmp [open $qor_file "r"]
    set x [read $tmp]
    close $tmp
    if {[regexp {\(max_delay/setup|\(min_delay/hold} $x]} { set pt_file 1 } else { set pt_file 0 }
  } else {
    if {$::synopsys_program_name == "pt_shell"} {
          if {$::pt_shell_mode=="primetime_master"} {echo "Error!! proc_qor not supported in DMSA Master" ; return }
          set pt_file 1
          set orig_uncons $::timing_report_unconstrained_paths
          if {[info exists ::timing_report_union_tns]} { set orig_union  $::timing_report_union_tns } else { set orig_union true }
          set ::timing_report_union_tns true
          echo -n "Running report_qor -pba_mode $pba_mode ; report_qor -pba_mode $pba_mode -summary ... "
          redirect {*}$tee x { report_qor -pba_mode $pba_mode ; report_qor -pba_mode $pba_mode -summary }
          echo "Done"
      } else {
        set pt_file 0
        if {$scenario_flag} {
          if { $::synopsys_program_name == "icc2_shell" || $::synopsys_program_name == "dcrt_shell" || $::synopsys_program_name == "fc_shell" } {
            echo -n "Running report_qor -pba_mode $pba_mode -nosplit -scenarios $results(-scenarios) ; report_qor -pba_mode $pba_mode -nosplit -summary ... "
            redirect {*}$tee x { report_qor -pba_mode $pba_mode -nosplit -scenarios $results(-scenarios) ; report_qor -pba_mode $pba_mode -nosplit -summary }
          } else {
            echo -n "Running report_qor -nosplit -scenarios $results(-scenarios) ... "
            redirect {*}$tee x { report_qor -nosplit -scenarios $results(-scenarios) }
          }
          echo "Done"
        } else {
          if { $::synopsys_program_name == "icc2_shell" || $::synopsys_program_name == "dcrt_shell" || $::synopsys_program_name == "fc_shell" } {
            echo -n "Running report_qor -pba_mode $pba_mode -nosplit ; report_qor -pba_mode $pba_mode -nosplit -summary ... "
            redirect {*}$tee x { report_qor -pba_mode $pba_mode -nosplit ; report_qor -pba_mode $pba_mode -nosplit -summary }
          } else {
            echo -n "Running report_qor -nosplit ... "
            redirect {*}$tee x { report_qor -nosplit }
          }
          echo "Done"
        }
    }
  }
  
  if {$unit_flag} {
    if {[string match $unit "ps"]} { set unit 1000000 } else { set unit 1000 }
  } else {
    catch {redirect -var y {report_units}}
    if {[regexp {(\S+)\s+Second} $y match unit]} {
      if {[regexp {e-12} $unit]} { set unit 1000000 } else { set unit 1000 }
    } elseif {[regexp {ns} $y]} { set unit 1000
    } elseif {[regexp {ps} $y]} { set unit 1000000 }
  }

  if {![info exists unit]} { set unit 1000 }
  
  set drc 0
  set cella 0
  set buf 0
  set leaf 0
  set tnets 0
  set cbuf 0
  set seqc 0
  set tran 0
  set cap 0
  set fan 0
  set combc 0
  set macroc 0
  set comba 0
  set seqa 0
  set desa 0
  set neta 0
  set netl 0
  set netx 0
  set nety 0
  set hierc 0
  if {![file writable [file dir $csv_file]]} {
    echo "$csv_file not writable, Writing to /dev/null instead"
    set csv_file "/dev/null"
  }
  set csv [open $csv_file "w"]

  if {!$pt_file} {
  set i 0
  set group_just_set 0
  foreach line [split $x "\n"] {
  
    incr i
    #echo "Processing $i : $line"

    if {[regexp {^\s*Scenario\s+\'(\S+)\'} $line match scenario]} {
    } elseif {[regexp {^\s*Timing Path Group\s+\'(\S+)\'} $line match group]} {
      if {[info exists scenario]} { set group ${group}($scenario) }
      set GROUPS($group) 1
      set group_just_set 1
      unset -nocomplain ll cpl wns cp tns nvp wnsh tnsh nvph fr
    } elseif {[regexp {^\s*------\s*$} $line]} {
      if {$group_just_set} {
        continue 
      } else {
        set group_just_set 0
        unset -nocomplain group scenario
      }
    } elseif {[regexp {^\s*Levels of Logic\s*:\s*(\S+)\s*$} $line match ll]} {
      set GROUP_LL($group) $ll
    } elseif {[regexp {^\s*Critical Path Length\s*:\s*(\S+)\s*$} $line match cpl]} {
      set GROUP_CPL($group) $cpl
    } elseif {[regexp {^\s*Critical Path Slack\s*:\s*(\S+)\s*$} $line match wns]} { 
      if {![string is double $wns]} { set wns 0.0 }
      set GROUP_WNS($group) $wns 
    } elseif {[regexp {^\s*Critical Path Clk Period\s*:\s*(\S+)\s*$} $line match cp]} { 
      if {![string is double $cp]} { set cp 0.0 }
      set GROUP_CP($group) $cp
    } elseif {[regexp {^\s*Total Negative Slack\s*:\s*(\S+)\s*$} $line match tns]} {
      set GROUP_TNS($group) $tns
    } elseif {[regexp {^\s*No\. of Violating Paths\s*:\s*(\S+)\s*$} $line match nvp]} {
      set GROUP_NVP($group) $nvp
    } elseif {[regexp {^\s*Worst Hold Violation\s*:\s*(\S+)\s*$} $line match wnsh]} {
      if {![string is double $wnsh]} { set wnsh 0.0 }
      set GROUP_WNSH($group) $wnsh
    } elseif {[regexp {^\s*Total Hold Violation\s*:\s*(\S+)\s*$} $line match tnsh]} {
      set GROUP_TNSH($group) $tnsh
    } elseif {[regexp {^\s*No\. of Hold Violations\s*:\s*(\S+)\s*$} $line match nvph]} {
      set GROUP_NVPH($group) $nvph

    } elseif {[regexp {^\s*Hierarchical Cell Count\s*:\s*(\S+)\s*$} $line match hierc]} {
    } elseif {[regexp {^\s*Hierarchical Port Count\s*:\s*(\S+)\s*$} $line match hierp]} {
    } elseif {[regexp {^\s*Leaf Cell Count\s*:\s*(\S+)\s*$} $line match leaf]} {
      set leaf [expr {$leaf/1000}]
    } elseif {[regexp {^\s*Buf/Inv Cell Count\s*:\s*(\S+)\s*$} $line match buf]} {
      set buf [expr {$buf/1000}]
    } elseif {[regexp {^\s*CT Buf/Inv Cell Count\s*:\s*(\S+)\s*$} $line match cbuf]} {
    } elseif {[regexp {^\s*Combinational Cell Count\s*:\s*(\S+)\s*$} $line match combc]} {
      set combc [expr $combc/1000]
    } elseif {[regexp {^\s*Sequential Cell Count\s*:\s*(\S+)\s*$} $line match seqc]} {
    } elseif {[regexp {^\s*Macro Count\s*:\s*(\S+)\s*$} $line match macroc]} {
 
    } elseif {[regexp {^\s*Combinational Area\s*:\s*(\S+)\s*$} $line match comba]} {
      set comba [expr {int($comba)}]
    } elseif {[regexp {^\s*Noncombinational Area\s*:\s*(\S+)\s*$} $line match seqa]} {
      set seqa [expr {int($seqa)}]
    } elseif {[regexp {^\s*Net Area\s*:\s*(\S+)\s*$} $line match neta]} {
      set neta [expr {int($neta)}]
    } elseif {[regexp {^\s*Net XLength\s*:\s*(\S+)\s*$} $line match netx]} {
    } elseif {[regexp {^\s*Net YLength\s*:\s*(\S+)\s*$} $line match nety]} {
    } elseif {[regexp {^\s*Cell Area\s*.*:\s*(\S+)\s*$} $line match cella]} {
      set cella [expr {int($cella)}]
    } elseif {[regexp {^\s*Design Area\s*:\s*(\S+)\s*$} $line match desa]} {
      set desa [expr {int($desa)}]
    } elseif {[regexp {^\s*Net Length\s*:\s*(\S+)\s*$} $line match netl]} {
      set netl [expr {int($netl)}]

    } elseif {[regexp {^\s*Total Number of Nets\s*:\s*(\S+)\s*$} $line match tnets]} {
      set tnets [expr {$tnets/1000}]
    } elseif {[regexp {^\s*Nets With Violations\s*:\s*(\S+)\s*$} $line match drc]} {
    } elseif {[regexp {^\s*Max Trans Violations\s*:\s*(\S+)\s*$} $line match tran]} {
    } elseif {[regexp {^\s*Max Cap Violations\s*:\s*(\S+)\s*$} $line match cap]} {
    } elseif {[regexp {^\s*Max Fanout Violations\s*:\s*(\S+)\s*$} $line match fan]} {


    } elseif {[regexp {^\s*Scenario:\s*(\S+)\s+\s+WNS:\s*(\S+)\s*TNS:\s*(\S+).*Paths:\s*(\S+)} $line match scenario wns tns nvp]} {
      set SETUP_SCENARIOS($scenario) 1
      set SETUP_SCENARIO_WNS($scenario) $wns
      set SETUP_SCENARIO_TNS($scenario) $tns
      set SETUP_SCENARIO_NVP($scenario) $nvp
    } elseif {[regexp {^\s*Scenario:\s*(\S+)\s+\(Hold\)\s+WNS:\s*(\S+)\s*TNS:\s*(\S+).*Paths:\s*(\S+)} $line match scenario wns tns nvp]} {
      set HOLD_SCENARIOS($scenario) 1
      set HOLD_SCENARIO_WNS($scenario) $wns
      set HOLD_SCENARIO_TNS($scenario) $tns
      set HOLD_SCENARIO_NVP($scenario) $nvp
    } elseif {[regexp {^\s*Design\s+WNS:\s*(\S+)\s*TNS:\s*(\S+).*Paths:\s*(\S+)} $line match setup_wns setup_tns setup_nvp]} {
      if {![string is double $setup_wns]} { set setup_wns 0.0 }
      if {![string is double $setup_tns]} { set setup_tns 0.0 }
      if {![string is double $setup_nvp]} { set setup_nvp 0 }
    } elseif {[regexp {^\s*Design\s+\(Hold\)\s*WNS:\s*(\S+)\s*TNS:\s*(\S+).*Paths:\s*(\S+)} $line match hold_wns hold_tns hold_nvp]} {
      if {![string is double $hold_wns]} { set hold_wns 0.0 }
      if {![string is double $hold_tns]} { set hold_tns 0.0 }
      if {![string is double $hold_nvp]} { set hold_nvp 0 }
    } elseif {[regexp {^\s*Design\s+\(Setup\)\s+(\S+)\s+(\S+)\s+(\d+)\s*$} $line match setup_wns setup_tns setup_nvp]} {
      if {![string is double $setup_wns]} { set setup_wns 0.0 }
      if {![string is double $setup_tns]} { set setup_tns 0.0 }
      if {![string is double $setup_nvp]} { set setup_nvp 0 }
    } elseif {[regexp {^\s*Design\s+\(Hold\)\s+(\S+)\s+(\S+)\s+(\d+)\s*$} $line match hold_wns hold_tns hold_nvp]} {
      if {![string is double $hold_wns]} { set hold_wns 0.0 }
      if {![string is double $hold_tns]} { set hold_tns 0.0 }
      if {![string is double $hold_nvp]} { set hold_nvp 0 }
    } elseif {[regexp {^\s*Error\:} $line]} {
      echo "Error: found in report_qor. Exiting ..."
      return
    }

  }
  if {$drc==0} { set drc [expr $tran+$cap+$fan] }
  }

  if {$pt_file} {
  set i 0
  set group_just_set 0
  foreach line [split $x "\n"] {
  
    incr i
    #echo "Processing $i : $line"

    if {[regexp {^\s*Scenario\s+\'(\S+)\'} $line match scenario]} {
    } elseif {[regexp {^\s*Timing Path Group\s+\'(\S+)\'\s*\(max_delay} $line match group]} {
      if {[info exists scenario]} { set group ${group}($scenario) }
      set GROUPS($group) 1
      set group_just_set 1
      set group_is_setup 1
      unset -nocomplain ll cpl wns cp tns nvp wnsh tnsh nvph fr
    } elseif {[regexp {^\s*Timing Path Group\s+\'(\S+)\'\s*\(min_delay} $line match group]} {
      if {[info exists scenario]} { set group ${group}($scenario) }
      set GROUPS($group) 1
      set group_just_set 1
      set group_is_setup 0
      unset -nocomplain ll cpl wns cp tns nvp wnsh tnsh nvph fr
    } elseif {[regexp {^\s*------\s*$} $line]} {
      if {$group_just_set} {
        continue 
      } else {
        set group_just_set 0
        unset -nocomplain group scenario
      }
    } elseif {[regexp {^\s*Levels of Logic\s*:\s*(\S+)\s*$} $line match ll]} {
      set GROUP_LL($group) $ll
    } elseif {[regexp {^\s*Critical Path Length\s*:\s*(\S+)\s*$} $line match cpl]} {
      set GROUP_CPL($group) $cpl
    } elseif {[regexp {^\s*Critical Path Slack\s*:\s*(\S+)\s*$} $line match wns]} {
      if {![string is double $wns]} { set wns 0.0 } 
      if {$group_is_setup} { set GROUP_WNS($group) $wns } else { set GROUP_WNSH($group) $wns }
    } elseif {[regexp {^\s*Critical Path Clk Period\s*:\s*(\S+)\s*$} $line match cp]} {
      if {![string is double $cp]} { set cp 0.0 }
      set GROUP_CP($group) $cp
    } elseif {[regexp {^\s*Total Negative Slack\s*:\s*(\S+)\s*$} $line match tns]} {
      if {$group_is_setup} { set GROUP_TNS($group) $tns } else { set GROUP_TNSH($group) $tns }
    } elseif {[regexp {^\s*No\. of Violating Paths\s*:\s*(\S+)\s*$} $line match nvp]} {
      if {$group_is_setup} { set GROUP_NVP($group) $nvp } else { set GROUP_NVPH($group) $nvp }

    } elseif {[regexp {^\s*Hierarchical Cell Count\s*:\s*(\S+)\s*$} $line match hierc]} {
    } elseif {[regexp {^\s*Hierarchical Port Count\s*:\s*(\S+)\s*$} $line match hierp]} {
    } elseif {[regexp {^\s*Leaf Cell Count\s*:\s*(\S+)\s*$} $line match leaf]} {
      set leaf [expr {$leaf/1000}]
    } elseif {[regexp {^\s*Buf/Inv Cell Count\s*:\s*(\S+)\s*$} $line match buf]} {
      set buf [expr {$buf/1000}]
    } elseif {[regexp {^\s*CT Buf/Inv Cell Count\s*:\s*(\S+)\s*$} $line match cbuf]} {
    } elseif {[regexp {^\s*Combinational Cell Count\s*:\s*(\S+)\s*$} $line match combc]} {
      set combc [expr $combc/1000]
    } elseif {[regexp {^\s*Sequential Cell Count\s*:\s*(\S+)\s*$} $line match seqc]} {
    } elseif {[regexp {^\s*Macro Count\s*:\s*(\S+)\s*$} $line match macroc]} {
 
    } elseif {[regexp {^\s*Combinational Area\s*:\s*(\S+)\s*$} $line match comba]} {
      set comba [expr {int($comba)}]
    } elseif {[regexp {^\s*Noncombinational Area\s*:\s*(\S+)\s*$} $line match seqa]} {
      set seqa [expr {int($seqa)}]
    } elseif {[regexp {^\s*Net Interconnect area\s*:\s*(\S+)\s*$} $line match neta]} {
      set neta [expr {int($neta)}]
    } elseif {[regexp {^\s*Net XLength\s*:\s*(\S+)\s*$} $line match netx]} {
    } elseif {[regexp {^\s*Net YLength\s*:\s*(\S+)\s*$} $line match nety]} {
    } elseif {[regexp {^\s*Total cell area\s*.*:\s*(\S+)\s*$} $line match cella]} {
      set cella [expr {int($cella)}]
    } elseif {[regexp {^\s*Design Area\s*:\s*(\S+)\s*$} $line match desa]} {
      set desa [expr {int($desa)}]
    } elseif {[regexp {^\s*Net Length\s*:\s*(\S+)\s*$} $line match netl]} {
      set netl [expr {int($netl)}]

    } elseif {[regexp {^\s*Total Number of Nets\s*:\s*(\S+)\s*$} $line match tnets]} {
      set tnets [expr {$tnets/1000}]
    } elseif {[regexp {^\s*Nets With Violations\s*:\s*(\S+)\s*$} $line match drc]} {
    } elseif {[regexp {^\s*max_transition Count\s*:\s*(\S+)\s*$} $line match tran]} {
    } elseif {[regexp {^\s*max_capacitance Count\s*:\s*(\S+)\s*$} $line match cap]} {
    } elseif {[regexp {^\s*max_fanout Count\s*:\s*(\S+)\s*$} $line match fan]} {


    } elseif {[regexp {^\s*Scenario:\s*(\S+)\s+\s+WNS:\s*(\S+)\s*TNS:\s*(\S+).*Paths:\s*(\S+)} $line match scenario wns tns nvp]} {
      set SETUP_SCENARIOS($scenario) 1
      set SETUP_SCENARIO_WNS($scenario) $wns
      set SETUP_SCENARIO_TNS($scenario) $tns
      set SETUP_SCENARIO_NVP($scenario) $nvp
    } elseif {[regexp {^\s*Scenario:\s*(\S+)\s+\(Hold\)\s+WNS:\s*(\S+)\s*TNS:\s*(\S+).*Paths:\s*(\S+)} $line match scenario wns tns nvp]} {
      set HOLD_SCENARIOS($scenario) 1
      set HOLD_SCENARIO_WNS($scenario) $wns
      set HOLD_SCENARIO_TNS($scenario) $tns
      set HOLD_SCENARIO_NVP($scenario) $nvp
    } elseif {[regexp {^\s*Setup\s+WNS:\s*(\S+)\s*TNS:\s*(\S+).*Paths:\s*(\S+)} $line match setup_wns setup_tns setup_nvp]} {
      if {![string is double $setup_wns]} { set setup_wns 0.0 }
      if {![string is double $setup_tns]} { set setup_tns 0.0 }
      if {![string is double $setup_nvp]} { set setup_nvp 0 }
    } elseif {[regexp {^\s*Hold\s*WNS:\s*(\S+)\s*TNS:\s*(\S+).*Paths:\s*(\S+)} $line match hold_wns hold_tns hold_nvp]} {
      if {![string is double $hold_wns]} { set hold_wns 0.0 }
      if {![string is double $hold_tns]} { set hold_tns 0.0 }
      if {![string is double $hold_nvp]} { set hold_nvp 0 }
    } elseif {[regexp {^\s*Error\:} $line]} {
      echo "Error: found in report_qor. Exiting ..."
      return
    }

  }
  if {$drc==0} { set drc [expr $tran+$cap+$fan] }
  }

  if {![info exists GROUPS]} {
    echo "Error!! no QoR data found to reformat"
    return
  }

  if {$skew_flag} {

    if { $::synopsys_program_name == "icc2_shell" || $::synopsys_program_name == "dcrt_shell" || $::synopsys_program_name == "fc_shell" } {
      if {![get_app_option -name time.remove_clock_reconvergence_pessimism]} { echo "WARNING!! crpr is not turned on, skew values reported could be pessimistic" }
    } else {
      if {$::timing_remove_clock_reconvergence_pessimism=="false"} { echo "WARNING!! crpr is not turned on, skew values reported could be pessimistic" }
    }
    echo "Skews numbers reported include any ocv derates, crpr value is close, but may not match report_timing UITE-468"
    echo "Getting setup timing paths for skew analysis"
    if { $::synopsys_program_name != "pt_shell" && $::synopsys_program_name != "icc2_shell" && $::synopsys_program_name != "fc_shell" } {
      redirect /dev/null {set paths [get_timing_paths -slack_less 0 -max_paths 100000] } 
    } else { 
      redirect /dev/null {set paths [get_timing_paths -slack_less 0 -max_paths 100000 -pba_mode $pba_mode] } 
    }

    foreach_in_collection p $paths {

      set g [get_attribute [get_attribute -quiet $p path_group] full_name]
      set scenario [get_attribute -quiet $p scenario]
      if {[regexp {^_sel\d+$} $scenario]} { set scenario [get_object_name $scenario] }
      if {$scenario !=""} { set g ${g}($scenario) }
      if { $::synopsys_program_name == "icc2_shell" || $::synopsys_program_name == "dcrt_shell" || $::synopsys_program_name == "fc_shell" } {
        set e_arr [get_attribute -quiet $p endpoint_clock_close_edge_arrival]
        set e_val [get_attribute -quiet $p endpoint_clock_close_edge_value]
        if {$e_arr!=""&&$e_val!=""} { set e [expr {$e_arr-$e_val}] ; if {$e<0} { set e 0.0 } }
        set s_arr [get_attribute -quiet $p startpoint_clock_open_edge_arrival]
        set s_val [get_attribute -quiet $p startpoint_clock_open_edge_value]
        if {$s_arr!=""&&$s_val!=""} { set s [expr {$s_arr-$s_val}] ; if {$s<0} { set s 0.0 } }
      } else {
        set e [get_attribute -quiet $p endpoint_clock_latency]
        set s [get_attribute -quiet $p startpoint_clock_latency]
      }

      if { $::synopsys_program_name == "pt_shell" || $::synopsys_program_name == "icc2_shell" || $::synopsys_program_name == "dcrt_shell" || $::synopsys_program_name == "fc_shell" } { 
        set crpr [get_attribute -quiet $p common_path_pessimism]
      } else {
        set crpr [get_attribute -quiet $p crpr_value]
      }
      if {$crpr==""} { set crpr 0 }

      if {$e!=""&&$s!=""} { set skew [expr {$e-$s}] } else { set skew 0 }

      if {$skew<0}       { set skew [expr {$skew+$crpr}]
      } elseif {$skew>0} { set skew [expr {$skew-$crpr}]
      } elseif {$skew==0} {}

      if {![info exists SKEW_WNS($g)]} { set SKEW_WNS($g) $skew }
      if {![info exists SKEW_TNS($g)]} { set SKEW_TNS($g) $skew } else { set SKEW_TNS($g) [expr {$SKEW_TNS($g)+$skew}] }
    }

    echo "Getting hold  timing paths for skew analysis"
    if {$::synopsys_program_name != "pt_shell"} {
      redirect /dev/null { set paths [get_timing_paths -slack_less 0 -max_paths 100000 -delay min] }
    } else { 
      redirect /dev/null { set paths [get_timing_paths -pba_mode $pba_mode -slack_less 0 -max_paths 100000 -delay min] }
    }

    foreach_in_collection p $paths {

      set g [get_attribute [get_attribute -quiet $p path_group] full_name]
      set scenario [get_attribute -quiet $p scenario]
      if {[regexp {^_sel\d+$} $scenario]} { set scenario [get_object_name $scenario] }
      if {$scenario !=""} { set g ${g}($scenario) }
      if { $::synopsys_program_name == "icc2_shell" || $::synopsys_program_name == "dcrt_shell" || $::synopsys_program_name == "fc_shell" } { 
        set e_arr [get_attribute -quiet $p endpoint_clock_close_edge_arrival]
        set e_val [get_attribute -quiet $p endpoint_clock_close_edge_value]
        if {$e_arr!=""&&$e_val!=""} { set e [expr {$e_arr-$e_val}] ; if {$e<0} { set e 0.0 } }
        set s_arr [get_attribute -quiet $p startpoint_clock_open_edge_arrival]
        set s_val [get_attribute -quiet $p startpoint_clock_open_edge_value]
        if {$s_arr!=""&&$s_val!=""} { set s [expr {$s_arr-$s_val}] ; if {$s<0} { set s 0.0 } }
      } else {
        set e [get_attribute -quiet $p endpoint_clock_latency]
        set s [get_attribute -quiet $p startpoint_clock_latency]
      }

      if { $::synopsys_program_name == "pt_shell" || $::synopsys_program_name == "icc2_shell" || $::synopsys_program_name == "dcrt_shell" || $::synopsys_program_name == "fc_shell" } { 
        set crpr [get_attribute -quiet $p common_path_pessimism]
      } else {
        set crpr [get_attribute -quiet $p crpr_value]
      }
      if {$crpr==""} { set crpr 0 }

      if {$e!=""&&$s!=""} { set skew [expr {$e-$s}] } else { set skew 0 }

      if {$skew<0}       { set skew [expr {$skew+$crpr}]
      } elseif {$skew>0} { set skew [expr {$skew-$crpr}]
      } elseif {$skew==0} {}

      if {![info exists SKEW_WNSH($g)]} { set SKEW_WNSH($g) $skew }
      if {![info exists SKEW_TNSH($g)]} { set SKEW_TNSH($g) $skew } else { set SKEW_TNSH($g) [expr {$SKEW_TNSH($g)+$skew}] }
    }

    foreach g [array names GROUPS] {

      if {![info exists SKEW_WNS($g)]} { 
        set SKEW_WNS($g) 0.0
        set SKEW_TNS($g) 0.0
      } else {
        set SKEW_TNS($g) [expr {$SKEW_TNS($g)/$GROUP_NVP($g)}]
        if {![info exists maxskew]} { set maxskew $SKEW_WNS($g) }
        if {![info exists maxavg]} { set maxavg $SKEW_TNS($g) }
        if {$maxskew>$SKEW_WNS($g)} { set maxskew $SKEW_WNS($g) }
        if {$maxavg>$SKEW_TNS($g)} { set maxavg $SKEW_TNS($g) }
      }

      if {![info exists SKEW_WNSH($g)]} {
        set SKEW_WNSH($g) 0.0
        set SKEW_TNSH($g) 0.0
      } else {
        set SKEW_TNSH($g) [expr {$SKEW_TNSH($g)/$GROUP_NVPH($g)}]
        if {![info exists maxskewh]} { set maxskewh $SKEW_WNSH($g) }
        if {![info exists maxavgh]} { set maxavgh $SKEW_TNSH($g) }
        if {$maxskewh<$SKEW_WNSH($g)} { set maxskewh $SKEW_WNSH($g) }
        if {$maxavgh<$SKEW_TNSH($g)} { set maxavgh $SKEW_TNSH($g) }
      }

    }

    if {![info exists maxskew]} { set maxskew 0.0 }
    if {![info exists maxavg]} { set maxavg 0.0 }
    if {![info exists maxskewh]} { set maxskewh 0.0 }
    if {![info exists maxavgh]} { set maxavgh 0.0 }

    set maxskew  [format "%10.3f" $maxskew]
    set maxavg   [format "%10.3f" $maxavg]
    set maxskewh [format "%10.3f" $maxskewh]
    set maxavgh  [format "%10.3f" $maxavgh]

  }

  if {[info exists GROUP_WNS]} {
    foreach g [proc_mysort_hash -values GROUP_WNS] {
  
      set wns  [expr {double($GROUP_WNS($g))}]
      if {$pt_file&&!$file_flag} {
        if {![info exists GROUP_CP($g)]} { 
          redirect /dev/null { set cp [get_attr -quiet [get_timing_path -group $g -pba_mode $pba_mode] endpoint_clock.period] }
          if {$cp!=""} { set GROUP_CP($g) $cp }
        }
      }
      if {![info exists GROUP_CP($g)]} { continue }
      set per  [expr {double($GROUP_CP($g))}]
      if {$wns >= $per} { set freq 0.0
      } else {
        if {$uncert_flag} {
          set freq [expr {1.0/($per-$wns-$signoff_uncert)*$unit}]
        } else {
          set freq [expr {1.0/($per-$wns)*$unit}] 
        }
      }
      if {![info exists wfreq]} { set wfreq [format "% 7.0fMHz" $freq] }
      set GROUP_FREQ($g) $freq

    }
  }

  if {![info exists wfreq]} { set wfreq [format "% 7.0fMhz" 0.0] }

  set ttns  0.0
  set tnvp  0
  set ttnsh 0.0
  set tnvph 0

  foreach g [array names GROUPS] {

    if {[info exists GROUP_TNS($g)]}  { set ttns  [expr {$ttns+$GROUP_TNS($g)}] }
    if {[info exists GROUP_NVP($g)]}  { set tnvp  [expr {$tnvp+$GROUP_NVP($g)}] }
    if {[info exists GROUP_TNSH($g)]} { set ttnsh [expr {$ttnsh+$GROUP_TNSH($g)}] }
    if {[info exists GROUP_NVPH($g)]} { set tnvph [expr {$tnvph+$GROUP_NVPH($g)}] }

    if {[info exists GROUP_WNS($g)]}  { set GROUP_WNS_F($g)  [format "% 10.3f" $GROUP_WNS($g)] }  else { set GROUP_WNS_F($g)  [format "% 10s" $nil] }
    if {[info exists GROUP_TNS($g)]}  { set GROUP_TNS_F($g)  [format "% 10.1f" $GROUP_TNS($g)] }  else { set GROUP_TNS_F($g)  [format "% 10s" $nil] }
    if {[info exists GROUP_NVP($g)]}  { set GROUP_NVP_F($g)  [format "% 7.0f"  $GROUP_NVP($g)] }  else { set GROUP_NVP_F($g)  [format "% 7s" $nil] }
    if {[info exists GROUP_WNSH($g)]} { set GROUP_WNSH_F($g) [format "% 10.3f" $GROUP_WNSH($g)] } else { set GROUP_WNSH_F($g) [format "% 10s" $nil] }
    if {[info exists GROUP_TNSH($g)]} { set GROUP_TNSH_F($g) [format "% 10.1f" $GROUP_TNSH($g)] } else { set GROUP_TNSH_F($g) [format "% 10s" $nil] }
    if {[info exists GROUP_NVPH($g)]} { set GROUP_NVPH_F($g) [format "% 7.0f"  $GROUP_NVPH($g)] } else { set GROUP_NVPH_F($g) [format "% 7s" $nil] }
    if {[info exists GROUP_FREQ($g)]} { set GROUP_FREQ_F($g) [format "% 7.0fMHz"  $GROUP_FREQ($g)] } else { set GROUP_FREQ_F($g) [format "% 10s" $nil] }

    if {[info exists SKEW_WNS($g)]}  { set SKEW_WNS_F($g)  [format "% 10.3f"  $SKEW_WNS($g)] }  else { set SKEW_WNS_F($g)  [format "% 10s" $nil] }
    if {[info exists SKEW_TNS($g)]}  { set SKEW_TNS_F($g)  [format "% 10.3f"  $SKEW_TNS($g)] }  else { set SKEW_TNS_F($g)  [format "% 10s" $nil] }
    if {[info exists SKEW_WNSH($g)]} { set SKEW_WNSH_F($g) [format "% 10.3f"  $SKEW_WNSH($g)] } else { set SKEW_WNSH_F($g) [format "% 10s" $nil] }
    if {[info exists SKEW_TNSH($g)]} { set SKEW_TNSH_F($g) [format "% 10.3f"  $SKEW_TNSH($g)] } else { set SKEW_TNSH_F($g) [format "% 10s" $nil] }
  }

  if {[info exists setup_tns]} { set ttns $setup_tns }
  if {[info exists setup_nvp]} { set tnvp $setup_nvp }
  if {[info exists hold_tns]} { set ttnsh $hold_tns }
  if {[info exists hold_nvp]} { set tnvph $hold_nvp }
  set ttns [format "% 10.1f" $ttns]
  set tnvp [format "% 7.0f" $tnvp]
  set ttnsh [format "% 10.1f" $ttnsh]
  set tnvph [format "% 7.0f" $tnvph]

  set maxl 0
  foreach g [array names GROUPS] {
    set l [string length $g]
    if {$maxl < $l} { set maxl $l }
  }
  set maxl [expr {$maxl+2}]
  if {$maxl < 20} { set maxl 20 }
  set drccol [expr {$maxl-13}]

  for {set i 0} {$i<$maxl} {incr i} { append bar - }
  if {$skew_flag} { 
    set bar "${bar}-------------------------------------------------------------------------------------------------------------------" 
  } else {
    set bar "${bar}-----------------------------------------------------------------------"
  }

  if {$skew_flag} {

    echo ""
    echo "SKEW      - Skew on WNS Path"
    echo "AVGSKW    - Average Skew on TNS Paths"
    echo "NVP       - No. of Violating Paths"
    echo "FREQ      - Estimated Frequency, not accurate in some cases, multi/half-cycle, etc"
    echo "WNS(H)    - Hold WNS"
    echo "SKEW(H)   - Skew on Hold WNS Path"
    echo "TNS(H)    - Hold TNS"
    echo "AVGSKW(H) - Average Skew on Hold TNS Paths"
    echo "NVP(H)    - Hold NVP"
    echo ""

    puts $csv "Path Group, WNS, SKEW, TNS, AVGSKW, NVP, FREQ, WNS(H), SKEW(H), TNS(H), AVGSKW(H), NVP(H)"
    echo [format "%-${maxl}s % 10s % 10s % 10s % 10s % 7s % 9s    % 8s % 10s % 10s % 10s % 7s" \
    "Path Group" "WNS" "SKEW" "TNS" "AVGSKW" "NVP" "FREQ" "WNS(H)" "SKEW(H)" "TNS(H)" "AVGSKW(H)" "NVP(H)"]
    echo "$bar"

  } else {

    echo ""
    echo "NVP    - No. of Violating Paths"
    echo "FREQ   - Estimated Frequency, not accurate in some cases, multi/half-cycle, etc"
    echo "WNS(H) - Hold WNS"
    echo "TNS(H) - Hold TNS"
    echo "NVP(H) - Hold NVP"
    echo ""

    puts $csv "Path Group, WNS, TNS, NVP, FREQ, WNS(H), TNS(H), NVP(H)"
    echo [format "%-${maxl}s % 10s % 10s % 7s % 9s    % 8s % 10s % 7s" \
    "Path Group" "WNS" "TNS" "NVP" "FREQ" "WNS(H)" "TNS(H)" "NVP(H)"]
    echo "$bar"

  }

  unset -nocomplain wwns wwnsh
  if {[info exists setup_wns]} {
    set wwns [format "%10.3f" $setup_wns]
  } else { if {[info exists GROUP_WNS]} { foreach g [proc_mysort_hash -values GROUP_WNS] { if {![info exists wwns]} { set wwns $GROUP_WNS_F($g) } } } }
  if {![info exists wwns]} { set wwns [format "% 10s" $nil] }

  if {[info exists hold_wns]} { 
    set wwnsh [format "%10.3f" $hold_wns]
  } else { if {[info exists GROUP_WNSH]} { foreach g [proc_mysort_hash -values GROUP_WNSH] { if {![info exists wwnsh]} { set wwnsh $GROUP_WNSH_F($g) } } } }
  if {![info exists wwnsh]} { set wwnsh [format "% 10s" $nil] }

  if {$sort_by_tns_flag} {
    set setup_sort_group GROUP_TNS
    set hold_sort_group  GROUP_TNSH
  } else {
    set setup_sort_group GROUP_WNS
    set hold_sort_group  GROUP_WNSH
  }

  if {[info exists GROUP_WNS]} {
    foreach g [proc_mysort_hash -values $setup_sort_group] {

      if {$skew_flag} {
        puts $csv "[format "%-${maxl}s" $g], $GROUP_WNS_F($g), $SKEW_WNS_F($g), $GROUP_TNS_F($g), $SKEW_TNS_F($g), $GROUP_NVP_F($g), $GROUP_FREQ_F($g), $GROUP_WNSH_F($g), $SKEW_WNSH_F($g), $GROUP_TNSH_F($g), $SKEW_TNSH_F($g), $GROUP_NVPH_F($g)\n"
      } else {
        puts $csv "[format "%-${maxl}s" $g], $GROUP_WNS_F($g), $GROUP_TNS_F($g), $GROUP_NVP_F($g), $GROUP_FREQ_F($g), $GROUP_WNSH_F($g), $GROUP_TNSH_F($g), $GROUP_NVPH_F($g)\n"
      }

      if {!$no_pg_flag} {
        if {$skew_flag} {
          echo      "[format "%-${maxl}s" $g] $GROUP_WNS_F($g) $SKEW_WNS_F($g) $GROUP_TNS_F($g) $SKEW_TNS_F($g) $GROUP_NVP_F($g) $GROUP_FREQ_F($g) $GROUP_WNSH_F($g) $SKEW_WNSH_F($g) $GROUP_TNSH_F($g) $SKEW_TNSH_F($g) $GROUP_NVPH_F($g)"
        } else {
          echo      "[format "%-${maxl}s" $g] $GROUP_WNS_F($g) $GROUP_TNS_F($g) $GROUP_NVP_F($g) $GROUP_FREQ_F($g) $GROUP_WNSH_F($g) $GROUP_TNSH_F($g) $GROUP_NVPH_F($g)"
        }
      }
      set PRINTED($g) 1

    }
  }

  if {[info exists GROUP_WNSH]} {
    foreach g [proc_mysort_hash -values $hold_sort_group] {

      if {[info exists PRINTED($g)]} { continue }

      if {$skew_flag} {
        puts $csv "[format "%-${maxl}s" $g], $GROUP_WNS_F($g), $SKEW_WNS_F($g), $GROUP_TNS_F($g), $SKEW_TNS_F($g), $GROUP_NVP_F($g), $GROUP_FREQ_F($g), $GROUP_WNSH_F($g), $SKEW_WNSH_F($g), $GROUP_TNSH_F($g), $SKEW_TNSH_F($g), $GROUP_NVPH_F($g)\n"
      } else {
        puts $csv "[format "%-${maxl}s" $g], $GROUP_WNS_F($g), $GROUP_TNS_F($g), $GROUP_NVP_F($g), $GROUP_FREQ_F($g), $GROUP_WNSH_F($g), $GROUP_TNSH_F($g), $GROUP_NVPH_F($g)\n"
      }

      if {!$no_pg_flag} {
        if {$skew_flag} {
          echo      "[format "%-${maxl}s" $g] $GROUP_WNS_F($g) $SKEW_WNS_F($g) $GROUP_TNS_F($g) $SKEW_TNS_F($g) $GROUP_NVP_F($g) $GROUP_FREQ_F($g) $GROUP_WNSH_F($g) $SKEW_WNSH_F($g) $GROUP_TNSH_F($g) $SKEW_TNSH_F($g) $GROUP_NVPH_F($g)"
        } else {
          echo      "[format "%-${maxl}s" $g] $GROUP_WNS_F($g) $GROUP_TNS_F($g) $GROUP_NVP_F($g) $GROUP_FREQ_F($g) $GROUP_WNSH_F($g) $GROUP_TNSH_F($g) $GROUP_NVPH_F($g)"
        }
      }
      set PRINTED($g) 1
    }
  }

  if {!$no_pg_flag} {
    echo "$bar"
  }

  if {$skew_flag} {
    puts $csv "Summary, $wwns, $maxskew, $ttns, $maxavg, $tnvp, $wfreq, $wwnsh, $maxskewh, $ttnsh, $maxavgh, $tnvph"
  } else {
    puts $csv "Summary, $wwns, $ttns, $tnvp, $wfreq, $wwnsh, $ttnsh, $tnvph"
  }

  if {$skew_flag} {
    echo "[format "%-${maxl}s" "Summary"] $wwns $maxskew $ttns $maxavg $tnvp $wfreq $wwnsh $maxskewh $ttnsh $maxavgh $tnvph"
  } else {
    echo "[format "%-${maxl}s" "Summary"] $wwns $ttns $tnvp $wfreq $wwnsh $ttnsh $tnvph"
  }
  echo "$bar"

  puts $csv "CAP, FANOUT, TRAN, TDRC, CELLA, BUFS, LEAFS, TNETS, CTBUF, REGS"

  if {$skew_flag} {
    echo [format "% 7s % 7s % 7s % ${drccol}s % 10s % 10s % 10s % 7s % 10s % 10s" \
     "CAP" "FANOUT" "TRAN" "TDRC" "CELLA" "BUFS" "LEAFS" "TNETS" "CTBUF" "REGS"]
  } else {
    echo [format "% 7s % 7s % 7s % ${drccol}s % 10s % 7s % 9s % 11s % 10s % 7s" \
    "CAP" "FANOUT" "TRAN" "TDRC" "CELLA" "BUFS" "LEAFS" "TNETS" "CTBUF" "REGS"]
  }
  echo "$bar"

  if {$buf==0}   { set buf   $nil }
  if {$tnets==0} { set tnets $nil }
  if {$cbuf==0}  { set cbuf  $nil }
  if {$seqc==0}  { set seqc  $nil }

  puts $csv "$cap, $fan, $tran, $drc, $cella, ${buf}K, ${leaf}K, ${tnets}K, $cbuf, $seqc"

  if {$skew_flag} {
    echo [format "% 7s % 7s % 7s % ${drccol}s % 10s % 9sK % 9sK % 6sK % 10s % 10s" \
    $cap $fan $tran $drc $cella $buf $leaf $tnets $cbuf $seqc]
  } else {
    echo [format "% 7s % 7s % 7s % ${drccol}s % 10s % 6sK % 8sK % 10sK % 10s % 7s" \
    $cap $fan $tran $drc $cella $buf $leaf $tnets $cbuf $seqc]
  }
  echo "$bar"


  if {![info exists setup_tns]} { echo "#Union TNS/NVP not found in report_qor, Summary line will report pessimistic summation TNS/NVP" }

  close $csv
  if {$::synopsys_program_name == "pt_shell"&&!$file_flag} {
          set ::timing_report_unconstrained_paths $orig_uncons
          set ::timing_report_union_tns $orig_union
  }
  echo "Written $csv_file"

  if {!$file_flag&&!$no_hist_flag} { 
    if {$pba_mode=="none"} {
      proc_histogram
    } else {
      proc_histogram -pba_mode $pba_mode
    }
  }
  rename proc_mysort_hash ""

}

define_proc_attributes proc_qor -info "USER PROC: reformats report_qor" \
          -define_args {
          {-tee     "Optional - displays the output of under-the-hood report_qor command" "" boolean optional}
          {-no_histogram "Optional - Skips printing text histogram for setup corner" "" boolean optional}
          {-existing_qor_file "Optional - Existing report_qor file to reformat" "<report_qor file>" string optional}
          {-scenarios "Optional - report qor on specified set of scenarios, skip on inactive scenarios" "{ scenario_name1 scenario_name2 ... }" string optional}
          {-no_pathgroup_info "Optional - to suppress individual pathgroup info" "" boolean optional}
          {-sort_by_tns "Optional - to sort by tns instead of wns" "" boolean optional}
          {-skew     "Optional - reports skew and avg skew on failing path groups" "" boolean optional}
          {-csv_file "Optional - Output csv file name, default is qor.csv" "<output csv file>" string optional}
          {-units    "Optional - override the automatic units calculation" "<ps or ns>" one_of_string {optional value_help {values {ps ns}}}}
          {-pba_mode "Optional - pba mode when in PrimeTime, ICC2, and FC" "<path, exhaustive, none>" one_of_string {optional value_help {values {path exhaustive none}}}}
          {-signoff_uncertainty_adjustment "Optional - adjusts ONLY the frequency column with signoff uncertainty, default 0." "" float optional}
          }

proc proc_histogram {args} {

set ::timing_save_pin_arrival_and_slack true
echo "\nStarting  Histogram (proc_histogram)\n"

parse_proc_arguments -args $args results

set s_flag  [info exists results(-slack_lesser_than)]
set gs_flag [info exists results(-slack_greater_than)]
set path_flag [info exists results(-paths)]
set h_flag [info exists results(-hold)]
set pba_mode "none"

if {[info exists results(-number_of_bins)]} { set numbins $results(-number_of_bins) } else { set numbins 10 }
if {[info exists results(-slack_lesser_than)]} { set slack $results(-slack_lesser_than) } else { set slack 0.0 }
if {[info exists results(-slack_greater_than)]} { set gslack $results(-slack_greater_than) }
if {[info exists results(-hold)]} { set attr "min_slack" } else { set attr "max_slack" }
if {[info exists results(-number_of_critical_hierarchies)]} { set number $results(-number_of_critical_hierarchies) } else { set number 10 }

if {[info exists results(-pba_mode)]} {
  if { $::synopsys_program_name != "pt_shell" && $::synopsys_program_name != "icc2_shell" && $::synopsys_program_name != "fc_shell" } { echo "Error!! -pba_mode supported in pt_shell, icc2_shell, and fc_shell" ; return }
  set pba_mode $results(-pba_mode)
}

if {$gs_flag&&!$s_flag} { echo "Error!! -slack_greater_than can only be used with -slack_lesser_than ....Exiting\n" ; return }
if {$gs_flag&&$gslack>$slack} { echo "Error!! -slack_greater_than should be more than -slack_lesser_than ....Exiting\n" ; return }

if {[info exists results(-clock)]} {
  set clock [get_clocks -quiet $results(-clock)]
  if {[sizeof $clock]!=1} { echo "Error!! provided -clock value did not results in 1 clock" ; return }
  set clock_arg "-clock [get_object_name $clock]"
  set clock_per [get_attr $clock period]
} else {
  set clock_arg ""
}

foreach_in_collection clock [all_clocks] { if {[get_attribute -quiet $clock sources] != "" } { append_to_collection -unique real_clocks $clock } }
set min_period [lindex [lsort -real [get_attr -quiet $real_clocks period]] 0]

catch {redirect -var y {report_units}}
if {[regexp {(\S+)\s+Second} $y match unit]} {
  if {[regexp {e-12} $unit]} { set unit 1000000 } else { set unit 1000 }
} elseif {[regexp {ns} $y]} { set unit 1000
} elseif {[regexp {ps} $y]} { set unit 1000000 }

if {![info exists unit]} { set unit 1000 }

if {[info exists clock_per]} { set min_period $clock_per }
if {$min_period<=0} { echo "Error!! Failed to calculate min_period of real clocks .... Exiting\n" ; return }

if {$path_flag} {

  set paths $results(-paths)
  if {[sizeof $paths]<2} { echo "Error! Not enough -paths [sizeof $paths] given for histogram" ; return }

  set paths [filter_coll $paths "slack!=INFINITY"]
  if {[sizeof $paths]<2} { echo "Error! Not enough -paths [sizeof $paths] with real slack given for histogram" ; return }

  set path_type [lsort -unique [get_attr -quiet $paths path_type]]
  if {[llength $path_type]!=1} { echo "Error! please provide only max paths or min paths - not both" ; return }
  if {$path_type=="min"} { set attr "min_slack" ; set h_flag 1 } else { set attr "max_slack" ; set h_flag 0 }

  echo "Analayzing given [sizeof $paths] path collection - ignores REGOUT\n"
  set coll $paths 
  set endpoint_coll [get_pins -quiet [get_attr -quiet $paths endpoint]]
  if {[sizeof $endpoint_coll]<2} { echo "\nNo Violations or Not enough Violations Found" ; return }
  set check_attr "slack"
}

if {!$path_flag} {

  if {$pba_mode =="none"} {
    set type "GBA"
  } elseif {$pba_mode =="path"} {
    set type "PBA Path"
  } elseif {$pba_mode =="exhaustive"} {
    set type "PBA Exhaustive"
  }

  if {$gs_flag} {
    echo -n "Acquiring $type Endpoints ($gslack > Slack < $slack) - ignores REGOUT ... "
  } else {
    echo -n "Acquiring $type Endpoints (Slack < $slack) - ignores REGOUT ... "
  }

  set coll   [sort_coll [filter_coll [eval all_registers -data_pins $clock_arg] "$attr<$slack"] $attr]
  if {$gs_flag} { set coll [sort_coll [filter_coll $coll "$attr>$gslack"] $attr] }

  if {[sizeof $coll]<2} { echo "\nNo Violations or Not enough Violations Found" ; return }
  set endpoint_coll $coll

  if {$pba_mode!="none"} {
    set check_attr "slack"
    if {$gs_flag} {
      redirect /dev/null {set coll [get_timing_path -to $coll -pba_mode $pba_mode -max_paths [sizeof $coll] -slack_lesser $slack -slack_greater $gslack] }
      set endpoint_coll [get_attr -quiet $coll endpoint]
    } else {
      redirect /dev/null {set coll [get_timing_path -to $coll -pba_mode $pba_mode -max_paths [sizeof $coll] -slack_lesser $slack] }
      set endpoint_coll [get_attr -quiet $coll endpoint]
    }
  } else {
    set check_attr $attr
  }

  echo "Done\n"
}

if {[sizeof $coll]<2} { echo "\nNo Violations or Not enough Violations Found" ; return }

echo -n "Initializing Histogram ... "
set values [lsort -real [get_attr -quiet $coll $check_attr]]
set min    [lindex $values 0]
set max    [lindex $values [expr {[llength $values]-1}]]
set new_max    [expr $max+0.1]
set range  [expr {$max-$min}]
set width  [expr {$range/$numbins}]

for {set i 1} {$i<=$numbins} {incr i} { 
  set compare($i) [expr {$min+$i*$width}] 
  set histogram($i) 0
  set tns_histogram($i) 0
}
set compare($i) $new_max

echo -n "Populating Bins ... "
foreach v $values {
  for {set i 1} {$i<=$numbins} {incr i} {
    if {$v<=$compare($i)} {
      incr histogram($i)
      if {$v<0} { set tns_histogram($i) [expr {$tns_histogram($i)+$v}] }
      break
    }
  }
}
echo "Done - TNS can be slightly off\n"

set tot_tns 0
for {set i 1} {$i<=$numbins} {incr i} { set tot_tns [expr $tot_tns+$tns_histogram($i)] }

echo "========================================================================="
echo "          WNS RANGE        -          Endpoints                       TNS"
echo "========================================================================="
if {[llength $values]>1} {
  for {set i $numbins} {$i>=1} {incr i -1} {
    set low [expr {$min+$i*$width}]
    set high [expr {$min+($i-1)*$width}]
    set f_low [format %.3f $low]
    set f_high [format %.3f $high]
    set pct [expr {100.0*$histogram($i)/[llength $values]}]
    echo -n "[format "% 10s" $f_low] to [format "% 10s" $f_high]   -  [format %9i $histogram($i)] ([format %4.1f $pct]%)"
    if {$attr=="max_slack"} {
      if {[expr {($min_period-$high)*$unit}]>0} { set freq [expr {(1.0/($min_period-$high))*$unit}] } else { set freq 0.0 }
      echo -n " - [format %4.0f ${freq}]Mhz"
    }
    if {$h_flag} { echo " [format "% 25.1f" $tns_histogram($i)]" } else { echo " [format "% 15.1f" $tns_histogram($i)]" }
  }
}
echo "========================================================================="
echo "Total Endpoints            - [format %10i [llength $values]] [format "% 33.1f" $tot_tns]"
if {$attr=="max_slack"} { echo "Clock Frequency            - [format %10.0f [expr (1.0/$min_period)*$unit]]Mhz (estimated)" }
echo "========================================================================="
echo ""

if { $::synopsys_program_name == "icc2_shell" || $::synopsys_program_name == "pt_shell" || $::synopsys_program_name == "dcrt_shell" || $::synopsys_program_name == "fc_shell" } {
  set allicgs [get_cells -quiet -hi -f "is_hierarchical==false&&is_integrated_clock_gating_cell==true"]
} else {
  set allicgs [get_cells -quiet -hi -f "is_hierarchical==false&&clock_gating_integrated_cell=~*"]
}
set slkff [remove_from_coll [get_cells -quiet -of $endpoint_coll] $allicgs]

foreach c [get_attr -quiet $slkff full_name] {
  set cell $c
  for {set i 1} {$i<20} {incr i} {
    set parent [file dir $cell]
    if {$parent=="."} { break }
    set parent_coll [get_cells -quiet $parent -f "is_hierarchical==true"]
    if {[sizeof $parent_coll]<1} { set cell $parent ; continue }
    if {[info exists hier_repeat($parent)]} { incr hier_repeat($parent) } else { set hier_repeat($parent) 1 }
    set cell $parent
  }
}

echo "========================================================================="
echo " Viol.   $number Critical"
echo " Count - Hierarchies - ignores ICGs"
echo "========================================================================="

if {![array exists hier_repeat]} { echo "No Critial Hierarchies found" ; return }

foreach {a b} [array get hier_repeat] { lappend repeat_list [list $a $b] }

set cnt 0
foreach i [lsort -real -decreasing -index 1 $repeat_list] { 
  echo "[format %6i [lindex $i 1]] - [lindex $i 0]" 
  incr cnt
  if {$cnt==$number} { break }
}
echo "========================================================================="
echo ""

}

define_proc_attributes proc_histogram -info "USER_PROC: Prints histogram of setup or hold slack endpoints" \
  -define_args { \
  {-number_of_bins      "Optional - number of bins for histgram, default 10"			"<int>"               int  optional}
  {-slack_lesser_than   "Optional - histogram for endpoints with slack less than, default 0" 	"<float>"               float  optional}
  {-slack_greater_than  "Optional - histogram for endpoints with slack greater than, can only be used with -slack_greater_than, default wns" 	"<float>"               float  optional}
  {-hold		"Optional - Generates histogram for hold slack, default is setup"	""                      boolean  optional}
  {-number_of_critical_hierarchies      "Optional - number of critical hierarchies to display viol. count, default 10" "<int>" int  optional}
  {-clock      		"Optional - Generates histogram only for the specified clock endpoints, default all clocks" "<clock>" string  optional}
  {-pba_mode 		"Optional - PBA mode supported in PrimeTime, ICC2 and FC" "<path or exhaustive>" one_of_string {optional value_help {values {path exhaustive none}}}}
  {-paths 		"Optional - Generates histogram for given user path collection" "<path coll>" string optional}
}
