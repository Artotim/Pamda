# Write Models


proc resolve_write_models {argv} {
    set str_path        [lindex $argv 0]
    set str_type        [lindex $argv 1]
    set md_path         [lindex $argv 2]
    set md_type         [lindex $argv 3]
    set out_path        [lindex $argv 4]
    set out_name        [lindex $argv 5]
    set first_frame     [lindex $argv 6]
    set last_frame      [lindex $argv 7]
    set run_pbc         [lindex $argv 8]
    set guess_chains    [lindex $argv 9]
    set src_path        [lindex $argv 10]

    source "${src_path}tcl/run_pbc.tcl"
    atomselect macro notSolvent {not (ion or resname HOH TIP3 TIP4 TP4E TP4V TP3E SPCE SPC SOL)}

    set mol [mol new $str_path type $str_type waitfor all]
    get_models $md_path $md_type $out_path $out_name $first_frame $last_frame $run_pbc $mol
    mol delete $mol

    if {$guess_chains == "True"} {
        set mol [mol new $str_path type $str_type waitfor all]

        set out_name "${out_name}_guessed_chains"
        guess_chains $mol

        get_models $md_path $md_type $out_path $out_name $first_frame $last_frame $run_pbc $mol
        mol delete $mol
    }
}


proc get_models {md_path md_type out_path out_name first_frame last_frame run_pbc mol} {
    puts "Creating models"

    animate delete all

    set loaded_frames [load_reference_frames $md_path $md_type $first_frame $mol]
    mol addfile $md_path type $md_type first $first_frame last $first_frame waitfor all molid $mol

    if {$run_pbc == "True"} {pbc_wrap "all_frames"}
    set firstFrame [ atomselect $mol all frame last ]
    set fileName "${out_path}models/${out_name}_first_analysis_frame.pdb"
    $firstFrame writepdb $fileName

    animate delete beg 0 end $loaded_frames skip 0 $mol

    set loaded_frames [load_reference_frames $md_path $md_type $last_frame $mol]

    mol addfile $md_path type $md_type first [expr $last_frame -1] last [expr $last_frame -1] waitfor all molid $mol
    if {$run_pbc == "True"} {pbc_wrap "all_frames"}
    set lastFrame [ atomselect $mol all frame last ]
    set fileName "${out_path}models/${out_name}_last_analysis_frame.pdb"
    $lastFrame writepdb $fileName

    animate delete beg 0 end $loaded_frames skip 0 $mol
}


proc guess_chains {mol} {
    set alpha {A B C D E F G H I J K L M N O P Q R S T U V W}

    puts "Guessing chains..."

    set chain_idx 0

    foreach chain_range [lsort -index 2 -integer -decreasing [get_chains_range $mol]] {
        if {$chain_idx < 23} {
            set chain_name [lindex $alpha $chain_idx]
        } else {
            set chain_name "X[expr $chain_idx - 22]"
        }

        puts "Guessed chain $chain_name: resid [lindex $chain_range 0] to [lindex $chain_range 1]"

        set chain [atomselect $mol "notSolvent and resid [lindex $chain_range 0] to [lindex $chain_range 1]"]
        $chain set chain $chain_name
        incr chain_idx
    }
}


proc get_chains_range {mol} {
    set all [atomselect $mol "notSolvent"]
    set unique_list [lsort -integer -unique [$all get resid]]

    set first_resid [lindex $unique_list 0]
    set last_resid [lindex $unique_list 0]
    set chain_list {}

    foreach resid $unique_list {
        if {[expr $resid - $last_resid] > 1} {
            set chain_size [expr $last_resid - $first_resid]
            lappend chain_list [subst {$first_resid $last_resid $chain_size}]
            set first_resid $resid
        }
        set last_resid $resid
    }

    lappend chain_list [subst {$first_resid $last_resid [expr $last_resid - $first_resid]}]

    return $chain_list
}


resolve_write_models $argv
quit
