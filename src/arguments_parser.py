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
            parts = '[resi...]'
        elif action.nargs == 2:
            parts = '[all residue]'
        return parts


def make_parser():
    """Return parser with arguments for program"""

    idx_validator = IndexValidator()

    # noinspection PyTypeChecker
    parser = argparse.ArgumentParser(description='This software generates analysis data from a dynamic run between '
                                                 'protein-peptide interaction or single protein.',
                                     epilog="Made by artotim",
                                     usage='%(prog)s -d <dcd_file.dcd> --pdb <pdb_file.pdb> --psf <psf_file.pdf> '
                                           '-<analysis>',
                                     add_help=False,
                                     formatter_class=SubcommandHelpFormatter)

    required = parser.add_argument_group('Required')
    optional = parser.add_argument_group('Optional')

    required.add_argument('-dcd', metavar='', required=True,
                          help='Path to dcd file')
    required.add_argument('-pdb', metavar='', required=True,
                          help='Path to pdb file')
    required.add_argument('-psf', metavar='', required=True,
                          help='Path to psf file')

    optional.add_argument("-h", "--help", action="help",
                          help="Show this help message and exit")

    optional.add_argument("-n", "--name", metavar='',
                          help="Output name")
    optional.add_argument('-o', '--output', metavar='',
                          help='Output folder path')

    optional.add_argument('-i', '--init', default=0, type=int, metavar='',
                          help='Start analysis frame (default: first)')
    optional.add_argument('-l', '--last', type=int, metavar='',
                          help='End analysis frame (default: last)')

    optional.add_argument('-vmd', '--vmd-exe', default='vmd', metavar='',
                          help='Path to vmd executable')

    optional.add_argument('-dpair', '--dist-pair', type=idx_validator, metavar='', default=[], nargs=2, action='append',
                          help='Index pairs to measure distances. Use this argument once for each pair'
                               'Specify the chains using comma notation (i.e. 25:A)')
    optional.add_argument('-dtype', '--dist-type', metavar='', default='resid', choices=['atom', 'resid'],
                          help='Type of index passed as distance pairs. Must be atom or resid (default:resid)')

    optional.add_argument('-C', '--contact', action='store_true',
                          help='Run contact analysis')
    optional.add_argument('-cti', '--contact-interval', type=int, metavar='',
                          help='Analyse contact each frame interval')
    optional.add_argument('--cutoff', default=3, type=int, dest='contact_cutoff', metavar='',
                          help='Max angstroms range to look for contacts (default: 3)')

    optional.add_argument('-R', '--rmsd', action='store_true',
                          help='Run rmsd and rmsf analysis with vmd')

    optional.add_argument('-E', '--energies', action='store_true',
                          help='Run energies analysis with namd and vmd')

    optional.add_argument('-G', '--graphs', action='store_true',
                          help='Plot analysis graphs')

    optional.add_argument('--compare-rmsd', metavar='', dest='compare_rmsd', nargs=2,
                          help='Path to another rmsd analysis output files to compare stats in plot '
                               '(must include all and residue csv)')
    optional.add_argument('--compare-energies', metavar='', dest='compare_energies',
                          help='Path to another energies analysis output file to compare stats in plot')

    optional.add_argument('-cat', '--catalytic-site', type=idx_validator, metavar='', dest='cat', default=[], nargs='+',
                          help='Pass a list of residues to get measures and highlight in plots. '
                               'You can specify the chain with a colon')

    return parser
