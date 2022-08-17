from src.arguments_parser import make_parser
from src.NomeCriativo import NomeCriativo


if __name__ == '__main__':
    parser = make_parser()
    args = parser.parse_args()
    dcd_analyser = NomeCriativo(**vars(args))
    dcd_analyser.main()
