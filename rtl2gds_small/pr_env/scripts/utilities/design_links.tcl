#!/usr/bin/env tclsh

proc env_or {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default
}

proc require_file {path label} {
    if {![file exists $path] || [file isdirectory $path]} {
        error "missing $label: $path"
    }
}

proc require_dir {path label} {
    if {![file isdirectory $path]} {
        error "missing $label: $path"
    }
}

proc link_path {src dst} {
    file mkdir [file dirname $dst]
    file delete -force $dst
    file link -symbolic $dst $src
}

proc copy_path {src dst} {
    file mkdir [file dirname $dst]
    file delete -force $dst
    file copy -force $src $dst
}

proc link_glob {pattern dst_dir {required 0}} {
    set files [lsort [glob -nocomplain $pattern]]
    if {$required && [llength $files] == 0} {
        error "no files matched: $pattern"
    }
    foreach f $files {
        link_path $f [file join $dst_dir [file tail $f]]
    }
    return [llength $files]
}

proc find_first_file {root leaf_name} {
    if {![file isdirectory $root]} {
        return ""
    }
    set stack [list $root]
    while {[llength $stack] > 0} {
        set dir [lindex $stack 0]
        set stack [lrange $stack 1 end]
        foreach f [lsort [glob -nocomplain -directory $dir *]] {
            if {[file isdirectory $f]} {
                lappend stack $f
            } elseif {[file tail $f] eq $leaf_name} {
                return $f
            }
        }
    }
    return ""
}

set DESIGN_NAME [env_or DESIGN_NAME spi_slave]
set ROOT_PATH   [env_or ROOT_PATH [pwd]]
set BE_ROOT     [env_or BE_ROOT [file normalize [file join $ROOT_PATH .. be_env]]]
set PDK_ROOT    [env_or PDK_ROOT [file normalize ~/PDK]]
set DESIGN_SRC_ROOT [env_or DESIGN_SRC_ROOT [file normalize [file join $ROOT_PATH .. DESIGN]]]

set run_dir    [file join $ROOT_PATH $DESIGN_NAME]
set tech_dir   [file join $run_dir tech]
set ref_dir    [file join $run_dir ref]
set inputs_dir [file join $run_dir inputs]
set pdk_dir    [file join $ROOT_PATH pdk]
set util_dir   [file join $ROOT_PATH scripts utilities]

set current_file [file join $ROOT_PATH scripts pdk process_select.tcl]
if {![file exists $current_file]} {
    error "PR PDK selector not found: $current_file"
}
source $current_file
if {![info exists PDK_PROFILE] || $PDK_PROFILE eq ""} {
    error "PDK_PROFILE is empty in $current_file"
}

file mkdir $pdk_dir
foreach d {tsmc28hpcplus} {
    set dst [file join $pdk_dir $d]
    if {[file exists $dst] && [file type $dst] ne "link"} {
        file delete -force $dst
    }
    link_path [file join $PDK_ROOT $d] $dst
}

file delete -force $tech_dir $ref_dir $inputs_dir
file mkdir $tech_dir $ref_dir $inputs_dir

set be_syn [file join $BE_ROOT $DESIGN_NAME]
foreach ext {scan.v scandef mapped.sdc} {
    link_path [file join $be_syn results ${DESIGN_NAME}.${ext}] \
              [file join $inputs_dir ${DESIGN_NAME}.${ext}]
}
set be_scan_path [file join $be_syn reports dft ${DESIGN_NAME}.scan_path.rpt]
if {[file exists $be_scan_path]} {
    link_path $be_scan_path [file join $inputs_dir ${DESIGN_NAME}.scan_path.rpt]
} else {
    puts "Warning: BE scan-path report missing: $be_scan_path"
}

set user_template [file join $util_dir layout_defaults.tcl]
set design_user [find_first_file $DESIGN_SRC_ROOT ${DESIGN_NAME}.pr_user_setting.tcl]
set linked_user [file join $inputs_dir ${DESIGN_NAME}.pr_user_setting.tcl]
if {$design_user ne ""} {
    link_path $design_user $linked_user
    puts "link: linked PR user setting $design_user"
} else {
    require_file $user_template "PR user setting template"
    copy_path $user_template $linked_user
    puts "link: generated PR user setting from $user_template"
}

set io_place [find_first_file $DESIGN_SRC_ROOT ${DESIGN_NAME}.io_placement.tcl]
if {$io_place ne ""} {
    link_path $io_place [file join $inputs_dir ${DESIGN_NAME}.io_placement.tcl]
    puts "link: linked IO placement $io_place"
}

require_file $user_template "PR user setting template"
source $user_template
if {[file exists $linked_user]} {
    source $linked_user
}
if {![info exists ENABLE_IO_LIBRARY]} {
    set ENABLE_IO_LIBRARY 0
}

