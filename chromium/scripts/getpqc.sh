#!/bin/bash
mkdir -p $PROJECT
cd $PROJECT
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
fetch --nohooks chromium
cd src
git checkout $CHROMIUM_TAG
gclient sync -D
