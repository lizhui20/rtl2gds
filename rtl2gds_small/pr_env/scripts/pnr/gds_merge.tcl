puts "RM-Info: \[date\] Running gds_merge.tcl"
source $env(ROOT_PATH)/scripts/pnr/layout_context.tcl

set stream_block_label [pnr_open_existing_signoff_block]

file mkdir $RESULTS_DIR

write_oasis -units 1000 -layer_map $GDS_MAP -allow_design_mismatch \
    ${RESULTS_DIR}/${DESIGN_NAME}.pnr.oas

foreach gds $STD_GDS {
    if {![file exists $gds]} {
        error "standard-cell GDS not found ($gds); cannot produce merged GDS. Run 'gmake link'."
    }
}
write_gds -units 1000 -layer_map $GDS_MAP -allow_design_mismatch \
    -output_pin all \
    -merge_gds_top_cell $DESIGN_NAME \
    -report_cell_source ${REPORTS_DIR}/merge_gds.cell_source.rpt \
    -verbose_report_cell_source ${REPORTS_DIR}/merge_gds.cell_source.verbose.rpt \
    -merge_files $STD_GDS \
    ${RESULTS_DIR}/${DESIGN_NAME}.pnr.mapped.gds

puts "RM-Info: pre-merge OASIS : ${RESULTS_DIR}/${DESIGN_NAME}.pnr.oas"
puts "RM-Info: merged GDS      : ${RESULTS_DIR}/${DESIGN_NAME}.pnr.mapped.gds"
puts "RM-Info: stream source   : ${DESIGN_NAME}/${stream_block_label}"
puts "RM-Info: \[date\] Completed gds_merge.tcl"
if {[info exists env(FC_AUTO_EXIT)]} { exit }
