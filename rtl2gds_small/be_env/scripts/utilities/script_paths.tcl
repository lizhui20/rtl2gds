puts "RM-Info: Running script [info script]\n"

set TCL_USER_SETTING                        ${DESIGN_NAME}.user_setting.tcl
set FC_SYN_PROCS_FC                         timing_reports.tcl
set TCL_FC_SYN_SETUP                        library_create.tcl
set TCL_DC_SYN_SETUP_FILENAMES              output_names.tcl
set TCL_FC_SYN_SETTINGS                 synthesis_options.tcl
set TCL_FC_CHANGE_VIEW                      change_view.tcl
set TCL_PARASITIC_SETUP_FILE                parasitic_load.tcl
set TCL_FC_SYN_MCMM_SETUP                   timing_corners.tcl
set my_pvt_file                             operating_corner.tcl
set my_regroup_file                         timing_groups.tcl
set TCL_FC_SYN_PROCEDURE                    input_lists.tcl
set TCL_FC_SYN_MAKE_TRACK ""
if {[info exists env(TRACK_SETUP_FILE)] && $env(TRACK_SETUP_FILE) ne ""} {
    set TCL_FC_SYN_MAKE_TRACK $env(TRACK_SETUP_FILE)
}
set TCL_COMMON_DEBUG                        debug_options.tcl


set TCL_PT_VARIABLE                         timing_context.tcl
set TCL_PT_CLOCK_UNCERTAINTY                clock_margins.tcl
set TCL_PT_MAX_TRANSITION                   slew_limits.tcl






puts "RM-Info: Completed script [info script]\n"
