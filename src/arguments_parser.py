import argparse
import re


class IndexValidator(object):

    def __init__(self):
        self._pattern = re.compile(r"^[\d]+(:\w)?$")

    def __call__(self, value):
        if not self._pattern.match(value):
            raise argparse.ArgumentTypeError(
                "Argument has to match 'index' or 'index:chain'".format(self._pattern.pattern))
        return value


class SubcommandHelpFormatter(argparse.RawDescriptionHelpFormatter):
    """Heleper format to exclude empty list on nargs +"""

    def _format_args(self, action, default_metavar):
        parts = super(argparse.RawDescriptionHelpFormatter, self)._format_args(action, default_metavar)
        if action.nargs == '+':
            parts = '[resid list]'
        elif action.nargs == 2:
            parts = '[index pair]'
        return parts


def make_parser():
    """Return parser with arguments for program"""

    idx_validator = IndexValidator()

    # noinspection PyTypeChecker
    parser = argparse.ArgumentParser(description='Program written to facilitate molecular dynamic analysis.',
                                     epilog="Made by artotim",
                                     usage='%(prog)s -md <md_file> -str <structure_file> -<analysis>',
                                     add_help=False,
                                     formatter_class=SubcommandHelpFormatter)

    required = parser.add_argument_group('Required')
    optional = parser.add_argument_group('Optional')

    required.add_argument('-md', metavar='', required=True,
                          help='Path to molecular dynamic file')
    required.add_argument('-str', metavar='', required=True,
                          help='Path to structure file')

    optional.add_argument("-h", "--help", action="help",
                          help="Show this help message and exit")

    optional.add_argument('-o', '--output', metavar='',
                          help='Output folder path')
    optional.add_argument("-n", "--name", metavar='',
                          help="Output name")

    optional.add_argument('-f', '--first', default=0, type=int, metavar='',
                          help='Start analysis frame (default: first)')
    optional.add_argument('-l', '--last', type=int, metavar='',
                          help='End analysis frame (default: last)')

    optional.add_argument('-vmd', '--vmd-exe', default='vmd', metavar='',
                          help='Path to vmd executable')

    optional.add_argument('-R', '--rms', action='store_true',
                          help='Run RMSD and RMSF analysis')

    optional.add_argument('-C', '--contacts', action='store_true',
                          help='Run contacts analysis')
    optional.add_argument('--contacts-cutoff', default=3, type=float, dest='contacts_cutoff', metavar='',
                          help='Max Angstroms range to look for contacts (default: 3)')
    optional.add_argument('-cci', '--contacts-interval', dest='contacts_interval', type=int, metavar='',
                          help='Frame interval to analyse contacts')

    optional.add_argument('-dpair', '--dist-pair', type=idx_validator, metavar='', default=[], nargs=2, action='append',
                          help='Index pairs to measure distances. Use this argument once for each pair. '
                               'Specify the chains using comma notation (i.e. 25:A)')
    optional.add_argument('-dtype', '--dist-type', metavar='', default='resid', choices=['atom', 'resid'],
                          help='Type of index passed as distance pairs. Must be atom or resid (default: resid)')

    optional.add_argument('-S', '--sasa', action='store_true',
                          help='Run SASA analysis')
    optional.add_argument('--sasa-radius', dest='sasa_radius', type=float, metavar='', default=1.4,
                          help='Radius to analyze SASA (default: 1.4')
    optional.add_argument('-ssi', '--sasa-interval', dest='sasa_interval', type=int, metavar='',
                          help='Frame interval to analyse SASA')

    optional.add_argument('-E', '--energies', action='store_true',
                          help='Run energies analysis')

    optional.add_argument('-G', '--graphs', action='store_true',
                          help='Plot analysis graphs')

    optional.add_argument('--guess-chains', action='store_true', dest='guess_chains',
                          help='Automatically try to guess and split chains')
    optional.add_argument('-pbc', action='store_true',
                          help='Unwraps molecule before analysis. '
                               'Use this flag only if you wrapped your protein during dynamic')

    optional.add_argument('-hgl', '--highlight', type=idx_validator, metavar='', dest='hgl', default=[], nargs='+',
                          help='List of residues to generate separated measures and highlight in plots. '
                               'Specify the chains using comma notation (i.e. 25:A)')

    optional.add_argument('--log_path', help=argparse.SUPPRESS)

    return parser
