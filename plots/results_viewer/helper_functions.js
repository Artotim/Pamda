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
