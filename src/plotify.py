from src.color_log import log
import subprocess
from time import sleep


def create_plots(chimera, score, energies, rmsd, program_path, out, name, init, last):
    """Create plots for each analysis"""

    if chimera:
        plot_contacts(program_path, out, name)

    if score:
        plot_score(program_path, out, name, init, last)

    if energies:
        plot_energies(program_path, out, name)

    if rmsd:
        plot_rmsd(program_path, out, name)


def plot_contacts(program_path, out, name):
    """Create plots for contact analysis"""

    script = program_path + 'plots/plot_contact_map.r'

    cmd = ['Rscript', '--vanilla', script, out, name]
    run_plot(cmd, 'contact map', out, name)

    script = program_path + 'plots/plot_contact_count.r'

    cmd = ['Rscript', '--vanilla', script, out, name]
    run_plot(cmd, 'contact count', out, name)


def plot_score(program_path, out, name, init, last):
    """Create plots for score analysis"""

    script = program_path + 'plots/plot_score.r'
    cmd = ['Rscript', '--vanilla', script, out, name, str(init), str(last)]
    run_plot(cmd, 'score', out, name)


def plot_energies(program_path, out, name):
    """Create plots for energies analysis"""

    script = program_path + 'plots/plot_energy.r'

    cmd = ['Rscript', '--vanilla', script, out, name]
    run_plot(cmd, 'energies', out, name)


def plot_rmsd(program_path, out, name):
    """Create plots for rmsd analysis"""

    script = program_path + 'plots/plot_rmsd_rmsf.r'

    cmd = ['Rscript', '--vanilla', script, out, name]
    run_plot(cmd, 'rmsd', out, name)


def run_plot(cmd, plot, out, name):
    """Run command on Rscript"""

    log('info', 'Creating plots for ' + plot + '.')

    log_file = out + 'logs/' + name + '_plots.log'
    err_file = out + 'logs/' + name + '_plots.err'
    log('info', 'Logging plot info to ' + log_file + '.')

    try:
        with open(log_file, 'a+') as log_f, open(err_file, "a+") as err_f:
            process = subprocess.Popen(cmd, stdout=log_f, stderr=err_f)

            while process.poll() is None:
                sleep(60)
            else:
                return

    except (PermissionError, FileNotFoundError):
        log('error', 'Failed to plot ' + plot + '.')
