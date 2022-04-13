# Energies Analysis


proc measure_energies {first last interaction first_analysis} {
    global main_chain peptide psf_path dcd_path out_path namdenergy_path wrapped

    puts "Measuring energy from $first to $last"

    set mol [mol new $psf_path type psf waitfor all]

    if {$first > 0 && $first_analysis == True} {
        mol addfile $dcd_path type dcd first [expr $first - 1] last $last waitfor all molid $mol
    } elseif {$first == 0} {
        mol addfile $dcd_path type dcd first $first last $last waitfor all molid $mol
    } else {
        mol addfile $dcd_path type dcd first [expr $first + 1] last $last waitfor all molid $mol
    }

    pbc_wrap frames_all $wrapped

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

	set first_analysis True
	set analysed_count $init

    while {$analysed_count < $last} {
        set next_analyse [expr {$analysed_count + 5000}]
        if {$next_analyse > $last} {
            set next_analyse $last
        }

        measure_energies $analysed_count $next_analyse $interaction $first_analysis
        mol delete top

        set analysed_count [expr {$analysed_count + 5000}]
        set first_analysis False
    }
}
