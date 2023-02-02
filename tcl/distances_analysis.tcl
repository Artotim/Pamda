# Distances Analysis


proc pamda::prepare_distances {} {
    pamda::create_distances_list
    pamda::create_distances_out_files
}


proc pamda::create_distances_list {} {
    variable dist_type
    variable dist_pairs
    variable dist_pairs_names

    variable mol

    variable dist_sel_dict

    foreach dist_pair $dist_pairs pair_name $dist_pairs_names {
        set pair1 [split [lindex $dist_pair 0] ":"]
        set pair2 [split [lindex $dist_pair 1] ":"]

        set pair1_sel "[lindex $pair1 0] and chain [lindex $pair1 1]"
        set pair2_sel "[lindex $pair2 0] and chain [lindex $pair2 1]"

        set dist_sel_list {}

        if {$dist_type == "resid"} {
            lappend dist_sel_list [uplevel "#0" [list \
                atomselect $mol "not solvent and resid ${pair1_sel}"]]
            lappend dist_sel_list [uplevel "#0" [list \
                atomselect $mol "not solvent and resid ${pair2_sel}"]]
        } else {
            lappend dist_sel_list [uplevel "#0" [list \
                atomselect $mol "index ${pair1_sel}"]]
            lappend dist_sel_list [uplevel "#0" [list \
                atomselect $mol "index ${pair2_sel}"]]
        }

        dict set dist_sel_dict $pair_name $dist_sel_list
    }
}


proc pamda::create_distances_out_files {} {
    variable out_path
    variable out_name
    variable dist_pairs_names

    puts "Creating distances out files"

    variable dist_out [open "${out_path}distances/${out_name}_all_distances.csv" w]
    puts -nonewline $dist_out "frame"

    foreach pair_name $dist_pairs_names {
        puts -nonewline $dist_out  ";${pair_name}"
    }
    puts $dist_out ""
}


proc pamda::measure_distances {frame} {
    puts "Measuring distances"

    variable dist_type
    variable dist_pairs_names
    variable dist_sel_dict
    variable dist_out

    puts -nonewline $dist_out "${frame}"

    foreach pair_name $dist_pairs_names {
        set pair1_sel [lindex [dict get $dist_sel_dict $pair_name] 0]
        set pair2_sel [lindex [dict get $dist_sel_dict $pair_name] 1]

        $pair1_sel frame last
        $pair2_sel frame last

        if {$dist_type == "resid"} {
            set pair1_com [measure center $pair1_sel weight mass]
            set pair2_com [measure center $pair2_sel weight mass]

            set dist [veclength [vecsub $pair1_com $pair2_com]]
        } else {
            set pair1_idx [$pair1_sel get index]
            set pair2_idx [$pair2_sel get index]

            set dist [measure bond [list $pair1_idx $pair2_idx] frame last]
        }

        puts -nonewline $dist_out ";[format "%.4f" $dist]"
    }

    puts $dist_out ""
}


proc pamda::close_distances_files {} {
    close $pamda::dist_out
}
