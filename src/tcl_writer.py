from src.color_log import log


def prepare_frame_analysis(rmsd, contact, cci, score, sci, pdb, psf, dcd, init, final, out, program_path):
    """Write script to frame analysis"""

    log('info', 'Preparing .tcl file for frame analysis.')

    vmd_file = []

    vmd_file = write_get_chain(vmd_file, program_path, pdb)
    vmd_file = write_get_models(vmd_file, program_path, psf, pdb, dcd, out, init, final)
    vmd_file = write_mol_create(vmd_file, program_path)

    if rmsd:
        vmd_file = write_bigdcd(vmd_file, program_path)
        vmd_file = write_rmsd(vmd_file, program_path)

        if contact or score:
            vmd_file = write_get_pdb(vmd_file, program_path, contact, score)

        vmd_file = write_bigdcd_main(vmd_file, program_path, contact, score)

    else:
        vmd_file = write_pdb_writer(vmd_file, program_path, score, contact)

    vmd_file = write_frame_variables(vmd_file, contact, cci, score, sci, pdb, psf, init, final, out)

    if rmsd:
        call = "\nbigdcd_analyser " + dcd + "\nquit"
    else:
        call = "\npdb_writer_interval " + dcd + "\nquit"

    vmd_file.append(call)

    write_vmd(vmd_file, out, 'frame')


def prepare_energies(psf, pdb, dcd, out, init, final, program_path):
    """Write script to energy analysis"""

    log('info', 'Preparing .tcl file for energies analysis.')

    vmd_file = []

    vmd_file = write_get_chain(vmd_file, program_path, pdb)
    vmd_file = write_get_models(vmd_file, program_path, psf, pdb, dcd, out, init, final)
    vmd_file = write_energies(vmd_file, program_path)

    vmd_file = write_energies_variables(vmd_file, psf, dcd, init, final, out, program_path)

    call = "\nget_energies\nquit"
    vmd_file.append(call)

    write_vmd(vmd_file, out, 'energies')


def write_get_chain(script, program_path, pdb_path):
    """Append get_chain routine to script"""

    with open(F'{program_path}tcl/get_chain.tcl', 'r') as get_chain:
        file = get_chain.readlines()
        file[-1] = file[-1].replace('*pdb_path*', pdb_path)
        script.extend(file)
    return script


def write_get_models(script, program_path, psf, pdb, dcd, out, init, last):
    """Append get_models routine to script"""

    with open(F'{program_path}tcl/get_models.tcl', 'r') as get_chain:
        file = get_chain.readlines()
        file[-1] = file[-1].replace('*psf_path*', psf)
        file[-1] = file[-1].replace('*pdb_path*', pdb)
        file[-1] = file[-1].replace('*dcd_path*', dcd)
        file[-1] = file[-1].replace('*out_path*', out)
        file[-1] = file[-1].replace('*init*', str(init))
        file[-1] = file[-1].replace('*last*', str(last))
        script.extend(file)
    return script


def write_mol_create(script, program_path):
    """Append mol_create routine to script"""

    with open(F'{program_path}tcl/prepare_mol.tcl', 'r') as create:
        script.extend(create.readlines())
    return script


def write_bigdcd(script, program_path):
    """Append bigdcd routine to script"""

    with open(F'{program_path}tcl/bigdcd.tcl', 'r') as energies:
        script.extend(energies.readlines())
    return script


def write_rmsd(script, program_path):
    """Append rmsd_rmsf routine to script"""

    with open(F'{program_path}tcl/rmsd_rmsf.tcl', 'r') as rmsd:
        script.extend(rmsd.readlines())
    return script


def write_get_pdb(script, program_path, contact, score):
    """Append get_frame_pdb routine to script"""

    with open(F'{program_path}tcl/get_frame_pdb.tcl', 'r') as pdb_writer:
        file = pdb_writer.readlines()
        if not contact:
            file[10:16] = ''
        if not score:
            file[3:9] = ''

        script.extend(file)
    return script


def write_bigdcd_main(script, program_path, contact, score):
    """Append bigdcd_main routine to script"""

    with open(F'{program_path}tcl/bigdcd_main.tcl', 'r') as main:
        file = main.readlines()

        if not contact and not score:
            file[8] = ''

        script.extend(file)

    return script


def write_pdb_writer(script, program_path, score, contact):
    """Append pdb_writer routine to script"""

    with open(F'{program_path}tcl/pdb_writer.tcl', 'r') as pdb_writer:
        file = pdb_writer.readlines()
        if not contact:
            file[7:31] = ''
        if not score:
            file[32:56] = ''

        script.extend(file)
    return script


def write_energies(script, program_path):
    """Append energies_analysis routine to script"""

    with open(F'{program_path}tcl/energies_analysis.tcl', 'r') as energies:
        script.extend(energies.readlines())
    return script


def write_frame_variables(script, contact, cci, score, sci, pdb, psf, init, final, out):
    """Write variables for frame analysis"""

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


def write_energies_variables(script, psf, dcd, init, final, out, program_path):
    """Write variables for energies analysis"""

    script = set_variable(script, 'psf_path', psf)
    script = set_variable(script, 'dcd_path', dcd)
    script = set_variable(script, 'out_path', out)
    script = set_variable(script, 'namd_path', program_path + 'namd/')

    script = set_variable(script, 'init', init)
    script = set_variable(script, 'last', final)

    return script


def set_variable(script, variable, value):
    """Set a variables on script"""

    append = 'set ' + variable + ' ' + str(value) + '\n'
    script.append(append)
    return script


def write_vmd(script, out, name):
    """Saves script as temp file"""

    filename = out + 'temp_' + name + '_analysis.tcl'
    with open(filename, 'w') as analysis:
        analysis.write(''.join(script))
