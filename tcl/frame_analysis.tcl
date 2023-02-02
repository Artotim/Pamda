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


proc pamda::frame_analysis_main {} {
    load_dependencies $pamda::program_src_path

    variable md_path
    variable md_type
    variable rms_analysis

    pamda::create_mol

    pamda::prepare_analysis

    bigdcd pamda::frame_analysis $md_type $md_path
    bigdcd_wait

    if {$pamda::rms_analysis == "True"} {
        pamda::prepare_rmsf
        bigdcd pamda::rmsf_analysis $md_type $md_path
        bigdcd_wait
    }

    pamda::close_analysis

    mol delete $pamda::mol
}


proc pamda::prepare_analysis {} {
    variable md_path
    variable md_type
    variable mol

    mol addfile $md_path type $md_type first 0 last 0 waitfor all molid $mol

    if {$pamda::rms_analysis == "True"} {pamda::prepare_rms}
    if {$pamda::contacts_analysis == "True"} {pamda::prepare_contacts}
    if {$pamda::distances_analysis == "True"} {pamda::prepare_distances}
    if {$pamda::sasa_analysis == "True"} {pamda::prepare_sasa}
}


proc pamda::close_analysis {} {
    if {$pamda::rms_analysis == "True"} {pamda::finish_and_close_rms_files}
    if {$pamda::contacts_analysis == "True"} {pamda::close_contacts_files}
    if {$pamda::distances_analysis == "True"} {pamda::close_distances_files}
    if {$pamda::sasa_analysis == "True"} {pamda::close_sasa_files}
}


proc pamda::frame_analysis {frame} {
    variable first_frame
    variable last_frame
    variable run_pbc
    variable cci
    variable ssi

    variable rms_analysis
    variable contacts_analysis
    variable distances_analysis
    variable sasa_analysis

    pamda::keep_frame $frame

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

    if {$rms_analysis == "True"} {pamda::measure_rms $frame}
    if {$contacts_analysis == "True" && [should_run_analysis $frame $first_frame $cci] == "True"} {pamda::measure_contacts $frame}
    if {$distances_analysis == "True"} {pamda::measure_distances $frame}
    if {$sasa_analysis == "True" && [should_run_analysis $frame $first_frame $ssi] == "True"} {pamda::measure_sasa $frame}
}


proc should_run_analysis {frame first_frame interval} {
    if {[expr $frame % $interval] == 0 || $frame == $first_frame } {
        return "True"
    } else {
        return "False"
    }
}


proc pamda::rmsf_analysis {frame} {
    variable first_frame
    variable last_frame
    variable mol
    variable run_pbc

    pamda::keep_frame $frame

    if {$frame >= $first_frame && $frame <= $last_frame} {
        if {$run_pbc == "True"} {pbc_wrap "current_frame"}
        pamda::measure_residue_rmsf $frame
    }
}


proc pamda::keep_frame {frame} {
    global bigdcd_keepframe

    variable kfi
    variable last_frame
    variable mol
    variable run_pbc

    if {[expr $frame % $kfi] == 0 && $frame <= $last_frame} {
        # Must duplicate frame before align and delete aligned one for pbc to work
        if {$run_pbc == "True"} {pbc_wrap "current_frame"}
        set bigdcd_keepframe "True"
        animate dup $mol
    }
}
