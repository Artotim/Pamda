async function fetchRequestedAnalysis() {
    const response = await fetch("../analysis_request_parameters.json");
    const json = await response.json();

    let referenceList = ["Analysis Parameters"];
    const requestedAnalysis = json["Requested analysis"].split(", ")

    if (requestedAnalysis.includes("RMS")) referenceList.push(...["RMSD", "RMSF"])
    if (requestedAnalysis.includes("Contacts")) referenceList.push("Contacts")
    if (requestedAnalysis.includes("Energies")) {
        referenceList.push("All Energies")
        json["Chains"].split(", ").length >= 2 && referenceList.push("Interaction Energies")
    }
    if (requestedAnalysis.includes("Distances")) referenceList.push("Distances")
    if (requestedAnalysis.includes("SASA")) referenceList.push("SASA")

    return referenceList
}


class NavBar extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            referenceList: []
        };
    }

    async componentDidMount() {
        const referenceList = await fetchRequestedAnalysis()

        this.setState({
            'referenceList': referenceList
        });

    }

    componentDidUpdate() {
        const $root = $('html, body');

        $('#title-holder > a').click(function() {
            const href = $.attr(this, 'href');
            const offset = 140

            $root.animate({
                scrollTop: $(escapeSpecial(href)).offset().top - offset
            }, 300, function () {
                window.location.hash = href;
            });

            return false;
        });
    }

    render() {
        let sideMenu = [];

        this.state.referenceList.forEach((reference, idx) => {
            sideMenu.push(
                <DisplayTitle
                    key={idx}
                    idx={idx}
                    title={reference}
                />
            );
        });

        return (
            <div id="title-holder">
                {sideMenu}
            </div>
        );
    }
}


const DisplayTitle = props => {
    let title = props.title;
    let className = props.idx === 0 ? "sidebar-item sidebar-item-now" : "sidebar-item";

    return (
        <a
            className={className}
            href={'#' + title.replace(" ", "-")}
            onClick={closeSideBar}
        >
            {title}
        </a>
    );
};


ReactDOM.render(<NavBar/>, document.querySelector('#nav-titles'));


$(document ).ready(function() {
    const selector = ".data > h2"

    $(document).scroll(function () {

        const windowTop = $(window).scrollTop() + 50;
        const pageElements = $(selector);
        let topElementTitle

        for (let idx = 0; idx < pageElements.length; idx++) {
            if ($(pageElements[idx]).position().top >= windowTop) {
                topElementTitle = $(pageElements[idx]).text().trim()
                break
            }
        }

        $("#title-holder > a").each((index, element) => $(element).removeClass("sidebar-item-now"))
        $(`.sidebar-item:contains(${topElementTitle})`).each((idx, sidebarElement) => {
            if ($(sidebarElement).text() === topElementTitle) {
                $(sidebarElement).addClass("sidebar-item-now");
                if ($('#title-holder:hover').length === 0) $(sidebarElement).get(0).scrollIntoView();
            }
        })
    });
})
