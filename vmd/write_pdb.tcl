proc write_pdb {frame} {
    global mol init last sci cci out_path name

    if {[expr $frame % $sci] == 0} {
        puts "Writing pdb $frame"
        set writePdb [ atomselect $mol all frame last ]
        set fileName "${out_path}score/score_model_$frame.pdb"
        $writePdb writepdb $fileName
    }

    if {[expr $frame % $cci] == 0} {
        puts "Writing pdb $frame"
        set writePdb [ atomselect $mol all frame last ]
        set fileName "${out_path}contact/contact_model_$frame.pdb"
        $writePdb writepdb $fileName
    }

    if {$frame == [expr {$init + 1}]} {
        puts "Writing first pdb"
        set writePdb [ atomselect $mol all frame last ]
        set fileName "${out_path}model_first.pdb"
        $writePdb writepdb $fileName
    }

    if {$frame == $last} {
        puts "Writing last pdb"
        set writePdb [ atomselect $mol all frame last ]
        set fileName "${out_path}model_last.pdb"
        $writePdb writepdb $fileName
    }
}
