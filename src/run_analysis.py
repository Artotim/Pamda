from src.color_log import log
import subprocess
from time import sleep


def start_bigdcd(out, name, vmd, chimera, init, last, cci, dir_path):
    log_file = out + name + '_frame.log'
    err_file = out + name + '_frame.err'
    vmd_file = out + 'temp_analysis.tcl'

    cmd = [vmd, '-e', vmd_file]

    try:
        with open(log_file, 'w') as log_f, open(err_file, "w") as err_f:
            process = run_vmd(cmd, log_f, err_f)

            if chimera:
                run_chimera(out, init, last, cci, dir_path)

            while process.poll() is None:
                sleep(300)
            else:
                return

    except (PermissionError, FileNotFoundError):
        log('error', 'VMD exe not found! Please specify path with -e.')


def start_energies(out, name, vmd):
    log_file = out + name + '_energies.log'
    err_file = out + name + '_energies.err'
    vmd_file = out + 'temp_analysis.tcl'

    cmd = [vmd, '-e', vmd_file]

    try:
        with open(log_file, 'w') as log_f, open(err_file, "w") as err_f:
            process = subprocess.Popen(cmd, stdout=log_f, stderr=err_f)

            while process.poll() is None:
                sleep(300)
            else:
                return

    except (PermissionError, FileNotFoundError):
        log('error', 'VMD exe not found! Please specify path with -e.')


def run_vmd(cmd, log_file, err_file):
    return subprocess.Popen(cmd, stdout=log_file, stderr=err_file)


def run_chimera(out, init, last, cci, dir_path):
    first = int(init) + int(cci)
    path = dir_path + 'chimera/chimera_contacts'
    cmd = ['python', '-m', 'pychimera', path, out, str(first), str(last)]
    subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def start_scoring(out, sci, init, last, dir_path):
    count = int(init) + int(sci)
    final = int(last)
    path = dir_path + 'rosetta/main/source/bin/relax.static.linuxgccrelease'

    while count <= final:
        count_str = str(count)

        model = out + 'score/score_model_' + count_str + '.pdb'

        cmd = [path, '-s', model, '-out:suffix', '_relaxed', '-nstruct', '2', '-relax:default_repeats', '5']

        log_file = out + 'score/score.log'
        err_file = out + 'score/score.err'

        try:
            with open(log_file, 'w') as log_f, open(err_file, "w") as err_f:
                process = subprocess.Popen(cmd, stdout=log_f, stderr=err_f)
                while process.poll() is None:
                    sleep(300)
                else:
                    return
        except (PermissionError, FileNotFoundError):
            log('error', 'Scoring error.')
