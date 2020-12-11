import argparse


def make_parser():
    """Return parser with arguments for program"""

    # noinspection PyTypeChecker
    parser = argparse.ArgumentParser(description='Make dynamics analysis.',
                                     epilog="Made by artotim",
                                     usage='%(prog)s -d <dcd_file.dcd> -m <path/to/models/> -C -E -R -S -G',
                                     add_help=False)
    required = parser.add_argument_group('Required')
    optional = parser.add_argument_group('Optional')

    required.add_argument('-d', '--dcd', metavar='', #required=True,
                          help='Dcd file')
    required.add_argument('-pdb', metavar='', #required=True,
                          help='Pdb file')
    required.add_argument('-psf', metavar='', #required=True,
                          help='Psf file')
    optional.add_argument("-h", "--help", action="help",
                          help="Show this help message and exit")
    optional.add_argument("-n", "--name", metavar='',
                          help="Output name")
    optional.add_argument('-o', '--output', metavar='',
                          help='Output folder')
    optional.add_argument('-i', '--init', default=0, type=int, metavar='',
                          help='Start analysis frame (default: first)')
    optional.add_argument('-l', '--last', type=int, metavar='',
                          help='Stop analysis frame (default: last)')
    optional.add_argument('-vmd', '--vmd-exe', default='vmd', metavar='',
                          help='Path to vmd executable')

    optional.add_argument('-S', '--score', action='store_false',
                          help='Allows contact map analysis with rosetta')
    optional.add_argument('-sci', '--scoring-interval', type=int, metavar='',
                          help='Run score function each frame interval')

    optional.add_argument('-C', '--chimera', action='store_false',
                          help='Allows contact map analysis with chimera')
    optional.add_argument('-cti', '--contact-interval', type=int, metavar='',
                          help='Run contact analysis each frame interval')

    optional.add_argument('-R', '--rmsd', action='store_false',
                          help='Allows rmsd and rmsf analysis with vmd')

    optional.add_argument('-E', '--energies', action='store_false',
                          help='Allows energies analysis with namd and vmd')

    optional.add_argument('-G', '--graphs', action='store_true',
                          help='Plot analysis graphs')

    return parser
