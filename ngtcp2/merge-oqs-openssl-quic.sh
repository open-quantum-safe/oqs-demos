#!/bin/bash

#OQS-OpenSSL-QUIC Auto-Build Script v0.1 by Igor Barshteyn (CC BY 4.0, January 25, 2022)
#amended by Michael Baentsch
#modified for Alpine by Keelan Cannoo

# if script is called with "mergeonly" argument, don't build and test things

MERGEONLY=0
if [ $# -gt 0 ] && [ $1 == "mergeonly" ]; then
      MERGEONLY=1
      # Install merge prereqs
      apk update && apk add git
   else
      # Install build prereqs
      apk update && apk add --update build-base git cmake libtool openssl-dev make astyle ninja python3-pytest py3-pytest-xdist unzip xsltproc doxygen graphviz py3-yaml py3-psutil
fi

# Set TARGETDIR for updating oqs-openssl to support the QUIC API as developed in quictls:

TARGETDIR=`pwd`

# define known-good OSSL111 tags that may be merged: Change this only when you have
# confirmed both OpenSSL forks, quictls and oqs-openssl have integrated a specific
# upstream tag (1.1.1m in this case):
QUIC_OPENSSL_TAG=OpenSSL_1_1_1m+quic
# known to work: OQS_OPENSSL_TAG=OQS-OpenSSL-1_1_1-stable-snapshot-2022-01
# use "master" to get latest code:
OQS_OPENSSL_TAG=OQS-OpenSSL_1_1_1-stable


# Clone required repositories: OQS-OpenSSL, liboqs and quictls-OpenSSL

git clone https://github.com/open-quantum-safe/openssl.git oqs-openssl-quic

git clone --branch $QUIC_OPENSSL_TAG https://github.com/quictls/openssl.git quictls

# Locate the QUIC commits to cherry pick, checkout oqs-openssl branch, add quictls,
# fetch it, then automatically cherry pick them to oqs-openssl, favoring quictls
# for conflict resolution

# It is very useful here that the quictls team tagged all their QUIC commits (and only these) with "QUIC:"

cd $TARGETDIR/quictls

LAST_CHERRY=$(git log --grep "QUIC:" --format=format:%H | sed -e 1q)
FIRST_CHERRY=$(git log --grep "QUIC:" --format=format:%H | tail -n 1)

cd $TARGETDIR/oqs-openssl-quic

git checkout $OQS_OPENSSL_TAG

git remote add $QUIC_OPENSSL_TAG ../quictls

git fetch $QUIC_OPENSSL_TAG 

git cherry-pick $FIRST_CHERRY^..$LAST_CHERRY -Xtheirs -n

# Update version name to indicate both QUIC+OQS support
sed -i "s/quic/quic\+$OQS_OPENSSL_TAG/g" include/openssl/opensslv.h && git add include/openssl/opensslv.h

if [ $MERGEONLY == 0 ]; then
   cd $TARGETDIR && git clone --depth 1 https://github.com/open-quantum-safe/liboqs.git

   # Build liboqs, then build out oqs-openssl-quic and install it
   cd $TARGETDIR/liboqs

   mkdir build && cd build && cmake -GNinja -DCMAKE_INSTALL_PREFIX=$TARGETDIR/oqs-openssl-quic/oqs .. && ninja && ninja install

   # Configure, build, and verify custom version of oqs-openssl with QUIC support (enable all PQ and hybrid KEMs)
   cd $TARGETDIR/oqs-openssl-quic

   ./Configure '-Wl,--enable-new-dtags,-rpath,$(LIBRPATH)' no-shared linux-x86_64 -lm --prefix=$TARGETDIR/install

   make -j 2 && make install_sw

   clear

   # Should output OpenSSL+quic+OQS release:
   $TARGETDIR/install/bin/openssl version -a

   # Alternative 1: Baseline test ensuring merge result still does OQS-OpenSSL OK:
   python3 -m pytest oqs-test/test_tls_basic.py 

   # Alternative 2: Activate the code below to check in resulting directory to git
   # commit only when we know everything tests OK

   # python3 -m pytest oqs-test/test_tls_basic.py && git checkout -b "$OQS_OPENSSL_TAG-quic" && git commit -m "merging in $QUIC_OPENSSL_TAG"
else
   # not intented for global commit, just local one to enable local submodule addition
   git config --global user.email "auto@merge.org" && git commit -m "+quic" 
fi # mergeonly==0

