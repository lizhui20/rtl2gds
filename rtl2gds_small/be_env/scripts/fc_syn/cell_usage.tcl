set TIE_LIB_CELL_PATTERN_LIST 		""
set HOLD_FIX_LIB_CELL_PATTERN_LIST 	""
set OPTIMIZATION_LIB_CELL_PATTERN_LIST ""
set CTS_LIB_CELL_PATTERN_LIST ""
set CTS_ONLY_LIB_CELL_PATTERN_LIST 	"$CTS_LIB_CELL_PATTERN_LIST"

if {$TIE_LIB_CELL_PATTERN_LIST != ""} {
	set_dont_touch [get_lib_cells $TIE_LIB_CELL_PATTERN_LIST] false
	set_attribute  [get_lib_cells $TIE_LIB_CELL_PATTERN_LIST] dont_use false
	set_lib_cell_purpose -include optimization [get_lib_cells $TIE_LIB_CELL_PATTERN_LIST]
	set tieCell [get_lib_cells $TIE_LIB_CELL_PATTERN_LIST]
	foreach_in_collection item $tieCell {
		remove_attribute $item dont_use
		remove_attribute $item dont_touch
	}   
}

if {0} {
if {$HOLD_FIX_LIB_CELL_PATTERN_LIST != ""} {
	set_dont_touch [get_lib_cells $HOLD_FIX_LIB_CELL_PATTERN_LIST] false
	set_lib_cell_purpose -exclude hold [get_lib_cells */*]
	set_lib_cell_purpose -include hold [get_lib_cells $HOLD_FIX_LIB_CELL_PATTERN_LIST]
}
}
if {$OPTIMIZATION_LIB_CELL_PATTERN_LIST != ""} {
#	set_lib_cell_purpose -include {optimization power} [get_lib_cells */*]
	set_lib_cell_purpose -exclude {optimization power} [get_lib_cells {*/DCCK* */DEL* */CK* */G* */*D24* */*D32*}] 
}
#	set_lib_cell_purpose -include cts [get_lib_cells */SDFF* -filter "valid_purposes=~*optimization*"]		 
if {$CTS_LIB_CELL_PATTERN_LIST != "" || $CTS_ONLY_LIB_CELL_PATTERN_LIST != ""} {
	set_lib_cell_purpose -exclude cts [get_lib_cells */*]
}

if {$CTS_LIB_CELL_PATTERN_LIST != ""} {
	set_dont_touch [get_lib_cells $CTS_LIB_CELL_PATTERN_LIST] false
	set_lib_cell_purpose -include cts [get_lib_cells $CTS_LIB_CELL_PATTERN_LIST]
} 

if {$CTS_ONLY_LIB_CELL_PATTERN_LIST != ""} {
	set_dont_touch [get_lib_cells $CTS_ONLY_LIB_CELL_PATTERN_LIST] false
	set_lib_cell_purpose -include none [get_lib_cells $CTS_ONLY_LIB_CELL_PATTERN_LIST]
	set_lib_cell_purpose -include cts [get_lib_cells $CTS_ONLY_LIB_CELL_PATTERN_LIST]
}

##set_lib_cell_purpose -exclude cts [get_lib_cells */*]

set _no_scan_ff [get_lib_cells -quiet "*/SDF*BWP7T40P140*"]
if {[sizeof_collection $_no_scan_ff] > 0} {
    set_attribute $_no_scan_ff dont_use true
}
