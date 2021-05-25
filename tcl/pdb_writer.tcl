proc pdb_writer_interval {dcd_path} {
	global mol init last sci out_path main_chain
	package require pbctools

	create_mol
	set reset 0

	set frame $init
	while {$frame <= $last} {
		if {$frame != $init && $frame != $last} {
			mol addfile $dcd_path type dcd first [expr $frame -1] last [expr $frame -1] waitfor all molid $mol

			pbc wrap -center com -centersel "protein and chain $main_chain" -compound residue -all
			pbc wrap -center com -centersel "protein" -compound residue -all

			set writePdb [ atomselect $mol all frame last ]
			set fileName "${out_path}score/score_model_$frame.pdb"
			puts "Writing pdb $frame"
			$writePdb writepdb $fileName

			set reset [expr $reset + 1]
		}

		if {$reset == 1000} {
			mol delete all
			create_mol
			set reset 0
		}

		set frame [expr $frame + $sci]
	}
}
