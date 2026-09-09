if {[info exists PDK_PVT_CORNER]} {
    set_voltage $PDK_PVT_VOLTAGE -min $PDK_PVT_VOLTAGE \
        -corner $PDK_PVT_CORNER -object_list [get_supply_nets VDD*]
    set_voltage 0 -min 0 -corner $PDK_PVT_CORNER \
        -object_list [get_supply_nets VSS*]
    set_temperature $PDK_PVT_TEMPERATURE -min $PDK_PVT_TEMPERATURE \
        -corner $PDK_PVT_CORNER
    if {![info exists PDK_SKIP_FC_PARASITICS] || !$PDK_SKIP_FC_PARASITICS} {
        set pdk_parasitic_spec $PDK_FC_PARASITIC_NAME
        set_parasitic_parameters -early_spec $pdk_parasitic_spec \
            -early_temperature $PDK_PVT_TEMPERATURE \
            -late_spec $pdk_parasitic_spec \
            -late_temperature $PDK_PVT_TEMPERATURE -corners $PDK_PVT_CORNER
    }
} else {
    error "Selected PDK must define PDK_PVT_CORNER"
}
