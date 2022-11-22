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

    variable residue_rmsf_out [open ${out_path}rms/${out_name}_residue_rmsf.csv w]
    puts $residue_rmsf_out "residue;rmsf"
}


proc nome_legal::create_rms_selections {} {
    variable mol
    variable chain_list
    variable residue_list

    puts "Creating rms selections"

    variable rmsf_total_frames 0

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

    variable avg_points_dict
    variable resid_reference_dict
    foreach residue $residue_list {
        set resid_sel "chain [lindex [split $residue :] 0] and resid [lindex [split $residue :] 1]"
        dict set resid_reference_dict $residue [uplevel "#0" [list \
            atomselect $mol "backbone and ${resid_sel}" frame $reference_frame]]

        set resid_points [[atomselect $mol "backbone and ${resid_sel}" frame $reference_frame] get {x y z}]
        set resid_zero_points {}
        for { set point_idx 0 } { $point_idx < [llength $resid_points] } { incr point_idx } {
            set zero_point {0 0 0}
            lappend resid_zero_points $zero_point
        }

        dict set avg_points_dict $residue $resid_zero_points
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
    nome_legal::sum_points_to_avg
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


proc nome_legal::sum_points_to_avg {} {
    variable residue_list
    variable resid_sel_dict

    variable rmsf_total_frames
    variable avg_points_dict

    incr rmsf_total_frames

    foreach residue $residue_list {
        set resid_sum_points {}
        set resid_points [[dict get $resid_sel_dict $residue] get {x y z}]

        for { set point_idx 0 } { $point_idx < [llength $resid_points] } { incr point_idx } {
            lappend resid_sum_points [subst \
                [vecadd [lindex [dict get $avg_points_dict $residue] $point_idx] [lindex $resid_points $point_idx] ] ]
        }
        dict set avg_points_dict $residue $resid_sum_points
    }
}


proc nome_legal::prepare_rmsf {} {
    variable md_path
    variable md_type
    variable mol
    variable residue_list

    variable resid_sel_dict
    variable avg_points_dict
    variable rmsf_total_frames

    variable resid_com_ref_dict
    variable resid_rmsf_sum_dict

    foreach residue $residue_list {
        set resid_avg_points_dict {}

        for { set point_idx 0 } { $point_idx < [llength [dict get $avg_points_dict $residue]] } { incr point_idx } {
            set avg_point [vecscale [lindex [dict get $avg_points_dict $residue] $point_idx] [expr 1.0 / $rmsf_total_frames]]

            lappend resid_avg_points_dict [subst $avg_point]
            set atom_index [lindex [[dict get $resid_sel_dict $residue] get index] $point_idx]
            [atomselect $mol "index ${atom_index}" frame last] moveto $avg_point
        }
        dict set avg_points_dict $residue $resid_avg_points_dict

        set resid_sel "chain [lindex [split $residue :] 0] and resid [lindex [split $residue :] 1]"
        dict set resid_com_ref_dict $residue [measure center [atomselect $mol "backbone and ${resid_sel}" frame last] weight mass]

        dict set resid_rmsf_sum_dict $residue 0
    }

    animate delete beg 0 end -1 skip 0 $mol
    mol addfile $md_path type $md_type first 0 last 0 waitfor all molid $mol
}


proc nome_legal::measure_residue_rmsf {frame} {
    variable first_frame
    variable residue_list

    variable all_atoms
    variable backbone_sel
    variable backbone_reference
    variable resid_sel_dict
    variable resid_com_ref_dict
    variable resid_rmsf_sum_dict

    if {$frame == $first_frame} {
        variable mol

        set reference_frame [expr [molinfo $mol get numframes] -1]
        nome_legal::create_reference_selections $reference_frame
        animate dup $mol
    }

    $all_atoms frame last
    $all_atoms move [measure fit $backbone_sel $backbone_reference]

    foreach residue $residue_list {
        set resid_center [measure center [dict get $resid_sel_dict $residue] weight mass]
        set centers_dist [veclength2 [vecsub [dict get $resid_com_ref_dict $residue] $resid_center]]

        dict set resid_rmsf_sum_dict $residue [expr [dict get $resid_rmsf_sum_dict $residue] +  $centers_dist]
    }
}


proc nome_legal::finish_and_close_rms_files {} {
    nome_legal::calculate_final_rmsf

    close $nome_legal::all_rmsd_out
    close $nome_legal::residue_rmsd_out
    close $nome_legal::residue_rmsf_out
}


proc nome_legal::calculate_final_rmsf {} {
    variable residue_list

    variable residue_rmsf_out
    variable rmsf_total_frames
    variable resid_rmsf_sum_dict

    puts "Finalizing RMSF"

    foreach residue $residue_list {
        set resid_rmsf [expr {sqrt([dict get $resid_rmsf_sum_dict $residue] / $rmsf_total_frames )}]
        puts $residue_rmsf_out "${residue};[format "%.4f" $resid_rmsf]"
    }
}
