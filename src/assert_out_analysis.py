import os
import re
import itertools

from src.color_log import docker_logger, log


def verify_write_models_out(out_path, out_name, expected_out):
    """Assert requested frame models was created"""

    base_path = F"{out_path}models/{out_name}"

    expected_files = [F"{base_path}_first_analysis_frame.pdb", F"{base_path}_last_analysis_frame.pdb"]

    for file in expected_files:
        if not check_file_exits(file):

            if expected_out == "frame_models":
                log_file = out_path + 'logs/' + out_name + '_write_models'
                fail_message = 'Failed to create models.\n'
            else:
                log_name = out_name.replace("_guessed_chains", "")
                log_file = out_path + 'logs/' + log_name + '_write_models'
                fail_message = 'Failed to guess chains.\n'

            fail_message += F'Check logs in {log_file} for more details.'
            docker_logger(log_type='error', message=fail_message)
            raise AssertionError("Missing outputs")


def verify_frame_analysis_out(analysis_request, out_path, out_name, chains_list, hgl):
    """Assert frame analysis generated respective output"""

    log_file = out_path + 'logs/' + out_name + '_frame_analysis.log'

    if analysis_request["rms_analysis"]:
        verify_rms_analysis_out(out_path, out_name, log_file)

    if analysis_request["contacts_analysis"]:
        verify_contacts_analysis_out(out_path, out_name, chains_list, log_file)

    if analysis_request["distances_analysis"]:
        verify_distances_analysis_out(out_path, out_name, log_file)

    if analysis_request["sasa_analysis"]:
        verify_sasa_analysis_out(out_path, out_name, hgl, log_file)


def verify_rms_analysis_out(out_path, out_name, log_file):
    """Assert RMS analysis generated output"""

    base_path = F"{out_path}rms/{out_name}"

    expected_files = [F"{base_path}_all_rmsd.csv", F"{base_path}_residue_rmsd.csv", F"{base_path}_residue_rmsf.csv"]

    for file in expected_files:
        if not check_file_exits(file):
            fail_message = F'Failed to execute RMS analysis.\nCheck logs in {log_file} for more details.'
            docker_logger(log_type='error', message=fail_message)
            raise AssertionError("Missing outputs")


def verify_contacts_analysis_out(out_path, out_name, chains_list, log_file):
    """Assert contacts analysis generated output"""

    analysis_failed = False
    base_path = F"{out_path}contacts/{out_name}"

    for chain_pair in list(itertools.combinations(chains_list, 2)):
        expected_files = []
        pair_out_path = base_path + F"_{chain_pair[0]}-{chain_pair[1]}"

        contact_types = ["nonbond", "hbonds", "sbridges"]
        for contact_type in contact_types:
            base_out_path = pair_out_path + F"_{contact_type}"
            expected_files.extend([F"{base_out_path}_contacts_count.csv", F"{base_out_path}_contacts_map.csv"])

        if any(not check_file_exits(file) for file in expected_files):
            log("error", F'Failed to measure contacts between chains {chain_pair[0]} and {chain_pair[1]}.')
            analysis_failed = True

    if analysis_failed:
        docker_logger(log_type="error", message=F"Check logs in {log_file} for more details.")
        raise AssertionError("Missing outputs")


def verify_distances_analysis_out(out_path, out_name, log_file):
    """Assert distances analysis generated output"""

    base_path = F"{out_path}distances/{out_name}"

    expected_file = F"{base_path}_all_distances.csv"

    if not check_file_exits(expected_file):
        fail_message = F'Failed to execute distances analysis.\nCheck logs in {log_file} for more details.'
        docker_logger(log_type='error', message=fail_message)
        raise AssertionError("Missing outputs")


def verify_sasa_analysis_out(out_path, out_name, hgl, log_file):
    """Assert SASA analysis generated output"""

    analysis_failed = False
    base_path = F"{out_path}sasa/{out_name}"

    expected_file = F"{base_path}_all_sasa.csv"
    if not check_file_exits(expected_file):
        log("error", F'Failed to execute SASA analysis.')
        analysis_failed = True

    if hgl:
        expected_file = F"{base_path}_hgl_sasa.csv"
        if not check_file_exits(expected_file):
            log("error", F'Failed to execute SASA analysis for chosen residues.')
            analysis_failed = True

    if analysis_failed:
        docker_logger(log_type="error", message=F"Check logs in {log_file} for more details.")
        raise AssertionError("Missing outputs")


def verify_energies_analysis_out(out_path, out_name, chains_list):
    """Assert energies analysis generated output"""

    analysis_failed = False
    log_file = out_path + 'logs/' + out_name + '_energies_analysis.log'
    files_list = os.listdir(F"{out_path}energies/")

    expected_regex = out_name + "_all_[0-9]*$"
    file_generated = next((True for file in files_list if re.search(expected_regex, file)), False)
    if not file_generated:
        log("error", F'Failed to execute energies analysis.')
        analysis_failed = True

    for chain_pair in list(itertools.combinations(chains_list, 2)):
        expected_regex = out_name + F"_{chain_pair[0]}-{chain_pair[1]}" + "_interaction_[0-9]*$"
        file_generated = next((True for file in files_list if re.search(expected_regex, file)), False)
        if not file_generated:
            log("error", F'Failed to execute energies analysis between chains {chain_pair[0]} and {chain_pair[1]}.')
            analysis_failed = True

    if analysis_failed:
        docker_logger(log_type="error", message=F"Check logs in {log_file} for more details.")
        raise AssertionError("Missing output")


def check_file_exits(file_path):
    """Check if file exists and its not empty"""

    if os.path.exists(file_path) and os.path.getsize(file_path) > 0:
        return True
    else:
        return False
