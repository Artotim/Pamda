proc frame_analysis {frame} {
    global main_chain
    puts "Analysing frame $frame ..."

    pbc wrap -center com -centersel "protein and chain $main_chain" -compound residue -all
    pbc wrap -center com -centersel "protein" -compound residue -all

    rmsd_rmsf $frame
	get_pdb $frame
}

proc bigdcd_analyser {dcd_path} {
	package require pbctools

    mol delete all
    create_mol
    prepare_rmsd

    bigdcd frame_analysis auto $dcd_path
    bigdcd_wait

    close_rmsd_files
}
