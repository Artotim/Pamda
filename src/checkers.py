import os
from src.color_log import log
import subprocess


def check_files(path, file_type):
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
    if name:
        return name

    pathless_file = dcd.split('/')[-1]
    return pathless_file.split('.dcd')[0]


def check_output(path, name):
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


def check_exe(program, *usage):
    if True not in usage:
        return True

    log('info', 'Looking for ' + program + '.')
    try:
        subprocess.Popen(program, subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    except (PermissionError, FileNotFoundError):
        log('error', 'Program not found: ' + program + '.')


def check_chimera(run_chimera, dir_path):
    if not run_chimera:
        return True

    log('info', 'Looking for chimera.')

    path = dir_path + 'chimera/chimera_test.py'
    chimera_test = open(path, 'w')
    chimera_test.write('import chimera')

    cmd = ['python', '-m', 'pychimera', path]

    run_test = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()

    os.remove(path)

    if run_test[1].decode("utf-8") != '':
        log('error', 'Chimera not found.')
        return False
    else:
        return True


def check_rosetta(run_rosetta, dir_path):
    if not run_rosetta:
        return True

    log('info', 'Looking for rosetta.')
    path = dir_path + 'rosetta/main/source/bin/relax.static.linuxgccrelease'

    if os.access(path, os.X_OK):
        return True
    else:
        make_executable(path)
        if os.access(path, os.X_OK):
            return True
        else:
            log('error', 'Rosetta not found.')
            return False


def check_r(run_r):
    if not run_r:
        return True

    log('info', 'Looking for R.')

    try:
        import rpy2.robjecsts as ro

    except OSError:
        log('error', 'R not found.')
        return False

    except ModuleNotFoundError:
        try:
            log('info', 'Installing "rpy2"')
            install_package('rpy2')
            check_r(run_r)

        except PermissionError:
            log('error', 'Could not install python module "rpy2". Permission denied.')
            return False


def install_package(package):
    import pip

    if hasattr(pip, 'main'):
        pip.main(['install', package])
    else:
        pip._internal.main(['install', package])


def check_last(last_frame, dcd, dir_path):
    if last_frame:
        return last_frame

    path = dir_path + 'countdcd/catdcd'

    if os.access(path, os.X_OK):
        cmd = [path, dcd]
        run_test = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()

        frames = run_test[0].decode("utf-8").find("Total frames:")
        new_line = run_test[0][frames:].decode("utf-8").find('\n')

        total_frames = run_test[0][(frames + 14):(frames + new_line)].decode("utf-8")
        return int(total_frames)

    else:
        make_executable(path)
        if os.access(path, os.X_OK):
            check_last(last_frame, dcd, dir_path)
        else:
            log('error', 'Could not found last frame.')
            return False


def check_interval(module, interval, total_frames):
    if interval:
        return interval

    if module == 'score':
        interval = total_frames // 5

    elif module == 'contact':
        if total_frames <= 1000:
            interval = 10
        else:
            interval = 100

    return interval


def make_executable(path):
    mode = os.stat(path).st_mode
    mode |= (mode & 0o444) >> 2    # copy R bits to X
    os.chmod(path, mode)


def create_outputs_dir(out, chimera, energies, rmsd, score):
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
