import subprocess
from time import sleep

from src.color_log import docker_logger, log


def create_plots(boss_class):
    """Create plots for each analysis"""

    if boss_class.contact_analysis:
        plot_contacts(boss_class.analysis_path, boss_class.output, boss_class.name, boss_class.highlight_residues)

    if boss_class.distances_analysis:
        plot_distances(boss_class.analysis_path, boss_class.output, boss_class.name)

    if boss_class.energies_analysis:
        plot_energies(boss_class.analysis_path, boss_class.output, boss_class.name)

    if boss_class.rmsd_analysis:
        plot_rmsd(boss_class.analysis_path, boss_class.output, boss_class.name, boss_class.highlight_residues)


def plot_contacts(program_path, out, name, highlight):
    """Create plots for contact analysis"""

    script = program_path + 'plots/plot_contact_map.r'

    cmd = ['Rscript', '--vanilla', script, out, name]
    cmd = plot_highlight_residues(cmd, highlight)
    run_plot(cmd, 'contact map', out, name)

    script = program_path + 'plots/plot_contact_count.r'

    cmd = ['Rscript', '--vanilla', script, out, name]
    run_plot(cmd, 'contact count', out, name)

    run_ffmpeg(out, name)


def run_ffmpeg(out, name):
    from os.path import exists
    from .finish_and_clean import remove

    out_path = out + "contact/" + name + "_contact_map_steps.mp4"
    log_file = F"{out}logs/{name}_plot_contact.log"
    err_file = F"{out}logs/{name}_plot_contact.err"

    cmd = ["ffmpeg", "-framerate", "1", "-pattern_type", "glob", "-i", out + "contact/*step_*.png", "-y",
           "-c:v", "libx264", "-r", "30", "-pix_fmt", "yuv420p", "-vf", "pad=ceil(iw/2)*2:ceil(ih/2)*2", out_path]

    try:
        with open(log_file, 'a+') as log_f, open(err_file, "a+") as err_f:
            process = subprocess.Popen(cmd, stdout=log_f, stderr=err_f)
            while process.poll() is None:
                sleep(10)

    except (PermissionError, FileNotFoundError):
        log('warning', 'Could not find installed ffmpeg to plot contacts.')

    if exists(out_path):
        remove(F'{out}contact/*step_*.png')
    else:
        log('warning', 'Could not run ffmpeg on contact plots.')


def plot_distances(program_path, out, name):
    """Create plots for score analysis"""

    script = program_path + 'plots/plot_distances.r'
    cmd = ['Rscript', '--vanilla', script, out, name]
    run_plot(cmd, 'distances', out, name)


def plot_energies(program_path, out, name):
    """Create plots for energies analysis"""

    script = program_path + 'plots/plot_energy.r'

    cmd = ['Rscript', '--vanilla', script, out, name]

    run_plot(cmd, 'energies', out, name)


def plot_rmsd(program_path, out, name, highlight):
    """Create plots for rmsd and rmsf analysis"""

    script = program_path + 'plots/plot_rmsd_rmsf.r'

    cmd = ['Rscript', '--vanilla', script, out, name]
    cmd = plot_highlight_residues(cmd, highlight)

    run_plot(cmd, 'rmsd and rmsf', out, name)


def plot_highlight_residues(cmd, highlight):
    """Add residues to highlight in plot to cmd"""

    if highlight:
        for resi in highlight:
            cmd.append(highlight[resi])

    return cmd


def run_plot(cmd, plot, out, name):
    """Run command on Rscript"""

    log('info', 'Creating plots for ' + plot + '.')

    plot_name = plot.split(' ')[0]

    log_file = F"{out}logs/{name}_plot_{plot_name}.log"
    err_file = F"{out}logs/{name}_plot_{plot_name}.err"
    docker_logger(log_type='info', message='Logging plot info to ' + log_file + '.')

    try:
        with open(log_file, 'a+') as log_f, open(err_file, "a+") as err_f:
            process = subprocess.Popen(cmd, stdout=log_f, stderr=err_f)

            while process.poll() is None:
                sleep(30)
            else:
                return

    except (PermissionError, FileNotFoundError):
        log('error', 'Failed to plot ' + plot + '.')
