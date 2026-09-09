puts "RM-Info: Running script [info script]\n"





set DCRM_MW_LIBRARY_NAME                                ${DESIGN_NAME}_LIB
set DCRM_FINAL_MW_CEL_NAME                              ${DESIGN_NAME}_DCT


set DCRM_SDC_INPUT_FILE                                 ${DESIGN_NAME}.sdc
set DCRM_CONSTRAINTS_INPUT_FILE                         ${DESIGN_NAME}.constraints.tcl


set DCRM_CHECK_LIBRARY_REPORT                           ${DESIGN_NAME}.check_library.rpt

set DCRM_CONSISTENCY_CHECK_ENV_FILE                     ${DESIGN_NAME}.compile_ultra.env
set DCRM_CHECK_DESIGN_REPORT                            ${DESIGN_NAME}.check_design.rpt
set DCRM_ANALYZE_DATAPATH_EXTRACTION_REPORT             ${DESIGN_NAME}.analyze_datapath_extraction.rpt

set DCRM_FINAL_QOR_REPORT                               ${DESIGN_NAME}.mapped.qor.rpt
set DCRM_FINAL_TIMING_REPORT                            ${DESIGN_NAME}.mapped.timing.rpt
set DCRM_FINAL_AREA_REPORT                              ${DESIGN_NAME}.mapped.area.rpt
set DCRM_FINAL_POWER_REPORT                             ${DESIGN_NAME}.mapped.power.rpt
set DCRM_FINAL_CLOCK_GATING_REPORT                      ${DESIGN_NAME}.mapped.clock_gating.rpt
set DCRM_FINAL_SELF_GATING_REPORT                       ${DESIGN_NAME}.mapped.self_gating.rpt
set DCRM_THRESHOLD_VOLTAGE_GROUP_REPORT                 ${DESIGN_NAME}.mapped.threshold.voltage.group.rpt
set DCRM_INSTANTIATE_CLOCK_GATES_REPORT                 ${DESIGN_NAME}.instatiate_clock_gates.rpt
set DCRM_FINAL_DESIGNWARE_AREA_REPORT                   ${DESIGN_NAME}.mapped.designware_area.rpt
set DCRM_FINAL_RESOURCES_REPORT                         ${DESIGN_NAME}.mapped.final_resources.rpt

set DCRM_MULTIBIT_CREATE_REGISTER_BANK_FILE             ${DESIGN_NAME}.register_bank.rpt
set DCRM_MULTIBIT_CREATE_REGISTER_BANK_REPORT           ${DESIGN_NAME}.register_bank_report_file.rpt 
set DCRM_MULTIBIT_COMPONENTS_REPORT                     ${DESIGN_NAME}.multibit.components.rpt
set DCRM_MULTIBIT_BANKING_REPORT                        ${DESIGN_NAME}.multibit.banking.rpt



#set DCRM_READ_DESIGN_FILE_LOG                           ${DESIGN_NAME}.read.log
set DCRM_AUTOREAD_RTL_SCRIPT                            ${DESIGN_NAME}.autoread_rtl.tcl
set DCRM_ELABORATED_DESIGN_DDC_OUTPUT_FILE              ${DESIGN_NAME}.elab.ddc
set DCRM_CONSTRAINTS_DDC_OUTPUT_FILE                    ${DESIGN_NAME}.constraints.ddc
set DCRM_COMPILE_ULTRA_DDC_OUTPUT_FILE                  ${DESIGN_NAME}.compile_ultra.ddc
set DCRM_OPTIMIZED_DDC_OUTPUT_FILE                      ${DESIGN_NAME}.optimized.ddc
set DCRM_FINAL_DDC_OUTPUT_FILE                          ${DESIGN_NAME}.mapped.ddc
set DCRM_FINAL_PG_VERILOG_OUTPUT_FILE                   ${DESIGN_NAME}.mapped.pg.v
set DCRM_FINAL_VERILOG_OUTPUT_FILE                      ${DESIGN_NAME}.mapped.v
set DCRM_FINAL_SDC_OUTPUT_FILE                          ${DESIGN_NAME}.mapped.sdc
set DCRM_FINAL_DESIGN_ICC2                              ICC2_files




set DCRM_DCT_DEF_INPUT_FILE                             ${DESIGN_NAME}.def
if {![file exists "${run_path}/inputs/${DESIGN_NAME}.def"] && [file exists "${run_path}/inputs/${DESIGN_NAME}.def.gz"]} {
set DCRM_DCT_DEF_INPUT_FILE			                    ${DESIGN_NAME}.def.gz
}

set DCRM_DCT_FLOORPLAN_INPUT_FILE                       ${DESIGN_NAME}.fp
set DCRM_DCT_PHYSICAL_CONSTRAINTS_INPUT_FILE            ${DESIGN_NAME}.physical_constraints.tcl



set DCRM_DCT_PHYSICAL_CONSTRAINTS_REPORT                ${DESIGN_NAME}.physical_constraints.rpt

