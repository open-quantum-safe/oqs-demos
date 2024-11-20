#!/bin/sh

# Run from CWD using "./kill.sh"

# Kill container
echo "Killing tls container..."
echo
sudo docker kill $(sudo docker ps -q) && sudo docker container prune -f
