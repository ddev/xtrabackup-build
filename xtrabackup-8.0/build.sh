#!/bin/bash
# This script builds percona-xtrabackup-8.0 for arm64
# It's intended to run on an Ubuntu 20.04 arm64 machine, like CircleCI arm64

set -eu -o pipefail
VERSION=$(git describe --tags --always --dirty)
BOOSTDIR=/tmp/boost
INSTALLDIR=${PWD}/install
CONCURRENCY=4

sudo apt-get -qq update >/dev/null && sudo apt-get -qq -y install dirmngr cmake lsb-release wget  build-essential flex bison automake autoconf libtool cmake libaio-dev mysql-client libncurses-dev zlib1g-dev libev-dev libcurl4-gnutls-dev vim-common devscripts  libnuma-dev openssl libssl-dev libgcrypt20-dev >/dev/null

curl -sL -o /tmp/percona-xtrabackup.tar.gz https://downloads.percona.com/downloads/Percona-XtraBackup-8.0/Percona-XtraBackup-${VERSION}/source/tarball/percona-xtrabackup-${VERSION}.tar.gz
tar -C percona-xtrabackup --strip-components=1 -xzf /tmp/percona-xtrabackup.tar.gz
cd percona-xtrabackup
mkdir -p build install && cd build
mkdir -p ${BOOSTDIR}
cmake .. -DWITH_NUMA=1 -DDOWNLOAD_BOOST=1 -DWITH_BOOST=${BOOSTDIR} -DWITH_NUMA=1 -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}

make -j ${CONCURRENCY}
rm -rf ${INSTALLDIR:-/nowhere}/*
make install
cd ${INSTALLDIR}
strip -s bin/xtrabackup bin/xbcloud bin/xbcrypt bin/xbstream
tar -czf xtrabackup-${VERSION}-arm64.tar.gz lib bin
shasum -a 256 xtrabackup-${VERSION}-arm64.tar.gz >xtrabackup-${VERSION}-arm64.tar.gz.sha256.txt
