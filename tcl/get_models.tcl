# Get Models


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


proc get_models {psf_path dcd_path out_path init last} {
	package require pbctools

	puts "Creating models"

    set mol [mol new $psf_path type psf waitfor all]

	mol addfile $dcd_path type dcd first $init last $init waitfor all molid $mol
	pbc_wrap frames_all False
	set writePdb [ atomselect $mol all frame last ]
	set fileName "${out_path}models/first_model.pdb"
	$writePdb writepdb $fileName

    animate delete beg 0 end 1 skip 0 $mol

	mol addfile $dcd_path type dcd first [expr $last -1] last [expr $last -1] waitfor all molid $mol
	pbc_wrap frames_all False
	set writePdb [ atomselect $mol all frame last ]
	set fileName "${out_path}models/last_model.pdb"
	$writePdb writepdb $fileName

	animate delete beg 0 end 1 skip 0 $mol
}


get_models *psf_path* *dcd_path* *out_path* *init* *last* *wrapped*
