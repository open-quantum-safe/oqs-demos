import dash_mantine_components as dmc
import numpy as np
from dash import ALL, Input, Output, State, callback, html
from dash_iconify import DashIconify


def nist_security_level_filter():
    return html.Div(
        [
            dmc.Stack(
                [
                    dmc.Title("Nist Security Level", order=4),
                    dmc.Group(
                        [
                            dmc.ChipGroup(
                                [
                                    dmc.Chip("1", value="1"),
                                    dmc.Chip("2", value="2"),
                                    dmc.Chip("3", value="3"),
                                    dmc.Chip("4", value="4"),
                                    dmc.Chip("5", value="5"),
                                ],
                                multiple=True,
                                value=["1", "2", "3", "4", "5"],
                                id="nist-security-levels-checkbox",
                            ),
                        ]
                    ),
                ],
                gap="xs",
            )
        ]
    )


def sizes_filter():
    return html.Div(
        [
            dmc.Stack(
                [
                    dmc.Title("Keys & Signatures sizes", order=4),
                    dmc.Title("Public key (bytes)", order=5),
                    dmc.RangeSlider(
                        id="pubkey-slider",
                        min=np.log10(32),
                        max=np.log10(3_000_000),
                        step=0.1,
                        minRange=1,
                        value=(np.log10(32), np.log10(3_000_000)),
                        updatemode="mouseup",
                        label=None,
                        marks=[
                            {"value": np.log10(32), "label": "32"},
                            {"value": np.log10(256), "label": "256"},
                            {"value": np.log10(1_000), "label": "1K"},
                            {"value": np.log10(5_000), "label": "5K"},
                            {"value": np.log10(100_000), "label": "100K"},
                            {"value": np.log10(3_000_000), "label": "3M"},
                        ],
                        mb=10,
                    ),
                    dmc.Title("Private key (bytes)", order=5),
                    dmc.RangeSlider(
                        id="privkey-slider",
                        min=np.log10(24),
                        max=np.log10(2_500_000),
                        step=0.1,
                        minRange=1,
                        value=(np.log10(24), np.log10(2_436_704)),
                        updatemode="mouseup",
                        label=None,
                        marks=[
                            {"value": np.log10(24), "label": "24"},
                            {"value": np.log10(256), "label": "256"},
                            {"value": np.log10(1_000), "label": "1K"},
                            {"value": np.log10(5_000), "label": "5K"},
                            {"value": np.log10(100_000), "label": "100K"},
                            {"value": np.log10(2_500_000), "label": "2.5M"},
                        ],
                        mb=10,
                    ),
                    dmc.Title("Signature size (bytes)", order=5),
                    dmc.RangeSlider(
                        id="signature-slider",
                        min=64,
                        max=76_298,
                        value=(64, 76_298),
                        updatemode="drag",
                        label=None,
                        marks=[
                            {"value": 64, "label": "64"},
                            {"value": 20_000, "label": "10K"},
                            {"value": 40_000, "label": "30K"},
                            {"value": 60_000, "label": "50K"},
                            {"value": 76_298, "label": "76K"},
                        ],
                    ),
                ]
            )
        ]
    )


def performance_filters():
    return html.Div(
        [
            dmc.Stack(
                [
                    dmc.Title("Performance", order=4),
                    dmc.Title("Keypair generation", order=5),
                    dmc.RangeSlider(
                        id="keypair-slider",
                        min=0,
                        max=2_600_000,
                        value=(0, 2_600_000),
                        updatemode="drag",
                        label=None,
                        marks=[
                            {"value": 0, "label": "0ms"},
                            # {"value": 1_000, "label": "10ms"},
                            # {"value": 10_000, "label": "100ms"},
                            {"value": 500_000, "label": "500ms"},
                            {"value": 1_000_000, "label": "1s"},
                            {"value": 1_500_000, "label": "1.5s"},
                            {"value": 2_000_000, "label": "2s"},
                            {"value": 2_600_000, "label": "2.6s"},
                        ],
                        mb=10,
                    ),
                    dmc.Title("Signature creation", order=5),
                    dmc.RangeSlider(
                        id="sign-slider",
                        min=0,
                        max=350_000,
                        value=(0, 350_000),
                        updatemode="drag",
                        label=None,
                        marks=[
                            {"value": 0, "label": "0"},
                            {"value": 50_000, "label": "50ms"},
                            {"value": 150_000, "label": "150ms"},
                            {"value": 250_000, "label": "250ms"},
                            {"value": 350_000, "label": "350ms"},
                        ],
                        mb=10,
                    ),
                    dmc.Title("Signature verification", order=5),
                    dmc.RangeSlider(
                        id="verify-slider",
                        min=0,
                        max=3000,
                        value=(0, 3000),
                        updatemode="drag",
                        label=None,
                        marks=[
                            {"value": 0, "label": "0"},
                            {"value": 1000, "label": "1ms"},
                            {"value": 2000, "label": "2ms"},
                            {"value": 3000, "label": "3ms"},
                        ],
                        mb=40,
                    ),
                ]
            )
        ]
    )


def create_alg_filters():
    return html.Div(
        [
            dmc.Container(
                size="405px",
                px="xs",
                children=[
                    nist_security_level_filter(),
                    dmc.Space(h="xl"),
                    sizes_filter(),
                    dmc.Space(h="xl"),
                    performance_filters(),
                    dmc.Space(h="xs"),
                    dmc.Button(
                        "Reset All",
                        id="reset-button",
                        leftSection=DashIconify(icon="tabler:zoom-reset"),
                    ),
                ],
            )
        ]
    )


def create_navbar(data):
    return dmc.AppShellNavbar(
        id="navbar",
        children=[
            dmc.ScrollArea(
                [
                    create_alg_filters(),
                ],
                type="scroll",
                w=410,
                h=1000,
            )
        ],
        p="xs",
    )


@callback(
    [
        Output("nist-security-levels-checkbox", "value"),
        Output("pubkey-slider", "value"),
        Output("privkey-slider", "value"),
        Output("signature-slider", "value"),
        Output("keypair-slider", "value"),
        Output("sign-slider", "value"),
        Output("verify-slider", "value"),
        Output({"type": "checkbox-alg", "index": ALL}, "checked"),
    ],
    Input("reset-button", "n_clicks"),
    State({"type": "checkbox-alg", "index": ALL}, "checked"),
    prevent_initial_call=True,
)
def reset_filters(n_clicks, algs):
    return (
        ("1", "2", "3", "4", "5"),
        (np.log10(32), np.log10(2_900_000)),
        (np.log10(24), np.log10(2_500_000)),
        (0, 76_298),
        (0, 2_600_000),
        (0, 350_000),
        (0, 3000),
        len(algs) * [False],
    )
