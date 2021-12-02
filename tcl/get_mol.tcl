# Get Mol


proc get_mol {} {
    global mol psf_path pdb_path

	puts "Creating molecule"

    set mol [uplevel "#0" [list mol new $psf_path type psf waitfor all]]
    mol addfile $pdb_path type pdb waitfor all
}
