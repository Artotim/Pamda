from src.arguments_parser import make_parser
from src.checkers import *
from src.tcl_writer import prepare_frame_analysis, prepare_energies
from src.run_analysis import start_frame_analysis, start_energies_analysis, start_score_analysis
from src.finish_and_clean import finish_analysis
from src.plotify import create_plots


class DynamicAnalysis:
    """Analysis a protein-peptide namd dynamics"""

    def __init__(self, **kwargs):
        self.dcd_path = os.path.abspath(kwargs['dcd'])
        self.pdb_path = os.path.abspath(kwargs['pdb'])
        self.psf_path = os.path.abspath(kwargs['psf'])

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
        """Main routine"""

        if not self.rmsd_analysis and not \
                self.score_analysis and not \
                self.energies_analysis and not \
                self.chimera_analysis:
            log('error', 'No analyze requested')
            return

        # Prepare files
        if not check_files(self.dcd_path, file_type="dcd") or \
                not check_files(self.pdb_path, file_type="pdb") or \
                not check_files(self.psf_path, file_type="psf"):
            return

        self.name = get_name(self.name, self.dcd_path)

        self.output = check_output(self.output, self.name)
        if not self.output:
            return

        create_outputs_dir(self.output, self.chimera_analysis, self.energies_analysis, self.rmsd_analysis,
                           self.score_analysis)

        self.vmd_exe = check_vmd(self.vmd_exe)
        if not self.vmd_exe:
            return

        if not check_chimera(self.chimera_analysis, self.output) or \
                not check_bin(self.score_analysis, self.analysis_path, 'rosetta') or \
                not check_bin(self.energies_analysis, self.analysis_path, 'namd') or \
                not check_r(self.plot_graphs, self.output):
            return

        self.last_frame = check_last_frame(self.last_frame, self.dcd_path, self.analysis_path)
        if not self.last_frame:
            return

        total = (self.last_frame - self.init_frame)

        self.chimera_contact_interval = check_interval('contact', self.chimera_contact_interval, total)
        self.scoring_interval = check_interval('score', self.scoring_interval, total)
        print()
        
        # Frame analysis
        if self.rmsd_analysis or self.score_analysis or self.chimera_analysis:
            prepare_frame_analysis(
                rmsd=self.rmsd_analysis,
                contact=self.chimera_analysis,
                cci=self.chimera_contact_interval,
                score=self.score_analysis,
                sci=self.scoring_interval,
                pdb=self.pdb_path,
                psf=self.psf_path,
                dcd=self.dcd_path,
                init=self.init_frame,
                final=self.last_frame,
                out=self.output,
                program_path=self.analysis_path
            )

            # Run frame analysis
            start_frame_analysis(
                out=self.output,
                name=self.name,
                vmd=self.vmd_exe,
                chimera=self.chimera_analysis,
                init=self.init_frame,
                last=self.last_frame,
                cci=self.chimera_contact_interval,
                program_path=self.analysis_path,
                pdb_path=self.pdb_path
            )
            print()

        # Energy analysis
        if self.energies_analysis:
            prepare_energies(
                psf=self.psf_path,
                pdb=self.pdb_path,
                dcd=self.dcd_path,
                out=self.output,
                init=self.init_frame,
                final=self.last_frame,
                program_path=self.analysis_path
            )

            # Run energy analysis
            start_energies_analysis(
                out=self.output,
                name=self.name,
                vmd=self.vmd_exe
            )
            print()

        # Score analysis
        if self.score_analysis:
            start_score_analysis(
                out=self.output,
                name=self.name,
                program_path=self.analysis_path,
                init=self.init_frame,
                final=self.last_frame,
                sci=self.scoring_interval
            )
            print()

        # Delete temp files and rename
        finish_analysis(
            chimera=self.chimera_analysis,
            score=self.score_analysis,
            energies=self.energies_analysis,
            rmsd=self.rmsd_analysis,
            out=self.output,
            name=self.name
        )
        print()

        # run R plots and analysis
        if self.plot_graphs:
            create_plots(
                chimera=self.chimera_analysis,
                score=self.score_analysis,
                energies=self.energies_analysis,
                rmsd=self.rmsd_analysis,
                program_path=self.analysis_path,
                out=self.output,
                name=self.name,
                init=self.init_frame,
                last=self.last_frame
            )
            print()

        log('info', 'Finished.')


if __name__ == '__main__':
    parser = make_parser()
    args = parser.parse_args()
    DynamicAnalysis(**vars(args))
