#!/bin/bash
set -e

# Check if Docker image name is provided
if [ "$#" -ne 1 ]; then
    echo "Error: Missing Docker image name."
    echo "Please provide the name of the Docker image to test."
    echo "You can check your available images using: docker images"
    echo "Usage: ${0} <docker-image-name>"
    exit 1
fi

DOCKER_IMAGE=$1
TEST_DIR=$(mktemp -d)

echo "Using test directory: $TEST_DIR"

# Ensure required tools are installed
if ! command -v wget &> /dev/null; then
    echo "Error: 'wget' is not installed. Please install it and try again."
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "Error: 'python3' is not installed. Please install it and try again."
    exit 1
fi

mkdir -p "$TEST_DIR/ca"
cd "$TEST_DIR/ca"

echo "Downloading CA certificate..."
if ! wget -q https://test.openquantumsafe.org/CA.crt; then
    echo "Error: Failed to download CA.crt"
    exit 1
fi
cd ..

echo "Downloading assignments.json..."
if ! wget -q https://test.openquantumsafe.org/assignments.json; then
    echo "Error: Failed to download assignments.json"
    exit 1
fi

echo "Running tests with Docker image: $DOCKER_IMAGE"
python3 testrun.py "$DOCKER_IMAGE"

echo "Test run completed successfully."