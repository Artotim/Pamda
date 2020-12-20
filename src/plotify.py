from src.color_log import log
import subprocess
from time import sleep


def make_plots(chimera, score, energies, rmsd, dir_path, out, name, init, last):
    if chimera:
        plot_contacts(dir_path, out, name)

    if score:
        plot_score(dir_path, out, name, init, last)

    if energies:
        plot_energies(dir_path, out, name)

    if rmsd:
        plot_rmsd(dir_path, out, name)


def plot_contacts(dir_path, out, name):
    script = dir_path + 'plots/plot_contact_map.r'

    cmd = ['Rscript', '--vanilla', script, out, name]
    run_plot(cmd, 'contact map')

    script = dir_path + 'plots/plot_contact_count.r'

    cmd = ['Rscript', '--vanilla', script, out, name]
    run_plot(cmd, 'contact count')


def plot_score(dir_path, out, name, init, last):
    script = dir_path + 'plots/plot_score.r'
    cmd = ['Rscript', '--vanilla', script, out, name, str(init), str(last)]
    run_plot(cmd, 'score')


def plot_energies(dir_path, out, name):
    script = dir_path + 'plots/plot_energy.r'

    cmd = ['Rscript', '--vanilla', script, out, name]
    run_plot(cmd, 'energies')


def plot_rmsd(dir_path, out, name):
    script = dir_path + 'plots/plot_rmsd_rmsf.r'

    cmd = ['Rscript', '--vanilla', script, out, name]
    run_plot(cmd, 'rmsd')


def run_plot(cmd, plot):
    try:
        print(cmd)
        process = subprocess.Popen(cmd)#, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while process.poll() is None:
            sleep(1)
        else:
            return
    except (PermissionError, FileNotFoundError):
        log('error', 'Failed to plot ' + plot + '.')
