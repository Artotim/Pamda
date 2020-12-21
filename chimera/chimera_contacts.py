from __future__ import print_function
import os
import time
import re
import sys
from chimera import runCommand as rc


def create_output_files(out_path):
    """Create csv files for writing"""

    map_file = out_path + "contact/contact_map.csv"
    count_file = out_path + "contact/contact_count.csv"

    with open(map_file, "w") as all_contacts:
        all_contacts.write("frame;atom1;atom2;overlap;distance\n")

    with open(count_file, "w") as contacts_count:
        contacts_count.write("frame;contacts\n")


def check_for_model(model, count, loops):
    """Check if model is ready"""

    if loops == 50:
        raise Exception("Contact files not being created")

    if not os.path.exists(model):
        print("Model not found! Awaiting...")
        time.sleep(2)
        loops = loops + 1
        return check_for_model(model, count, loops)
    else:
        print("Computing model", count, end=".")


def create_contact_map(out_path, count, main_chain, peptide):
    """Get contact info with chimera"""

    file_name = out_path + "contact/overlaps_" + count + ".txt"
    cmd = "findclash :." + main_chain + " test :." + peptide + \
          " overlap -0.4 hbond 0.0 namingStyle simple save " + file_name
    rc(cmd)
    return file_name


def read_contacts(contact_map):
    """Read contact infos"""

    with open(contact_map, "r") as contacts_now:
        file = contacts_now.readlines()
    print(".", end="")
    return file


def get_contact_number(out_path, contact_file, count):
    """Count contact hits"""

    count_file = out_path + "contact/contact_count.csv"
    contact_number = re.findall(r'\d+', contact_file[6])

    with open(count_file, "a") as contacts_count:
        contacts_count.write(count + ";" + str(contact_number[0]) + "\n")
    print(".", end="")


def get_contact_list(out_path, contact_file, count):
    """Format contact map"""

    map_file = out_path + "contact/contact_map.csv"
    line = 8

    while line < len(contact_file):
        formatted_line = re.sub(r'\s\s+', ';', contact_file[line])
        with open(map_file, "a") as all_contacts:
            all_contacts.write(count + ";" + formatted_line)
        line += 1
    print(" Done!")


def finnish(model, contact_map):
    """Close chimera and remove old info"""

    rc("close all")
    os.remove(model)
    os.remove(contact_map)


def main(init, final, out_path, cci, main_chain, peptide):
    """Main routine"""

    count = init + cci

    while count <= final:
        count_str = str(count)

        # Await pdb file
        model = out_path + 'contact/contact_model_' + count_str + '.pdb'
        check_for_model(model, count_str, 0)

        # Open model on chimera
        rc("open " + model)

        # Create contact map
        contact_map = create_contact_map(out_path, count_str, main_chain, peptide)

        # Read contact maps file
        contact_file = read_contacts(contact_map)

        # Get number of contact for this frame
        get_contact_number(out_path, contact_file, count_str)

        # Get contact list for this frame
        get_contact_list(out_path, contact_file, count_str)

        # Close pdb and remove files
        finnish(model, contact_map)

        count += cci

    print("Finished!")


if __name__ == '__main__':
    print("Starting analysis...")
    out = sys.argv[1]
    create_output_files(out)

    main(int(sys.argv[2]), int(sys.argv[3]), out, int(sys.argv[4]), sys.argv[5], sys.argv[6])
