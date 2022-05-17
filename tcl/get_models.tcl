# Get Models


proc load_initial_frames {dcd_path first mol} {
    puts "Loading initial frames"

    set loaded_frames 0
    set next_frame 1
    set load_interval [expr $first / 500 + 1]

    while {$next_frame < $first} {
        mol addfile $dcd_path type dcd first $next_frame last $next_frame waitfor all molid $mol
        set next_frame [expr $next_frame + $load_interval]
        set loaded_frames [expr $loaded_frames + 1]
    }

    return $loaded_frames
}


proc pbc_wrap {frames wrapped} {
    global main_chain

    if {$frames == "frames_now"} {
        if {$wrapped == True} {
            pbc unwrap -now -sel "protein"
        } else {
            pbc wrap -center com -centersel "protein and chain $main_chain" -compound residue -now
            pbc wrap -center com -centersel "protein" -compound residue -now
        }
    } else {
        if {$wrapped == True} {
            pbc unwrap -all -sel "protein"
        } else {
            pbc wrap -center com -centersel "protein and chain $main_chain" -compound residue -all
            pbc wrap -center com -centersel "protein" -compound residue -all
        }
    }
}


proc get_models {psf_path dcd_path out_path init last wrapped} {
	package require pbctools

	puts "Creating models"

    set mol [mol new $psf_path type psf waitfor all]

    set loaded_frames [load_initial_frames $dcd_path $init $mol]

	mol addfile $dcd_path type dcd first $init last $init waitfor all molid $mol
	pbc_wrap frames_all $wrapped
	set writePdb [ atomselect $mol all frame last ]
	set fileName "${out_path}models/first_frame.pdb"
	$writePdb writepdb $fileName

    animate delete beg 0 end $loaded_frames skip 0 $mol
    set loaded_frames [load_initial_frames $dcd_path $last $mol]

	mol addfile $dcd_path type dcd first [expr $last -1] last [expr $last -1] waitfor all molid $mol
	pbc_wrap frames_all $wrapped
	set writePdb [ atomselect $mol all frame last ]
	set fileName "${out_path}models/last_frame.pdb"
	$writePdb writepdb $fileName

    animate delete beg 0 end $loaded_frames skip 0 $mol
}


get_models *psf_path* *dcd_path* *out_path* *init* *last* *wrapped*
