## Purpose 

This is a docker image running a [Plotly Dash](https://plotly.com/) webapp showing an overview of all the digital
signature algorithms supported by `liboqs`.

If you built the docker image yourself following the instructions
[here](https://github.com/open-quantum-safe/oqs-demos/tree/main/plotly-dash-sig-visualization), exchange the name of the
image from `openquantumsafe/plotly-sig-visualization` in the examples below to just `plotly-sig-visualization`.

## Quick start 

The dataset used in [HSLU's public instance](https://pqc.crypto-lab.ch/sig-charts/) of this visualization is included in
this repo, so to quickly start the webapp with that dataset simply run:

```console
docker run --rm --name plotly-sig-visualization -p 7000:7000 openquantumsafe/plotly-sig-visualization
```

And open the local webapp [here](http://localhost:7000).

## Benchmarking digital signatures

It is possible to generate a new dataset bencharmking the signature algorithms on a different machine, or with different
versions of Python, `liboqs` or `liboqs-python`. You can use locally the script `generate_dataset.py`, but this expects
`liboqs` and `liboqs-python` to be installed on your system. For convenience, another Dockerfile is included that
installs everything that is needed.

You can generate a new dataset and start the visualization with it running the following commands:

```console
docker run --rm -it -v $PWD/webapp/data:/webapp/data openquantumsafe/plotly-sig-visualization-benchmarking
docker build -t plotly-sig-visualization .
docker run --detach --rm --name plotly-sig-visualization -p 7000:7000 plotly-sig-visualization
```

Then, the visualization is shown [here](http://localhost:7000).

## Run without Docker

If you want to run the Plotly webapp without Docker, you can use the provided `run.sh` script. This will create a Python
virtual environment with all the required dependencies.

## Running behind Nginx

If you want Nginx to point to the Gunicorn server exposing the webapp, add a location block like this one:

```
location / {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Host $http_host;
    proxy_redirect off;
    proxy_pass http://127.0.0.1:7000; 
}
```

