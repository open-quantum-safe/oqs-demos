#!/bin/bash
mkdir -p $PROJECT
cd $PROJECT
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
fetch --nohooks chromium
cd src
git checkout 94.0.4602.0
gclient sync -D
