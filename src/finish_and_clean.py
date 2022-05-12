from src.color_log import log
import os
import re


def finish_analysis(contact, energies, distances, rmsd, out, name, init):
    """Rename outputs and remove temps"""

    print()
    if rmsd:
        finish_rmsd(out, name)

    if contact:
        finish_contact(out, name)

    if energies:
        finish_energies(out, name, init)

    if distances:
        finish_distances(out, name)

    rename_models(out, name)

    log('info', 'Excluding temporary files.')
    remove(F'{out}temp*analysis.tcl')

    print()


def finish_rmsd(out, name):
    """Rename RMSD outputs and remove temps"""

    log('info', 'Adjusting rmsd output.')

    old_rmsd = out + 'rmsd/all_rmsd.csv'
    new_rmsd = out + 'rmsd/' + name + '_all_rmsd.csv'
    rename(old_rmsd, new_rmsd)

    old_residue = out + 'rmsd/residue_rmsd.csv'
    new_residue = out + 'rmsd/' + name + '_residue_rmsd.csv'
    rename(old_residue, new_residue)

    create_rmsf_out(out, name, new_residue)


def create_rmsf_out(out, name, new_residue):
    """Calculate RMSF for each residue"""

    from pandas import read_csv

    residue_rmsd = read_csv(new_residue, sep=";")
    third1 = round(len(residue_rmsd) / 3)
    third2 = round((len(residue_rmsd) / 3) * 2)
    third3 = round((len(residue_rmsd) / 3) * 3)

    rmsf_out = out + 'rmsd/' + name + '_all_rmsf.csv'

    with open(rmsf_out, 'w') as rmsf_file:
        rmsf_file.write("residue;rmsf;rmsf_init;rmsf_middle;rmsf_final\n")

        for column in residue_rmsd.columns[1:]:
            sd_total = str(residue_rmsd[column].std())
            sd_third1 = str(residue_rmsd[column][:third1].std())
            sd_third2 = str(residue_rmsd[column][third1: third2].std())
            sd_third3 = str(residue_rmsd[column][third2:third3].std())

            residue_rmsf = [column, sd_total, sd_third1, sd_third2, sd_third3]
            rmsf_file.write(";".join(residue_rmsf) + '\n')


def finish_contact(out, name):
    """Rename contact outputs and remove temps"""

    log('info', 'Adjusting contact output.')

    old_map = out + 'contact/contact_map.csv'
    new_map = out + 'contact/' + name + '_contact_map.csv'
    rename(old_map, new_map)

    old_count = out + 'contact/contact_count.csv'
    new_count = out + 'contact/' + name + '_contact_count.csv'
    rename(old_count, new_count)


def finish_distances(out, name):
    """Rename score outputs and remove temps"""

    log('info', 'Adjusting distances output.')

    old_distances = out + 'distances/all_distances.csv'
    new_distances = out + 'distances/' + name + '_all_distances.csv'
    rename(old_distances, new_distances)


def finish_energies(out, name, init):
    """Merge energies outputs and remove temps"""

    log('info', 'Adjusting energies output.')

    energies_path = out + "energies"
    all_name = out + "energies/" + name + '_all_energies.csv'
    inter_name = out + "energies/" + name + '_interaction_energies.csv'

    all_frame_count = inter_frame_count = init if init != 0 else 1

    file_list = natural_sort(os.listdir(energies_path))

    for file_name in file_list:
        file_to_write = out + 'energies/' + file_name

        if file_name.startswith("all_"):
            with open(all_name, 'a+') as all_en:
                all_frame_count = write_energies(file_to_write, all_en, all_name, all_frame_count)

        elif file_name.startswith("interaction_"):
            with open(inter_name, 'a+') as inter_en:
                inter_frame_count = write_energies(file_to_write, inter_en, inter_name, inter_frame_count)


def write_energies(file_to_write, file_to_merge, file_to_merge_name, frame_count):
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
            line = re.sub(r'^\d+;\d+', F'{frame_count};{frame_count}', line)
            file_to_merge.write('\n')
            file_to_merge.write(line)
            frame_count += 1

    os.remove(file_to_write)
    return frame_count


def rename_models(out, name):
    """Rename pdb models"""

    log('info', 'Renaming first and last models outputs.')

    old_first = out + 'models/first_frame.pdb'
    new_first = out + 'models/' + name + '_first_frame.pdb'
    rename(old_first, new_first)

    old_last = out + 'models/last_frame.pdb'
    new_last = out + 'models/' + name + '_last_frame.pdb'
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
