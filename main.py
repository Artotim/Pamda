from src.arguments_parser import make_parser
from src.Pamda import Pamda


if __name__ == '__main__':
    parser = make_parser()
    args = parser.parse_args()
    dcd_analyser = Pamda(**vars(args))
    dcd_analyser.main()
