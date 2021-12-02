#Get Chains


proc get_chain {pdb_path} {
	global main_chain peptide interaction

	set mol [mol new $pdb_path type pdb waitfor all]
	set sel [atomselect $mol "protein and name CA"]
	set chains [$sel get chain]

	mol delete $mol

	set counters {}
	foreach item $chains {
		dict incr counters $item
	}
	dict for {item count} $counters {
		puts "${item}: $count"
	}

	proc sortDictByValue {dict args} {
		set lst {}
		dict for {k v} $dict {lappend lst [list $k $v]}
		return [concat {*}[lsort -index 0 {*}$args $lst]]
	}

	set sorted [sortDictByValue $counters]

	set main_chain [lindex $sorted 0]
	set peptide [lindex $sorted 2]

    if {[llength $sorted] > 2} {
        set interaction true
    } else {
       set interaction false
    }
}


get_chain *pdb_path*
