import os
from src.color_log import log
import subprocess


def check_analysis_path(main_file):
    import sys

    if getattr(sys, 'frozen', False):
        application_path = os.path.dirname(sys.executable)
    else:
        application_path = os.path.dirname(os.path.abspath(main_file))

    return os.path.dirname(application_path) + '/'


def check_files(path, file_type):
    """Check if required files exist and are right"""

    if not os.path.exists(path):
        log('error', 'Invalid ' + file_type + ' path: ' + path)
        return False

    if file_type == 'dcd':
        log('info', 'Checking dcd file')
        if path.endswith('.dcd'):
            return True
        else:
            log('error', 'Please input a valid .dcd file')

    elif file_type == 'pdb':
        log('info', 'Checking pdb file')
        if path.endswith('.pdb'):
            return True
        else:
            log('error', 'Please input a valid .dcd file')

    elif file_type == 'psf':
        log('info', 'Checking psf file')
        if path.endswith('.psf'):
            return True
        else:
            log('error', 'Please input a valid .dcd file')

    return False


def get_name(name, dcd):
    """Get complex name"""

    if not name:
        pathless_file = dcd.split('/')[-1]
        name = pathless_file.split('.dcd')[0]

    log('info', 'Naming out files prefix: ' + name + '.')
    return name


def check_output(path, name):
    """Resolve output path"""

    if not path:
        path = os.path.abspath(name) + '/'
    else:
        path = os.path.abspath(path) + '/'

    if not os.path.exists(path):
        os.makedirs(path)
    else:
        if len(os.listdir(path)) != 0:
            log('error', 'Output folder not empty.')
            return False

    log('info', 'Setting output folder.')
    return path


def check_vmd(vmd):
    """Check for vmd exe"""

    log('info', 'Looking for vmd.')

    try:
        vmd_test = subprocess.Popen(vmd, stdout=subprocess.PIPE, stdin=subprocess.PIPE, stderr=subprocess.STDOUT)
        vmd_test.communicate(input=b'quit')
        return vmd

    except (PermissionError, FileNotFoundError):
        log('error', 'Vmd not found.')
        return False


def check_bin(run_program, dir_path, program):
    """Check bin archives for rosetta and namd"""

    if not run_program:
        return True

    if program == "namd":
        log('info', 'Looking for namd.')
        path = dir_path + 'namd/namd2'
    else:
        return False

    if os.access(path, os.X_OK):
        return True
    else:
        log('warning', 'Trying to convert ' + program + ' to executable.')
        make_executable(path)

        if os.access(path, os.X_OK):
            log('info', 'Success.')
            return True
        else:
            log('error', 'Program not responding: ' + program + '.')
            return False


def check_r(run_r, out_path):
    """Check if Rscript is running"""

    if not run_r:
        return True

    log('info', 'Looking for R.')

    path = out_path + 'r_test.r'
    r_test = open(path, 'w')
    r_test.write('print("test")')

    cmd = ['Rscript', '--vanilla', path]

    try:
        run_test = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()

        if run_test[1].decode("utf-8") != '':
            log('error', 'R returned error:')
            print(run_test[1].decode("utf-8"))
            finish_test(r_test, path)
            return False

        else:
            finish_test(r_test, path)
            return True

    except (PermissionError, FileNotFoundError):
        log('error', 'R not found.')
        finish_test(r_test, path)
        return False


def finish_test(file, path):
    """Remove tests files"""

    file.close()
    os.remove(path)


def check_last_frame(last_frame, dcd, dir_path):
    """Check last frame using catdcd"""

    if not last_frame:
        log('info', 'Using catdcd to determine last frame.')
        path = dir_path + 'countdcd/catdcd'

        if os.access(path, os.X_OK):
            cmd = [path, dcd]
            run_test = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()

            frames = run_test[0].decode("utf-8").find("Total frames:")
            new_line = run_test[0][frames:].decode("utf-8").find('\n')

            total_frames = run_test[0][(frames + 14):(frames + new_line)].decode("utf-8")
            last_frame = int(total_frames)

        else:
            make_executable(path)
            if os.access(path, os.X_OK):
                check_last_frame(last_frame, dcd, dir_path)
            else:
                log('error', 'Catdcd failed. Specify last frame with "-l".')
                return False

    log('info', 'Last frame set to: ' + str(last_frame) + '.')
    return last_frame


