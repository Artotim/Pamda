# Protein-peptide `.dcd` dynamics analysis
This software generates analysis data from a dynamic run in `.dcd` format for a protein-peptide complex, or a single protein.

It can generate *csv* and plot files with information about contact hits between chains; map contacts between chain residues; RMSD general and for individual chains or residues; RMSF for each residue; complex energies; interaction energies; and distances between set of atoms or residues.

## Contacts
Analyze contacts between chains every frame interval. Reports number of contacts for each frame and maps which residues and atoms are contacting for the entire simulation.
 
`-C` Enables contact analysis.  
`-cti` Defines interval for running contact analysis.
`--cutoff` Defines max Ångström to look for contacts.

## RMSD and RMSF
Measures RMSD in each frame, for the entire complex and separated chains, and measure RMSF for each residue. 

`-R` Enables RMSD and RMSF analysis.

## Energies
Measures angles, bond, conformational, dihedrals, electrostatic , impropers, nonbond, vdW, and total energies in the complex and between chains interaction.

`-E` Enables energies analysis.

## Distances
Measures distances in Ångström between a pair of atom os residues.

`-dpair` Specify a pair of residues, or atoms, to measure distances. More than one pair can be passed. You can pecify the chains using comma notation (i.e. 25:A).  
`-dtype` Type of indexes passed as pairs to measure distance.

## Plots
Optionally you can plot the analysis results to a *png* file.

`-R` Enables analysis plotting.

## Installation
This software uses third party programs and requires you to first install/obtain them.

VMD must be obtained from [University of Illinois](https://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD).  

After this, send an email with both licenses to [pyrthur@gmail.com](pyrthur@gmail.com) to get access to the download link.

Download the program and untar it with:

    tar -zxvf path/to/program.tar.gz

Then give it executable permissions:
 
    chmod +x path/to/program/dynamic_analysis

## Usage
You can set the program to your path or simply run it with ./dynamic_analysis

Basic usage: 
```
dynamic_analysis -dcd <dcd_file.dcd> -pdb <pdb_file.pdb> -psf <psf_file.pdf> -<analysis>`
```

## Options

### Required:
`-dcd` `DCD_PATH`  
Indicates the path to your `dcd` file.

`-pdb` `PDB_PATH`  
Indicates the path to your `pdb` file.  

`-psf` `PSF_PATH`  
Indicates the path to your `pdf` file.

### Optional:
`-h`, `--help`  
Show help message and exit.
***

`-n`, `--name` `NAME`  
Prefix to name output files (default: same as `dcd`).

`-o`, `--output` `OUTPUT_PATH`  
Path to output folder. Creates one if not exist.
***

` -i`, `--init` `INT`  
Frame to start analysis (default: first).

`-l`, `--last` `INT`  
Frame to end analysis (default: last).
***

`-vmd`, `--vmd-exe` `VMD_PATH`  
Indicates the path to your vmd executable.
***

`-dpair`, `--dist-pair`  `IDX IDX`
Index pairs to measure distances. Use this argument once for each pair. Specify the chains using comma notation (i.e. 25:A).

`-dtype`, `--dist-type` `INT`  
Type of index passed as distance pairs. Must be atom or resid (default:resid).
***

`-C`, `--contact`  
Run contact count and map analysis (default: False).

`-cti`, `--contact-interval` `INT`  
Frame interval number to perform contact analysis.

`-cutoff`, `INT`  
Max angstroms range to look for contacts (default: 3).
***

`-R`, `--rmsd`   
Run rmsd and rmsf analysis default: False).
***

`-E`, `--energies`  
Run energies analysis (default: False).
***

`-G`, `--graphs`
Plot analysis graphs (default: False).

***
`--compare-rmsd` `ALL.CSV` `RESIDUE.CSV`  
Path to compare output rmsd files to plot compare stats (must include all and residue `csv`).

`--compare-energies` `ENERGIES.CSV`  
Path to compare output energies file to compare stats.
***

`-cat`, `--catalytic-site` `INT` `INT` `...`  
Pass a list of residues to highlight on plots and also get specific plots.
***
     
## Disclaimer

This product comes with no warranty whatsoever.  

This product is not an official VMD release or has any affiliation to it.  

This software includes code developed by the Theoretical and Computational Biophysics Group in the Beckman Institute for Advanced Science and Technology at the University of Illinois at Urbana-Champaign.
 
Third party licenses not obtained by the user are provided with its software. 

### Known issues and improvements to do
- Provide full standalone program
