if {![info exists PDK_SKIP_FC_PARASITICS] || !$PDK_SKIP_FC_PARASITICS} {
    if {![file isfile $PDK_FC_PARASITIC_FILE] || ![file readable $PDK_FC_PARASITIC_FILE]} {
        error "Missing FC parasitic file: $PDK_FC_PARASITIC_FILE; run run_prepare_inputs first"
    }
    puts "RM-info: Loading $PDK_FC_PARASITIC_NAME parasitics from $PDK_FC_PARASITIC_FILE"
    read_parasitic_tech -tlup $PDK_FC_PARASITIC_FILE -name $PDK_FC_PARASITIC_NAME
} else {
    puts "RM-warning: Selected PDK disables FC parasitic technology loading."
}
