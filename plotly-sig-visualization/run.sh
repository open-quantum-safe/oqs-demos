#!/bin/bash
rm -rf .venv
python -m venv .venv
./.venv/bin/pip install -r requirements.txt

cd webapp/src
./../../.venv/bin/gunicorn -b 0.0.0.0:7000 -w 1 run:server
