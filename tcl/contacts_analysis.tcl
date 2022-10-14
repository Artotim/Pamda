# Contact Analysis


proc nome_legal::prepare_contacts {} {
    puts "Creating contacts out files"

    variable out_path
    variable out_name

    variable chain_interactions

    variable contacts_count_out
    variable contacts_map_out

    foreach chain_pair $chain_interactions {

        set pair_name "[lindex $chain_pair 0]-[lindex $chain_pair 1]"

		set pair_count_outs {}
		set pair_maps_out {}

		set contact_types {"nonbond" "hbonds" "sbridges"}
		foreach contact_type $contact_types {
			set count_file [open "${out_path}contacts/${out_name}_${pair_name}_${contact_type}_contacts_count.csv" w]
			puts $count_file "frame;${contact_type}_count"

			set map_file [open "${out_path}contacts/${out_name}_${pair_name}_${contact_type}_contacts_map.csv" w]
			puts $map_file [nome_legal::define_map_out_header $contact_type]

			dict set pair_count_outs $contact_type $count_file
			dict set pair_maps_out $contact_type $map_file
		}

        dict set contacts_count_out $pair_name $pair_count_outs
        dict set contacts_map_out $pair_name $pair_maps_out
    }
}


proc nome_legal::define_map_out_header {contact_type} {
	set header "frame"

	if {$contact_type == "nonbond"} {
		set header "${header};atom_no;atom_name;resid;resname;chain;atom_no;atom_name;resid;resname;chain;distance"
	} elseif {$contact_type == "hbonds"} {
		foreach type {"donor" "acceptor"} {
			set header "${header};${type}_atom_no;${type}_atom_name;resid;resname;chain"
		}
		set header "${header};distance;hydrogen_no"
	} elseif {$contact_type == "sbridges"} {
		foreach type {"acidic" "basic"} {
			set header "${header};${type}_atom_no;${type}_atom_name;resid;resname;chain"
		}
		set header "${header};distance"
	}

	return $header
}


proc nome_legal::measure_contacts {frame} {
    puts "Measuring contacts"

    variable contacts_cutoff

    variable mol
    variable chain_interactions

    foreach chain_pair $chain_interactions {

        set chain1 [lindex $chain_pair 0]
        set chain2 [lindex $chain_pair 1]

        set pair_name "${chain1}-${chain2}"

        set chain1_sel [atomselect $mol "not solvent and chain $chain1" frame last]
        set chain2_sel [atomselect $mol "not solvent and chain $chain2" frame last]

        nome_legal::get_nonbond_contact $frame $pair_name $chain1_sel $chain2_sel
		nome_legal::get_hbond_contact $frame $pair_name $chain1_sel $chain2_sel
		nome_legal::get_salt_bridges_contacts $frame $pair_name [$chain1_sel text] [$chain2_sel text]

        $chain1_sel delete
        $chain2_sel delete
    }
}


proc nome_legal::get_nonbond_contact {frame pair_name chain1_sel chain2_sel} {
    variable contacts_cutoff

    variable contacts_count_out
    variable contacts_map_out

	set nonbond_contacts [measure contacts $contacts_cutoff $chain1_sel $chain2_sel]

	set count [llength [lindex $nonbond_contacts 0]]
	puts [dict get [dict get $contacts_count_out $pair_name] "nonbond"] "${frame};${count}"

	foreach atom1_index [lindex $nonbond_contacts 0] atom2_index [lindex $nonbond_contacts 1] {
		puts [dict get [dict get $contacts_map_out $pair_name] "nonbond"] "${frame};[nome_legal::get_contact_data $atom1_index $atom2_index]"
	}
}


