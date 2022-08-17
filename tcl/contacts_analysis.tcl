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

        set count_file [open "${out_path}contacts/${out_name}_${pair_name}_contacts_count.csv" w]
        puts $count_file "frame;contacts"

        set map_file [open "${out_path}contacts/${out_name}_${pair_name}_contacts_map.csv" w]
        puts -nonewline $map_file "frame"

        foreach chain $chain_pair {
            puts -nonewline $map_file ";atom_${chain};name_${chain};resid_${chain};resname_${chain}"
        }
        puts $map_file ";distance"

        dict set contacts_count_out $pair_name $count_file
        dict set contacts_map_out $pair_name $map_file
    }
}


proc nome_legal::measure_contacts {frame} {
    puts "Measuring contacts"

    variable contacts_cutoff

    variable mol
    variable chain_interactions

    variable contacts_count_out
    variable contacts_map_out

    foreach chain_pair $chain_interactions {

        set chain1 [lindex $chain_pair 0]
        set chain2 [lindex $chain_pair 1]

        set pair_name "${chain1}-${chain2}"

        set chain1_sel [atomselect $mol "notSolvent and chain $chain1" frame last]
        set chain2_sel [atomselect $mol "notSolvent and chain $chain2" frame last]

        set contacts [measure contacts $contacts_cutoff $chain1_sel $chain2_sel]

        set count [llength [lindex $contacts 0]]
        puts [dict get $contacts_count_out $pair_name] "${frame};${count}"

        foreach atom_chain1 [lindex $contacts 0] atom_chain2 [lindex $contacts 1] {
            set atom1 [atomselect $mol "index $atom_chain1" frame last]
            set atom2 [atomselect $mol "index $atom_chain2" frame last]

            set name1 [$atom1 get name]
            set name2 [$atom2 get name]

            set resid1 [$atom1 get resid]
            set resid2 [$atom2 get resid]

            set resname1 [$atom1 get resname]
            set resname2 [$atom2 get resname]

            set distance [measure bond [list $atom_chain1 $atom_chain2] frame last]

            puts [dict get $contacts_map_out $pair_name] "${frame};${atom_chain1};${name1};${resid1};${resname1};${atom_chain2};${name2};${resid2};${resname2};[format "%.4f" $distance]"
        }
    }
}


proc nome_legal::close_contacts_files {} {
    variable chain_interactions

    variable contacts_count_out
    variable contacts_map_out

    foreach chain_pair $chain_interactions {

        set pair_name "[lindex $chain_pair 0]-[lindex $chain_pair 1]"

        close [dict get $contacts_count_out $pair_name]
        close [dict get $contacts_map_out $pair_name]
    }
}
