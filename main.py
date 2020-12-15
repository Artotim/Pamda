from src.arguments_parser import make_parser
from src.checkers import *
from src.tcl_writer import prepare_bigdcd, prepare_energies
from src.run_analysis import start_bigdcd, start_energies, start_scoring
from src.finish_and_clean import finisher


class DynamicAnalysis:
    """Analysis a namd dynamics"""

    def __init__(self, **kwargs):
        self.dcd_path = 'oi'  # os.path.abspath(kwargs['dcd'])
        self.pdb_path = 'oi'  # os.path.abspath(kwargs['pdb'])
        self.psf_path = 'oi'  # os.path.abspath(kwargs['psf'])

        self.analysis_path = os.path.dirname(os.path.abspath(__file__)) + '/'

        self.name = kwargs['name']
        self.output = kwargs['output']

        self.init_frame = kwargs['init']
        self.last_frame = kwargs['last']

        self.vmd_exe = kwargs['vmd_exe']

        self.rmsd_analysis = kwargs['rmsd']

        self.chimera_analysis = kwargs['chimera']
        self.chimera_contact_interval = kwargs['contact_interval']

        self.energies_analysis = kwargs['energies']

        self.score_analysis = kwargs['score']
        self.scoring_interval = kwargs['scoring_interval']

        self.plot_graphs = kwargs['graphs']

        try:
            self.main()
        except KeyboardInterrupt:
            log('error', 'Interrupted by user.')

    def main(self):

        if not self.rmsd_analysis and not \
                self.score_analysis and not \
                self.energies_analysis and not \
                self.chimera_analysis:
            log('error', 'No analyze requested')
            return

        # prepare files
        # if not check_files(self.dcd_path, file_type="dcd") or \
        #         not check_files(self.pdb_path, file_type="pdb") or \
        #         not check_files(self.psf_path, file_type="psf"):
        #     return

        complex_name = get_name(self.name, self.dcd_path)

        self.output = check_output(self.output, complex_name)
        # if not self.output:
        #     return
        create_outputs_dir(self.output, self.chimera_analysis, self.energies_analysis, self.rmsd_analysis,
                           self.score_analysis)

        # self.vmd_exe = check_exe(self.vmd_exe, self.energies_analysis, self.rmsd_analysis, self.chimera_analysis)
        # if not self.vmd_exe: return

        # if not check_chimera(self.chimera_analysis, self.analysis_path): return
        # if not check_rosetta(self.score_analysis, self.analysis_path): return
        # if not check_r(self.plot_graphs): return

        # self.last_frame = check_last(self.last_frame, self.dcd_path, self.analysis_path)
        # total = self.last_frame - self.init_frame

        # self.chimera_contact_interval = check_interval('contact', self.chimera_contact_interval, total)
        # self.scoring_interval = check_interval('score', self.scoring_interval, total)

        # prepare vmd script
        if self.rmsd_analysis or self.score_analysis or self.chimera_analysis:
            prepare_bigdcd(rmsd=self.rmsd_analysis,
                           contact=self.chimera_analysis,
                           cci=self.chimera_contact_interval,
                           score=self.score_analysis,
                           sci=self.scoring_interval,
                           pdb=self.pdb_path,
                           psf=self.psf_path,
                           dcd=self.dcd_path,
                           init=self.init_frame,
                           final=self.last_frame,
                           out=self.output)

            # run vmd with contact
            # start_bigdcd(self.output, self.name, self.vmd_exe, self.chimera_analysis, self.init_frame, self.last_frame,
            #              self.chimera_contact_interval)

        # run energies
        if self.energies_analysis:
            prepare_energies(psf=self.psf_path,
                             pdb=self.pdb_path,
                             dcd=self.dcd_path,
                             out=self.output,
                             init=self.init_frame,
                             final=self.last_frame,
                             dir_path=self.analysis_path)
            # start_energies(self.output, self.name, self.vmd_exe)

        # run scoring
        # if self.score_analysis:
            # start_scoring(self.output, self.analysis_path)

        # delete temps and make out files
        finisher(self.chimera_analysis, self.score_analysis, self.energies_analysis, self.rmsd_analysis, self.output, self.name)


        # run R plots and analysis


if __name__ == '__main__':
    parser = make_parser()
    args = parser.parse_args()
    DynamicAnalysis(**vars(args))
    # parser.print_help()
    # print(args)
