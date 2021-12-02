# Bigdcd Main


proc frame_analysis {frame} {
    global main_chain init last

    if {$frame < $init || $frame > $last} {
        puts "Skipping frame $frame ...
        return
    }

    puts "\nAnalysing frame $frame ..."

    pbc wrap -center com -centersel "protein and chain $main_chain" -compound residue -all
    pbc wrap -center com -centersel "protein" -compound residue -all

    measure_rmsd_rmsf $frame
	measure_contact_interval $frame *wrap*
	measure_distances $frame
}


proc bigdcd_analysis_main {dcd_path} {
	package require pbctools

    mol delete all
    get_mol

    prepare_rmsd
    prepare_distances *dist_list*
    create_contact_files

    bigdcd frame_analysis auto $dcd_path
    bigdcd_wait

    close_rmsd_files
    close_contact_files
    close_distances_files
}
