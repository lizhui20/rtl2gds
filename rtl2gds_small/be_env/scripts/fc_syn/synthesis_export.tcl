puts "RM-Info: [date] Running script [info script]\n"


if {[info exists DIRTY_LINK] && $DIRTY_LINK == 1} {
    set write_verilog_dc_cmd "write_verilog  -exclude {leaf_module_declarations pg_objects end_cap_cells well_tap_cells filler_cells pad_spacer_cells physical_only_cells cover_cells diode_cells} -hierarchy all ${RESULTS_DIR}/${DCRM_FINAL_VERILOG_OUTPUT_FILE}"
} else {
    set write_verilog_dc_cmd "write_verilog  -exclude {leaf_module_declarations pg_objects end_cap_cells well_tap_cells filler_cells pad_spacer_cells physical_only_cells cover_cells diode_cells} -hierarchy all ${RESULTS_DIR}/${DCRM_FINAL_VERILOG_OUTPUT_FILE}"
}
puts "RM-info: running $write_verilog_dc_cmd"
eval $write_verilog_dc_cmd

#set write_sdc_cmd "write_sdc -exclude {pvt} -nosplit -output ${RESULTS_DIR}/${DCRM_FINAL_SDC_OUTPUT_FILE}"
#puts "RM-info: running $write_sdc_cmd"
#eval $write_sdc_cmd

set write_def_cmd "write_def -compress gzip -version 5.8 -include_tech_via_definitions ${RESULTS_DIR}/${DESIGN_NAME}.def"
puts "RM-info: running $write_def_cmd"
eval $write_def_cmd

write_sdf ${RESULTS_DIR}/${DCRM_DCT_FINAL_SDF_OUTPUT_FILE}

write_floorplan \
  -format icc2 \
  -def_version 5.8 \
  -force \
  -output ${RESULTS_DIR}/${DESIGN_NAME}_write_floorplan \
  -read_def_options {-add_def_only_objects {all}} \
  -exclude {scan_chains fills pg_metal_fills routing_rules} \
  -net_types {power ground} \
  -include_physical_status {fixed locked}

saif_map -type primepower -write_map ${RESULTS_DIR}/${DESIGN_NAME}.mapped.SAIF.namemap

report_qor           > ${REPORTS_DIR}/${DCRM_FINAL_QOR_REPORT}
report_qor -summary  >> ${REPORTS_DIR}/${DCRM_FINAL_QOR_REPORT}
report_timing -significant_digits 4 -transition_time -nets -attributes -nosplit > ${REPORTS_DIR}/${DCRM_FINAL_TIMING_REPORT}

report_area -nosplit > ${REPORTS_DIR}/${DCRM_FINAL_AREA_REPORT}
report_area -nosplit -hierarchy > ${REPORTS_DIR}/${DESIGN_NAME}.mapped.hierarchy_area.rpt
report_area -designware  > ${REPORTS_DIR}/${DCRM_FINAL_DESIGNWARE_AREA_REPORT}
report_resources -hierarchy > ${REPORTS_DIR}/${DCRM_FINAL_RESOURCES_REPORT}
report_clock_gating -nosplit > ${REPORTS_DIR}/${DCRM_FINAL_CLOCK_GATING_REPORT}
report_threshold_voltage_groups > ${REPORTS_DIR}/${DESIGN_NAME}.report_threshold_voltage_groups.rpt
report_constraints -all_violators -max_delay -nosplit > ${REPORTS_DIR}/${DESIGN_NAME}.violators.max.rpt
redirect -tee -file ${REPORTS_DIR}/${DESIGN_NAME}.report_utilization.rpt {report_utilization}

# check_design
redirect -file ${REPORTS_DIR}/${DESIGN_NAME}.check_design.post.sum.rpt \
    {check_design -ems_database check_design.post.ems -checks [list design_mismatch netlist mv_design]}
report_ems_database -name check_design.post.ems > ${REPORTS_DIR}/${DESIGN_NAME}.check_design.post.rpt

if {!([info exists LOGIC_SYN] && $LOGIC_SYN == 1)} {
set_app_options -name route.global.timing_driven -value true	
redirect -tee -file ${REPORTS_DIR}/${DESIGN_NAME}.report_congestion.rpt {report_congestion -layers [get_layers -filter "layer_type==interconnect"] -nosplit}
}
if {[info exists env(DISPLAY)]} {
	gui_start
	#gui_execute_menu_item -menu "View->Layout View"
	gui_execute_menu_item -menu "View->Map->Global Route Congestion"
	gui_write_window_image -format png -file ${REPORTS_DIR}/${DESIGN_NAME}.report_congestion.png
	gui_stop
} else {
	puts "RM-info: env(DISPLAY) is not defined. Global route congestion map snapshot is skipped."
}

