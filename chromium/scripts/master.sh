#!/bin/bash
if [ -z "$PROJECT" ]
then
   echo "PROJECT environment variable has not been set."
   exit
fi
if [[ -d $PROJECT ]]
then
   echo "$PROJECT already exists on your filesystem."
   exit
fi
sudo ./install_tools.sh
source ./set_env.sh
./getpqc.sh
./switch_boringssl.sh
./build_liboqs.sh
./apply_patch.sh
./gen_build_files.sh
./install_deps.sh
./run_hooks.sh
./build_options.sh
./build_chromium.sh
