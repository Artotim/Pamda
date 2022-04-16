# Distance Analysis


proc prepare_distances {dist_list} {
    create_distances_list $dist_list
    create_dist_out_file
}


proc create_dist_out_file {} {
    global dist_out	out_path dist_names_list

	puts "Creating dist out file"

    set dist_out [open ${out_path}distances/all_distances.csv w]
    puts -nonewline $dist_out "frame"

    foreach name $dist_names_list {
        puts -nonewline $dist_out  ";$name"
    }
    puts $dist_out ""
}


proc create_distances_list {distances_list_in} {
    global distances_list dist_type mol

    set distances_list {}

    if {$dist_type == "resid"} {
        foreach item $distances_list_in {
            lappend distances_list [uplevel "#0" [list \
                atomselect $mol "resid $item and protein"]]
        }
    } else {
        foreach item $distances_list_in {
            lappend distances_list [uplevel "#0" [list \
                atomselect $mol "index $item"]]
        }
    }
}


proc measure_distances {frame} {
	global mol distances_list dist_type dist_out

	puts "Masuring distance for frame $frame"

	foreach item [dict values $distances_list] {
	    $item frame $frame
	}

    set distances_objs {}
    if {$dist_type == "resid"} {
        foreach item $distances_list {
            lappend distances_objs [measure center $item weight mass]
        }
    } else {
        foreach item $distances_list {
            lappend distances_objs [$item get index]
        }
    }

    set list_length [llength $distances_objs]
    set index 0
    puts -nonewline $dist_out "$frame"

    if {$dist_type == "resid"} {
        while {$index <  $list_length} {
            set dist [veclength [vecsub [lindex $distances_objs $index] [lindex $distances_objs [expr $index + 1]]]]
            set index [expr $index + 2]
            puts -nonewline $dist_out ";$dist"
        }
    } else {
        while {$index <  $list_length} {
            set dist [measure bond [list [lindex $distances_objs $index] [lindex $distances_objs [expr $index + 1]]] frame $frame]
            set index [expr $index + 2]
            puts -nonewline $dist_out ";$dist"
        }
    }
    puts $dist_out ""
}


proc close_distances_files {} {
	global dist_out

	close $dist_out
}

set dist_type *dist_type*
set dist_names_list *dist_names*
