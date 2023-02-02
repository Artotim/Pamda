# SASA Analysis


proc pamda::prepare_sasa {} {
    pamda::create_sasa_selections
    pamda::create_sasa_out_files
}


proc pamda::create_sasa_selections {} {
    variable mol
    variable chain_list
    variable hgl_residues

    variable sasa_all_sel [uplevel "#0" [list atomselect $mol "not solvent"]]

    variable sasa_chain_sel_dict
    foreach chain $chain_list {
        dict set sasa_chain_sel_dict $chain [uplevel "#0" [list \
            atomselect $mol "not solvent and chain $chain"]]
    }

    variable sasa_hgl_sel_dict
    foreach resid $hgl_residues {
        set resid_sel "[lindex [split $resid :] 0] and chain [lindex [split $resid :] 1]"
        dict set sasa_hgl_sel_dict $resid [uplevel "#0" [list \
            atomselect $mol "not solvent and resid $resid_sel"]]
    }
}


proc pamda::create_sasa_out_files {} {
    puts "Creating sasa out files"

    variable out_path
    variable out_name
    variable hgl_residues

    variable chain_list

    variable sasa_all_out [open "${out_path}sasa/${out_name}_all_sasa.csv" w]
    puts -nonewline $sasa_all_out "frame;SASA_all;BSA_all"

    foreach chain $chain_list {
        puts -nonewline $sasa_all_out ";SASA_chain_${chain};BSA_chain_${chain}"
    }
    puts $sasa_all_out ""

    if {[llength $hgl_residues] > 0} {
        variable sasa_hgl_out [open "${out_path}sasa/${out_name}_hgl_sasa.csv" w]
        puts -nonewline $sasa_hgl_out "frame"

        foreach residue $hgl_residues {
            puts -nonewline $sasa_hgl_out ";SASA_resid_${residue};BSA_resid_${residue}"
        }
        puts $sasa_hgl_out ""
    }
}


proc pamda::measure_sasa {frame} {
    puts "Measuring sasa"

    variable hgl_residues
    variable mol
    variable chain_list

    variable sasa_all_sel
    variable sasa_chain_sel_dict
    variable sasa_hgl_sel_dict

    variable sasa_all_out
    variable sasa_hgl_out

    $sasa_all_sel frame last

    set all_sasa_bsa [pamda::calculate_sasa_bsa $sasa_all_sel]
    puts -nonewline $sasa_all_out "${frame};[lindex $all_sasa_bsa 0];[lindex $all_sasa_bsa 1]"

    foreach chain $chain_list {
        set chain_sasa_bsa [pamda::calculate_sasa_bsa [dict get $sasa_chain_sel_dict $chain]]
        puts -nonewline $sasa_all_out ";[lindex $chain_sasa_bsa 0];[lindex $chain_sasa_bsa 1]"
    }
    puts $sasa_all_out ""

    if {[llength $hgl_residues] > 0} {
        puts -nonewline $sasa_hgl_out "${frame}"

        foreach resid $hgl_residues {
            set resid_sasa_bsa [pamda::calculate_sasa_bsa [dict get $sasa_hgl_sel_dict $resid]]
            puts -nonewline $sasa_hgl_out ";[lindex $resid_sasa_bsa 0];[lindex $resid_sasa_bsa 1]"
        }
        puts $sasa_hgl_out ""
    }
}


proc pamda::calculate_sasa_bsa {current_sel} {
    variable sasa_radius

    variable sasa_all_sel

    set n_samples 50

    $current_sel frame last

    set sasa_alone [measure sasa $sasa_radius $current_sel -samples $n_samples]
    set sasa_complex [measure sasa $sasa_radius $sasa_all_sel -restrict $current_sel -samples $n_samples]

    set bsa [expr $sasa_alone - $sasa_complex]

    return [subst {[format "%.4f" $sasa_complex] [format "%.4f" $bsa]}]
}


proc pamda::close_sasa_files {} {
    close $pamda::sasa_all_out
    close $pamda::sasa_hgl_out
}
