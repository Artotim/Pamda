# Energies Analysis


proc energies {first last interaction} {
    global main_chain peptide psf_path dcd_path out_path namdenergy_path

    puts "Measuring energy from $first to $last"

    set mol [mol new $psf_path type psf waitfor all]
    mol addfile $dcd_path type dcd first $first last [expr $last -1] waitfor all molid $mol

    pbc wrap -center com -centersel "protein and chain $main_chain" -compound residue -all
    pbc wrap -center com -centersel "protein" -compound residue -all

    set temp "${out_path}energies/all_temp_$last"
    set out "${out_path}energies/all_$last"

    set sel_all [atomselect top protein]
    namdenergy -sel $sel_all -exe ${namdenergy_path}namdenergy -par ${namdenergy_path}params/par_all36_prot.prm -par ${namdenergy_path}params/par_all36_na.prm -par ${namdenergy_path}params/toppar_water_ions.str -all -tempname $temp -ofile $out

    if {$interaction == true} {
        set temp "${out_path}energies/interaction_temp_$last"
        set out "${out_path}energies/interaction_$last"

        set sel_a [atomselect top "chain $main_chain"]
        set sel_b [atomselect top "chain $peptide"]
        namdenergy -sel $sel_a $sel_b -exe ${namdenergy_path}namdenergy -par ${namdenergy_path}params/par_all36_prot.prm -par ${namdenergy_path}params/par_all36_na.prm -par ${namdenergy_path}params/toppar_water_ions.str -vdw -elec -nonb -tempname $temp -ofile $out
    }
}


proc get_energies {} {
    global init last interaction

	package require namdenergy
	package require pbctools

	puts "Preparing to get energy"

    mol delete all

	set total_frames $last
	set count $init

    while {$count < $total_frames} {
        energies $count [expr {$count + 5000}] $interaction
        mol delete top

        set count [expr {$count + 5000}]
    }
}
