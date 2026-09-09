puts "Start run_prepare_inputs [date]"

set PREPARE_INPUTS 1
source -e -v $env(ROOT_PATH)/scripts/utilities/project_context.tcl

set user_setting_file ${run_path}/inputs/${DESIGN_NAME}.user_setting.tcl

proc prepare_filelist {filename} {
    global TO_SOC run_path
    set dst ${run_path}/inputs/${filename}
    set flist [exec find $TO_SOC -name $filename]
    set flist [lsearch -all -inline -not -exact $flist $dst]
    if {$flist != ""} {
        if {[llength $flist] == 1} {
            file delete -force $dst
            file link -symbolic $dst [lindex $flist 0]
            puts "Linked design filelist $dst -> [lindex $flist 0]"
        } else {
            puts "Warning:There are multi filelist,$flist"
        }
    } elseif {![file exists $dst]} {
        puts "Warning: RTL filelist $filename does not exist!"
    }
}

prepare_filelist "${DESIGN_NAME}.f"


if {![file exists ${run_path}/inputs/${DESIGN_NAME}.sdc]} {
     set fsdc [exec find $TO_SOC -name "${DESIGN_NAME}.sdc"]
     set fsdc [lsearch -all -inline -not -exact $fsdc \
         ${run_path}/inputs/${DESIGN_NAME}.sdc]
     if {$fsdc != ""} {
         if {[llength $fsdc] == 1} {
             exec ln -sf $fsdc ${run_path}/inputs/
         } else {
             puts "Warning:There are multi sdc file,$fsdc"
         }
     } else {
         puts "Warning: ${DESIGN_NAME}.sdc does not exist!"
     }

}

if {[info exists PDK_INPUT_LINKS]} {
    file delete -force ${run_path}/ref ${run_path}/tech
    file mkdir ${run_path}/ref ${run_path}/tech
    set resolved_pdk_db_files  {}
    set resolved_pdk_lib_files {}
    set resolved_pdk_ndm_files {}
    foreach {dst src} $PDK_INPUT_LINKS {
        if {![file exists $src]} {
            puts "Error: required PDK view does not exist: $src"
            set EXIT_STATUS 1
            continue
        }
        file delete -force $dst
        file link -symbolic $dst $src
        puts "Linked $dst -> $src"
        switch -- [file extension $dst] {
            ".db"  { lappend resolved_pdk_db_files  $dst }
            ".lib" { lappend resolved_pdk_lib_files $dst }
            ".ndm" { lappend resolved_pdk_ndm_files $dst }
        }
    }
    if {[info exists PDK_OPTIONAL_INPUT_LINKS]} {
        foreach {dst src} $PDK_OPTIONAL_INPUT_LINKS {
            if {![file exists $src]} {
                file delete -force $dst
                puts "Warning: optional PDK view does not exist yet: $src"
                continue
            }
            file delete -force $dst
            file link -symbolic $dst $src
            puts "Linked optional $dst -> $src"
        }
    }

    if {[file exists $user_setting_file]} {
        set fh [open $user_setting_file r]
        set user_setting_text [read $fh]
        close $fh

        set kept_lines {}
        set skip_auto 0
        foreach line [split $user_setting_text "\n"] {
            if {[string match "# Auto-generated PDK views*" $line]} {
                set skip_auto 1
                continue
            }
            if {$skip_auto} {
                if {$line eq {puts "Resolved PDK .ndm: $PDK_REF_NDM_FILES"} ||
                    $line eq "# End auto-generated PDK views"} {
                    set skip_auto 0
                }
                continue
            }
            lappend kept_lines $line
        }

        set fh [open $user_setting_file w]
        puts -nonewline $fh [string trimright [join $kept_lines "\n"]]
        puts $fh ""
        puts $fh ""
        puts $fh "# Auto-generated PDK views (rewritten by run_prepare_inputs)"
        foreach {var_name resolved_files} [list \
            PDK_REF_DB_FILES  $resolved_pdk_db_files \
            PDK_REF_LIB_FILES $resolved_pdk_lib_files \
            PDK_REF_NDM_FILES $resolved_pdk_ndm_files] {
            puts $fh "set $var_name \[list \\"
            foreach resolved_file $resolved_files {
                puts $fh "    \${run_path}/ref/[file tail $resolved_file] \\"
            }
            puts $fh "\]"
        }
        puts $fh {puts "Resolved PDK .db : $PDK_REF_DB_FILES"}
        puts $fh {puts "Resolved PDK .lib: $PDK_REF_LIB_FILES"}
        puts $fh {puts "Resolved PDK .ndm: $PDK_REF_NDM_FILES"}
        puts $fh "# End auto-generated PDK views"
        close $fh
    }
}

exit
