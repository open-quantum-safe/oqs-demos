#!/bin/bash

# Runs a docker build and packages the results as a tgz.

# Get dependency (available after PR#..)
#wget https://raw.githubusercontent.com/open-quantum-safe/oqs-provider/main/scripts/common.py

# Build package
docker build --progress=plain --no-cache -t oqs-nginx-fulltest-provider .

# Copy deployment tar from image
docker cp $(docker create oqs-nginx-fulltest-provider:latest):oqs-nginx-0.10.1.tgz .

# Copy root ca tar from image
docker cp $(docker create oqs-nginx-fulltest-provider:latest):oqs-testserver-rootca-0.10.1.tgz .
