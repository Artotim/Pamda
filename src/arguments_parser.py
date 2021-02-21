import argparse


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

    # noinspection PyTypeChecker
    parser = argparse.ArgumentParser(description='This software generates analysis data from a dynamic run between '
                                                 'protein-peptide interaction or single protein.',
                                     epilog="Made by artotim",
                                     usage='%(prog)s -d <dcd_file.dcd> --pdb <pdb_file.pdb> --psf <psf_file.pdf> '
                                           '-C -S -R -E -G',
                                     add_help=False,
                                     formatter_class=SubcommandHelpFormatter)

    required = parser.add_argument_group('Required')
    optional = parser.add_argument_group('Optional')

    required.add_argument('-d', '--dcd', metavar='',  required=True,
                          help='Path to dcd file')
    required.add_argument('-pdb', metavar='',  required=True,
                          help='Path to pdb file')
    required.add_argument('-psf', metavar='',  required=True,
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

    optional.add_argument('-S', '--score', action='store_true',
                          help='Run binding score analysis with rosetta')
    optional.add_argument('-sci', '--scoring-interval', type=int, metavar='',
                          help='Analyse score function each frame interval')

    optional.add_argument('-C', '--chimera', action='store_true',
                          help='Run contact map analysis with chimera')
    optional.add_argument('-cti', '--contact-interval', type=int, metavar='',
                          help='Analyse contact each frame interval')

    optional.add_argument('-R', '--rmsd', action='store_true',
                          help='Run rmsd and rmsf analysis with vmd')

    optional.add_argument('-E', '--energies', action='store_true',
                          help='Run energies analysis with namd and vmd')

    optional.add_argument('-G', '--graphs', action='store_true',
                          help='Plot analysis graphs')

    optional.add_argument('--alone-rmsd', metavar='', dest='alone_rmsd', nargs=2,
                          help='Path to alone output rmsd files to compare stats (must include all and residue csv)')
    optional.add_argument('--alone-energies', metavar='', dest='alone_energies',
                          help='Path to alone output energies file to compare stats')

    optional.add_argument('-cat', '--catalytic-site', type=int, metavar='', dest='cat', default=[], nargs='+',
                          help='Pass a list of residues to display on graphs and get specific plots')

    return parser
