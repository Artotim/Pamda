# Bigdcd Main


proc frame_analysis {frame} {
    global main_chain init last wrapped mol bigdcd_keepframe kfi

    if {$frame < $init || $frame > $last} {
        puts "Skipping frame $frame ..."
        return
    }

    puts "\nAnalysing frame $frame ..."

    pbc_wrap frames_now $wrapped

    if {[expr $frame % $kfi] == 0} {
        set bigdcd_keepframe True
        animate dup $mol
    }

    measure_rmsd_rmsf $frame
	measure_contact_interval $frame *call_pbc* $wrapped
	measure_distances $frame
}


proc bigdcd_analysis_main {dcd_path} {
	package require pbctools

    mol delete all
    get_mol

    prepare_rmsd $dcd_path
    prepare_distances *dist_list*
    create_contact_files

    bigdcd frame_analysis auto $dcd_path
    bigdcd_wait

    close_rmsd_files
    close_contact_files
    close_distances_files
}