proc Proc_Get_Flop_ICG_Rate {rpt} {
    set f [open $rpt r]
    set icg_num "N/A"
    set reg_num "N/A"
    while {![eof $f]} {
        gets $f line
        if {[string match "*Number of Clock gating elements*" $line]} {
            set icg_num [lindex [split $line "|"] 2]
        }
        if {[string match "*Total number of registers*" $line]} {
            set reg_num [lindex [split $line "|"] 2]
        }
    }
    close $f

    if {$icg_num == "N/A" || $reg_num == "N/A"} {
        echo "Total_number_of_registers:        $reg_num "  >> $rpt
        echo "Number_of_Clock gating_elements:  $icg_num "  >> $rpt
        echo "Registers_and_Clock_gating_Rate:  N/A "       >> $rpt
    } else {
        echo "Total_number_of_registers:        $reg_num "  >> $rpt
        echo "Number_of_Clock_gating_elements:  $icg_num "  >> $rpt
        #echo "Registers and Clock gating Rate:  [format "%0.2f" [expr [format "%0.2f" $reg_num]/$icg_num]] "       >> $rpt
        if {$icg_num != "0"} {
            echo "Registers_and_Clock_gating_Rate:  [format "%0.2f" [expr [format "%0.2f" $reg_num]/$icg_num]] "       >> $rpt
        } else {
            echo "Registers_and_Clock_gating_Rate:  0 "     >> $rpt
        }

    }
}

Proc_Get_Flop_ICG_Rate ${REPORTS_DIR}/${DCRM_FINAL_CLOCK_GATING_REPORT}

# redirect ${REPORTS_DIR}/${DCRM_MULTIBIT_BANKING_REPORT} {report_multibit_banking -nosplit }

# read_saif -auto_map_names -input ${DESIGN_NAME}.saif -instance < DESIGN_INSTANCE > -verbose

report_power -nosplit > ${REPORTS_DIR}/${DCRM_FINAL_POWER_REPORT}

# report_self_gating  -nosplit > ${REPORTS_DIR}/${DCRM_FINAL_SELF_GATING_REPORT}

# report_threshold_voltage_group -nosplit > ${REPORTS_DIR}/${DCRM_THRESHOLD_VOLTAGE_GROUP_REPORT}


report_transformed_registers -nosplit > ${REPORTS_DIR}/${DESIGN_NAME}.report_transformed_registers.rpt

create_frame
if {[catch {create_abstract} abstract_error]} {
    if {[string match "*abstract view*not been merged*" $abstract_error]} {
        puts "Warning: stale abstract view detected; removing it and regenerating abstract."
        remove_abstract
        create_frame
        create_abstract
    } else {
        error $abstract_error
    }
}
write_lef  ${RESULTS_DIR}/${DESIGN_NAME}.lef

report_msg -summary
print_message_info -ids * -summary


set write_sdc_cmd "write_sdc -exclude {pvt} -nosplit -output ${RESULTS_DIR}/${DCRM_FINAL_SDC_OUTPUT_FILE}"
puts "RM-info: running $write_sdc_cmd"
eval $write_sdc_cmd

if {1} {
exec sh -c "sed -i 's/^set_operating_conditions /#set_operating_conditions/' ${RESULTS_DIR}/${DCRM_FINAL_SDC_OUTPUT_FILE}"
exec sh -c "sed -i 's/^set_max_fanout /#set_max_fanout/' ${RESULTS_DIR}/${DCRM_FINAL_SDC_OUTPUT_FILE}"
exec sh -c "sed -i 's/^set_max_area /#set_max_area/' ${RESULTS_DIR}/${DCRM_FINAL_SDC_OUTPUT_FILE}"
exec sh -c "sed -i 's/^set_max_transition /#set_max_transition/' ${RESULTS_DIR}/${DCRM_FINAL_SDC_OUTPUT_FILE}"
exec sh -c "sed -i 's/^set_voltage /#set_voltage/' ${RESULTS_DIR}/${DCRM_FINAL_SDC_OUTPUT_FILE}"
exec sh -c "sed -i 's/^set_ideal_network /#set_ideal_network/' ${RESULTS_DIR}/${DCRM_FINAL_SDC_OUTPUT_FILE}"
exec sh -c "sed -i -e {/^#.*line/d} ${RESULTS_DIR}/${DCRM_FINAL_SDC_OUTPUT_FILE}"
}
puts "Information: Fusion Compiler has finished.time is [date]"
puts "RM-Info: [date] Completed script [info script]"

if {[info exists EXIT_STATUS] && $EXIT_STATUS == 1} {
    exit
}
