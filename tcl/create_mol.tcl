# Create mol


proc pamda::create_mol {} {
    variable str_path
    variable str_type

    puts "Creating molecule"

    variable mol [mol new $str_path type $str_type waitfor all]
    animate delete beg 0 end -1 skip 0 $mol

    pamda::get_mol_info $mol
}


proc pamda::get_mol_info {mol} {
    set all_sell [atomselect $mol "not solvent"]

    variable chain_list [lsort -unique [$all_sell get chain]]
    puts "Found chains ${chain_list}"

    variable residue_list {}
    foreach resid [$all_sell get resid] chain [$all_sell get chain] {
        set resid_name "${chain}:${resid}"
        if {$resid_name ni $residue_list} {
            lappend residue_list $resid_name
        }
    }

    variable chain_interactions {}
    for {set pair1 0} {$pair1 < [llength $chain_list]} {incr pair1} {
        for {set pair2 [expr $pair1 + 1]} {$pair2 < [llength $chain_list]} {incr pair2} {
            lappend chain_interactions [subst {[lindex $chain_list $pair1] [lindex $chain_list $pair2]}]
        }
    }
}
