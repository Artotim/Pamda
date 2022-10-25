const dynamic_data_legends = {
    "RMSD": [
        "Entire complex fit RMSD",
        "Chain x fit RMSD",
        "Chain x no fit RMSD",
        "Highlight residues fit RMSD"
    ],
    "RMSF": [
        "Chain x RMSF",
        "Chain x RMSF for each step",
        "Chain x RMSF initial 1/3 analysed frames",
        "Chain x RMSF middle of analysed frames",
        "Chain x RMSF last 1/3 analysed frames",
    ],
    "Contacts": [
        "Number of contactType contacts per frame between chains chainComb",
        "contactType contact heat map between chains chainComb in entire dynamic",
        "contactType contact heat map between chains chainComb through dynamic"
    ],
    "AllEnergies": [
        "All Bond energy",
        "All Angles energy",
        "All Dihedrals energy",
        "All Impropers energy",
        "All Electrostatic energy",
        "All VdW energy",
        "All Conformational energy",
        "All Nonbond energy",
        "All Total energy"
    ],
    "InteractionEnergies": [
        "Chains chainComb interaction Electrostatic energy",
        "Chains chainComb interaction VdW energy",
        "Chains chainComb interaction Nonbond energy",
        "Chains chainComb interaction Total energy"
    ],
    "SASA": [
        "sasaSelection SASA and BSA total areas",
        "sasaSelection SASA and BSA percentage areas",
    ]
};


const toTitleCase = (phrase) => {
    return phrase
        .toLowerCase()
        .split(' ')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');
};


function getCombinations(chainsList) {
    return chainsList.flatMap(
        (v, i) => chainsList.slice(i + 1).map(w => v + '-' + w)
    );
}


function componentUpdated() {
    $('.gallery').flickity({
        fullscreen: true
    });

    createInfo();
    if (window.location.hash && $(window.location.hash).get(0)) {
        $(window.location.hash).get(0).scrollIntoView();
    }
}


class ConvertasePage extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            folder: './',
            name: "",
            dynamicInfo: NaN,
            requestedAnalysis: [],
            chains: []
        };
    }

    async componentDidMount() {
        const response = await fetch("../analysis_request_parameters.json");
        const dynamicInfo = await response.json();

        this.setState({
            'name': dynamicInfo["Name"],
            'dynamicInfo': dynamicInfo,
            'requestedAnalysis': dynamicInfo["Requested analysis"].split(", "),
            'chains': dynamicInfo["Chains"].split(", "),
        }, componentUpdated());

        document.title = dynamicInfo["Name"] + " - Dynamic Analysis Results";
    }

    componentDidUpdate() {
        componentUpdated();
    }

    render() {
        return (
            <div id='content-holder'>
                <div id="Title">
                    <h1>{toTitleCase(this.state.name)} Analysis Results</h1>
                </div>
                <div id="content-body">
                    <Info name={this.state.name} dynamicInfo={this.state.dynamicInfo}/>
                    <Rmsd name={this.state.name} folder={this.state.folder} chains={this.state.chains}
                          hgl={!!this.state.dynamicInfo["Highlight residues"]}
                          shouldRender={this.state.requestedAnalysis.includes("RMS")}/>
                    <Rmsf name={this.state.name} folder={this.state.folder} chains={this.state.chains}
                          shouldRender={this.state.requestedAnalysis.includes("RMS")}/>
                    <Contact name={this.state.name} folder={this.state.folder} chains={this.state.chains}
                             shouldRender={this.state.requestedAnalysis.includes("Contacts")}/>
                    <AllEnergies name={this.state.name} folder={this.state.folder}
                                 shouldRender={this.state.requestedAnalysis.includes("Energies")}/>
                    <InteractionEnergies name={this.state.name} folder={this.state.folder} chains={this.state.chains}
                                         shouldRender={this.state.requestedAnalysis.includes("Energies")}/>
                    <Distances name={this.state.name} folder={this.state.folder}
                               pairs={this.state.dynamicInfo["Distances pairs"]}
                               type={this.state.dynamicInfo["Distances type"]}
                               shouldRender={this.state.requestedAnalysis.includes("Distances")}/>
                    <Sasa name={this.state.name} folder={this.state.folder} chains={this.state.chains}
                          hgl={this.state.dynamicInfo["Highlight residues"]}
                          shouldRender={this.state.requestedAnalysis.includes("SASA")}/>
                </div>
            </div>
        );
    }
}


const Info = props => {
    let infoDisplay = [];
    Object.keys(props.dynamicInfo).forEach((info, idx) => {
        let infoText = props.dynamicInfo[info];

        const infoElement = <span key={idx}>{infoText}<br/></span>;

        infoDisplay.push(
            <li className="info" key={idx}><strong>{info}:</strong> {infoElement}</li>
        );
    });


    return (
        <div className="data" id="Analysis-Parameters">
            <h2>Analysis Parameters</h2>
            <div className="dynamic-data">
                {infoDisplay}
            </div>
        </div>
    );
};


