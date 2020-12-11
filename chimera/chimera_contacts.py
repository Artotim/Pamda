from __future__ import print_function
import os
import time
import re
import sys
from chimera import runCommand as rc


def create_output_files(out):
    map_file = out + "contact/contact_map.txt"
    count_file = out + "contact/contact_count.txt"

    with open(map_file, "w") as all_contacts:
        all_contacts.write("frame;atom1;atom2;overlap;distance\n")

    with open(count_file, "w") as contacts_count:
        contacts_count.write("frame;contacts\n")


def check_for_model(model, count):
    if not os.path.exists(model):
        print("Model not found! Awaiting...")
        time.sleep(2)
    else:
        print("Computing model", count, end=".")


def create_contact_map(count):
    file_name = "contact/overlaps_" + count + ".txt"
    rc("findclash :.A test :.B overlap -0.4 hbond 0.0 namingStyle simple save " + file_name)
    return file_name


def read_contacts(contact_map):
    with open(contact_map, "r") as contacts_now:
        file = contacts_now.readlines()
    print(".", end="")
    return file


def get_contact_number(out, contact_file, count):
    count_file = out + "contact/contact_count.txt"
    contact_number = re.findall(r'\d+', contact_file[6])

    with open(count_file, "a") as contacts_count:
        contacts_count.write(count + ";" + str(contact_number[0]) + "\n")
    print(".", end="")


def get_contact_list(out, contact_file, count):
    map_file = out + "contact/contact_map.txt"
    line = 8

    while line < len(contact_file):
        formatted_line = re.sub(r'\s\s+', ';', contact_file[line])
        with open(map_file, "a") as all_contacts:
            all_contacts.write(count + ";" + formatted_line)
        line += 1
    print(" Done!")


def finnish(model, contact_map):
    rc("close all")
    os.remove(model)
    os.remove(contact_map)


def look_for_models(count, final, out):
    while count <= final:
        count_str = str(count)

        # Await pdb file
        model = out + 'contact/contact_model_' + count_str + '.pdb'
        check_for_model(model, count_str)

        # Open model on chimera
        rc("open " + model)

        # Create contact map
        contact_map = create_contact_map(count_str)

        # Read contact maps file
        contact_file = read_contacts(contact_map)

        # Get number of contact for this frame
        get_contact_number(out, contact_file, count_str)

        # Get contact list for this frame
        get_contact_list(out, contact_file, count_str)

        # Close pdb and remove files
        finnish(model, contact_map)

        count += 100

    print("Finished!")


def main():
    print("Starting analysis...")
    out = sys.argv[1]
    create_output_files(out)

    look_for_models(int(sys.argv[2]), int(sys.argv[3]), out)


if __name__ == '__main__':
    main()
