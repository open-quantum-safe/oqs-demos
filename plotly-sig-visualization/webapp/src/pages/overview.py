import dash
import dash_mantine_components as dmc
import pandas as pd
from components.dataset import FEATURES
from components.dataset import data as df
from dash import ALL, Input, Output, State, callback, no_update

df = df.reset_index()

selected_algs = {alg: True for alg in df["Algorithm"].to_list()}
clicked_algs = {alg: False for alg in df["Algorithm"].to_list()}


selected = 0


def generate_radar_chart(alg_name):
    data = []
    raw_data = df[df["Algorithm"] == alg_name][FEATURES].squeeze(0)
    for i, val in enumerate(raw_data):
        data.append({"feature": FEATURES[i].split("(")[0].strip(), "value": val})
    return dmc.Box(
        children=[
            dmc.Stack(
                [
                    dmc.Checkbox(
                        id={
                            "type": "checkbox-alg",
                            "index": f"checkbox-{alg_name}",
                        },
                        checked=False,
                        size="xs",
                        variant="filled",
                        label=dmc.Text(
                            alg_name,
                            ta="center",
                            style={
                                "fontSize": "9pt",
                                "whiteSpace": "nowrap",
                                "overflow": "hidden",
                                "textOverflow": "ellipsis",
                            },
                        ),
                        persistence=True,
                        persistence_type="session",
                    ),
                    dmc.RadarChart(
                        id={
                            "type": "radar-chart",
                            "index": f"radar_{alg_name}",
                        },
                        h=250,
                        w=250,
                        data=data,
                        dataKey="feature",
                        withPolarGrid=True,
                        withPolarAngleAxis=True,
                        withPolarRadiusAxis=True,
                        polarRadiusAxisProps={
                            "angle": 90,
                            "scale": "log",
                            "domain": [1, 10**5],
                            "tick": False,
                        },
                        radarProps={
                            "isAnimationActive": False,
                        },
                        radarChartProps={
                            "margin": {
                                "top": 0,
                                "right": 0,
                                "bottom": 0,
                                "left": 0,
                            },
                            "outerRadius": "40%",
                        },
                        polarGridProps={
                            "outerRadius": -10,
                        },
                        series=[{"name": "value", "color": "blue.4", "opacity": 0.5}],
                    ),
                ],
                gap=0,
                p=0,
                align="center",
            ),
        ]
    )


dash.register_page(
    __name__,
    "/",
    title="PQC Digital Signatures",
    description="Comparative of PQC sigs available in OQS liboqs library.",
)

layout = [
    dmc.SimpleGrid(
        id="content",
        type="container",
        cols={
            "base": 1,
            "500px": 2,
            "750px": 3,
            "1000px": 4,
            "1250px": 5,
            "1500px": 6,
            "1750px": 7,
            "2000px": 8,
            "2250px": 9,
            "2500px": 10,
        },
        spacing=0,
        verticalSpacing="xs",
        children=[generate_radar_chart(alg) for alg in df["Algorithm"].to_list()],
    ),
]


@callback(
    [
        Output("selected-algs", "data"),
        Output("n-selected-algs", "data"),
    ],
    [
        Input("nist-security-levels-checkbox", "value"),
        Input("pubkey-slider", "value"),
        Input("privkey-slider", "value"),
        Input("signature-slider", "value"),
        Input("keypair-slider", "value"),
        Input("sign-slider", "value"),
        Input("verify-slider", "value"),
    ],
)
def update_filtered_algorithms(nist_levels, pubkey, privkey, sig, keypair, sign, verify):
    pubkey = [10 ** pubkey[0], 10 ** pubkey[1]]
    privkey = [10 ** privkey[0], 10 ** privkey[1]]
    all_algs = df["Algorithm"].to_list()
    try:
        tmp = pd.concat([df[df["NIST"] == int(l)] for l in nist_levels])
    except ValueError:
        return {alg: False for alg in all_algs}

    tmp = tmp[(tmp["Pubkey (bytes)"] >= int(pubkey[0])) & (tmp["Pubkey (bytes)"] <= int(pubkey[1]))]
    tmp = tmp[(tmp["Privkey (bytes)"] >= int(privkey[0])) & (tmp["Privkey (bytes)"] <= int(privkey[1]))]
    tmp = tmp[(tmp["Signature (bytes)"] >= int(sig[0])) & (tmp["Signature (bytes)"] <= int(sig[1]))]
    tmp = tmp[(tmp["Keygen (μs)"] >= keypair[0]) & (tmp["Keygen (μs)"] <= keypair[1])]
    tmp = tmp[(tmp["Sign (μs)"] >= int(sign[0])) & (tmp["Sign (μs)"] <= int(sign[1]))]
    tmp = tmp[(tmp["Verify (μs)"] >= int(verify[0])) & (tmp["Verify (μs)"] <= int(verify[1]))]

    selected = tmp["Algorithm"].to_list()
    selected_algs = {}
    for alg in all_algs:
        if alg in selected:
            selected_algs[alg] = True
        else:
            selected_algs[alg] = False
    return selected_algs, {"value": len(selected)}


@callback(
    [
        Output("content", "children", allow_duplicate=True),
        Output("website-title", "children", allow_duplicate=True),
    ],
    [
        Input("selected-algs", "data"),
        Input("n-selected-algs", "data"),
    ],
    State("url", "pathname"),
    prevent_initial_call="initial_duplicate",
)
def update_shown_charts(algs, n_algs, url):
    if url != "/":
        return no_update

    n_algs_total = df.shape[0]
    charts = []
    for alg_name in algs:
        if algs[alg_name]:
            charts.append(generate_radar_chart(alg_name))

    return (
        charts,
        f"PQC Digital Signatures ({n_algs["value"]} / {n_algs_total})",
    )


@callback(
    Output("clicked-algs", "data"),
    Input({"type": "checkbox-alg", "index": ALL}, "checked"),
    [
        State({"type": "checkbox-alg", "index": ALL}, "id"),
        State("url", "pathname"),
    ],
)
def update_clicked_algorithms(values, ids, url):
    if url == "/compare/":
        return no_update

    clicked_algs = {}
    for i, id_ in enumerate(ids):
        alg_name = "-".join(id_["index"].split("-")[1:])
        if values[i]:
            clicked_algs[alg_name] = True
        else:
            clicked_algs[alg_name] = False
    return clicked_algs


@callback(
    [
        Output("compare-button", "children"),
        Output("n-clicked-algs", "data"),
    ],
    Input("clicked-algs", "data"),
)
def update_compare_selection(clicked):
    if clicked is None:
        return no_update

    n_clicked = 0
    for alg in clicked:
        if clicked[alg]:
            n_clicked += 1
    return f"Compare ({n_clicked})", {"value": n_clicked}


@callback(
    Output({"type": "checkbox-alg", "index": ALL}, "disabled"),
    [Input("n-clicked-algs", "data")],
    [
        State({"type": "checkbox-alg", "index": ALL}, "checked"),
        State("n-selected-algs", "data"),
    ],
)
def disable_checkboxes(clicked, checked, selected):
    selected = selected["value"]
    if clicked["value"] < 5:
        return selected * [False]

    disabled_list = selected * [False]
    for i, id_ in enumerate(checked):
        if not id_:
            disabled_list[i] = True

    return disabled_list
