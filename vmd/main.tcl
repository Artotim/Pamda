proc bigdcd_analysis {frame} {
    rmsd_rmsf $frame
	write_pdb $frame
}

proc main {dcd_path} {
	package require pbctools

    create_mol
    prepare_rmsd

    bigdcd bigdcd_analysis auto $dcd_path
    bigdcd_wait

    close_rmsd_files
}
