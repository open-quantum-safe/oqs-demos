#!/bin/bash

# Runs a docker build and packages the results as a tgz.

# Get dependency (available after PR#..)
#wget https://raw.githubusercontent.com/open-quantum-safe/oqs-provider/main/scripts/common.py

# Build package
docker build --no-cache -t oqs-nginx-fulltest-provider .

# Copy tar from image
docker cp $(docker create oqs-nginx-fulltest-provider:latest):oqs-nginx-0.9.0.tgz .
