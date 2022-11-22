import os

from src.color_log import docker_logger, log
from src.pre_run_routines import get_program_src_path, check_input_molecule_files, resolve_out_name, \
    create_output_main_dir, create_outputs_dir, check_vmd, check_dependencies, check_r, write_parameters_json
from src.md_info_routines import get_last_frame, decide_interval, get_molecule_chains, get_dist_pair_info, get_hgl_info
from src.tcl_writer import TclWriter
from src.vmd_runner import start_create_models, start_frame_analysis, start_energies_analysis
from src.analysis_helpers import create_rmsd_sd_out, merge_energies, delete_temp_files
from src.assert_out_analysis import verify_write_models_out, verify_frame_analysis_out, verify_energies_analysis_out
from src.plot_creator import create_plots


class NomeCriativo:
    """Analysis a molecular dynamics"""

    def __init__(self, **kwargs):
        self.md_path = os.path.abspath(kwargs['md'])
        self.md_type = None

        self.str_path = os.path.abspath(kwargs['str'])
        self.str_type = None

        self.program_src_path = get_program_src_path(__file__)

        self.out_path = kwargs['output']
        self.out_name = kwargs['name']

        self.first_frame = kwargs['first']
        self.last_frame = kwargs['last']

        self.vmd_exe = kwargs['vmd_exe']

        self.rms_analysis = kwargs['rms']

        self.contacts_analysis = kwargs['contacts']
        self.contacts_interval = kwargs['contacts_interval']
        self.contacts_cutoff = kwargs['contacts_cutoff']
        self.contacts_h_angle = kwargs['contacts_h_angle']

        self._dist_pairs = kwargs['dist_pair']
        self.distances_analysis = True if len(self._dist_pairs) > 0 else False
        self.dist_type = kwargs['dist_type']
        self.dist_pairs_names = None

        self.sasa_analysis = kwargs['sasa']
        self.sasa_radius = kwargs['sasa_radius']
        self.sasa_interval = kwargs['sasa_interval']

        self.energies_analysis = kwargs['energies']

        self.plot_graphs = kwargs['graphs']

        self.guess_chains = kwargs['guess_chains']
        self.run_pbc = kwargs['pbc']

        self.highlight_residues = kwargs['hgl']
        self.chains_list = []

        self.keep_frame_interval = None

        self._log_path = kwargs['log_path']

    def main(self):
        try:
            self.main_routine()
        except KeyboardInterrupt:
            log('error', 'Interrupted by user.')
        except AssertionError:
            log('error', 'Aborting.')
            exit(1)

    def main_routine(self):
        """Main program routine"""

        # Check Inputs
        self._enforce_analysis_requested()
        self._check_molecule_inputs()
        self.out_name = resolve_out_name(self.out_name, self.md_path)
        self._check_input_for_energies()

        # Create outputs
        self._create_outputs_directories()

        # Set docker logger path
        docker_logger.set_paths(self.out_path, self._log_path)

        # Check dependency programs
        self._check_dependencies()

        # Get md data
        self._resolve_frame_range()
        self._resolve_frame_analysis_intervals()

        # Create models
        first_frame_pdb = self._resolve_create_models()

        # Check molecule residues
        self._get_chains_list(first_frame_pdb)
        self._get_dist_pairs_info(first_frame_pdb)
        self.highlight_residues = get_hgl_info(self.highlight_residues, first_frame_pdb)

        # Create tcl writer
        tcl_writer = TclWriter(self)

        # Write analysis parameters
        self._resolve_write_parameters()

        # Start frame analysis
        self._resolve_frame_analysis(tcl_writer)

        # Start energies analysis
        self._resolve_energies_analysis(tcl_writer)

        # Delete temp files
        delete_temp_files(self.out_path, self.frame_analysis, self.energies_analysis)

        # Run R plots and analysis
        if self.plot_graphs:
            create_plots(self.analysis_request, self.program_src_path, self.out_path, self.out_name,
                         self.chains_list, self.highlight_residues)

        print()
        log('info', 'Finished.')

    def _enforce_analysis_requested(self):
        """Enforce any analysis was requested"""

        if not self.frame_analysis and not self.energies_analysis:
            log('error', 'No analysis requested')
            exit(1)

    def _check_molecule_inputs(self):
        """Check if molecule input files are valid"""

        self.md_type = check_input_molecule_files(self.md_path, file_type="dynamic")
        self.str_type = check_input_molecule_files(self.str_path, file_type="structure")

        if not self.md_type or not self.str_type:
            exit(1)

    def _check_input_for_energies(self):
        """Check if imputed structure file is a psf"""

        if self.energies_analysis:
            if self.str_type != "psf" or self.guess_chains:
                error_message = "Energies analysis currently only supports psf structure files"
                if self.guess_chains:
                    error_message += " and cannot be used with guess-chains option"

                log("error", error_message + ".")
                exit(1)

    def _create_outputs_directories(self):
        """Create an output directory and necessary subdirectories"""

        self.out_path = create_output_main_dir(self.out_path, self.out_name)
        if not self.out_path:
            exit(1)

        create_outputs_dir(self.out_path, self.analysis_request, self.plot_graphs)

    def _check_dependencies(self):
        """Check if dependencies are working"""

        self.vmd_exe = check_vmd(self.vmd_exe)

        if not self.vmd_exe or \
                not check_dependencies(self.energies_analysis, self.program_src_path) or \
                not check_r(self.plot_graphs, self.out_path):
            exit(1)

    def _resolve_frame_range(self):
        """Resolve last frame"""

        log('info', 'First frame set to: ' + str(self.first_frame) + '.')

        self.last_frame = get_last_frame(self.last_frame, self.md_path, self.md_type, self.program_src_path)
        if not self.last_frame:
            exit(1)

    def _resolve_frame_analysis_intervals(self):
        """Resolves intervals needed for vmd frame analysis"""

        total_frames = (self.last_frame - self.first_frame)

        if self.frame_analysis:
            kfi = total_frames // 500
            self.keep_frame_interval = kfi if kfi > 20 else 20

        if self.contacts_analysis:
            self.contacts_interval = decide_interval(self.contacts_interval, total_frames, "contacts")

        if self.sasa_analysis:
            self.sasa_interval = decide_interval(self.sasa_interval, total_frames, "SASA")

    def _resolve_create_models(self):
        """Create models for first and last frames"""

        print()
        create_models_args = [self.str_path, self.str_type, self.md_path, self.md_type, self.out_path, self.out_name,
                              self.first_frame, self.last_frame, self.run_pbc, self.guess_chains, self.program_src_path]

        start_create_models(self.out_path, self.out_name, self.vmd_exe, self.program_src_path, create_models_args)
        verify_write_models_out(self.out_path, self.out_name, "frame_models")

        if self.guess_chains:
            log('info', "Guessing chains.")

            guess_chains_name = F"{self.out_name}_guessed_chains"
            verify_write_models_out(self.out_path, guess_chains_name, "guess_chains_models")

            self.str_path = F"{self.out_path}models/{guess_chains_name}_first_analysis_frame.pdb"
            self.str_type = "pdb"
            return self.str_path

        else:
            return F"{self.out_path}models/{self.out_name}_first_analysis_frame.pdb"

    def _get_chains_list(self, first_frame_pdb):
        """Get molecule chains"""

        chains_list = get_molecule_chains(first_frame_pdb, self.program_src_path, self.vmd_exe)

        if self.contacts_analysis and len(chains_list) <= 1:
            log('error', 'Input molecule must have at least two chains to run contacts analysis between chains.')
            exit(1)
        elif len(chains_list) == 0:
            log('error', 'Failed to detect chains on input molecule. '
                         'Consider using --guess-chains option to automatically determine chains.')
            exit(1)
        else:
            log("info", "Detected chains: " + ", ".join(chains_list) + ".")
            self.chains_list = chains_list

    def _get_dist_pairs_info(self, first_frame_pdb):
        """Get data for each imputed index for distances analysis"""

        if not self.distances_analysis:
            return None

        log('info', 'Checking distances queries in generated PDB file.')

        self._dist_pairs, self.dist_pairs_names = get_dist_pair_info(self._dist_pairs, self.dist_type, first_frame_pdb)
        if not self._dist_pairs or not self.dist_pairs_names:
            exit(1)

    def _resolve_write_parameters(self):
        """Writes analysis request parameters to json file"""

        requested_analysis = []
        for analysis, requested in self.analysis_request.items():
            if requested:
                analysis = analysis.split("_")[0].capitalize().replace("Rms", "RMS").replace("Sasa", "SASA")
                requested_analysis.append(analysis)

        parameters = {
            "Name": self.out_name,
            "Md type": self.md_type,
            "Run pbc": str(self.run_pbc),
            "First analysed frame": f"{self.first_frame:,}",
            "Last analysed frame": f"{self.last_frame:,}",
            "Requested analysis": ", ".join(requested_analysis),
            "Chains": ", ".join(self.chains_list),
            "Guess chains": str(self.guess_chains)
        }

        if self.highlight_residues:
            parameters["Highlight residues"] = ", ".join(self.highlight_residues.values())
        if self.contacts_analysis:
            parameters["Contacts cutoff"] = str(self.contacts_cutoff)
        if self.contacts_analysis:
            parameters["Hydrogen Bonds angle cutoff"] = str(self.contacts_h_angle)
        if self.contacts_analysis:
            parameters["Contacts measurement interval"] = str(self.contacts_interval)
        if self.distances_analysis:
            parameters["Distances type"] = self.dist_type
        if self.distances_analysis:
            parameters["Distances pairs"] = ", ".join([pair.replace("to", " ") for pair in self.dist_pairs_names])
        if self.sasa_analysis:
            parameters["SASA radius"] = str(self.sasa_radius)
        if self.sasa_analysis:
            parameters["SASA measurement interval"] = str(self.sasa_interval)

        write_parameters_json(self.out_path, parameters)

    def _resolve_frame_analysis(self, tcl_writer):
        """Prepare and run frame analysis"""

        if self.frame_analysis:
            print()

            tcl_writer.prepare_frame_analysis()

            start_frame_analysis(self.out_path, self.out_name, self.vmd_exe)
            verify_frame_analysis_out(self.analysis_request, self.out_path, self.out_name, self.chains_list,
                                      self.highlight_residues)

            if self.rms_analysis:
                create_rmsd_sd_out(self.out_path, self.out_name)

    def _resolve_energies_analysis(self, tcl_writer):
        """Prepare and run energies analysis"""

        if self.energies_analysis:
            print()

            tcl_writer.prepare_energies_analysis()

            start_energies_analysis(self.out_path, self.out_name, self.vmd_exe)
            verify_energies_analysis_out(self.out_path, self.out_name, self.chains_list)
            merge_energies(self.out_path, self.out_name, self.first_frame, self.chains_list)

    @property
    def frame_analysis(self):
        """Returns if any frame analysis was requested"""

        if self.rms_analysis or self.contacts_analysis or self.distances_analysis or self.sasa_analysis:
            return True
        else:
            return False

    @property
    def analysis_request(self):
        """Returns dict with analysis requested"""

        analysis_request = {
            "rms_analysis": self.rms_analysis,
            "contacts_analysis": self.contacts_analysis,
            "distances_analysis": self.distances_analysis,
            "sasa_analysis": self.sasa_analysis,
            "energies_analysis": self.energies_analysis
        }

        return analysis_request

    @property
    def dist_pairs_tcl(self):
        """Returns dist pairs as used in tcl script"""

        flat_pair_list = []
        for pair in self._dist_pairs:
            pair_list = '{' + " ".join(pair) + '}'
            flat_pair_list.append(pair_list)

        dist_pairs_tcl_list = '{' + ' '.join(flat_pair_list) + '}'

        return dist_pairs_tcl_list