const Rmsd = props => {
    if (!props.shouldRender) return null;

    const folder = `${props.folder}rms/`;

    const rmsdImages = ['_all_rmsd.png'];
    const legend = [dynamic_data_legends["RMSD"][0]];

    props.chains.forEach(chain => {
        rmsdImages.push(...[`_chain_${chain}_fit_rmsd.png`, `_chain_${chain}_no_fit_rmsd.png`]);
        legend.push(...[dynamic_data_legends["RMSD"][1].replace("x", chain), dynamic_data_legends["RMSD"][2].replace("x", chain)]);
    });

    if (props.hgl) {
        rmsdImages.push("_highlight_rmsd.png");
        legend.push(dynamic_data_legends["RMSD"][3]);
    }

    let display = [];
    rmsdImages.forEach((image, idx) => {
        display.push(
            <div className="gallery-cell" key={idx}>
                <img className="img" src={folder + props.name + image} alt="RMSD plot"/>
                <div className='legend bigger'>{legend[idx]}</div>
            </div>
        );
    });

    return (
        <div className="data" id="RMSD">
            <h2>RMSD <i className="fa fa-info-circle info-icon"></i></h2>
            <div id="Rmsd" className="gallery js-flickity">
                {display}
            </div>
        </div>
    );
};


const Rmsf = props => {
    if (!props.shouldRender) return null;

    const folder = `${props.folder}rms/`;
    const legend = [];

    let display = [];
    let totalImageIdx = 0;

    props.chains.forEach(chain => {
        const rmsfImages = [
            '_chain_' + chain + '_rmsf.png',
            '_chain_' + chain + '_rmsf_steps.png',
            '_chain_' + chain + '_rmsf_init.png',
            '_chain_' + chain + '_rmsf_middle.png',
            '_chain_' + chain + '_rmsf_final.png',
        ];

        legend.push(...dynamic_data_legends["RMSF"].map(x => x.replace("x", chain)));

        rmsfImages.forEach((image) => {
            display.push(
                <div className="gallery-cell trio" key={totalImageIdx}>
                    <img className="img" src={folder + props.name + image}
                         alt="RMSF plot"/>
                    <div
                        className='legend bigger'>{legend ? legend[totalImageIdx] : ''}
                    </div>
                </div>
            );

            totalImageIdx++;
        });
    });

    return (
        <div className="data" id="RMSF">
            <h2>RMSF <i className="fa fa-info-circle info-icon"></i></h2>
            <div id="Rmsf" className="gallery trio js-flickity">
                {display}
            </div>
        </div>
    );
};


const Contact = props => {
    if (!props.shouldRender) return null;

    const folder = `${props.folder}contacts/`;

    const contactTypes = ["nonbond", "hbonds", "sbridges"];
    const contactLegendTypes = ["Non-bonded", "Hydrogen Bonds", "Salt Bridges"];
    const chainsComb = getCombinations(props.chains);

    let display = [];
    let totalImageIdx = 0;

    chainsComb.forEach(comb => {
        contactTypes.forEach((type, idx) => {

            const legends = [...dynamic_data_legends["Contacts"].map(x => x.replace("chainComb", comb).replace("contactType", contactLegendTypes[idx]))];

            display.push(
                <div className="gallery-cell" key={totalImageIdx}>
                    <img className="img"
                         src={folder + props.name + '_' + comb + '_' + type + '_count.png'}
                         alt="Contact count plot"/>
                    <div className='legend bigger'>{legends[0]}</div>
                </div>
            );
            display.push(
                <div className="gallery-cell" key={totalImageIdx + 1}>
                    <img className="img"
                         src={folder + props.name + '_' + comb + '_' + type + '_contacts_map.png'}
                         alt="Contact map plot"/>
                    <div className='legend bigger'>{legends[1]}</div>
                </div>
            );
            display.push(
                <div className="gallery-cell" key={totalImageIdx + 2}>
                    <video className="contact-video" autoPlay muted loop controls>
                        <source
                            src={folder + props.name + '_' + comb + '_' + type + '_contacts_map_steps.mp4'}/>
                    </video>
                    <div className='legend bigger'>{legends[2]}</div>
                </div>
            );

            totalImageIdx = totalImageIdx + 3;
        });
    });

    return (
        <div className="data" id="Contacts">
            <h2>Contacts <i className="fa fa-info-circle info-icon"></i></h2>
            <div id="Contacts" className="gallery js-flickity">
                {display}
            </div>
        </div>
    );
};


