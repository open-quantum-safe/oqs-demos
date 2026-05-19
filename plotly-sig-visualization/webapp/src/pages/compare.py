import dash
import dash_mantine_components as dmc
import pandas as pd
from components.dataset import FEATURES
from components.dataset import data as df
from dash import Input, Output, State, callback, no_update

COLORS = ["#ff6b6b", "#339af0", "#51cf66", "#fcc419", "#cc5de8"]

dash.register_page(
    __name__,
    "/compare",
    title="PQC DS",
    description="Comparative of PQC sigs available in OQS liboqs library.",
)

df = df.reset_index()
df = df[
    [
        "Algorithm",
        "NIST",
        "Pubkey (bytes)",
        "Privkey (bytes)",
        "Signature (bytes)",
        "Keygen (μs)",
        "Sign (μs)",
        "Verify (μs)",
    ]
]
df.rename(columns={"NIST": "NIST Security Level"}, inplace=True)

layout = [
    dmc.Stack(
        [],
        id="content",
        align="center",
        justify="flex-start",
        gap=0,
    ),
]


def generate_table(algs):
    data = []
    tmp = pd.concat([df[df["Algorithm"] == alg_name] for alg_name in algs if algs[alg_name]])
    for i, row in tmp.iterrows():
        alg_name = row["Algorithm"]
        nist_level = row["NIST Security Level"]
        sizes = [f"{row.values[i]}" for i in range(2, 5)]
        times = [f"{row.values[i]:.1f}" for i in range(5, 8)]
        data.append([alg_name, nist_level] + sizes + times)

    return dmc.Container(
        [
            dmc.Table(
                striped=True,
                highlightOnHover=True,
                withTableBorder=True,
                withColumnBorders=True,
                data={
                    "head": df.columns.to_list(),
                    "body": data,
                },
            )
        ],
        size="90%",
    )


def generate_radar(algs):
    data = []
    tmp = pd.concat([df[df["Algorithm"] == alg_name] for alg_name in algs if algs[alg_name]])
    for feature in FEATURES:
        serie = {"feature": feature}
        for i, row in tmp.iterrows():
            serie[row["Algorithm"]] = row[feature]
        data.append(serie)

    series = []
    count = 0
    for alg in algs:
        if algs[alg]:
            series.append({"name": alg, "color": COLORS[count], "opacity": 0.25})
            count += 1

    return dmc.RadarChart(
        w=600,
        h=600,
        data=data,
        dataKey="feature",
        withPolarGrid=True,
        withPolarAngleAxis=True,
        withPolarRadiusAxis=True,
        polarRadiusAxisProps={
            "angle": 60,
            "scale": "log",
            "domain": [1, 10**6],
        },
        radarProps={
            "isAnimationActive": True,
        },
        withLegend=True,
        series=series,
    )


@callback(
    [
        Output("content", "children", allow_duplicate=True),
        Output("website-title", "children", allow_duplicate=True),
    ],
    [
        Input("clicked-algs", "data"),
        Input("url", "pathname"),
    ],
    State("n-clicked-algs", "data"),
    prevent_initial_call="initial_duplicate",
)
def update_comparison(clicked_algs, url, n_clicked):
    if url != "/compare/":
        return no_update

    if n_clicked is None:
        return no_update

    if n_clicked["value"] < 1:
        return no_update

    return (
        [
            generate_radar(clicked_algs),
            generate_table(clicked_algs),
        ],
        "PQC Signatures",
    )
