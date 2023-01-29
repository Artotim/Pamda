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

    set mol [mol new $str_path type $str_type waitfor all]
    get_models $md_path $md_type $out_path $out_name $first_frame $last_frame $run_pbc $mol
    mol delete $mol

    if {$guess_chains == "True"} {
        set tmp_pdb_file "${out_path}models/${out_name}_temp.pdb"
        set mol [load_fixed_pdb_mol $str_path $str_type $out_path $out_name $tmp_pdb_file]

        set out_name "${out_name}_guessed_chains"
        guess_chains $mol

        get_models $md_path $md_type $out_path $out_name $first_frame $last_frame $run_pbc $mol
        mol delete $mol

        file delete $tmp_pdb_file
    }
}


proc get_models {md_path md_type out_path out_name first_frame last_frame run_pbc mol} {
    package ifneeded pbctools [package require pbctools]

    puts "Creating models"

    animate delete all
    set loaded_frames 0

    if {$run_pbc == "True"} {load_pbc_reference_frames $md_path $md_type $mol $first_frame}
    mol addfile $md_path type $md_type first [expr $first_frame -1] last [expr $first_frame -1] waitfor all molid $mol
    if {$run_pbc == "True"} {
        pbc_wrap "all_frames"
    }
    pbc wrap -center com -centersel "not solvent" -compound fragment -now -sel "solvent"

    set first_frame_sel [ atomselect $mol all frame last ]
    set pdb_file_name "${out_path}models/${out_name}_first_analysis_frame.pdb"
    $first_frame_sel writepdb $pdb_file_name

    animate delete all

    if {$run_pbc == "True"} {load_pbc_reference_frames $md_path $md_type $mol $last_frame}
    mol addfile $md_path type $md_type first [expr $last_frame -1] last [expr $last_frame -1] waitfor all molid $mol
    if {$run_pbc == "True"} {
        pbc_wrap "all_frames"
    }
    pbc wrap -center com -centersel "not solvent" -compound fragment -now -sel "solvent"

    set last_frame_sel [ atomselect $mol all frame last ]
    set pdb_file_name "${out_path}models/${out_name}_last_analysis_frame.pdb"
    $last_frame_sel writepdb $pdb_file_name

    animate delete all
}


proc load_fixed_pdb_mol {str_path str_type out_path out_name tmp_pdb_file} {
    set mol [mol new $str_path type $str_type waitfor all]

    if {[llength [[atomselect $mol "name OC1"] get name]] > 0} {
        # Fix gromacs C-terminal so VMD can recognize it as a protein
        [atomselect  $mol "name OC1"] set name "O"

        [atomselect  $mol "all"] writepdb $tmp_pdb_file
        set mol [mol new $tmp_pdb_file type pdb waitfor all]
    }

    return $mol
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

        set chain [atomselect $mol "not solvent and resid [lindex $chain_range 0] to [lindex $chain_range 1]"]
        $chain set chain $chain_name
        incr chain_idx
    }
}


proc get_chains_range {mol} {
    set all [atomselect $mol "not solvent"]
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
