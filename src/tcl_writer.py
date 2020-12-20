def prepare_frame(rmsd, contact, cci, score, sci, pdb, psf, dcd, init, final, out, dir_path):
    vmd_file = []

    vmd_file = write_get_chain(vmd_file, dir_path, pdb)
    vmd_file = write_get_models(vmd_file, dir_path, psf, pdb, dcd, out, init, final)
    vmd_file = write_mol_create(vmd_file, dir_path)

    if rmsd:
        vmd_file = write_bigdcd(vmd_file, dir_path)
        vmd_file = write_rmsd(vmd_file, dir_path)

        if contact or score:
            vmd_file = write_pdb_writer(vmd_file, dir_path, contact, score)

        vmd_file = write_bigdcd_main(vmd_file, dir_path, contact, score)

    else:
        vmd_file = write_pdb_interval(vmd_file, dir_path, score, contact)

    vmd_file = write_frame_variables(vmd_file, contact, cci, score, sci, pdb, psf, init, final, out)

    if rmsd:
        call = "\nmain " + dcd + "\nquit"
    else:
        call = "\npdb_writer_interval " + dcd + "\nquit"

    vmd_file.append(call)

    write_vmd(vmd_file, out, 'frame')


def prepare_energies(psf, pdb, dcd, out, init, final, dir_path):
    vmd_file = []

    vmd_file = write_get_chain(vmd_file, dir_path, pdb)
    vmd_file = write_get_models(vmd_file, dir_path, psf, pdb, dcd, out, init, final)
    vmd_file = write_energies(vmd_file, dir_path)

    vmd_file = write_energies_variables(vmd_file, psf, dcd, init, final, out, dir_path)

    call = "\nget_energies\nquit"
    vmd_file.append(call)

    write_vmd(vmd_file, out, 'energies')


def write_get_models(script, dir_path, psf, pdb, dcd, out, init, last):
    with open(F'{dir_path}vmd/get_models.tcl', 'r') as get_chain:
        file = get_chain.readlines()
        file[-1] = file[-1].replace('*psf_path*', psf)
        file[-1] = file[-1].replace('*pdb_path*', pdb)
        file[-1] = file[-1].replace('*dcd_path*', dcd)
        file[-1] = file[-1].replace('*out_path*', out)
        file[-1] = file[-1].replace('*init*', str(init))
        file[-1] = file[-1].replace('*last*', str(last))
        script.extend(file)
    return script


def write_get_chain(script, dir_path, pdb_path):
    with open(F'{dir_path}vmd/get_chain.tcl', 'r') as get_chain:
        file = get_chain.readlines()
        file[-1] = file[-1].replace('*pdb_path*', pdb_path)
        script.extend(file)
    return script


def write_bigdcd(script, dir_path):
    with open(F'{dir_path}vmd/bigdcd.tcl', 'r') as energies:
        script.extend(energies.readlines())
    return script


def write_mol_create(script, dir_path):
    with open(F'{dir_path}vmd/prepare_mol.tcl', 'r') as create:
        script.extend(create.readlines())
    return script


def write_pdb_interval(script, dir_path, score, contact):
    with open(F'{dir_path}vmd/pdb_writer.tcl', 'r') as pdb_writer:
        file = pdb_writer.readlines()
        if not contact:
            file[7:30] = ''
        if not score:
            file[31:54] = ''

        script.extend(file)
    return script


def write_energies(script, dir_path):
    with open(F'{dir_path}vmd/energies.tcl', 'r') as energies:
        script.extend(energies.readlines())
    return script


def write_rmsd(script, dir_path):
    with open(F'{dir_path}vmd/rmsd.tcl', 'r') as rmsd:
        script.extend(rmsd.readlines())
    return script


def write_pdb_writer(script, dir_path, contact, score):
    with open(F'{dir_path}vmd/write_pdb.tcl', 'r') as pdb_writer:
        file = pdb_writer.readlines()
        if not contact:
            file[10:16] = ''
        if not score:
            file[3:9] = ''

        script.extend(file)
    return script


def write_bigdcd_main(script, dir_path, contact, score):
    with open(F'{dir_path}vmd/main.tcl', 'r') as main:
        file = main.readlines()

        if not contact and not score:
            file[6] = ''

        script.extend(file)

    return script


def set_variable(script, variable, value):
    append = 'set ' + variable + ' ' + str(value) + '\n'
    script.append(append)
    return script


def write_frame_variables(script, contact, cci, score, sci, pdb, psf, init, final, out):
    script = set_variable(script, 'psf_path', psf)
    script = set_variable(script, 'pdb_path', pdb)
    script = set_variable(script, 'out_path', out)

    script = set_variable(script, 'init', init)
    script = set_variable(script, 'last', final)

    if contact:
        script = set_variable(script, 'cci', cci)

    if score:
        script = set_variable(script, 'sci', sci)

    return script


def write_energies_variables(script, psf, dcd, init, final, out, dir_path):
    script = set_variable(script, 'psf_path', psf)
    script = set_variable(script, 'dcd_path', dcd)
    script = set_variable(script, 'out_path', out)
    script = set_variable(script, 'namd_path', dir_path + 'namd/')

    script = set_variable(script, 'init', init)
    script = set_variable(script, 'last', final)

    return script


def write_vmd(script, out, name):
    filename = out + 'temp_' + name + '_analysis.tcl'
    with open(filename, 'w') as analysis:
        analysis.write(''.join(script))
