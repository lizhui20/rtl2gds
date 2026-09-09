set netlist_path_syn "$RESULTS_DIR"
proc my_read_file {my_file} {
    if {![file isfile $my_file]} {
        error "Required synthesis netlist does not exist: $my_file"
    }
    puts "RM-info: Reading synthesis netlist: $my_file"
    read_file -format verilog $my_file
}
set harden_list [concat ${DESIGN_NAME}]
foreach blk $harden_list { my_read_file $netlist_path_syn/${blk}.mapped.v }
