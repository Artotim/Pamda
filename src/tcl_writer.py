from src.color_log import log


class TclWriter:
    """Class to write tcl files to use with vmd"""

    def __init__(self, pamda_instance):
        self.pamda_instance = pamda_instance

    def prepare_frame_analysis(self):
        """Write script to frame analysis"""

        log('info', 'Preparing tcl file for frame analysis.')

        frame_script = initialize_namespace()

        frame_script = self.set_common_variables(frame_script)
        frame_script = self.set_frame_variables(frame_script)

        if self.pamda_instance.contacts_analysis:
            frame_script = self.set_contacts_analysis_variables(frame_script)

        if self.pamda_instance.distances_analysis:
            frame_script = self.set_distances_analysis_variables(frame_script)

        if self.pamda_instance.sasa_analysis:
            frame_script = self.set_sasa_analysis_variables(frame_script)

        frame_script = self.write_main_script_call(frame_script, "frame")

        self.write_tcl_tmp_file(frame_script, 'frame')

    def prepare_energies_analysis(self):
        """Write script to energy analysis"""

        log('info', 'Preparing tcl file for energies analysis.')

        energies_script = initialize_namespace()

        energies_script = self.set_common_variables(energies_script)

        energies_script = self.write_main_script_call(energies_script, "energies")

        self.write_tcl_tmp_file(energies_script, 'energies')

    def set_common_variables(self, tcl_script):
        """Set variables common to both frame and energies analysis"""

        tcl_script = set_variable(tcl_script, "md_path", self.pamda_instance.md_path)
        tcl_script = set_variable(tcl_script, "md_type", self.pamda_instance.md_type)
        tcl_script = set_variable(tcl_script, "str_path", self.pamda_instance.str_path)
        tcl_script = set_variable(tcl_script, "str_type", self.pamda_instance.str_type)
        tcl_script = set_variable(tcl_script, "program_src_path", self.pamda_instance.program_src_path)
        tcl_script = set_variable(tcl_script, "out_path", self.pamda_instance.out_path)
        tcl_script = set_variable(tcl_script, "out_name", self.pamda_instance.out_name)
        tcl_script = set_variable(tcl_script, "first_frame", self.pamda_instance.first_frame)
        tcl_script = set_variable(tcl_script, "last_frame", self.pamda_instance.last_frame)
        tcl_script = set_variable(tcl_script, "run_pbc", self.pamda_instance.run_pbc)
        return tcl_script

    def set_frame_variables(self, tcl_script):
        """Set variables for frame analysis"""

        tcl_script = set_variable(tcl_script, "kfi", self.pamda_instance.keep_frame_interval)
        tcl_script = set_variable(tcl_script, "rms_analysis", self.pamda_instance.rms_analysis)
        tcl_script = set_variable(tcl_script, "contacts_analysis", self.pamda_instance.contacts_analysis)
        tcl_script = set_variable(tcl_script, "distances_analysis", self.pamda_instance.distances_analysis)
        tcl_script = set_variable(tcl_script, "sasa_analysis", self.pamda_instance.sasa_analysis)
        return tcl_script

    def set_contacts_analysis_variables(self, tcl_script):
        """Set variables for contacts analysis"""

        tcl_script = set_variable(tcl_script, "cci", self.pamda_instance.contacts_interval)
        tcl_script = set_variable(tcl_script, "contacts_cutoff", self.pamda_instance.contacts_cutoff)
        tcl_script = set_variable(tcl_script, "contacts_hbond_angle", self.pamda_instance.contacts_h_angle)
        return tcl_script

    def set_distances_analysis_variables(self, tcl_script):
        """Set variables for distances analysis"""

        dist_pairs_names = '{' + ' '.join(self.pamda_instance.dist_pairs_names) + '}'

        tcl_script = set_variable(tcl_script, "dist_type", self.pamda_instance.dist_type)
        tcl_script = set_variable(tcl_script, "dist_pairs", self.pamda_instance.dist_pairs_tcl)
        tcl_script = set_variable(tcl_script, "dist_pairs_names", dist_pairs_names)
        return tcl_script

    def set_sasa_analysis_variables(self, tcl_script):
        """Set variables for SASA analysis"""

        if self.pamda_instance.highlight_residues:
            hgl_residues = '{' + ' '.join(self.pamda_instance.highlight_residues.keys()) + '}'
        else:
            hgl_residues = '{}'

        tcl_script = set_variable(tcl_script, "sasa_radius", self.pamda_instance.sasa_radius)
        tcl_script = set_variable(tcl_script, "ssi", self.pamda_instance.sasa_interval)
        tcl_script = set_variable(tcl_script, "hgl_residues", hgl_residues)
        return tcl_script

    def write_main_script_call(self, script, script_name):
        """Append source and function call to tcl script"""

        script.append("}\n")

        script_src = F"source {self.pamda_instance.program_src_path}tcl/{script_name}_analysis.tcl\n"
        script.append(script_src)

        script_call = F"pamda::{script_name}_analysis_main\n"
        script.append(script_call)

        return script

    def write_tcl_tmp_file(self, tcl_script, script_name):
        """Saves tcl script as temp file"""

        tmp_tcl_filename = self.pamda_instance.out_path + 'temp_' + script_name + '_analysis.tcl'
        with open(tmp_tcl_filename, 'w') as tmp_tcl_file:
            tmp_tcl_file.write(''.join(tcl_script))
            tmp_tcl_file.write("\nquit\n")


def initialize_namespace():
    """Initializes tcl namespace"""

    return ["namespace eval pamda {\n"]


def set_variable(script, variable_name, value):
    """Set a variable in namespace"""

    tab = "    "

    declare_variable = tab + 'variable ' + variable_name + ' ' + str(value) + '\n'
    script.append(declare_variable)
    return script
