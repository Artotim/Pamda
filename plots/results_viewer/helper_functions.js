function openSideBar() {
    document.getElementById("mySidebar").style.display = "block";
    document.getElementById("myOverlay").style.display = "block";
    document.dispatchEvent(new CustomEvent('scroll'))
}


function closeSideBar() {
    document.getElementById("mySidebar").style.display = "none";
    document.getElementById("myOverlay").style.display = "none";
}


function escapeSpecial(text) {
    return text.replace(/\+/g, '\\+').replace(/\//g, '\\/')
}


function capitalizeFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
}


function chooseModel(model) {
    switch (model) {
        case "i":
        case "ul":
            return "Crystal";
        case "ap":
            return "Alphafold";
        case "sw":
            return "Swiss";
        case "t":
            return "i-Tasser";
    }
}


function generateDynamicTitle(dynamicName) {
    const dynamicInfo = dynamicName.split("_");
    const convertase = capitalizeFirstLetter(dynamicInfo[0]);
    const model = chooseModel(dynamicInfo[1]);
    const peptide_len = dynamicInfo[2];
    const peptide_model = dynamicInfo[3].toUpperCase();

    return `${convertase} ${model} + Peptide ${peptide_len}${peptide_model}`
}


function generateConvertaseTitle(convertase) {
    const dynamicInfo = convertase.split("_");
    const name = capitalizeFirstLetter(dynamicInfo[0]);
    const peptide_len = dynamicInfo[1];

    return `${name} + Pep${peptide_len}`
}
