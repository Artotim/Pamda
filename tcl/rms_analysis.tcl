# RMS Analysis


proc nome_legal::prepare_rms {} {
    nome_legal::create_rms_out_files
    nome_legal::create_rms_selections
}


proc nome_legal::create_rms_out_files {} {
    puts "Creating rms out files"

    variable out_path
    variable out_name

    variable mol
    variable chain_list
    variable residue_list

    variable all_rmsd_out [open ${out_path}rms/${out_name}_all_rmsd.csv w]
    puts -nonewline $all_rmsd_out "frame;all"
    foreach chain $chain_list {
        puts -nonewline $all_rmsd_out ";chain_${chain}_fit;chain_${chain}_no_fit"
    }
    puts $all_rmsd_out ""

    variable residue_rmsd_out [open ${out_path}rms/${out_name}_residue_rmsd.csv w]
    puts -nonewline $residue_rmsd_out "frame"
    foreach residue $residue_list {
        puts -nonewline $residue_rmsd_out ";${residue}"
    }
    puts $residue_rmsd_out ""
}


proc nome_legal::create_rms_selections {} {
    variable mol
    variable chain_list
    variable residue_list

    puts "Creating rms selections"

    variable all_atoms [uplevel "#0" [list atomselect $mol all]]
    variable backbone_sel [uplevel "#0" [list atomselect $mol "backbone"]]

    variable chain_sel_dict
    foreach chain $chain_list {
        dict set chain_sel_dict $chain [uplevel "#0" [list \
            atomselect $mol "backbone and chain $chain"]]
    }

    variable resid_sel_dict
    foreach residue $residue_list {
        set resid_sel "chain [lindex [split $residue :] 0] and resid [lindex [split $residue :] 1]"
        dict set resid_sel_dict $residue [uplevel "#0" [list \
            atomselect $mol "backbone and ${resid_sel}"]]
    }
}


proc nome_legal::create_reference_selections {reference_frame} {
    variable mol
    variable chain_list
    variable residue_list

    puts "Creating rms reference selections"

    variable backbone_reference [uplevel "#0" [list atomselect $mol "backbone" frame $reference_frame]]

    variable chain_reference_dict
    foreach chain $chain_list {
        dict set chain_reference_dict $chain [uplevel "#0" [list \
            atomselect $mol "backbone and chain $chain" frame $reference_frame]]
    }

    variable resid_reference_dict
    foreach residue $residue_list {
        set resid_sel "chain [lindex [split $residue :] 0] and resid [lindex [split $residue :] 1]"
        dict set resid_reference_dict $residue [uplevel "#0" [list \
            atomselect $mol "backbone and ${resid_sel}" frame $reference_frame]]
    }
}


proc nome_legal::measure_rms {frame} {
    variable first_frame

    variable all_atoms
    variable backbone_sel
    variable backbone_reference

    if {$frame == $first_frame} {
        variable mol

        set reference_frame [expr [molinfo $mol get numframes] -1]
        nome_legal::create_reference_selections $reference_frame
        animate dup $mol
    }

    $all_atoms frame last
    $all_atoms move [measure fit $backbone_sel $backbone_reference]

    nome_legal::measure_all_rmsd $frame
    nome_legal::measure_residue_rmsd $frame
}


proc nome_legal::measure_all_rmsd {frame} {
    puts "Measuring rms"

    variable chain_list
    variable all_rmsd_out

    variable all_atoms
    variable backbone_sel
    variable backbone_reference
    variable chain_sel_dict
    variable chain_reference_dict

    set all_rmsd  [measure rmsd $backbone_sel $backbone_reference]
    puts -nonewline $all_rmsd_out "${frame};[format "%.4f" $all_rmsd]"

    foreach chain $chain_list {
        set chain_no_fit_rmsd [measure rmsd [dict get $chain_sel_dict $chain] [dict get $chain_reference_dict $chain]]

        $all_atoms move [measure fit [dict get $chain_sel_dict $chain] [dict get $chain_reference_dict $chain]]
        set chain_fit_rmsd [measure rmsd [dict get $chain_sel_dict $chain] [dict get $chain_reference_dict $chain]]

        $all_atoms move [measure fit $backbone_sel $backbone_reference]
        puts -nonewline $all_rmsd_out ";[format "%.4f" $chain_fit_rmsd];[format "%.4f" $chain_no_fit_rmsd]"
    }

    puts $all_rmsd_out ""
}


proc nome_legal::measure_residue_rmsd {frame} {
    variable residue_list
    variable residue_rmsd_out
    variable resid_sel_dict
    variable resid_reference_dict

    puts -nonewline $residue_rmsd_out "$frame"

    foreach residue $residue_list {
        set resid_rmsd [measure rmsd [dict get $resid_sel_dict $residue] [dict get $resid_reference_dict $residue]]
        puts -nonewline $residue_rmsd_out ";[format "%.4f" $resid_rmsd]"
    }

    puts $residue_rmsd_out ""
}


proc nome_legal::close_rms_files {} {
    close $nome_legal::residue_rmsd_out
    close $nome_legal::all_rmsd_out
}
