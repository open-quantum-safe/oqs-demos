import dash_mantine_components as dmc
from dash import Input, Output, clientside_callback, dcc
from dash_iconify import DashIconify

theme_toggle = dmc.Switch(
    offLabel=DashIconify(icon="radix-icons:sun", width=15, color=dmc.DEFAULT_THEME["colors"]["yellow"][8]),
    onLabel=DashIconify(
        icon="radix-icons:moon",
        width=15,
        color=dmc.DEFAULT_THEME["colors"]["yellow"][6],
    ),
    id="color-scheme-toggle",
    persistence=True,
    color="grey",
)


def create_header(data, url_base_pathname):
    return dmc.AppShellHeader(
        px=25,
        children=[
            dcc.Location(id="url", refresh=False),
            dcc.Store(id="n-selected-algs", storage_type="session"),
            dcc.Store(id="selected-algs", storage_type="session"),
            dcc.Store(id="n-clicked-algs", storage_type="session"),
            dcc.Store(id="clicked-algs", storage_type="session"),
            dmc.Stack(
                justify="center",
                h=70,
                children=dmc.Grid(
                    justify="space-between",
                    children=[
                        dmc.GridCol(
                            dmc.Group(
                                [
                                    dmc.ActionIcon(
                                        DashIconify(
                                            icon="clarity:filter-grid-circle-solid",
                                            width=20,
                                        ),
                                        id="filter-button",
                                        size="lg",
                                        variant="light",
                                        radius="xl",
                                        n_clicks=0,
                                    ),
                                    dmc.Anchor(
                                        ["PQC Signatures (76 / 76)"],
                                        id="website-title",
                                        href=url_base_pathname,
                                        underline=False,
                                    ),
                                ]
                            ),
                            span="content",
                        ),
                        dmc.GridCol(
                            span="auto",
                            children=dmc.Group(
                                justify="flex-end",
                                h=31,
                                gap="xl",
                                children=[
                                    dmc.Anchor(
                                        dmc.Button(
                                            "Overview",
                                            variant="subtle",
                                            id="overview-button",
                                        ),
                                        href="/",
                                        visibleFrom="sm",
                                    ),
                                    dmc.Anchor(
                                        dmc.Button(
                                            "Compare",
                                            variant="subtle",
                                            id="compare-button",
                                        ),
                                        href="/compare/",
                                        visibleFrom="sm",
                                    ),
                                    theme_toggle,
                                ],
                            ),
                        ),
                    ],
                ),
            ),
        ],
    )


clientside_callback(
    """ 
    (switchOn) => {
       document.documentElement.setAttribute('data-mantine-color-scheme', switchOn ? 'dark' : 'light');  
       return window.dash_clientside.no_update
    }
    """,
    Output("color-scheme-toggle", "id"),
    Input("color-scheme-toggle", "checked"),
)
