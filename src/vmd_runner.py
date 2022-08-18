import os
import subprocess
from signal import SIGTERM
from time import sleep

from src.color_log import log, docker_logger


def start_create_models(out_path, out_name, vmd, program_src_path, create_models_args):
    """Runs vmd to create models for first and last requested frames"""

    log('info', 'Writing models for first and last requested frames.')

    log_file = out_path + 'logs/' + out_name + '_write_models.log'
    err_file = out_path + 'logs/' + out_name + '_write_models.err'

    cmd = [vmd, '-e', F'{program_src_path}tcl/write_models.tcl', "-args"]
    cmd.extend(list(map(str, create_models_args)))

    run_vmd(cmd, log_file, err_file)


def start_frame_analysis(out, out_name, vmd):
    """Runs vmd for frame analysis"""

    log('info', 'Starting frame analysis.')

    log_file = out + 'logs/' + out_name + '_frame_analysis.log'
    err_file = out + 'logs/' + out_name + '_frame_analysis.err'
    vmd_file = out + 'temp_frame_analysis.tcl'

    docker_logger(log_type='info', message='Logging frame analysis info to ' + log_file + '.')

    cmd = [vmd, '-e', vmd_file]
    run_vmd(cmd, log_file, err_file)

    log('info', 'Frame analysis done.')


def start_energies_analysis(out, name, vmd):
    """Runs vmd for energy analysis"""

    log('info', 'Starting energies analysis.')

    log_file = out + 'logs/' + name + '_energies_analysis.log'
    err_file = out + 'logs/' + name + '_energies_analysis.err'
    vmd_file = out + 'temp_energies_analysis.tcl'

    docker_logger(log_type='info', message='Logging energies analysis info to ' + log_file + '.')

    cmd = [vmd, '-e', vmd_file]
    run_vmd(cmd, log_file, err_file)

    log('info', 'Energies analysis done.')


def run_vmd(cmd, log_file, err_file):
    """Executes command with vmd"""

    try:
        with open(log_file, 'w') as log_f, open(err_file, "w") as err_f:
            process = subprocess.Popen(cmd, stdout=log_f, stderr=err_f, preexec_fn=os.setsid)
            while process.poll() is None:
                sleep(5)

    except (PermissionError, FileNotFoundError):
        log('error', 'VMD exe not found! Please specify path with -vmd.')
        return

    except KeyboardInterrupt:
        os.killpg(os.getpgid(process.pid), SIGTERM)
        raise
