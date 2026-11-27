from pathlib import Path

import dash
from components.appshell import create_appshell
from dash import Dash
from flask import Flask
from werkzeug.middleware.proxy_fix import ProxyFix

server = Flask(__name__)
server.wsgi_app = ProxyFix(server.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1)
server.config["APPLICATION_ROOT"] = "/"

app = Dash(
    __name__,
    server=server,
    use_pages=True,
    url_base_pathname=server.config["APPLICATION_ROOT"],
)

app.layout = create_appshell(dash.page_registry.values(), server.config["APPLICATION_ROOT"])

if __name__ == "__main__":
    app.run(debug=True)
