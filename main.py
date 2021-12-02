from src.arguments_parser import make_parser
from src.DynamicAnalysis import DynamicAnalysis


if __name__ == '__main__':
    parser = make_parser()
    args = parser.parse_args()
    dcd_analyser = DynamicAnalysis(**vars(args))
    dcd_analyser.main()
