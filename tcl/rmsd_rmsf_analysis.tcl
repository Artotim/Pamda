# RMSD RMSF Analysis


proc retrieve_mol_info {} {
    global mol residue_list all_atoms atoms_reference atoms_selected interaction main_chain peptide main_chain_atom main_chain_reference peptide_atom peptide_reference

	puts "Retrieving molecule infos"

    set residue_list [[atomselect $mol "name CA"] get resid]
	set all_atoms [uplevel "#0" [list atomselect $mol all]]
    set atoms_reference [uplevel "#0" [list atomselect $mol "backbone" frame 1]]
    set atoms_selected [uplevel "#0" [list atomselect $mol "backbone"]]

	set main_chain_reference [uplevel "#0" [list atomselect $mol "backbone and chain $main_chain" frame 1]]
	set main_chain_atom [uplevel "#0" [list atomselect $mol "backbone and chain $main_chain"]]

	if {$interaction == true} {
		set peptide_reference [uplevel "#0" [list atomselect $mol "backbone and chain $peptide" frame 1]]
		set peptide_atom [uplevel "#0" [list atomselect $mol "backbone and chain $peptide"]]
	}

}


proc create_res_dic {} {
    global mol reference_dict compare_dict residue_list

	puts "Creating residue dicts"

    foreach residue $residue_list {
        dict set reference_dict $residue [uplevel "#0" [list \
		    atomselect $mol "backbone and resid $residue" frame 1]]
    }

    foreach residue $residue_list {
        dict set compare_dict $residue [uplevel "#0" [list \
		    atomselect $mol "backbone and resid $residue"]]
    }
}


proc create_rmsd_out_files {} {
    global residue_list residue_out rmsd_out out_path interaction main_chain peptide mol

	puts "Creating out files"

    set rmsd_out [open ${out_path}rmsd/all_rmsd.csv w]
	puts -nonewline $rmsd_out "frame;all;${main_chain}"
	if {$interaction == true} {
        puts -nonewline $rmsd_out ";$peptide"
	}
    puts $rmsd_out ""

    set residue_out [open ${out_path}rmsd/residue_rmsd.csv w]
    puts -nonewline $residue_out "frame"
    
    set chain_list [[atomselect $mol "name CA"] get chain]
    set residues_length [llength $residue_list]
    set idx 0

    while {$idx < $residues_length} {
        set resid [lindex $residue_list $idx]
        set chain [lindex $chain_list $idx]
        
        puts -nonewline $residue_out ";$chain:$resid"
        
        set idx [expr $idx +1]
    }

    puts $residue_out ""
}


proc close_rmsd_files {} {
    global residue_out rmsd_out

    close $residue_out
    close $rmsd_out
}


proc measure_rmsd_rmsf {frame} {
    global all_atoms atoms_selected atoms_reference

    $all_atoms move [measure fit $atoms_selected $atoms_reference]
	measure_rmsd $frame
	measure_residue $frame
}


proc measure_rmsd {frame} {
	global rmsd_out atoms_selected atoms_reference interaction main_chain_atom main_chain_reference peptide_atom peptide_reference

    set rmsd  [measure rmsd $atoms_selected $atoms_reference]
    puts -nonewline $rmsd_out "$frame;$rmsd"

	set main_rmsd  [measure rmsd $main_chain_atom $main_chain_reference]
	puts -nonewline $rmsd_out ";$main_rmsd"

	if {$interaction == true} {
		set peptide_rmsd  [measure rmsd $peptide_atom $peptide_reference]
		puts -nonewline $rmsd_out ";$peptide_rmsd"
	}

	puts $rmsd_out ""
}


proc measure_residue {frame} {
	global residue_list compare_dict reference_dict residue_out

    puts -nonewline $residue_out "$frame"

    foreach residue $residue_list {
        set resid_rmsd [measure rmsd [dict get $compare_dict $residue] [dict get $reference_dict $residue]]
        puts -nonewline $residue_out ";[format "%.4f" $resid_rmsd]"
    }

    puts $residue_out ""
}


proc prepare_rmsd {dcd_path} {
    global init mol wrapped

    if {$init == 0} {
        mol addfile $dcd_path type dcd first $init last $init waitfor all molid $mol
    } else {
        mol addfile $dcd_path type dcd first [expr $init - 1] last $init waitfor all molid $mol
    }

    pbc_wrap frames_now $wrapped

    retrieve_mol_info
    create_res_dic
    create_rmsd_out_files
}
