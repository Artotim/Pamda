proc retrieve_mol_info {init} {
    global mol residue_list all_atoms atoms_reference atoms_selected interaction main_chain peptide main_chain_atom main_chain_reference peptide_atom peptide_reference

	puts "Retrieving molecule infos"

    set residue_list [[atomselect $mol "name CA"] get resid]
	set all_atoms [uplevel "#0" [list atomselect $mol all]]
    set atoms_reference [uplevel "#0" [list atomselect $mol "name CA" frame $init]]
    set atoms_selected [uplevel "#0" [list atomselect $mol "name CA"]]

	set main_chain_reference [uplevel "#0" [list atomselect $mol "name CA and chain $main_chain" frame $init]]
	set main_chain_atom [uplevel "#0" [list atomselect $mol "name CA and chain $main_chain"]]

	if {$interaction == true} {
		set peptide_reference [uplevel "#0" [list atomselect $mol "name CA and chain $peptide" frame $init]]
		set peptide_atom [uplevel "#0" [list atomselect $mol "name CA and chain $peptide"]]
	}

}

proc create_res_dic {init} {
    global mol reference_dict compare_dict residue_list

	puts "Creating residue dicts"

    foreach residue $residue_list {
        dict set reference_dict $residue [uplevel "#0" [list \
		    atomselect $mol "name CA and resid $residue and noh" frame $init]]
    }

    foreach residue $residue_list {
        dict set compare_dict $residue [uplevel "#0" [list \
		    atomselect $mol "name CA and resid $residue and noh"]]
    }
}

proc create_rmsf_out_file {} {
    global residue_list rmsf_out rmsd_out out_path interaction main_chain peptide

	puts "Creating out files"

    set rmsd_out [open ${out_path}rmsd/all_rmsd.csv w]
	puts -nonewline $rmsd_out "frame;all;${main_chain}"
	if {$interaction == true} {
        puts -nonewline $rmsd_out ";$peptide"
	}
    puts $rmsd_out ""

    set rmsf_out [open ${out_path}rmsd/residue_rmsd.csv w]
    foreach residue $residue_list {
        puts -nonewline $rmsf_out "$residue;"
    }
    puts $rmsf_out ""
}

proc close_rmsd_files {} {
    global rmsf_out rmsd_out

    close $rmsf_out
    close $rmsd_out
}

proc rmsd_rmsf {frame} {
    global all_atoms atoms_selected atoms_reference

    $all_atoms move [measure fit $atoms_selected $atoms_reference]
	measure_rmsd $frame
	measure_rmsf
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
proc measure_rmsf {} {
	global residue_list compare_dict reference_dict rmsf_out

    foreach residue $residue_list {
        set resid_rmsd [measure rmsd [dict get $compare_dict $residue] [dict get $reference_dict $residue]]
        puts -nonewline $rmsf_out "[format "%.4f" $resid_rmsd];"
    }
    puts $rmsf_out ""
}

proc prepare_rmsd {} {
    global init

    retrieve_mol_info $init
    create_res_dic $init
    create_rmsf_out_file
}
