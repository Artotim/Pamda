const tooltip = document.getElementById('infoTooltip');

const tooltipInfo = {
    "Structure": "Pdb model representation.",
    "RMSD": "RMSD fit and no fit measured in Ångstroms for entire complex and each chain.",
    "RMSF": "RMSF measure in Ångstroms for each chain and for dynamic slices.",
    "Contacts": "Contacts count and maps between chains.",
    "All Energies": "Energies for the entire molecule measured through dynamic.",
    "Interaction Energies": "Energies for the chain interactions measured through dynamic.",
    "Distances": "Distances in Ångstroms between queries.",
    "SASA": "Solvent Accessible Surface Area and Buried Surface Area in Ångstroms and percentage through dynamic."
};

function createInfo() {
    $('.info-icon').mousemove((e) => {
            let data = e.target.parentNode.textContent.trim();
            tooltip.style.display = "block";
            tooltip.textContent = tooltipInfo[data];
            tooltip.style.left = (e.pageX + 30) + 'px';
            tooltip.style.top = e.pageY + 'px';
        }
    );
    $('.info-icon').mouseleave(() => {
            tooltip.style.display = "none";
        }
    );
}

