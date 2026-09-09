set DESIGN_NAME "$env(DESIGN_NAME)"
set run_path    "$env(RUN_PATH)/${DESIGN_NAME}"
if {![read_lib ${run_path}/results/$DESIGN_NAME.lib]} {
    error "Failed to read timing model for $DESIGN_NAME"
}
if {![write_lib -format db $DESIGN_NAME -output ${run_path}/results/$DESIGN_NAME.db]} {
    error "Failed to write timing database for $DESIGN_NAME"
}
puts "LC_WRITE_DB_COMPLETE"
exit
