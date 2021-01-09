import os
from src.color_log import log
import subprocess


def check_analysis_path(main_file):
    import sys

    if getattr(sys, 'frozen', False):
        application_path = os.path.dirname(sys.executable)
    else:
        application_path = os.path.dirname(os.path.abspath(main_file))

    return application_path + '/'


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


def check_chimera(run_chimera, out_path):
    """Check if chimera is running"""

    if not run_chimera:
        return True

    log('info', 'Looking for chimera.')

    path = out_path + 'chimera_test.py'
    chimera_test = open(path, 'w')
    chimera_test.write('import chimera')

    cmd = ['python', '-m', 'pychimera', path]

    try:
        run_test = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
        if run_test[1].decode("utf-8") != '':
            log('error', 'Chimera returned error:')
            print(run_test[1].decode("utf-8"))
            finish_test(chimera_test, path)
            return False

        else:
            finish_test(chimera_test, path)
            return True

    except (PermissionError, FileNotFoundError):
        log('error', 'Chimera not found.')
        finish_test(chimera_test, path)
        return False


def check_bin(run_program, dir_path, program):
    """Check bin archives for rosetta and namd"""

    if not run_program:
        return True

    if program == "rosetta":
        log('info', 'Looking for rosetta.')
        path = dir_path + 'rosetta/main/source/bin/relax.static.linuxgccrelease'
    else:
        log('info', 'Looking for namd.')
        path = dir_path + 'namd/namd2'

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
        if module == 'score':
            interval = total_frames // 5

        elif module == 'contact':
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


def create_outputs_dir(out, chimera, energies, rmsd, score):
    """Create the output folders"""

    path = out + 'logs'
    os.makedirs(path)

    path = out + 'models'
    os.makedirs(path)

    if chimera:
        path = out + 'contact'
        os.makedirs(path)

    if energies:
        path = out + 'energies'
        os.makedirs(path)

    if rmsd:
        path = out + 'rmsd'
        os.makedirs(path)

    if score:
        path = out + 'score'
        os.makedirs(path)