set DCRM_DCT_FINAL_CONGESTION_REPORT                    ${DESIGN_NAME}.mapped.congestion.rpt
set DCRM_DCT_FINAL_CONGESTION_MAP_OUTPUT_FILE           ${DESIGN_NAME}.mapped.congestion_map.png
set DCRM_DCT_FINAL_CONGESTION_MAP_WINDOW_OUTPUT_FILE    ${DESIGN_NAME}.mapped.congestion_map_window.png
set DCRM_ANALYZE_RTL_CONGESTION_REPORT_FILE             ${DESIGN_NAME}.analyze_rtl_congetion.rpt

set DCRM_DCT_FINAL_QOR_SNAPSHOT_FOLDER                  ${DESIGN_NAME}.qor_snapshot
set DCRM_DCT_FINAL_QOR_SNAPSHOT_REPORT                  ${DESIGN_NAME}.qor_snapshot.rpt


set DCRM_DCT_FLOORPLAN_OUTPUT_FILE                      ${DESIGN_NAME}.initial.fp

set DCRM_DCT_FINAL_FLOORPLAN_OUTPUT_FILE                ${DESIGN_NAME}.mapped.fp
set DCRM_DCT_FINAL_SPEF_OUTPUT_FILE                     ${DESIGN_NAME}.mapped.spef
set DCRM_DCT_FINAL_SDF_OUTPUT_FILE                      ${DESIGN_NAME}.mapped.sdf


# set DCRM_DCT_SPG_PLACEMENT_OUTPUT_FILE                  ${DESIGN_NAME}.mapped.std_cell.def



set DCRM_DFT_SIGNAL_SETUP_INPUT_FILE                    ${DESIGN_NAME}.dft_signal_defs.tcl
set DCRM_DFT_AUTOFIX_CONFIG_INPUT_FILE                  ${DESIGN_NAME}.dft_autofix_config.tcl


set DCRM_DFT_DRC_CONFIGURED_VERBOSE_REPORT              ${DESIGN_NAME}.dft_drc_configured.rpt
set DCRM_DFT_SCAN_CONFIGURATION_REPORT                  ${DESIGN_NAME}.scan_config.rpt
set DCRM_DFT_COMPRESSION_CONFIGURATION_REPORT           ${DESIGN_NAME}.compression_config.rpt
set DCRM_DFT_PREVIEW_CONFIGURATION_REPORT               ${DESIGN_NAME}.report_dft_insertion_config.preview_dft.rpt
set DCRM_DFT_PREVIEW_DFT_SUMMARY_REPORT                 ${DESIGN_NAME}.preview_dft_summary.rpt
set DCRM_DFT_PREVIEW_DFT_ALL_REPORT                     ${DESIGN_NAME}.preview_dft.rpt

set DCRM_DFT_FINAL_SCAN_PATH_REPORT                     ${DESIGN_NAME}.mapped.scanpath.rpt
set DCRM_DFT_DRC_FINAL_REPORT                           ${DESIGN_NAME}.mapped.dft_drc_inserted.rpt
set DCRM_DFT_FINAL_SCAN_COMPR_SCAN_PATH_REPORT          ${DESIGN_NAME}.mapped.scanpath.scan_compression.rpt
set DCRM_DFT_DRC_FINAL_SCAN_COMPR_REPORT                ${DESIGN_NAME}.mapped.dft_drc_inserted.scan_compression.rpt
set DCRM_DFT_FINAL_CHECK_SCAN_DEF_REPORT                ${DESIGN_NAME}.mapped.check_scan_def.rpt
set DCRM_DFT_FINAL_DFT_SIGNALS_REPORT                   ${DESIGN_NAME}.mapped.dft_signals.rpt


set DCRM_DFT_FINAL_SCANDEF_OUTPUT_FILE                  ${DESIGN_NAME}.mapped.scandef
set DCRM_DFT_FINAL_EXPANDED_SCANDEF_OUTPUT_FILE         ${DESIGN_NAME}.mapped.expanded.scandef
set DCRM_DFT_FINAL_CTL_OUTPUT_FILE                      ${DESIGN_NAME}.mapped.ctl
set DCRM_DFT_FINAL_PROTOCOL_OUTPUT_FILE                 ${DESIGN_NAME}.mapped.scan.spf
set DCRM_DFT_FINAL_SCAN_COMPR_PROTOCOL_OUTPUT_FILE      ${DESIGN_NAME}.mapped.scancompress.spf



set DCRM_SVF_OUTPUT_FILE                                ${DESIGN_NAME}.mapped.svf
set DCRM_VSDC_OUTPUT_FILE                               ${DESIGN_NAME}.mapped.vsdc

set FMRM_UNMATCHED_POINTS_REPORT                        ${DESIGN_NAME}.fmv_unmatched_points.rpt

set FMRM_FAILING_SESSION_NAME                           ${DESIGN_NAME}
set FMRM_FAILING_POINTS_REPORT                          ${DESIGN_NAME}.fmv_failing_points.rpt
set FMRM_ABORTED_POINTS_REPORT                          ${DESIGN_NAME}.fmv_aborted_points.rpt
set FMRM_ANALYZE_POINTS_REPORT                          ${DESIGN_NAME}.fmv_analyze_points.rpt

puts "RM-Info: Completed script [info script]\n"

