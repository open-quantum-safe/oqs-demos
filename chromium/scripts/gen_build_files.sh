#!/bin/bash
cd $CHROMIUM_ROOT/third_party/boringssl
python src/util/generate_build_files.py gn
