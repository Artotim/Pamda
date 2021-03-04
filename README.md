# DCD protein-peptide analysis
This software generates analysis data from a dynamic run between protein-peptide interaction, or a single protein.

It can generate *csv* files with information about contact hits between chains; contact map for residues; RMSD general and for individual chains; RMSF; interaction energies; complex energies; and binding score.

## Contacts
Uses [pychimera](https://pypi.org/project/pychimera/) to analyze contacts between chains every frame interval. Reports number of contacts for each frame and maps which residues are contacting.
 
`-C` Enables contact analysis.  
`-cti` Defines interval for running contact analysis.

## RMSD and RMSF
Uses [VMD](https://www.ks.uiuc.edu/Research/vmd/) to measure RMSD in each frame, for the entire complex and separated chains, and also measure RMSF. 

`-R` Enables RMSD and RMSF analysis.

## Energies
Uses [NAMD](https://www.ks.uiuc.edu/Research/namd/) to measure several energies in the complex and between chains interaction.

`-E` Enables energie analysis.

## Score
Uses [Rosetta](https://www.rosettacommons.org/) scoring function to generate binding scores every frame interval.

`-S` Enables contact analysis.  
`-sci` Defines interval for running scoring analysis.

## Plots
Optionally you can plot the analysis results to a *png* file.

`-R` Enables analysis plotting.

Requires [R](https://www.r-project.org/) installed.

## Installation
This software uses third party programs and requires you to first install/obtain them.

VMD must be obtained from [University of Illinois](https://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD).  
Pychimera must be installed both the [exe version](https://www.cgl.ucsf.edu/chimera/download.html) and the [python module](https://pypi.org/project/pychimera/). 

Then you must obtain a license for NAMD with [University of Illinois](https://www.ks.uiuc.edu/Development/Download/download.cgi?UserID=&AccessCode=&ArchiveID=1641). And a license for [rosetta](https://els2.comotion.uw.edu/product/rosetta).

After this send an email with both licenses to [pyrthur@gmail.com](pyrthur@gmail.com) to get access to the download link.

Download the program and untar it with:

    tar -zxvf path/to/program.tar.gz

Then give it executable permissions:
 
    chmod +x path/to/program/dinamic_analysis

## Usage
You can set the program to your path or simply run it with ./dinamic_analysis

Basic usage: 
```
dinamic_analysis -d <dcd_file.dcd> --pdb <pdb_file.pdb> --psf <psf_file.pdf> -C -S -R -E -G`
```

## Options

### Required:
`-d` , `--dcd` `DCD_PATH`  
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
Path to an empty output folder. Creates one if not exist.
***

` -i`, `--init` `INT`  
Frame to start analysis (default: first).

`-l`, `--last` `INT`  
Frame to end analysis (default: last).
***

`-vmd`, `--vmd-exe` `VMD_PATH`  
Indicates the path to your vmd executable.
***

`-S`, `--score`  
Run binding score analysis with rosetta (default: False).

`-sci`, `--scoring-interval` `INT`  
Frame interval number to perform score analysis.
***

`-C`, `--chimera`  
Run contact map analysis with chimera (default: False).

`-cti`, `--contact-interval` `INT`  
Frame interval number to perform contact analysis.
***

`-R`, `--rmsd`   
Run rmsd and rmsf analysis with vmd (default: False).
***

`-E`, `--energies`  
Run energies analysis with namd and vmd (default: False).
***

`-G`, `--graphs`
Plot analysis graphs (default: False).

***
`--alone-rmsd` `ALL.CSV` `RESIDUE.CSV`  
Path to alone output rmsd files to plot compare stats (must include all and residue `csv`).

`--alone-energies` `ENERGIES.CSV`  
Path to alone output energies file to compare stats.
***

`-cat`, `--catalytic-site` `INT` `INT` `...`  
Pass a list of residues to display on graphs and get specific plots.
***
     
## Disclaimer

This product comes with no warranty whatsoever.  

This product is not an official VMD release or has any affiliation to it.  
This product is not an official NAMD release or has any affiliation to it.  
This product is not an official pychimera release or has any affiliation to it.  
This product is not an official Rosetta release or has any affiliation to it.  

This software includes code developed by the Theoretical Biophysics Group in the Beckman Institute for Advanced Science and Technology at the University of Illinois at Urbana-Champaign.  
This software includes code developed by the Theoretical and Computational Biophysics Group in the Beckman Institute for Advanced Science and Technology at the University of Illinois at Urbana-Champaign.
 
Third party licenses not obtained by the user are provided with its software. 

### Known issues and improvements to do
- Provide full standalone program
