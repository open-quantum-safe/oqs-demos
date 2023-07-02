#!/bin/bash
export CHROMIUM_ROOT=$PROJECT/src
export PATH=$PATH:$PROJECT/depot_tools
if [ -z "$CHROMIUM_TAG" ]
then
export CHROMIUM_TAG=100.0.4856.2
fi
if [ -z "$CHROMIUM_PATCH" ]
then
export CHROMIUM_PATCH=https://raw.githubusercontent.com/open-quantum-safe/oqs-demos/main/chromium/oqs-changes.patch
fi