const AllEnergies = props => {
    if (!props.shouldRender) return null;

    const folder = `${props.folder}energies/`;

    let display = [];

    const allEnergies = ['Bond', 'Angle', 'Dihed', 'Impr', 'Elec', 'VdW', 'Conf', 'Nonbond', 'Total'];

    allEnergies.forEach((image, idx) => {
        display.push(
            <div className="gallery-cell trio" key={idx}>
                <img className="img"
                     src={folder + props.name + '_all_' + image + '_energy.png'}
                     alt="Complex energies plot"/>
                <div className='legend bigger'>{dynamic_data_legends["AllEnergies"][idx]}</div>
            </div>
        );
    });

    return (
        <div className="data" id="Contacts">
            <h2>All Energies <i className="fa fa-info-circle info-icon"></i></h2>
            <div id="All-Energies" className="gallery trio js-flickity">
                {display}
            </div>
        </div>
    );
};


const InteractionEnergies = props => {
    if (!props.shouldRender || props.chains.length < 2) return null;

    const folder = `${props.folder}energies/`;

    const interaction_energies = ['Elec', 'VdW', 'Nonbond', 'Total'];
    const chainsComb = getCombinations(props.chains);
    let display = [];
    let totalImageIdx = 0;

    chainsComb.forEach(comb => {
        interaction_energies.forEach((image, idx) => {
            const legends = [...dynamic_data_legends["InteractionEnergies"].map(x => x.replace("chainComb", comb))];

            display.push(
                <div className="gallery-cell trio" key={totalImageIdx}>
                    <img className="img"
                         src={folder + props.name + '_' + comb + '_interaction_' + image + '_energy.png'}
                         alt="Interaction energies plot"/>
                    <div className='legend bigger'>{legends[idx]}</div>
                </div>
            );

            totalImageIdx++;
        });
    });


    return (
        <div className="data" id="Contacts">
            <h2>Interaction Energies <i className="fa fa-info-circle info-icon"></i></h2>
            <div id="Interaction-Energies" className="gallery trio js-flickity">
                {display}
            </div>
        </div>
    );
};


const Distances = props => {
    if (!props.shouldRender) return null;

    const folder = `${props.folder}distances/`;
    const pairs = props.pairs.split(", ");
    const type = props.type === "atom" ? "atoms" : "residues";

    let display = [];

    for (let pairNum = 1; pairNum <= pairs.length; pairNum++) {
        const pair = pairs[pairNum - 1].split(" ");
        const legend = `Distances between ${type} ${pair[0]} and ${pair[1]}`;

        display.push(
            <div className="gallery-cell trio" key={pairNum}>
                <img className="img"
                     src={folder + props.name + '_pair' + pairNum + '_distance.png'}
                     alt="Distances between queries plot"/>
                <div className='legend bigger'>{legend}</div>
            </div>
        );
    }

    return (
        <div className="data" id={"Distances"}>
            <h2>Distances <i className="fa fa-info-circle info-icon"></i></h2>
            <div id="Distances" className="gallery trio js-flickity">
                {display}
            </div>
        </div>
    );
};


const Sasa = props => {
    if (!props.shouldRender) return null;

    const folder = `${props.folder}sasa/`;

    const sasaSelections = [{name: "all", type: "all"}];
    props.chains.forEach(chain => {
        sasaSelections.push({name: chain, type: "chain"});
    });
    props.hgl.split(", ").forEach(resid => {
        sasaSelections.push({name: resid, type: "resid"});
    });

    const sasaTypes = ["area", "percentage"];

    let display = [];
    let totalImageIdx = 0;

    sasaSelections.forEach(selection => {
        let selectionName, selectionImage
        switch (selection.type) {
            case "all":
                selectionName = "All"
                selectionImage = selection.name
                break;
            case "chain":
                selectionName = capitalizeFirstLetter(selection.type) + " " + selection.name
                selectionImage = selection.type + "_" + selection.name
                break;
            case "resid":
                selectionName = "Residue " + selection.name
                selectionImage = selection.type + "_" + selection.name.split(":")[2] + selection.name.split(":")[0]
                break;
        }

        sasaTypes.forEach((type, idx) => {
            const legend = dynamic_data_legends["SASA"][idx].replace("sasaSelection", selectionName)
            display.push(
                <div className="gallery-cell trio" key={totalImageIdx}>
                    <img className="img"
                         src={folder + props.name + '_' + selectionImage + '_sasa_bsa_' + type + '.png'}
                         alt="SASA plot"/>
                    <div className='legend bigger'>{legend}</div>
                </div>
            );
            totalImageIdx++;
        });
    });

    return (
        <div className="data" id={"Distances"}>
            <h2>SASA <i className="fa fa-info-circle info-icon"></i></h2>
            <div id="SASA" className="gallery trio js-flickity">
                {display}
            </div>
        </div>
    );
};


ReactDOM.render(<ConvertasePage/>, document.querySelector('#content'));
