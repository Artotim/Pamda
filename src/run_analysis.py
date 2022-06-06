import os
import subprocess
from signal import SIGTERM
from time import sleep

from src.color_log import log, docker_logger


def start_frame_analysis(out, name, vmd):
    """Run vmd for frame analysis"""

    log('info', 'Starting frame analysis.')

    log_file = out + 'logs/' + name + '_frame.log'
    err_file = out + 'logs/' + name + '_frame.err'
    vmd_file = out + 'temp_frame_analysis.tcl'

    docker_logger(log_type='info', message='Logging frame analysis info to ' + log_file + '.')

    run_vmd(vmd, vmd_file, log_file, err_file)

    log('info', 'Frame analysis done.')


def start_energies_analysis(out, name, vmd):
    """Run vmd for energy analysis"""

    log('info', 'Starting energies analysis.')

    log_file = out + 'logs/' + name + '_energies.log'
    err_file = out + 'logs/' + name + '_energies.err'
    vmd_file = out + 'temp_energies_analysis.tcl'

    docker_logger(log_type='info', message='Logging energies analysis info to ' + log_file + '.')

    run_vmd(vmd, vmd_file, log_file, err_file)

    log('info', 'Energies analysis done.')


def run_vmd(vmd, vmd_file, log_file, err_file):
    cmd = [vmd, '-e', vmd_file]

    try:
        with open(log_file, 'w') as log_f, open(err_file, "w") as err_f:
            process = subprocess.Popen(cmd, stdout=log_f, stderr=err_f, preexec_fn=os.setsid)
            while process.poll() is None:
                sleep(30)

    except (PermissionError, FileNotFoundError):
        log('error', 'VMD exe not found! Please specify path with -e.')
        return

    except KeyboardInterrupt:
        os.killpg(os.getpgid(process.pid), SIGTERM)
        raise
