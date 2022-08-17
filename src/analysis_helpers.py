import os
import re
import itertools

from src.color_log import log


def create_rmsf_out(out_path, out_name):
    """Calculate RMSF for each residue"""

    from pandas import read_csv

    log('info', 'Calculating RMSF from output.')

    residue_rmsd_file = F"{out_path}rms/{out_name}_residue_rmsd.csv"

    residue_rmsd = read_csv(residue_rmsd_file, sep=";")
    third1 = round(len(residue_rmsd) / 3)
    third2 = round((len(residue_rmsd) / 3) * 2)
    third3 = round((len(residue_rmsd) / 3) * 3)

    rmsf_out = F"{out_path}rms/{out_name}_all_rmsf.csv"

    with open(rmsf_out, 'w') as rmsf_file:
        rmsf_file.write("residue;rmsf;rmsf_init;rmsf_middle;rmsf_final\n")

        for column in residue_rmsd.columns[1:]:
            sd_total = str(residue_rmsd[column].std())
            sd_third1 = str(residue_rmsd[column][:third1].std())
            sd_third2 = str(residue_rmsd[column][third1: third2].std())
            sd_third3 = str(residue_rmsd[column][third2:third3].std())

            residue_rmsf = [column, sd_total, sd_third1, sd_third2, sd_third3]
            rmsf_file.write(";".join(residue_rmsf) + '\n')


def merge_energies(out_path, out_name, first_frame, chains_list):
    """Merge energies outputs and remove temps"""

    log('info', 'Merging energies outputs.')

    first_frame = first_frame if first_frame != 0 else 1

    energies_path = out_path + "energies/"

    file_list = natural_sort(os.listdir(energies_path))
    frame_count_dict = {"_all": first_frame}

    for chain_pair in list(itertools.combinations(chains_list, 2)):
        frame_count_dict[F"_{chain_pair[0]}-{chain_pair[1]}_interaction"] = first_frame

    for file_name in file_list:
        file_basename = [file_basename for file_basename in frame_count_dict.keys()
                         if file_basename in file_name and re.search(r'\d+$', file_name)]

        if len(file_basename) != 1:
            continue

        file_basename = file_basename[0]
        reading_file = energies_path + file_name
        merged_file_name = energies_path + out_name + file_basename + "_energies.csv"

        open_method = "w" if frame_count_dict[file_basename] == first_frame else "a+"
        with open(merged_file_name, open_method) as merged_file:
            frame_count = write_energies(reading_file, merged_file, frame_count_dict[file_basename], open_method)
            frame_count_dict[file_basename] = frame_count


def write_energies(reading_file, merged_file, frame_count, merged_open_method):
    """Write energies to new output"""

    with open(reading_file, "r") as file_now:
        if merged_open_method == "w":
            line = file_now.readline().strip()
            line = re.sub(r'\s+', ';', line)
            merged_file.write(line)

        else:
            file_now.readline()

        for line in file_now:
            line = re.sub(r'\s+', ';', line.strip())
            line = re.sub(r'^\d+;\d+', F'{frame_count};{frame_count}', line)
            merged_file.write('\n')
            merged_file.write(line)
            frame_count += 1

    os.remove(reading_file)
    return frame_count


def natural_sort(file_list):
    """Sort list of files ascending"""

    convert = lambda text: int(text) if text.isdigit() else text.lower()
    alphanum_key = lambda key: [convert(c) for c in re.split('([0-9]+)', key)]
    return sorted(file_list, key=alphanum_key)


def delete_temp_files(out_path, frame_analysis, energies_analysis):
    """Deletes temporary tcl files"""

    print()

    log('info', 'Excluding temporary files.')

    if frame_analysis:
        os.remove(F'{out_path}temp_frame_analysis.tcl')

    if energies_analysis:
        os.remove(F'{out_path}temp_energies_analysis.tcl')
