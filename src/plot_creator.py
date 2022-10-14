import subprocess
from time import sleep
import itertools

from src.color_log import docker_logger, log


def create_plots(analysis_request, program_src_path, out_path, out_name, chains_list, hgl):
    """Create plots for each analysis"""

    print()

    if analysis_request["rms_analysis"]:
        plot_rms(program_src_path, out_path, out_name, hgl)

    if analysis_request["contacts_analysis"]:
        plot_contacts(program_src_path, out_path, out_name, chains_list, hgl)

    if analysis_request["distances_analysis"]:
        plot_distances(program_src_path, out_path, out_name)

    if analysis_request["sasa_analysis"]:
        plot_sasa(program_src_path, out_path, out_name)

    if analysis_request["energies_analysis"]:
        plot_energies(program_src_path, out_path, out_name, chains_list)

    copy_results_html(program_src_path, out_path)


def plot_rms(program_path, out_path, out_name, hgl):
    """Create plots for RMS analysis"""

    script = program_path + 'plots/plot_rmsd_rmsf.r'

    cmd = ['Rscript', '--vanilla', script, out_path, out_name]
    cmd = plot_highlight_residues(cmd, hgl)

    log('info', 'Creating plots for RMS.')
    run_plot(cmd, 'rms', out_path, out_name)


def plot_contacts(program_path, out_path, out_name, chains_list, hgl):
    """Create plots for contacts analysis"""

    map_script = program_path + 'plots/plot_contacts_map.r'
    count_script = program_path + 'plots/plot_contacts_count.r'
    contact_types = ["nonbond", "hbonds", "sbridges"]

    for chain_pair in list(itertools.combinations(chains_list, 2)):
        log('info', F'Creating plots for contacts maps between chains {chain_pair[0]} and {chain_pair[1]}.')
        silent = False

        for contact_type in contact_types:
            plot_name = F"{out_name}_{chain_pair[0]}-{chain_pair[1]}_{contact_type}"

            cmd = ['Rscript', '--vanilla', map_script, out_path, plot_name]
            cmd = plot_highlight_residues(cmd, hgl)

            run_plot(cmd, 'contacts', out_path, out_name, silent)
            run_ffmpeg(out_path, out_name, plot_name, contact_type)
            silent = True

    for chain_pair in list(itertools.combinations(chains_list, 2)):
        log('info', F'Creating plots for contacts counts between chains {chain_pair[0]} and {chain_pair[1]}.')
        silent = False

        for contact_type in contact_types:
            plot_name = F"{out_name}_{chain_pair[0]}-{chain_pair[1]}_{contact_type}"
            cmd = ['Rscript', '--vanilla', count_script, out_path, plot_name]

            run_plot(cmd, 'contacts', out_path, out_name, silent)
            silent = True


def run_ffmpeg(out_path, out_name, plot_name, contact_type):
    """Run ffmpeg to convert contacts map steps to mp4"""

    from os.path import exists

    out_file = F"{out_path}graphs/contacts/{plot_name}_contacts_map_steps.mp4"

    log_file = F"{out_path}logs/{out_name}_contacts_plot.log"
    err_file = F"{out_path}logs/{out_name}_contacts_plot.err"

    cmd = [
        "ffmpeg", "-framerate", "1", "-pattern_type", "glob",
        "-i", F"{out_path}graphs/contacts/{plot_name}_contacts_map_step_*.png",
        "-y", "-c:v", "libx264", "-r", "30",
        "-pix_fmt", "yuv420p", "-vf", "pad=ceil(iw/2)*2:ceil(ih/2)*2",
        out_file
    ]

    try:
        with open(log_file, 'a+') as log_f, open(err_file, "a+") as err_f:
            process = subprocess.Popen(cmd, stdout=log_f, stderr=err_f)
            while process.poll() is None:
                sleep(10)

    except (PermissionError, FileNotFoundError):
        log('warning', 'Could not find installed ffmpeg to plot contacts.')

    if exists(out_file):
        remove_file_pattern(F'{out_path}graphs/contacts/*step_*.png')
    else:
        log('warning', F'Could not run ffmpeg on {contact_type} contacts plots.')


def remove_file_pattern(pattern):
    """Remove files with pattern"""

    import glob
    from os import remove

    file_list = glob.glob(pattern)
    if len(file_list) >= 1:
        for file in file_list:
            try:
                remove(file)
            except FileNotFoundError:
                docker_logger(log_type='warning', message='Missing file ' + file + '.')
    else:
        docker_logger(log_type='warning', message='Could not find files with pattern: ' + pattern + ' to delete.')


def plot_distances(program_path, out_path, out_name):
    """Create plots for distances analysis"""

    script = program_path + 'plots/plot_distances.r'
    cmd = ['Rscript', '--vanilla', script, out_path, out_name]

    log('info', 'Creating plots for distances.')
    run_plot(cmd, 'distances', out_path, out_name)


def plot_sasa(program_path, out_path, out_name):
    """Create plots for SASA analysis"""

    script = program_path + 'plots/plot_sasa.r'
    cmd = ['Rscript', '--vanilla', script, out_path, out_name]

    log('info', 'Creating plots for SASA.')
    run_plot(cmd, 'sasa', out_path, out_name)


def plot_energies(program_path, out_path, out_name, chains_list):
    """Create plots for energies analysis"""

    script = program_path + 'plots/plot_energy.r'

    cmd = ['Rscript', '--vanilla', script, out_path, out_name]

    for chain_pair in list(itertools.combinations(chains_list, 2)):
        cmd.append(F"{chain_pair[0]}-{chain_pair[1]}")

    log('info', 'Creating plots for energies.')
    run_plot(cmd, 'energies', out_path, out_name)


def plot_highlight_residues(cmd, highlight):
    """Add highlight residues to  plot cmd"""

    if highlight:
        for resi in highlight:
            cmd.append(highlight[resi])

    return cmd


def run_plot(cmd, log_name, out_path, out_name, silent=False):
    """Run command with Rscript"""

    log_file = F"{out_path}logs/{out_name}_{log_name}_plot.log"
    err_file = F"{out_path}logs/{out_name}_{log_name}_plot.err"

    if not silent:
        docker_logger(log_type='info', message='Logging plot info to ' + log_file + '.')

    try:
        with open(log_file, 'a+') as log_f, open(err_file, "a+") as err_f:
            process = subprocess.Popen(cmd, stdout=log_f, stderr=err_f)

            while process.poll() is None:
                sleep(5)
            else:
                return

    except (PermissionError, FileNotFoundError):
        log('error', 'Failed to plot ' + log_name + '.')


def copy_results_html(program_src_path, out_path):
    """Copy results html page to output folder"""

    import shutil
    shutil.copy(F"{program_src_path}plots/results_viewer.html", F"{out_path}graphs/")