def check_interval(analysis, module, interval, total_frames):
    """Resolves analysis interval for contact and score"""

    if not analysis:
        return 0

    if not interval:
        if module == 'contact':
            if total_frames <= 1000:
                interval = 10
            else:
                interval = 100

    log('info', 'Analyzing ' + module + ' each ' + str(interval) + ' frames.')
    return interval


def make_executable(path):
    """Make file in executable"""

    mode = os.stat(path).st_mode
    mode |= (mode & 0o444) >> 2  # copy R bits to X
    os.chmod(path, mode)


def create_outputs_dir(out, contact, energies, rmsd, distances):
    """Create the output folders"""

    path = out + 'logs'
    os.makedirs(path)

    path = out + 'models'
    os.makedirs(path)

    if contact:
        path = out + 'contact'
        os.makedirs(path)

    if energies:
        path = out + 'energies'
        os.makedirs(path)

    if rmsd:
        path = out + 'rmsd'
        os.makedirs(path)

    if distances:
        path = out + 'distances'
        os.makedirs(path)


def check_compare_files(compare_rmsd, compare_energies):
    """Resolves compare files path"""

    if compare_rmsd is not None and compare_energies is not None:
        log('info', 'Analyzing compare path to compare.')

    compare_files = dict()

    if compare_rmsd is not None:
        for rmsd_file in compare_rmsd:
            rmsd_file = os.path.abspath(rmsd_file)
            if not os.path.exists(rmsd_file) or not rmsd_file.endswith(".csv"):
                log('error', 'Invalid csv path: ' + rmsd_file)
                return False

        with open(compare_rmsd[0], 'r') as first, open(compare_rmsd[1], 'r') as second:
            fisrt_size = len(first.readline().split(';'))
            second_size = len(second.readline().split(';'))
            compare_rmsd = compare_rmsd[::-1] if fisrt_size > second_size else compare_rmsd

    compare_files['rmsd'] = compare_rmsd

    if compare_energies is not None:
        compare_energies = os.path.abspath(compare_energies)
        if not os.path.exists(compare_energies) or not compare_energies.endswith(".csv"):
            log('error', 'Invalid csv path: ' + compare_energies)
            return False
        compare_energies = [compare_energies]

    compare_files['energies'] = compare_energies

    return compare_files


def check_catalytic(catalytic, pdb):
    """Resolves catalytic site residues names"""

    if len(catalytic) == 0:
        return False

    log('info', 'Checking catalytic residues in PDB file.')

    catalytic_data = {}

    for resid in catalytic:
        resid_data = get_pdb_by_idx(resid, pdb, 'resid')

        if not resid_data:
            log('warning', 'Could not define residues name \"' + resid +
                '\" in imputed catalytic site. This may affect plots.')
            resid_data = [resid.split(':')[0], '']

        catalytic_data[resid_data[0]] = resid_data[1].split(':')[1]

    return catalytic_data


def check_dist_names(dist_pairs, dist_type, pdb):

    dist_names = []

    for pair in dist_pairs:
        pair_names = []
        for query in pair:
            query_data = get_pdb_by_idx(query, pdb, dist_type)

            if not query_data:
                query_input = query.split(':')

                if len(query_input) > 1:
                    log('error', 'Could not find ' + dist_type + ' index: ' + query_input[0] +
                        ', in chain: ' + query_input[1] + '.')
                else:
                    log('error', 'Could not find ' + dist_type + ' index: ' + query_input[0] + '.')

            else:
                pair_names.append(query_data[1])
        dist_names.append('to'.join(pair_names))

    if len(dist_names) != len(dist_pairs):
        exit(1)

    return dist_names


def get_pdb_by_idx(query, pdb, idx_type):
    """Get query indexes data in pdb file"""

    column = 1 if idx_type == 'atom' else 5

    query_info = query.split(':')
    query_number = query_info[0]

    with open(pdb, 'r') as pdb_file:
        for line in pdb_file:
            line_elements = line.split()
            try:
                if line_elements[column] == query_number:
                    chain = line_elements[4]
                    residue = line_elements[3].replace('HSD', 'HIS')
                    atom = line_elements[2]

                    if len(query_info) > 1:
                        if chain != query_info[1]:
                            continue

                    if idx_type == 'resid':
                        result = [query_number, chain + ":" + residue]
                    else:
                        result = [query_number , chain + ":" + residue + ":" + atom]

                    break

            except IndexError:
                continue

    if not result:
        return None
    else:
        return result
