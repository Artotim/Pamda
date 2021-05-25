from src.color_log import log
import subprocess
from time import sleep


def create_plots(contact, score, energies, rmsd, program_path, out, name, init, last, alone, catalytic):
    """Create plots for each analysis"""

    if contact:
        plot_contacts(program_path, out, name, catalytic)

    if score:
        plot_score(program_path, out, name, init, last)

    if energies:
        plot_energies(program_path, out, name, alone)

    if rmsd:
        plot_rmsd(program_path, out, name, alone, catalytic)


def plot_contacts(program_path, out, name, catalytic):
    """Create plots for contact analysis"""

    script = program_path + 'plots/plot_contact_map.r'

    cmd = ['Rscript', '--vanilla', script, out, name]
    cmd = plot_catalytic_site(cmd, catalytic)
    run_plot(cmd, 'contact map', out, name)

    script = program_path + 'plots/plot_contact_count.r'

    cmd = ['Rscript', '--vanilla', script, out, name]
    run_plot(cmd, 'contact count', out, name)


def plot_score(program_path, out, name, init, last):
    """Create plots for score analysis"""

    script = program_path + 'plots/plot_score.r'
    cmd = ['Rscript', '--vanilla', script, out, name, str(init), str(last)]
    run_plot(cmd, 'score', out, name)


def plot_energies(program_path, out, name, alone):
    """Create plots for energies analysis"""

    script = program_path + 'plots/plot_energy.r'

    cmd = ['Rscript', '--vanilla', script, out, name]
    cmd = plot_alone_files(cmd, program_path, "energies", alone)

    run_plot(cmd, 'energies', out, name)


def plot_rmsd(program_path, out, name, alone, catalytic):
    """Create plots for rmsd analysis"""

    script = program_path + 'plots/plot_rmsd_rmsf.r'

    cmd = ['Rscript', '--vanilla', script, out, name]
    cmd = plot_alone_files(cmd, program_path, "rmsd", alone)
    cmd = plot_catalytic_site(cmd, catalytic)

    run_plot(cmd, 'rmsd', out, name)


def plot_alone_files(cmd, program_path, plot, alone):
    """Add alone files to compare on cmd"""

    program_path = {'rmsd': program_path + 'plots/plot_rmsd_rmsf_alone.r',
                    'energies': program_path + 'plots/plot_energy_alone.r'}

    if alone[plot] is not None:
        cmd.append(program_path[plot])
        cmd.extend(alone[plot])
    else:
        cmd.append(str(False))
        cmd.append(str(False))
        if plot == 'rmsd':
            cmd.append(str(False))

    return cmd


def plot_catalytic_site(cmd, catalytic):
    """Add catalytic sites to plot on cmd"""

    if catalytic:
        for resi in catalytic:
            cmd.append(catalytic[resi] + str(resi))

    return cmd


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
