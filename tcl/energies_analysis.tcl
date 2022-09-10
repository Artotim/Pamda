# Energies Analysis


proc load_dependencies {program_src_path} {
    source "${program_src_path}tcl/create_mol.tcl"
    source "${program_src_path}tcl/run_pbc.tcl"
}


proc nome_legal::energies_analysis_main {} {
    load_dependencies $nome_legal::program_src_path

    package require namdenergy

    variable first_frame
    variable last_frame
    variable mol

    nome_legal::create_mol

    set current_frame $first_frame
    set next_frame $first_frame

    set frame_range 5000
    set first_analysis True

    while {$current_frame < [expr {$last_frame - 1}]} {
        set next_frame [expr {$next_frame + $frame_range}]
        if {$next_frame >= $last_frame} {set next_frame [expr {$last_frame - 1}]}

        nome_legal::measure_energies $current_frame $next_frame $first_analysis

        set current_frame $next_frame
        set first_analysis False
    }

    mol delete $mol
}


proc nome_legal::measure_energies {current_frame next_frame first_analysis} {
    variable out_path
    variable out_name
    variable md_path
    variable md_type
    variable run_pbc

    variable mol
    variable chain_interactions

    set namdenergy_path "${::nome_legal::program_src_path}dependencies/namdenergy/"
    set loaded_frames 0

    puts "Measuring energy from $current_frame to $next_frame"

    if {$run_pbc == "True"} {set loaded_frames [load_pbc_reference_frames $md_path $md_type $mol $current_frame]}
    nome_legal::load_analysis_frames $current_frame $next_frame $first_analysis
    if {$run_pbc == "True"} {pbc_wrap "all_frames"}

    if {$loaded_frames > 0 } {animate delete beg 0 end [expr $loaded_frames - 1] skip 0 $mol}

    set temp_file "${out_path}energies/${out_name}_all_temp_$next_frame"
    set out_file "${out_path}energies//${out_name}_all_$next_frame"
    set sel_all [atomselect $mol "not solvent"]

    namdenergy -sel $sel_all -exe ${namdenergy_path}namdenergy \
        -par ${namdenergy_path}params/par_all36_prot.prm -par ${namdenergy_path}params/par_all36_na.prm \
        -par ${namdenergy_path}params/par_all36_lipid.prm -par ${namdenergy_path}params/toppar_water_ions.str \
        -all -tempname $temp_file -ofile $out_file

    foreach chain_pair $chain_interactions {
        set pair_name "[lindex $chain_pair 0]-[lindex $chain_pair 1]"

        set temp_file "${out_path}energies/${out_name}_${pair_name}_interaction_temp_$next_frame"
        set out_file "${out_path}energies/${out_name}_${pair_name}_interaction_$next_frame"

        set pair1_sel [atomselect top "not solvent and chain [lindex $chain_pair 0]"]
        set pair2_sel [atomselect top "not solvent and chain [lindex $chain_pair 1]"]

        namdenergy -sel $pair1_sel $pair2_sel -exe ${namdenergy_path}namdenergy \
            -par ${namdenergy_path}params/par_all36_prot.prm -par ${namdenergy_path}params/par_all36_na.prm \
            -par ${namdenergy_path}params/par_all36_lipid.prm -par ${namdenergy_path}params/toppar_water_ions.str \
            -vdw -elec -nonb -tempname $temp_file -ofile $out_file

        $pair1_sel delete
        $pair2_sel delete
    }

    animate delete all
}


proc nome_legal::load_analysis_frames {current_frame next_frame first_analysis} {
    variable md_path
    variable md_type

    variable mol

    if {$first_analysis == True} {
        mol addfile $md_path type $md_type first [expr $current_frame - 1] last $next_frame waitfor all molid $mol
    } else {
        mol addfile $md_path type $md_type first [expr $current_frame + 1] last $next_frame waitfor all molid $mol
    }
}
