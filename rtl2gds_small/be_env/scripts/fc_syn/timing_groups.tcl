#remove_path_groups -all

set all_macros [get_cells * -filter "is_hard_macro == true" -hierarchical -physical_context -quiet]
set all_reg [filter_collection [ all_registers] "is_integrated_clock_gating_cell== false"]
group_path -name in2out -from [all_inputs ] -to [all_outputs ] -priority 0 -weight 0.1
if {$all_reg != ""} {
	group_path -name in2reg  -from [all_inputs ] -to $all_reg  -priority 0 -weight 0.3
	group_path -name reg2out -from $all_reg  -to [all_outputs ] -priority 0 -weight 0.3
	group_path -name reg2reg -from $all_reg  -to $all_reg  -priority 10 -weight 1.5
	if {$all_macros != ""} {
		group_path -name reg2mem -from $all_reg  -to $all_macros -priority 10 -weight 1.5
		group_path -name mem2reg -from $all_macros -to $all_reg  -priority 10 -weight 1.5
		group_path -name mem2mem -from $all_macros -to $all_macros -priority 10 -weight 1.5

	}
}
if {$all_macros != ""} {
	group_path -name in2mem -from [all_inputs ] -to $all_macros -priority 0 -weight 0.1
	group_path -name mem2out -from $all_macros -to [all_outputs ] -priority 0 -weight 0.1
}
