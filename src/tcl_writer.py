def prepare_bigdcd(rmsd, contact, cci, score, sci, pdb, psf, dcd, init, final, out):
    vmd_file = []
    if rmsd:
        vmd_file = write_get_chain(vmd_file, pdb)

    vmd_file = write_bigdcd(vmd_file)
    vmd_file = write_mol_create(vmd_file)

    if rmsd:
        vmd_file = write_rmsd(vmd_file)

    if contact or score:
        vmd_file = write_pdb_writer(vmd_file, contact, score)

    vmd_file = write_bigdcd_main(vmd_file, rmsd, contact, score)

    vmd_file = write_bigdcd_variables(vmd_file, contact, cci, score, sci, pdb, psf, init, final, out)

    call = "\nmain " + dcd + "\nquit"
    vmd_file.append(call)

    write_vmd(vmd_file, out, 'frame')


def prepare_energies(psf, pdb, dcd, out, init, final, dir_path):
    vmd_file = []
    vmd_file = write_get_chain(vmd_file, pdb)
    vmd_file = write_energies(vmd_file)

    vmd_file = write_energies_variables(vmd_file, psf, dcd, init, final, out, dir_path)

    call = "\nget_energies\nquit"
    vmd_file.append(call)

    write_vmd(vmd_file, out, 'energies')


def write_get_chain(script, pdb_path):
    with open('vmd/get_chain.tcl', 'r') as get_chain:
        file = get_chain.readlines()
        file[-1] = file[-1].replace('*pdb_path*', pdb_path)
        script.extend(file)
    return script


def write_bigdcd(script):
    with open('vmd/bigdcd.tcl', 'r') as energies:
        script.extend(energies.readlines())
    return script


def write_mol_create(script):
    with open('vmd/prepare_mol.tcl', 'r') as create:
        script.extend(create.readlines())
    return script


def write_energies(script):
    with open('vmd/energies.tcl', 'r') as energies:
        script.extend(energies.readlines())
    return script


def write_rmsd(script):
    with open('vmd/rmsd.tcl', 'r') as rmsd:
        script.extend(rmsd.readlines())
    return script


def write_pdb_writer(script, contact, score):
    with open('vmd/write_pdb.tcl', 'r') as pdb_writer:
        file = pdb_writer.readlines()
        if not contact:
            file[3:9] = ''
        if not score:
            file[10:16] = ''
        script.extend(file)
    return script


def write_bigdcd_main(script, rmsd, contact, score):
    with open('vmd/main.tcl', 'r') as main:
        file = main.readlines()

        if not rmsd:
            file[1] = ''
            file[9] = ''
            file[15] = ''

        if not contact and not score:
            file[2] = ''

        script.extend(file)

    return script


def set_variable(script, variable, value):
    append = 'set ' + variable + ' ' + str(value) + '\n'
    script.append(append)
    return script


def write_bigdcd_variables(script, contact, cci, score, sci, pdb, psf, init, final, out):
    script = set_variable(script, 'psf_path', psf)
    script = set_variable(script, 'pdb_path', pdb)
    script = set_variable(script, 'out_path', out)

    script = set_variable(script, 'init', init)

    if contact or score:
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
    filename = out + '/temp_' + name + '_analysis.tcl'
    with open(filename, 'w') as analysis:
        analysis.write(''.join(script))
