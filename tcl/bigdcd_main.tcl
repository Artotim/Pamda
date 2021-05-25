proc frame_analysis {frame} {
    global main_chain
    puts "Analysing frame $frame ..."

    pbc wrap -center com -centersel "protein and chain $main_chain" -compound residue -all
    pbc wrap -center com -centersel "protein" -compound residue -all

    rmsd_rmsf $frame
	analyze_interval $frame
}

proc bigdcd_analyser {dcd_path} {
	package require pbctools

    mol delete all
    create_mol

    prepare_rmsd
    create_contact_files

    bigdcd frame_analysis auto $dcd_path
    bigdcd_wait

    close_rmsd_files
    close_contact_files
}
