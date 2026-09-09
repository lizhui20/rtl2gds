set clks [get_clocks *]
set dc_unc_per  0.30
set dcg_unc_per 0.10
if {[sizeof_collection $clks] > 0} {
    foreach_in_collection clk $clks {
        set per [get_attribute $clk period]
        if {$per > 5} {
           set_clock_uncertainty 0.5 -setup -from $clk -to $clk
           set_clock_uncertainty 0.005 -hold -from $clk -to $clk
        } else {
           if {[info exists LOGIC_SYN] && $LOGIC_SYN != 0} {
               set_clock_uncertainty [expr $per * $dcg_unc_per] -setup -from $clk -to $clk
           } else {
               set_clock_uncertainty [expr $per * $dc_unc_per] -setup -from $clk -to $clk
           }
           set_clock_uncertainty 0.005 -hold -from $clk -to $clk
        }
    }
}
