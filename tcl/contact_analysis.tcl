#Contact Analysis


proc create_contact_files {} {
	global main_chain peptide out_path contact_map_out contact_count_out

	set contact_map_out [open ${out_path}contact/contact_map.csv w]
	puts -nonewline $contact_map_out "frame;"
	puts -nonewline $contact_map_out "atom_$main_chain;name_$main_chain;resid_$main_chain;resname_$main_chain;"
	puts $contact_map_out "atom_$peptide;name_$peptide;resid_$peptide;resname_$peptide"

	set contact_count_out [open ${out_path}contact/contact_count.csv w]
	puts $contact_count_out "frame;contacts"
}


proc  close_contact_files {} {
	global contact_map_out contact_count_out

	close $contact_map_out
	close $contact_count_out
}


proc get_contacts {frame} {
	global mol main_chain peptide cutoff contact_map_out contact_count_out

	set main_chain_sel [atomselect $mol "chain $main_chain" frame $frame]
	set peptide_sel [atomselect $mol "chain $peptide" frame $frame]

	set contacts [measure contacts $cutoff $main_chain_sel $peptide_sel]

	foreach atom_chainA [lindex $contacts 0] atom_chainB [lindex $contacts 1] {
		set atomA [atomselect $mol "index $atom_chainA" frame $frame]
		set atomB [atomselect $mol "index $atom_chainB" frame $frame]

		set nameA [$atomA get name]
		set nameB [$atomB get name]

		set residA [$atomA get resid]
		set residB [$atomB get resid]

		set resnameA [$atomA get resname]
		set resnameB [$atomB get resname]

		puts $contact_map_out "$frame;$atom_chainA;$nameA;$residA;$resnameA;$atom_chainB;$nameB;$residB;$resnameB"
	}

	set count [llength [lindex $contacts 0]]
	puts $contact_count_out "$frame;$count"
}


proc measure_contact_interval {frame call_pbc wrapped} {
    global mol init last cci out_path main_chain

    if {[expr $frame % $cci] == 0} {
        puts "Measuring contacts for frame $frame"
        if {$call_pbc == True} {
            pbc_wrap frames_now $wrapped
        }

        get_contacts $frame
    }
}