switch -- $PDK_PROFILE {
    smic18 {
        set fill_ndm [file join $PDK_ROOT smic18 smic18_fill.ndm]
        require_file $fill_ndm "smic18 filler NDM"
        puts "link: smic18 (6LM) profile"
        link_path [file join $BE_ROOT pdk smic18 digital sc apollo tf smic18_6lm.tf] \
                  [file join $tech_dir smic18_6lm.tf]
        link_path [file join $BE_ROOT pdk smic18 digital sc apollo gds2OutLayer_6lm.map] \
                  [file join $tech_dir smic18_6lm.gds.map]
        link_path [file join $BE_ROOT pdk smic18 smic18_typical.tluplus] \
                  [file join $tech_dir smic18_typical.tluplus]
        link_path [file join $BE_ROOT pdk smic18 smic18_lib.ndm] \
                  [file join $ref_dir smic18_lib.ndm]
        link_path $fill_ndm [file join $ref_dir smic18_fill.ndm]
        link_path [file join $BE_ROOT pdk smic18 digital sc gds2 smic18.gds2] \
                  [file join $ref_dir smic18.gds2]
        link_path [file join $BE_ROOT pdk smic18 digital sc lvs_netlist smic18.cdl] \
                  [file join $ref_dir smic18.cdl]
        link_path [file join $BE_ROOT pdk smic18 digital sc verilog smic18.v] \
                  [file join $ref_dir smic18.v]
    }
    tsmc28hpcplus {
        set pr_pdk_tsmc [file join $pdk_dir tsmc28hpcplus]
        set pr_tsmchome [file join $pr_pdk_tsmc TSMCHOME]
        set n28_prtf [file join $pr_pdk_tsmc installed tech synopsys_pr N28_PRTF_Syn_v1d5a PR_tech Synopsys]
        set n28_rc [file join $pr_pdk_tsmc installed tech rc_1p9m_4x2y2r]
        set n28_cal [file join $pr_pdk_tsmc installed tech calibre_1p13m profile CALIBRE_FLOW]
        set n28_ipdk_9m [file join $PDK_ROOT tsmc28a ipdk_cln28hpcp_1p9m_4x2y2r]
        set n28_ipdk_frontend [file join $PDK_ROOT tsmc28a ipdk_cln28hpcp_frontend]
        set tlu_base cln28hpc+_1p09m+ut-alrdl_4x2y2r

        set n28_lvs_rc_deck [file join $n28_cal DFM_LVS_RC_CALIBRE_N28HP_1p9m_ALRDL.v1.0_3o]
        set n28_lvs_dfm_dir [file join $n28_cal DFM]
        set n28_foundry_drc_deck [file join $n28_ipdk_9m calibre drc calibre.drc]
        set n28_foundry_ant_deck [file join $n28_ipdk_9m calibre drc CLN28HP_9M.ANT_002.14a]
        set n28_foundry_mim_ant_deck [file join $n28_ipdk_9m calibre drc CLN28HP_9M.MIM_ANT_002.14a]
        set n28_dummy_od_po [file join $n28_ipdk_frontend Calibre dummy_util Dummy_OD_PO_Calibre_28nm_HP_13a_nopdf.tar.gz]
        set n28_dummy_metal_via [file join $n28_ipdk_frontend Calibre dummy_util Dummy_Metal_Via_Calibre_28nm_13a_nopdf.tar.gz]

        require_file $n28_lvs_rc_deck "N28 Calibre LVS/RC deck"
        require_dir  $n28_lvs_dfm_dir "N28 Calibre LVS DFM dir"
        require_file $n28_foundry_drc_deck "N28 Calibre DRC deck"
        require_file $n28_foundry_ant_deck "N28 Calibre antenna deck"
        require_file $n28_foundry_mim_ant_deck "N28 Calibre MIM antenna deck"
        require_file $n28_dummy_od_po "N28 Calibre dummy OD/PO utility"
        require_file $n28_dummy_metal_via "N28 Calibre dummy metal/via utility"

        puts "link: tsmc28hpcplus (9LM 4X2Y2R) profile"
        link_path [file join $n28_prtf TechFile VHV tsmcn28_9lm4X2Y2RUTRDL.tf] \
                  [file join $tech_dir tsmcn28_9lm4X2Y2RUTRDL.tf]
        link_path [file join $n28_prtf SCM antennaRule_n28_9lm.tcl] \
                  [file join $tech_dir antennaRule_n28_9lm.tcl]
        link_path [file join $n28_prtf GdsOutMap gdsout_4X2Y2R.map] \
                  [file join $tech_dir gdsout_4X2Y2R.map]
        link_path $n28_lvs_rc_deck [file join $tech_dir DFM_LVS_RC_CALIBRE_N28HP_1p9m_ALRDL.v1.0_3o]
        link_path $n28_lvs_dfm_dir [file join $tech_dir DFM]
        link_path $n28_foundry_drc_deck [file join $tech_dir calibre.drc]
        link_path $n28_foundry_ant_deck [file join $tech_dir CLN28HP_9M.ANT_002.14a]
        link_path $n28_foundry_mim_ant_deck [file join $tech_dir CLN28HP_9M.MIM_ANT_002.14a]
        link_path $n28_dummy_od_po [file join $tech_dir Dummy_OD_PO_Calibre_28nm_HP_13a_nopdf.tar.gz]
        link_path $n28_dummy_metal_via [file join $tech_dir Dummy_Metal_Via_Calibre_28nm_13a_nopdf.tar.gz]

        foreach {corner src_leaf dst_leaf} [list \
            cworst ${tlu_base}_cworst_T.nxtgrd tsmcn28_9lm_cworst.nxtgrd \
            cbest  ${tlu_base}_cbest.nxtgrd   tsmcn28_9lm_cbest.nxtgrd] {
            set src [file join $n28_rc $src_leaf]
            if {[file exists $src]} {
                link_path $src [file join $tech_dir $dst_leaf]
            } else {
                puts "Warning: missing $src; $corner StarRC grid is not linked"
            }
        }

        link_path [file join $pr_pdk_tsmc installed tech tsmc28_7t_site_via.lef] \
                  [file join $tech_dir tsmc28_7t_site_via.lef]

        foreach v {tcbn28hpcplusbwp7t40p140 tcbn28hpcplusbwp7t40p140hvt tcbn28hpcplusbwp7t40p140lvt} {
            link_path [file join $pr_pdk_tsmc ndm ${v}.ndm] [file join $ref_dir ${v}.ndm]
            link_path [file join $pr_tsmchome digital Back_End lef ${v}_110a lef ${v}.lef] \
                      [file join $ref_dir ${v}.lef]
            link_path [file join $pr_tsmchome digital Back_End gds ${v}_110a ${v}.gds] \
                      [file join $ref_dir ${v}.gds]
            link_glob [file join $pr_tsmchome digital Front_End timing_power_noise CCS ${v}_180a *.{db,lib}] $ref_dir 1
        }
        link_path [file join $pr_tsmchome digital Back_End spice tsmc28_7t_all.spi] \
                  [file join $ref_dir tsmc28_7t_all.spi]
        link_path [file join $pr_tsmchome digital Front_End verilog tsmc28_7t_all.v] \
                  [file join $ref_dir tsmc28_7t_all.v]

        set n28_io_name tphn28hpcpgv18
        set n28_io_root [file join $PDK_ROOT IO installed ${n28_io_name}_9lm]
        set n28_io_ndm [file join $n28_io_root ${n28_io_name}.ndm]
        set n28_io_gds [file join $n28_io_root TSMCHOME digital Back_End gds ${n28_io_name}_110a mt_2 9lm ${n28_io_name}.gds]
        set n28_io_spi [file join $n28_io_root TSMCHOME digital Back_End spice ${n28_io_name}_110a ${n28_io_name}.spi]
        set n28_io_vlog [file join $n28_io_root TSMCHOME digital Front_End verilog ${n28_io_name}_110a ${n28_io_name}.v]
        set n28_io_db_dir [file join $n28_io_root TSMCHOME digital Front_End timing_power_noise NLDM ${n28_io_name}_170a]
        if {$ENABLE_IO_LIBRARY} {
            require_file $n28_io_ndm "IO NDM"
            require_file $n28_io_gds "IO GDS"
            require_file $n28_io_spi "IO SPI"
            require_file $n28_io_vlog "IO Verilog"
            require_dir  $n28_io_db_dir "IO NLDM dir"
            link_path $n28_io_ndm [file join $ref_dir ${n28_io_name}.ndm]
            link_path $n28_io_gds [file join $ref_dir ${n28_io_name}.gds]
            link_path $n28_io_spi [file join $ref_dir ${n28_io_name}.spi]
            link_path $n28_io_vlog [file join $ref_dir ${n28_io_name}.v]
            link_glob [file join $n28_io_db_dir *.{db,lib}] $ref_dir 1
            puts "link: ENABLE_IO_LIBRARY=1; linked $n28_io_name IO NDM/GDS/SPI/Verilog/NLDM views"
        } else {
            puts "link: ENABLE_IO_LIBRARY=0; skipped $n28_io_name IO reference views"
        }
    }
    default {
        error "Unsupported PDK_PROFILE '$PDK_PROFILE'"
    }
}

puts "link: $PDK_PROFILE tech/ref/inputs links ready for $DESIGN_NAME"
