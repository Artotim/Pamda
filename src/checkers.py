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


def check_files(path, file_type, silent=False):
    """Check if required files exist and are right"""

    if not os.path.exists(path):
        log('error', 'Invalid ' + file_type + ' path: ' + path)
        return False

    if not silent:
        log('info', F'Checking {file_type} file.')

    if path.endswith(file_type):
        return True
    else:
        log('error', F'Input "{path}" is not a valid {file_type} file.')
        return False


def get_name(name, dcd, silent=False):
    """Get complex name"""

    if not name:
        pathless_file = dcd.split('/')[-1]
        name = pathless_file.split('.dcd')[0]

    if not silent:
        log('info', 'Naming out files prefix: ' + name + '.')

    return name


def check_output(path, name, silent=False):
    """Resolve output path"""

    if not path:
        path = os.path.abspath(name) + '/'
    else:
        path = os.path.abspath(path) + '/'

    if not os.path.exists(path):
        os.makedirs(path)
    else:
        if len([i for i in os.listdir(path) if not i.startswith('.')]) > 0:
            log('error', 'Output folder not empty.')
            return False

    if not silent:
        log('info', 'Setting output folder.')

    return path


def check_vmd(vmd, silent=False):
    """Check for vmd exe"""

    if not silent:
        log('info', 'Looking for VMD.')

    vmd_path = os.path.abspath(vmd)

    def _test_vmd(test_vmd):
        vmd_test = subprocess.Popen(test_vmd, stdout=subprocess.PIPE, stdin=subprocess.PIPE, stderr=subprocess.STDOUT)
        vmd_test.communicate(input=b'quit')

    try:
        _test_vmd(vmd_path)
        return vmd_path

    except (PermissionError, FileNotFoundError):
        try:
            _test_vmd(vmd)
            return vmd

        except (PermissionError, FileNotFoundError):
            log('error', 'Vmd not found.')
            return False


def check_dependencies(energies_analysis, dir_path):
    """Check for dependencies"""

    if not energies_analysis:
        return True

    log('info', 'Checking dependencies.')

    path = dir_path + 'dependencies/namdenergy/namdenergy'

    if os.access(path, os.X_OK):
        return True
    else:
        log('warning', 'Trying to convert dependence to executable.')
        make_executable(path)

        if os.access(path, os.X_OK):
            log('info', 'Success.')
            return True
        else:
            log('error', F'A dependence in {path} did not respond.')
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
        path = dir_path + 'dependencies/catdcd/catdcd'

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


def check_highlight(highlight, pdb):
    """Resolves highlight residues names"""

    if len(highlight) == 0:
        return False

    log('info', 'Checking residues to highlight in PDB file.')

    highlight_data = {}

    for resid in highlight:
        resid_data = get_pdb_by_idx(resid, pdb, 'resid')

        if not resid_data:
            log('warning', 'Could not define residues name \"' + resid +
                '\" in imputed highlight option. This may affect plots.')
            resid_data = [resid.split(':')[0], '']

        highlight_data[resid_data[0]] = resid_data[1]

    return highlight_data


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
    result = False

    with open(pdb, 'r') as pdb_file:
        for line in pdb_file:
            line_elements = line.split()
            try:
                if line_elements[column] == query_number:
                    chain = line_elements[4]
                    resname = line_elements[3].replace('HSD', 'HIS')
                    atom = line_elements[2]

                    if len(query_info) > 1:
                        if chain != query_info[1]:
                            continue

                    if idx_type == 'resid':
                        result = [query_number, chain + ":" + resname + ":" + str(query_number)]
                    else:
                        result = [query_number, chain + ":" + resname + ":" + str(query_number) + ":" + atom]

                    break

            except IndexError:
                continue

    if not result:
        return None
    else:
        return result
