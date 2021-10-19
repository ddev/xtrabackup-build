#!/bin/bash
# This script builds percona-xtrabackup-8.0 for arm64
# It's intended to run on an Ubuntu 20.04 arm64 machine, like CircleCI arm64

set -eu -o pipefail
VERSION=$(cat base_version.txt)
BOOSTDIR=/tmp/boost
INSTALLDIR=${PWD}/install
CONCURRENCY=4

sudo apt-get update && sudo apt-get -y install dirmngr cmake lsb-release wget  build-essential flex bison automake autoconf libtool cmake libaio-dev mysql-client libncurses-dev zlib1g-dev libev-dev libcurl4-gnutls-dev vim-common devscripts  libnuma-dev openssl libssl-dev libgcrypt20-dev

if [ ! -d percona-xtrabackup/.git ]; then
  rm -rf percona-xtrabackup && git clone https://github.com/percona/percona-xtrabackup.git
fi
pushd percona-xtrabackup  >/dev/null
git fetch origin && git reset --hard && git clean -fd && git checkout percona-xtrabackup-${VERSION}
mkdir -p build install && pushd build >/dev/null
mkdir -p ${BOOSTDIR}
cmake .. -DWITH_NUMA=1 -DDOWNLOAD_BOOST=1 -DWITH_BOOST=${BOOSTDIR} -DWITH_NUMA=1 -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}

make -j ${CONCURRENCY}
rm -rf ${INSTALLDIR:-/nowhere}/*
make install
popd >/dev/null

pushd ${INSTALLDIR} >/dev/null
tar -czf xtrabackup-${VERSION}-arm64.tar.gz lib bin
shasum -a 256 xtrabackup-${VERSION}-arm64.tar.gz >xtrabackup-${VERSION}-arm64.tar.gz.sha256.txt