proc nome_legal::get_hbond_contact {frame pair_name chain1_sel chain2_sel} {
    variable contacts_cutoff
	variable contacts_hbond_angle

    variable contacts_count_out
    variable contacts_map_out

	set donors {}
	set acceptors {}
	set hydrogens {}

	set hbond1 [measure hbonds $contacts_cutoff $contacts_hbond_angle $chain1_sel $chain2_sel]
	set hbond2 [measure hbonds $contacts_cutoff $contacts_hbond_angle $chain2_sel $chain1_sel]

	lappend donors {*}[lindex $hbond1 0] {*}[lindex $hbond2 0]
	lappend acceptors {*}[lindex $hbond1 1] {*}[lindex $hbond2 1]
	lappend hydrogens {*}[lindex $hbond1 2] {*}[lindex $hbond2 2]

	set count [llength $hydrogens]
	puts [dict get [dict get $contacts_count_out $pair_name] "hbonds"] "${frame};${count}"

	foreach donor_index $donors acceptor_index $acceptors hydrogen_index $hydrogens {
		puts [dict get [dict get $contacts_map_out $pair_name] "hbonds"] "${frame};[nome_legal::get_contact_data $donor_index $acceptor_index];${hydrogen_index}"
	}
}


proc nome_legal::get_salt_bridges_contacts {frame pair_name chain1_sel_text chain2_sel_text} {
    variable contacts_cutoff

	variable mol

    variable contacts_count_out
    variable contacts_map_out

	set acidic {}
	set basic {}

	set acidic_c1_sel [atomselect $mol "(protein and acidic and oxygen and not backbone) and $chain1_sel_text"]
	set basic_c2_sel [atomselect $mol "(protein and basic and nitrogen and not backbone) and $chain2_sel_text"]

	set salt_briges1 [measure contacts $contacts_cutoff $acidic_c1_sel $basic_c2_sel]

	set acidic_c2_sel [atomselect $mol "(protein and acidic and oxygen and not backbone) and $chain2_sel_text"]
	set basic_c1_sel [atomselect $mol "(protein and basic and nitrogen and not backbone) and $chain1_sel_text"]

	set salt_briges2 [measure contacts $contacts_cutoff $acidic_c2_sel $basic_c1_sel]

	lappend acidic {*}[lindex $salt_briges1 0] {*}[lindex $salt_briges2 0]
	lappend basic {*}[lindex $salt_briges1 1] {*}[lindex $salt_briges2 1]

	set bridges {}
	foreach atom_acidic $acidic atom_basic $basic {
		set resid1 [[atomselect $mol "index $atom_acidic" frame last] get resid]
		set resid2 [[atomselect $mol "index $atom_basic" frame last] get resid]

		lappend bridges [subst "${resid1}:${resid2}"]
	}

	set count [llength [lsort -unique $bridges]]
	puts [dict get [dict get $contacts_count_out $pair_name] "sbridges"] "${frame};${count}"

	foreach acidic_index $acidic basic_index $basic {
		puts [dict get [dict get $contacts_map_out $pair_name] "sbridges"] "${frame};[nome_legal::get_contact_data $acidic_index $basic_index]"
	}
}


proc nome_legal::get_contact_data {atom1_index atom2_index} {
	variable mol

	set atom1 [atomselect $mol "index $atom1_index" frame last]
	set atom2 [atomselect $mol "index $atom2_index" frame last]

	set name1 [$atom1 get name]
	set name2 [$atom2 get name]

	set resid1 [$atom1 get resid]
	set resid2 [$atom2 get resid]

	set resname1 [$atom1 get resname]
	set resname2 [$atom2 get resname]

	set chain1 [$atom1 get chain]
	set chain2 [$atom2 get chain]

	set distance [measure bond [list $atom1_index $atom2_index] frame last]

	return "${atom1_index};${name1};${resid1};${resname1};${chain1};${atom2_index};${name2};${resid2};${resname2};${chain2};[format "%.4f" $distance]"
}


proc nome_legal::close_contacts_files {} {
    variable chain_interactions

    variable contacts_count_out
    variable contacts_map_out

    foreach chain_pair $chain_interactions {

        set pair_name "[lindex $chain_pair 0]-[lindex $chain_pair 1]"

		set contact_types {"nonbond" "hbonds" "sbridges"}
		foreach contact_type $contact_types {
			close [dict get [dict get $contacts_count_out $pair_name] $contact_type]
			close [dict get [dict get $contacts_map_out $pair_name] $contact_type]
		}
    }
}
