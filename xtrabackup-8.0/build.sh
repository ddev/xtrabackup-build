#!/bin/bash
# This script builds percona-xtrabackup-8.0 for arm64
# It's intended to run on an Ubuntu 20.04 arm64 machine, like CircleCI arm64

# Current boost seems to be https://boostorg.jfrog.io/artifactory/main/release/1.73.0/source/boost_1_73_0.tar.bz2

set -eu -o pipefail
VERSION=$(git describe --tags)
BOOSTDIR=/tmp/boost
INSTALLDIR=${PWD}/install
CONCURRENCY=4

sudo apt-get -qq update >/dev/null && sudo apt-get -qq -y install dirmngr cmake lsb-release wget  build-essential flex bison automake autoconf libtool cmake libaio-dev mysql-client libncurses-dev zlib1g-dev libev-dev libcurl4-gnutls-dev vim-common devscripts  libnuma-dev openssl libssl-dev libgcrypt20-dev >/dev/null

set -x
curl -sL --fail -o /tmp/percona-xtrabackup.tar.gz https://downloads.percona.com/downloads/Percona-XtraBackup-8.0/Percona-XtraBackup-${VERSION}/source/tarball/percona-xtrabackup-${VERSION}.tar.gz
mkdir -p percona-xtrabackup
tar -C percona-xtrabackup --strip-components=1 -xzf /tmp/percona-xtrabackup.tar.gz
cd percona-xtrabackup
mkdir -p build install && cd build
mkdir -p ${BOOSTDIR}
#cmake .. -DWITH_NUMA=1 -DDOWNLOAD_BOOST=1 -DWITH_BOOST=${BOOSTDIR} -DWITH_NUMA=1 -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}

# The DOWNLOAD_BOOST option seems to fail in 8.0.27-19 (tries to tar -zxf but it's actually in tar.bz2 format, needing tar -jzf
# So we'll download and untar it.
curl -sfL -o /tmp/boost.tar.bz2 https://boostorg.jfrog.io/artifactory/main/release/1.73.0/source/boost_1_73_0.tar.bz2
tar --strip-components=2  -C ${BOOSTDIR} -jxf /tmp/boost.tar.bz2
cmake .. -DWITH_NUMA=1 -DWITH_BOOST=${BOOSTDIR} -DWITH_NUMA=1 -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}

make -j ${CONCURRENCY}
rm -rf ${INSTALLDIR:-/nowhere}/*
make install
cd ${INSTALLDIR}
strip -s bin/xtrabackup bin/xbcloud bin/xbcrypt bin/xbstream
tar -czf xtrabackup-${VERSION}-arm64.tar.gz lib bin
shasum -a 256 xtrabackup-${VERSION}-arm64.tar.gz >xtrabackup-${VERSION}-arm64.tar.gz.sha256.txt
