proc my_parsing_flist {f_name} {
    global TO_SOC
    set f [open $f_name r]
    set f_content [read $f]
    set f_lines [split $f_content "\n"]
    close $f
    set DEFINE_LIST  [list ]                
    set ADDITIONAL_SEARCH_PATH [list ] 
    set RTL_SOURCE_SVFILES [list ]    
    foreach l $f_lines {
        if {$l eq ""} {continue}
        if {[regexp "^\/\/" $l]} {continue}
        if {[regexp "^\\s+\/\/" $l]} {continue}
        if {[regexp "^\\*" $l]} {continue}
        if {[regexp "^\/\\*" $l]} {continue}
        if {[regexp {^\+define\+} $l]} {
            set w [split $l "+"]
            lappend DEFINE_LIST [subst [lindex $w 2]]
            continue
        }
        if {[regexp {^\+definedc\+} $l]} {
            set w [split $l "+"]
            lappend DEFINE_LIST [subst [lindex $w 2]]
            continue
        }
        if {[regexp {^\+incdir\+} $l]} { 
            set w [split $l "+"]
            #lappend ADDITIONAL_SEARCH_PATH [subst [lindex $w 2]]
            set  ADDITIONAL_SEARCH_PATH [concat $ADDITIONAL_SEARCH_PATH [subst [lindex $w 2]]]
            continue
        }
       
        regsub -all -- {[[:space:]]+} $l " " l  
        set w [split $l " "]
        if {[lindex $w 0] eq "-f" || [lindex $w 0] eq "-F"} {
            my_parsing_flist [subst [lindex $w 1]]
        } elseif {[lindex $w 0] eq "-y" || [lindex $w 0] eq "-Y"} {
            #lappend ADDITIONAL_SEARCH_PATH [subst [lindex $w 1]]
            set  ADDITIONAL_SEARCH_PATH [concat $ADDITIONAL_SEARCH_PATH [subst [lindex $w 1]]]
            continue
        } else {
            if {[lindex $w 0] eq ""} { 
               lappend RTL_SOURCE_SVFILES [subst [lindex $w 1]]
            } else {
               if {[lindex $w 0] eq "-v" || [lindex $w 0] eq "-V" } {
                   lappend RTL_SOURCE_SVFILES [subst [lindex $w 1]]
               } else {
                   lappend RTL_SOURCE_SVFILES [subst [lindex $w 0]]
               }
            }
        }
    }
    return [list $DEFINE_LIST $ADDITIONAL_SEARCH_PATH $RTL_SOURCE_SVFILES]
}
if {[file exists ${run_path}/inputs/${DESIGN_NAME}.f]} {
    set parsing_reslut          [my_parsing_flist ${run_path}/inputs/${DESIGN_NAME}.f] 
    set DEFINE_LIST             [lindex $parsing_reslut 0]    
    set ADDITIONAL_SEARCH_PATH  [lindex $parsing_reslut 1]
    set RTL_SOURCE_SVFILES      [lindex $parsing_reslut 2]
} else {
    puts "RM-error:Can not find ${run_path}/inputs/${DESIGN_NAME}.f"
}

if {![info exists NDM_LIST]} {
    set NDM_LIST {}
}
if {![info exists ADDITIONAL_LINK_LIB_FILES]} {
    set ADDITIONAL_LINK_LIB_FILES {}
}
