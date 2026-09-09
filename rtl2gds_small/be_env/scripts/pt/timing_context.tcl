set_program_options -disable_high_capacity
set_app_var case_analysis_sequential_propagation never
set_app_var delay_calc_waveform_analysis_mode "full_design"
set_app_var delay_calc_enhanced_ccsn_waveform_analysis "true"
set_app_var sh_message_limit 100
set_message_info -id CMD-005 -limit 100
set_app_var si_enable_analysis "true"
set_app_var timing_clock_reconvergence_pessimism "normal"
set_app_var timing_remove_clock_reconvergence_pessimism true
set search_path [concat $search_path ${run_path}/ref]
set link_library [concat "*" $PDK_TIMING_DBS]
set current_scenario_name "func_${PDK_TIMING_CORNER}"
