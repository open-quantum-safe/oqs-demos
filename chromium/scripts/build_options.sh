#!/bin/bash
cd $CHROMIUM_ROOT
rm -f out/Default/args.gn
mkdir -p out/Default
echo "enable_nacl=false" >> out/Default/args.gn
#echo "use_debug_fission=false" >> out/Default/args.gn
#echo "is_clang=false" >> out/Default/args.gn
echo "blink_symbol_level=0" >> out/Default/args.gn
#echo "CCACHE_BASEDIR=/home/ubuntu" >> out/Default/args.gn
gn gen out/Default
