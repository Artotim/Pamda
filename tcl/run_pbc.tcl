# Run PBC


proc load_reference_frames {md_path md_type target_frame mol} {
    puts "Loading reference frames"

    set loaded_frames 0
    set next_frame 0
    set load_interval [expr $target_frame / 500 + 1]

    while {$next_frame < $target_frame} {
        mol addfile $md_path type $md_type first $next_frame last $next_frame waitfor all molid $mol
        set next_frame [expr $next_frame + $load_interval]
        set loaded_frames [expr $loaded_frames + 1]
    }

    return $loaded_frames
}


proc pbc_wrap {frame_selection} {
    package ifneeded pbctools [package require pbctools]

    if {$frame_selection == "current_frame"} {
        pbc unwrap -now -sel "notSolvent"
        pbc wrap -center com -centersel "notSolvent" -compound fragment -now
    } else {
        pbc unwrap -all -sel "notSolvent"
        pbc wrap -center com -centersel "notSolvent" -compound fragment -all
    }
}
