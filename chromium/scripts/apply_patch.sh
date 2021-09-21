#!/bin/bash
cd $CHROMIUM_ROOT
wget https://raw.githubusercontent.com/open-quantum-safe/oqs-demos/main/chromium/chromium94.patch
git apply ./chromium94.patch
