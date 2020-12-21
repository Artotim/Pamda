proc get_pdb {frame} {
    global mol init last sci cci out_path

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
}
