import os

from src.color_log import docker_logger, log
from src.checkers import check_analysis_path, check_files, get_name, check_output, check_vmd, check_dependencies, \
    check_r, check_last_frame, check_interval, create_outputs_dir, check_highlight, check_dist_names
from src.tcl_writer import TclWriter
from src.run_analysis import start_frame_analysis, start_energies_analysis
from src.finish_and_clean import finish_analysis
from src.plotify import create_plots


class DynamicAnalysis:
    """Analysis a protein-peptide namd dynamics"""

    def __init__(self, **kwargs):
        self.dcd_path = os.path.abspath(kwargs['dcd'])
        self.pdb_path = os.path.abspath(kwargs['pdb'])
        self.psf_path = os.path.abspath(kwargs['psf'])

        self.analysis_path = check_analysis_path(__file__)

        self.name = kwargs['name']
        self.output = kwargs['output']

        self.init_frame = kwargs['init']
        self.last_frame = kwargs['last']

        self._vmd_exe = kwargs['vmd_exe']

        self.rmsd_analysis = kwargs['rmsd']

        self.contact_analysis = kwargs['contact']
        self.contact_interval = kwargs['contact_interval']
        self.contact_cutoff = kwargs['contact_cutoff']

        self.energies_analysis = kwargs['energies']

        self._dist_pairs = kwargs['dist_pair']
        self.distances_analysis = True if len(self._dist_pairs) > 0 else False
        self.dist_type = kwargs['dist_type']
        self.dist_names = None

        self._plot_graphs = kwargs['graphs']

        self.highlight_residues = kwargs['hgl']

        self.wrapped = kwargs['wrapped']

        self.keep_frame_interval = None

        self._log_path = kwargs['log_path']

    def main(self):
        try:
            self.main_routine()
        except KeyboardInterrupt:
            log('error', 'Interrupted by user.')

    def main_routine(self):
        """Main routine for analysis"""

        # Check Inputs
        self._enforce_analysis_requested()
        self._enforce_valid_files()
        self.name = get_name(self.name, self.dcd_path)
        self.highlight_residues = check_highlight(self.highlight_residues, self.pdb_path)
        self._get_dist_names()

        # Check outputs
        self._enforce_output()
        create_outputs_dir(self.output, self.contact_analysis, self.energies_analysis,
                           self.rmsd_analysis, self.distances_analysis)

        # Set docker logger path
        docker_logger.set_paths(self.output, self._log_path)

        # Check programs
        self._get_vmd()
        self._check_dependencies()

        # Get dcd data
        self._resolve_last_frame()
        total_frames = (self.last_frame - self.init_frame)
        self._decide_keep_frame_interval(total_frames)
        self.contact_interval = check_interval(self.contact_analysis, 'contact', self.contact_interval, total_frames)

        # Create tcl writer
        tcl_writer = TclWriter(self)

        # Start frame analysis
        self._resolve_frame_analysis(tcl_writer)

        # Start energies analysis
        self._resolve_energies_analysis(tcl_writer)

        # Delete temp files and reformat output
        finish_analysis(self.contact_analysis, self.energies_analysis, self.distances_analysis, self.rmsd_analysis,
                        self.output, self.name, self.init_frame)

        # Run R plots and analysis
        if self._plot_graphs:
            create_plots(self)
        print()

        log('info', 'Finished.')

    def _enforce_analysis_requested(self):
        """Enforce any analysis was requested"""

        if not self.rmsd_analysis and \
                not self.energies_analysis and \
                not self.distances_analysis and \
                not self.contact_analysis:
            log('error', 'No analyze requested')
            exit(1)

    def _enforce_valid_files(self):
        """Enforce input files are valid"""

        if not check_files(self.dcd_path, file_type="dcd") or \
                not check_files(self.pdb_path, file_type="pdb") or \
                not check_files(self.psf_path, file_type="psf"):
            exit(1)

    def _enforce_output(self):
        """Enforce output is valid and can be created"""

        self.output = check_output(self.output, self.name)
        if not self.output:
            exit(1)

    def _get_vmd(self):
        """Find vmd executable"""

        self._vmd_exe = check_vmd(self._vmd_exe)
        if not self._vmd_exe:
            exit(1)

    def _check_dependencies(self):
        """Check if dependencies are working"""

        if not check_dependencies(self.energies_analysis, self.analysis_path) or \
                not check_r(self._plot_graphs, self.output):
            exit(1)

    def _resolve_last_frame(self):
        """Resolve last frame"""

        self.last_frame = check_last_frame(self.last_frame, self.dcd_path, self.analysis_path)
        if not self.last_frame:
            exit(1)

    def _decide_keep_frame_interval(self, total_frames):
        """Resolves interval to keep frames on memory for reference"""

        if self.rmsd_analysis or self.contact_analysis or self.distances_analysis:
            kfi = total_frames // 500
            self.keep_frame_interval = kfi if kfi > 20 else 20

    def _resolve_frame_analysis(self, tcl_writer):
        """Prepare and run frame analysis"""

        if self.rmsd_analysis or self.contact_analysis or self.distances_analysis:
            print()

            tcl_writer.prepare_frame_analysis()
            start_frame_analysis(self.output, self.name, self._vmd_exe)

    def _resolve_energies_analysis(self, tcl_writer):
        """Prepare and run energies analysis"""

        if self.energies_analysis:
            print()

            tcl_writer.prepare_energies_analysis()
            start_energies_analysis(self.output, self.name, self._vmd_exe)

    def _get_dist_names(self):
        """Get data for each imputed index for distance measure"""

        log('info', 'Checking distance queries in PDB file.')

        if not self.distances_analysis:
            return None

        self.dist_names = check_dist_names(self._dist_pairs, self.dist_type, self.pdb_path)
        if not self.dist_names:
            exit(1)

    @property
    def dist_pairs(self):
        """Returns dist pairs as used in tcl script"""

        flat_list = []
        for sublist in self._dist_pairs:
            for item in sublist:
                item = '{' + item + '}'
                item = item.replace(':', ' and chain ')
                flat_list.append(item)

        return flat_list
