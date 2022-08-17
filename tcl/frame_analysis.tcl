# Frame anaylsis main


proc load_dependencies {program_src_path} {
    source "${program_src_path}tcl/bigdcd.tcl"
    source "${program_src_path}tcl/create_mol.tcl"
    source "${program_src_path}tcl/run_pbc.tcl"
    source "${program_src_path}tcl/rms_analysis.tcl"
    source "${program_src_path}tcl/contacts_analysis.tcl"
    source "${program_src_path}tcl/distances_analysis.tcl"
    source "${program_src_path}tcl/sasa_analysis.tcl"
}


proc nome_legal::frame_analysis_main {} {
    load_dependencies $nome_legal::program_src_path

    variable md_path
    variable md_type

    nome_legal::create_mol

    nome_legal::prepare_analysis

    bigdcd nome_legal::frame_analysis $md_type $md_path
    bigdcd_wait

    nome_legal::close_analysis

    mol delete $nome_legal::mol
}


proc nome_legal::prepare_analysis {} {
    variable md_path
    variable md_type
    variable mol

    mol addfile $md_path type $md_type first 0 last 0 waitfor all molid $mol

    if {$nome_legal::rms_analysis == "True"} {nome_legal::prepare_rms}
    if {$nome_legal::contacts_analysis == "True"} {nome_legal::prepare_contacts}
    if {$nome_legal::distances_analysis == "True"} {nome_legal::prepare_distances}
    if {$nome_legal::sasa_analysis == "True"} {nome_legal::prepare_sasa}
}


proc nome_legal::close_analysis {} {
    if {$nome_legal::rms_analysis == "True"} {nome_legal::close_rms_files}
    if {$nome_legal::contacts_analysis == "True"} {nome_legal::close_contacts_files}
    if {$nome_legal::distances_analysis == "True"} {nome_legal::close_distances_files}
    if {$nome_legal::sasa_analysis == "True"} {nome_legal::close_sasa_files}
}


proc nome_legal::frame_analysis {frame} {
    global bigdcd_keepframe

    variable first_frame
    variable last_frame
    variable mol
    variable kfi
    variable run_pbc
    variable cci
    variable ssi

    variable rms_analysis
    variable contacts_analysis
    variable distances_analysis
    variable sasa_analysis

    if {[expr $frame % $kfi] == 0} {
        # Must duplicate frame before align and delete aligned one for pbc to work
        if {$run_pbc == "True"} {pbc_wrap "current_frame"}
        set bigdcd_keepframe "True"
        animate dup $mol
    }

    if {$frame >= $first_frame && $frame <= $last_frame && (
            $rms_analysis == "True" ||
            $distances_analysis == "True" ||
            ( $contacts_analysis == "True" && [should_run_analysis $frame $first_frame $cci] == "True" ) ||
            ( $sasa_analysis == "True" && [should_run_analysis $frame $first_frame $ssi] == "True" )
        )} {
            puts "\nAnalysing frame $frame ..."
    } else {
        puts "Skipping frame $frame ..."
        return
    }

    if {$run_pbc == "True"} {pbc_wrap "current_frame"}

    if {$rms_analysis == "True"} {nome_legal::measure_rms $frame}
    if {$contacts_analysis == "True" && [should_run_analysis $frame $first_frame $cci] == "True"} {nome_legal::measure_contacts $frame}
    if {$distances_analysis == "True"} {nome_legal::measure_distances $frame}
    if {$sasa_analysis == "True" && [should_run_analysis $frame $first_frame $ssi] == "True"} {nome_legal::measure_sasa $frame}
}


proc should_run_analysis {frame first_frame interval} {
    if {[expr $frame % $interval] == 0 ||
        $frame == $first_frame ||
        ($frame == 1 && $first_frame == 0) } {
        return "True"
    } else {
        return "False"
    }
}
