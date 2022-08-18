# Run PBC


proc load_pbc_reference_frames {md_path md_type mol target_frame} {
    puts "Loading reference frames"

    set target_frame [expr $target_frame - 1]
    set frame_step [expr $target_frame / 500 + 1]

    mol addfile $md_path type $md_type first 0 last $target_frame step $frame_step waitfor all molid $mol

    set loaded_frames [expr $target_frame / $frame_step + 1]
    return $loaded_frames
}


proc pbc_wrap {frame_selection} {
    package ifneeded pbctools [package require pbctools]

    if {$frame_selection == "current_frame"} {
        pbc unwrap -now -sel "not solvent"
    } else {
        pbc unwrap -all -sel "not solvent"
    }
}
