if {[file exists ${run_path}/inputs/${DESIGN_NAME}.mcmm.setup.tcl]} {
    rm_source -file ${run_path}/inputs/${DESIGN_NAME}.mcmm.setup.tcl
} else {
set mode1 				"func"
set mode_constraints($mode1)            ""

if {![info exists PDK_PVT_CORNER] || $PDK_PVT_CORNER eq ""} {
    error "Selected PDK must define PDK_PVT_CORNER"
}
set corner1 $PDK_PVT_CORNER
set corner_constraints($corner1)        ""

set scenario1 				"${mode1}::${corner1}"
set scenario_constraints($scenario1)    "${run_path}/inputs/${DESIGN_NAME}.sdc"

}    

remove_modes -all; remove_corners -all; remove_scenarios -all

foreach m [array name mode_constraints] {
	puts "RM-info: create_mode $m"
	create_mode $m
}

foreach c [array name corner_constraints] {
	puts "RM-info: create_corner $c"
	create_corner $c
}

foreach s [array name scenario_constraints] {
	set m [lindex [split $s :] 0]
	set c [lindex [split $s :] end]
	create_scenario -name $s -mode $m -corner $c
}

if {0} {
	foreach m [array name mode_constraints] {
		current_mode $m
	
		current_scenario [index_collection [get_scenarios -mode $m] 0] 
	
		puts "RM-info: current_mode $m"
		rm_source -file $mode_constraints($m)
	}
}
if {0} {
	foreach c [array name corner_constraints] {
		current_corner $c
	
		current_scenario [index_collection [get_scenarios -corner $c] 0] 
	
		puts "RM-info: current_corner $c"
		rm_source -file $corner_constraints($c)
	
	}
}
if {1} {
	foreach s [array name scenario_constraints] {
		current_scenario $s
		puts "RM-info: current_scenario $s"
		rm_source -file $scenario_constraints($s)
	}
}

foreach c [array name corner_constraints] {
	current_corner $c
	set_extraction_options -corners [current_corner] \
                       -virtual_shield_extraction false \
                       -real_metalfill_extraction floating \
                       -reference_direction horizontal \
                       -late_ccap_threshold 1e-15 \
                       -late_ccap_ratio 0.02
}

set_operating_conditions -analysis_type on_chip_variation


set all_scenarios [get_scenarios *]
foreach_in_collection sce $all_scenarios {
	set sce_name [get_object_name $sce]
	if {[regexp "slow" $sce_name]} {
		set_scenario_status $sce_name -none -setup true -hold false -leakage_power true -dynamic_power true -max_transition true -max_capacitance true -min_capacitance false -active true
	} elseif {[regexp "fast" $sce_name]} {
		set_scenario_status $sce_name -none -setup false -hold true -leakage_power false -dynamic_power false -max_transition true -max_capacitance false -min_capacitance true -active true
	} elseif {[regexp "typical" $sce_name]} {
		set_scenario_status $sce_name -none -setup true -hold true -leakage_power true -dynamic_power true -max_transition true -max_capacitance true -min_capacitance true -active true
	}
}



