from src.color_log import log
import os
import re


def finish_analysis(chimera, score, energies, rmsd, out, name):
    """Rename outputs and remove temps"""

    if rmsd:
        finish_rmsd(out, name)

    if chimera:
        finish_chimera(out, name)

    if energies:
        finish_energies(out, name)

    if score:
        finish_score(out, name)

    rename_models(out, name)

    log('info', 'Excluding temp.')
    remove(F'{out}temp*analysis.tcl')


def finish_rmsd(out, name):
    """Rename rmsd outputs and remove temps"""

    log('info', 'Adjusting rmsd output.')

    old_rmsd = out + 'rmsd/all_rmsd.csv'
    new_rmsd = out + 'rmsd/' + name + '_all_rmsd.csv'
    rename(old_rmsd, new_rmsd)

    old_rmsf = out + 'rmsd/residue_rmsd.csv'
    new_rmsf = out + 'rmsd/' + name + '_residue_rmsd.csv'
    rename(old_rmsf, new_rmsf)


def finish_chimera(out, name):
    """Rename contact outputs and remove temps"""

    log('info', 'Adjusting contact output.')

    old_map = out + 'contact/contact_map.csv'
    new_map = out + 'contact/' + name + '_contact_map.csv'
    rename(old_map, new_map)

    old_count = out + 'contact/contact_count.csv'
    new_count = out + 'contact/' + name + '_contact_count.csv'
    rename(old_count, new_count)


def finish_score(out, name):
    """Rename score outputs and remove temps"""

    log('info', 'Adjusting score output.')

    old_score_path = out + 'score/score_relaxed.sc'
    new_score_path = out + 'score/' + name + '_score.csv'

    with open(old_score_path, 'r') as old_score:
        with open(new_score_path, 'w') as new_score:
            old_score.readline()
            for line in old_score:
                line = re.sub(r'\s+', ';', line.strip())
                new_score.write(line + '\n')

    remove(old_score_path)

    remove(F"{out}score/*.pdb")
    remove(F"{out}score/*.fasta")

    remove(F"{out}models/*_ignorechain.*")


def finish_energies(out, name):
    """Merge energies outputs and remove temps"""

    log('info', 'Adjusting energies output.')

    energies_path = out + "energies"
    all_name = out + "energies/" + name + '_all_energies.csv'
    inter_name = out + "energies/" + name + '_interaction_energies.csv'

    file_list = natural_sort(os.listdir(energies_path))

    for file_name in file_list:
        file_to_write = out + 'energies/' + file_name

        if "all_" in file_name:
            with open(all_name, 'a+') as all_en:
                write_energies(file_to_write, all_en, all_name)

        elif "interaction_" in file_name:
            with open(inter_name, 'a+') as inter_en:
                write_energies(file_to_write, inter_en, inter_name)


def write_energies(file_to_write, file_to_merge, file_to_merge_name):
    """Write energies to new output"""

    with open(file_to_write, "r") as file_now:
        if os.path.getsize(file_to_merge_name) == 0:
            line = file_now.readline().strip()
            line = re.sub(r'\s+', ';', line)
            file_to_merge.write(line)

        else:
            file_now.readline()

        for line in file_now:
            line = re.sub(r'\s+', ';', line.strip())
            file_to_merge.write('\n')
            file_to_merge.write(line)

    os.remove(file_to_write)


def rename_models(out, name):
    """Rename pdb models"""

    old_first = out + 'models/first_model.pdb'
    new_first = out + 'models/' + name + '_first_model.pdb'
    rename(old_first, new_first)

    old_last = out + 'models/last_model.pdb'
    new_last = out + 'models/' + name + '_last_model.pdb'
    rename(old_last, new_last)


def rename(old, new):
    """Rename file"""

    try:
        os.rename(old, new)
    except FileNotFoundError:
        log('warning', 'Missing file ' + old + '.')


def remove(pattern):
    """Remove files with pattern"""

    import glob
    file_list = glob.glob(pattern)
    if len(file_list) >= 1:
        for file in file_list:
            try:
                os.remove(file)
            except FileNotFoundError:
                log('warning', 'Missing file ' + file + '.')
    else:
        log('warning', 'Could not find files with pattern: ' + pattern + '.')


def natural_sort(file_list):
    """Sort list of files ascending"""

    convert = lambda text: int(text) if text.isdigit() else text.lower()
    alphanum_key = lambda key: [convert(c) for c in re.split('([0-9]+)', key)]
    return sorted(file_list, key=alphanum_key)
