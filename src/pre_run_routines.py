import os
import subprocess

from src.color_log import log


def get_program_src_path(main_file):
    """Get program source directory path"""

    import sys

    if getattr(sys, 'frozen', False):
        application_path = os.path.dirname(sys.executable)
    else:
        application_path = os.path.dirname(os.path.abspath(main_file))

    return os.path.dirname(application_path) + '/'


def check_input_molecule_files(path, file_type, silent=False):
    """Check if required molecule input files exist and are the right type"""

    if file_type == "dynamic":
        accepted_types = ["dcd", "xtc"]
    else:
        accepted_types = ["psf", "pdb", "gro"]

    if not os.path.exists(path):
        log('error', 'Invalid ' + file_type + ' path: ' + path)
        return False

    if not silent:
        log('info', F'Checking {file_type} file.')

    file_extension = os.path.splitext(path)[1].replace(".", "")

    if not file_extension or file_extension not in accepted_types:
        log('error', F'Input "{path}" is not a valid {file_type} file.')
        return False
    else:
        return file_extension


def resolve_out_name(out_name, md_path, silent=False):
    """Get output name from md if not provided"""

    if not out_name:
        pathless_file = md_path.split('/')[-1]
        out_name = os.path.splitext(pathless_file)[0]

    if not silent:
        log('info', 'Naming out files with prefix: ' + out_name + '.')

    return out_name


def create_output_main_dir(out_path, out_name, silent=False):
    """Create output main directory if not exist"""

    if not out_path:
        out_path = os.path.abspath(out_name) + '/'
    else:
        out_path = os.path.abspath(out_path) + '/'

    if not os.path.exists(out_path):
        os.makedirs(out_path)
    else:
        if not silent:
            if len([i for i in os.listdir(out_path) if not i.startswith('.')]) > 0:
                log('warning', 'Output folder not empty. Results may be overwritten.')
            else:
                log('info', 'Creating output folder.')

    return out_path


def create_outputs_dir(out_path, analysis_request, plot_graphs):
    """Create the directories inside output main folder"""

    create_dir(out_path + 'logs')
    create_dir(out_path + 'models')

    create_outputs_sub_dir(out_path, analysis_request)

    if plot_graphs:
        create_dir(out_path + 'graphs')
        create_outputs_sub_dir(out_path + 'graphs/', analysis_request)


def create_outputs_sub_dir(out_path, analysis_request):
    """Create the subdirectories inside output folder"""
    if analysis_request["rms_analysis"]:
        create_dir(out_path + 'rms')

    if analysis_request["contacts_analysis"]:
        create_dir(out_path + 'contacts')

    if analysis_request["distances_analysis"]:
        create_dir(out_path + 'distances')

    if analysis_request["sasa_analysis"]:
        create_dir(out_path + 'sasa')

    if analysis_request["energies_analysis"]:
        create_dir(out_path + 'energies')


def create_dir(dir_path):
    """Creates a directory if not exists"""

    if not os.path.exists(dir_path):
        os.makedirs(dir_path)


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


def make_executable(path):
    """Make file executable"""

    mode = os.stat(path).st_mode
    mode |= (mode & 0o444) >> 2  # copy R bits to X
    os.chmod(path, mode)


def check_r(run_r, out_path):
    """Check if Rscript is running"""

    def finish_test(file, path):
        file.close()
        os.remove(path)

    if not run_r:
        return True

    log('info', 'Looking for R.')

    r_file_path = out_path + 'r_test.r'
    r_test = open(r_file_path, 'w')
    r_test.write('print("test")')

    cmd = ['Rscript', '--vanilla', r_file_path]

    try:
        run_test = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()

        if run_test[1].decode("utf-8") != '':
            log('error', 'R returned error:')
            print(run_test[1].decode("utf-8"))
            finish_test(r_test, r_file_path)
            return False

        else:
            finish_test(r_test, r_file_path)
            return True

    except (PermissionError, FileNotFoundError):
        log('error', 'R not found.')
        finish_test(r_test, r_file_path)
        return False


def write_parameters_json(out_path, parameters):
    """Write requested parameters to json file"""

    import json
    with open(out_path + 'analysis_request_parameters.json', 'w') as request_parameters_file:
        json.dump(parameters, request_parameters_file, indent=4)
