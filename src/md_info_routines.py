import os
import subprocess

from src.color_log import log
from src.pre_run_routines import make_executable


def get_last_frame(last_frame, md_path, md_type, program_src_path):
    """Get last frame from dynamic if not provided"""

    if not last_frame:
        log('info', 'Automatically determining last frame.')

        if md_type == "dcd":
            last_frame = get_dcd_last_frame(md_path, program_src_path)
        else:
            last_frame = get_xtc_last_frame(md_path)

    log('info', 'Last frame set to: ' + str(last_frame) + '.')
    return last_frame


def get_dcd_last_frame(md_path, program_src_path):
    """Get last frame from a dcd md"""

    catdcd_path = program_src_path + 'dependencies/catdcd/catdcd'

    if os.access(catdcd_path, os.X_OK):
        cmd = [catdcd_path, md_path]
        run_test = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()

        frames = run_test[0].decode("utf-8").find("Total frames:")
        new_line = run_test[0][frames:].decode("utf-8").find('\n')

        total_frames = run_test[0][(frames + 14):(frames + new_line)].decode("utf-8")
        last_frame = int(total_frames)

        return last_frame

    else:
        make_executable(catdcd_path)
        if os.access(catdcd_path, os.X_OK):
            return get_dcd_last_frame(md_path, catdcd_path)
        else:
            log('error', 'Catdcd failed. Specify last frame with "-l".')
            return False


def get_xtc_last_frame(md_path):
    """Get last frame from a xtc md"""

    def str_seek(stream, s, buf_size=10000):
        """Extracted from https://mailman-1.sys.kth.se/pipermail/gromacs.org_gmx-developers/2012-June/005940.html"""
        v = len(s)
        x = stream.read(buf_size)
        n = 0

        while len(x) >= v:
            m = x.find(s)
            if m > -1:
                n += m
                yield n
                x = x[m + v:]
                n += v
            elif len(x) > v:
                n += len(x) - v + 1
                x = x[1 - v:]
            if len(x) <= v:
                x += stream.read(buf_size)

    md_file = open(md_path, "rb")
    tag = md_file.read(8)
    md_file.close()

    md_file = open(md_path, "rb")
    frames = [i for i in str_seek(md_file, tag)]
    md_file.close()

    return len(frames)


def decide_interval(interval, total_frames, analysis_type):
    """Decides frame analysis interval based on total frames"""

    if not interval:
        if total_frames <= 1000:
            interval = 10
        else:
            interval = 100

    log('info', 'Analyzing ' + analysis_type + ' each ' + str(interval) + ' frames.')
    return interval


def get_molecule_chains(pdb_path, program_src_path, vmd):
    """Get chains list from generated pdb file"""

    get_chains_cmd = F"""
    namespace eval nome_legal {{
    variable str_path {pdb_path}
    variable str_type pdb }}
    source {program_src_path}tcl/create_mol.tcl
    nome_legal::create_mol
    quit
    """

    try:
        vmd_open = subprocess.Popen(vmd, stdout=subprocess.PIPE, stdin=subprocess.PIPE, stderr=subprocess.STDOUT)
        vmd_output = vmd_open.communicate(input=get_chains_cmd.encode())[0]
        vmd_output = vmd_output.decode().split("\n")
        chains_list = [line.replace("Found chains", "").split() for line in vmd_output if "Found chains" in line][-1]
    except IndexError:
        chains_list = []

    return chains_list


def get_dist_pair_info(query_pairs, dist_type, pdb_path):
    """Gets name and chain info for each distance pair"""

    dist_pairs = []
    dist_names = []
    query_failed = False

    for pair_idx, query_pair in enumerate(query_pairs):
        pair = []
        pair_names = []

        for query_idx, query in enumerate(query_pair):
            query_data = get_pdb_by_idx(query, pdb_path, dist_type)

            if not query_data:
                query_failed = True
                query_input = query.split(':')

                if len(query_input) > 1:
                    log('error', 'Could not find ' + dist_type + ' index: ' + query_input[0] +
                        ', in chain: ' + query_input[1] + '.')
                else:
                    log('error', 'Could not find ' + dist_type + ' index: ' + query_input[0] + '.')

            else:
                pair.append(query_data[0])
                pair_names.append(query_data[1])

        if len(pair) == 2 and len(pair_names) == 2:
            dist_name = 'to'.join(pair_names)
            if pair not in dist_pairs and dist_name not in dist_names:
                dist_pairs.append(pair)
                dist_names.append(dist_name)

    if query_failed:
        return False, False

    return dist_pairs, dist_names


def get_hgl_info(input_highlight, pdb_path):
    """Gets highlight residues names and chains"""

    if len(input_highlight) == 0:
        return False

    log('info', 'Checking residues to highlight in generated PDB file.')

    highlight_data = {}

    for resid_input in input_highlight:
        resid_data = get_pdb_by_idx(resid_input, pdb_path, 'resid')

        if resid_data:
            if resid_data[1] not in highlight_data.values():
                highlight_data[resid_data[0]] = resid_data[1]
        else:
            log('warning', 'Could not find imputed highlight residue \"' + resid_input + '\" in PDB file.')

    return highlight_data


def get_pdb_by_idx(query, pdb_path, idx_type):
    """Get query indexes data in pdb file"""

    column = 1 if idx_type == 'atom' else 5

    query_info = query.split(':')
    query_number = query_info[0]
    pdb_query_number = query_number if idx_type == 'resid' else str(int(query_number) + 1)
    result = False

    with open(pdb_path, 'r') as pdb_file:
        for line in pdb_file:
            line_elements = line.split()
            try:
                if line_elements[column] == pdb_query_number:
                    chain = line_elements[4]
                    resname = line_elements[3].replace('HSD', 'HIS')
                    resid = line_elements[5]
                    atom = line_elements[2]

                    if len(query_info) > 1:
                        if chain != query_info[1]:
                            continue

                    result = [F"{query_number}:{chain}", F"{chain}:{resname}:{resid}"]
                    if idx_type == 'atom':
                        result[1] += F":{atom}"

                    break

            except IndexError:
                continue

    if not result:
        return None
    else:
        return result
