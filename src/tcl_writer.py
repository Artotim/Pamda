from src.color_log import log


class TclWriter:
    """Class to write tcl files to use with vmd"""

    def __init__(self, dynamic_analysis):
        self.dynamic_analysis = dynamic_analysis
        self.frame_script = []
        self.energies_script = []

    def prepare_frame_analysis(self):
        """Write script to frame analysis"""

        log('info', 'Preparing .tcl file for frame analysis.')

        self.frame_script = self.write_get_chain(self.frame_script)
        self.frame_script = self.write_get_models(self.frame_script)
        self.frame_script = self.write_prepare_mol(self.frame_script)

        self.write_bigdcd_script()

        if self.dynamic_analysis.rmsd_analysis:
            self.write_rmsd_rmsf_analysis()

        if self.dynamic_analysis.contact_analysis:
            self.write_contacts_analysis()

        if self.dynamic_analysis.distances_analysis:
            self.write_distances_analysis()

        self.write_bigdcd_main()

        self.write_frame_variables()

        script_call = "\nbigdcd_analysis_main " + self.dynamic_analysis.dcd_path
        self.frame_script.append(script_call)

        self.write_tcl_tmp_file(self.frame_script, 'frame')

    def prepare_energies_analysis(self):
        """Write script to energy analysis"""

        log('info', 'Preparing .tcl file for energies analysis.')

        self.energies_script = self.write_get_chain(self.energies_script)
        self.energies_script = self.write_get_models(self.energies_script)

        self.write_energies()
        self.write_energies_variables()

        script_call = "\nget_energies"
        self.energies_script.append(script_call)

        self.write_tcl_tmp_file(self.energies_script, 'energies')

    def write_get_chain(self, script):
        """Append get_chain routine to script"""

        with open(F'{self.dynamic_analysis.analysis_path}tcl/get_chain.tcl', 'r') as get_chain:
            file = get_chain.readlines()
            file = set_argument(file, 'pdb_path', self.dynamic_analysis.pdb_path)
            script.extend(file)

        return script

    def write_get_models(self, script):
        """Append get_models routine to script"""

        with open(F'{self.dynamic_analysis.analysis_path}tcl/get_models.tcl', 'r') as get_chain:
            file = get_chain.readlines()
            file = set_argument(file, 'psf_path', self.dynamic_analysis.psf_path)
            file = set_argument(file, 'pdb_path', self.dynamic_analysis.pdb_path)
            file = set_argument(file, 'dcd_path', self.dynamic_analysis.dcd_path)
            file = set_argument(file, 'out_path', self.dynamic_analysis.output)
            file = set_argument(file, 'init', str(self.dynamic_analysis.init_frame))
            file = set_argument(file, 'last', str(self.dynamic_analysis.last_frame))

            script.extend(file)

        return script

    def write_prepare_mol(self, script):
        """Append mol_create routine to script"""

        with open(F'{self.dynamic_analysis.analysis_path}tcl/get_mol.tcl', 'r') as create:
            script.extend(create.readlines())
        return script

    def write_bigdcd_script(self):
        """Append bigdcd routine to script"""

        with open(F'{self.dynamic_analysis.analysis_path}tcl/bigdcd.tcl', 'r') as energies:
            self.frame_script.extend(energies.readlines())

    def write_rmsd_rmsf_analysis(self):
        """Append rmsd_rmsf routine to script"""

        with open(F'{self.dynamic_analysis.analysis_path}tcl/rmsd_rmsf_analysis.tcl', 'r') as rmsd:
            self.frame_script.extend(rmsd.readlines())

    def write_contacts_analysis(self):
        """Append get contacts routine to script"""

        with open(F'{self.dynamic_analysis.analysis_path}tcl/contact_analysis.tcl', 'r') as rmsd:
            self.frame_script.extend(rmsd.readlines())

    def write_distances_analysis(self):
        """Append get contacts routine to script"""

        with open(F'{self.dynamic_analysis.analysis_path}tcl/distances_analysis.tcl', 'r') as distance:
            file = distance.readlines()
            file = set_argument(file, 'dist_type', self.dynamic_analysis.dist_type.replace('atom', 'atom_idx'))
            file = set_argument(file, 'dist_names', '{' + ' '.join(self.dynamic_analysis.dist_names) + '}')

            self.frame_script.extend(file)

    def write_bigdcd_main(self):
        """Append bigdcd_main routine to script"""
    
        with open(F'{self.dynamic_analysis.analysis_path}tcl/bigdcd_main.tcl', 'r') as bigdcd_main:
            file = bigdcd_main.readlines()

            if not self.dynamic_analysis.rmsd_analysis:
                file = remove_function_call(file, 'prepare_rmsd')
                file = remove_function_call(file, 'measure_rmsd_rmsf')
                file = remove_function_call(file, 'close_rmsd_files')
                
            if not self.dynamic_analysis.contact_analysis:
                file = remove_function_call(file, 'create_contact_files')
                file = remove_function_call(file, 'measure_contact_interval')
                file = remove_function_call(file, 'close_contact_files')

            if not self.dynamic_analysis.distances_analysis:
                file = remove_function_call(file, 'prepare_distances')
                file = remove_function_call(file, 'measure_distances')
                file = remove_function_call(file, 'close_distances_files')

            file = self.set_bigdcd_main_variables(file)

            self.frame_script.extend(file)

    def set_bigdcd_main_variables(self, file):
        if not self.dynamic_analysis.rmsd_analysis and not self.dynamic_analysis.distances_analysis:
            file = set_argument(file, 'wrap', 'True')
            file = remove_function_call(file, 'pbc')
        else:
            file = set_argument(file, 'wrap', 'False')

            if self.dynamic_analysis.distances_analysis:
                file = set_argument(file, 'dist_list', '{' + ' '.join(self.dynamic_analysis.dist_pairs) + '}')

        return file

    def write_pdb_writer(self, script):
        """Append pdb_writer routine to script"""

        with open(F'{self.dynamic_analysis.analysis_path}tcl/pdb_writer.tcl', 'r') as pdb_writer:
            file = pdb_writer.readlines()
            script.extend(file)
        return script

    def write_energies(self):
        """Append energies_analysis routine to script"""

        with open(F'{self.dynamic_analysis.analysis_path}tcl/energies_analysis.tcl', 'r') as energies:
            self.energies_script.extend(energies.readlines())

    def write_frame_variables(self):
        """Write variables for frame analysis"""

        set_variable(self.frame_script, 'psf_path', self.dynamic_analysis.psf_path)
        set_variable(self.frame_script, 'pdb_path', self.dynamic_analysis.pdb_path)
        set_variable(self.frame_script, 'out_path', self.dynamic_analysis.output)

        set_variable(self.frame_script, 'init', self.dynamic_analysis.init_frame)
        set_variable(self.frame_script, 'last', self.dynamic_analysis.last_frame)

        if self.dynamic_analysis.contact_analysis:
            set_variable(self.frame_script, 'cci', self.dynamic_analysis.contact_interval)
            set_variable(self.frame_script, 'cutoff', self.dynamic_analysis.contact_cutoff)

    def write_energies_variables(self):
        """Write variables for energies analysis"""

        set_variable(self.energies_script, 'psf_path', self.dynamic_analysis.psf_path)
        set_variable(self.energies_script, 'dcd_path', self.dynamic_analysis.dcd_path)
        set_variable(self.energies_script, 'out_path', self.dynamic_analysis.output)
        set_variable(self.energies_script, 'namdenergy_path',
                     self.dynamic_analysis.analysis_path + 'dependencies/namdenergy/')

        set_variable(self.energies_script, 'init', self.dynamic_analysis.init_frame)
        set_variable(self.energies_script, 'last', self.dynamic_analysis.last_frame)

    def write_tcl_tmp_file(self, script, name):
        """Saves script as temp file"""

        filename = self.dynamic_analysis.output + 'temp_' + name + '_analysis.tcl'
        with open(filename, 'w') as analysis:
            analysis.write(''.join(script))
            analysis.write("\nquit\n")


def set_variable(script, variable, value):
    """Set a variables in script"""

    append = 'set ' + variable + ' ' + str(value) + '\n'
    script.append(append)
    return script


def set_argument(script, arg_name, arg):
    """Set a function argument in script"""

    arg_name = '*' + arg_name + '*'
    for idx, line in enumerate(script):
        if arg_name in line:
            script[idx] = line.replace(arg_name, arg)

    return script


def remove_function_call(script, fnc_call):
    """Remove a call to an unrequested function in script"""

    for idx, line in enumerate(script):
        if fnc_call in line:
            script[idx] = "# " + line

    return script
