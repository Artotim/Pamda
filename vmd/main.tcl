proc bigdcd_analysis {frame} {
    global main_chain
    pbc wrap -center com -centersel "protein and chain $main_chain" -compound residue -all
    pbc wrap -center com -centersel "protein" -compound residue -all

    rmsd_rmsf $frame
	pdb_writer $frame
}

proc main {dcd_path} {
	package require pbctools

    mol delete all
    create_mol
    prepare_rmsd

    bigdcd bigdcd_analysis auto $dcd_path
    bigdcd_wait

    close_rmsd_files
}
