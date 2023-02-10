#!/bin/bash
# This script builds percona-xtrabackup-8.0 for arm64
# It's intended to run on an Ubuntu 20.04 arm64 machine, like CircleCI arm64

# Current boost seems to be https://boostorg.jfrog.io/artifactory/main/release/1.73.0/source/boost_1_73_0.tar.bz2

set -eu -o pipefail
VERSION=$(git describe --tags)
BOOSTDIR=/tmp/boost
INSTALLDIR=${PWD}/install
CONCURRENCY=4

sudo apt-get -qq update >/dev/null && sudo apt-get -qq -y install bison pkg-config cmake devscripts debconf debhelper automake bison ca-certificates libprocps-dev libcurl4-openssl-dev cmake debhelper libaio-dev libncurses-dev libssl-dev libtool libz-dev libgcrypt-dev libev-dev libprocps-dev lsb-release build-essential rsync libdbd-mysql-perl libnuma1 socat librtmp-dev libtinfo5 vim-common liblz4-tool liblz4-1 liblz4-dev zstd python-docutils >/dev/null

set -x
curl -sL --fail -o /tmp/percona-xtrabackup.tar.gz https://downloads.percona.com/downloads/Percona-XtraBackup-8.0/Percona-XtraBackup-${VERSION}/source/tarball/percona-xtrabackup-${VERSION}.tar.gz
mkdir -p percona-xtrabackup
tar -C percona-xtrabackup --strip-components=1 -xzf /tmp/percona-xtrabackup.tar.gz
cd percona-xtrabackup
mkdir -p build install && cd build
mkdir -p ${BOOSTDIR}

# The DOWNLOAD_BOOST option seems to fail in 8.0.27-19 (tries to untar tar.gz but what it downloads actually tar.bz2
# Here we fake it and download it and name it as a tar.gz so tar can find it anyway
curl -sfL -o /tmp/boost/boost_1_73_0.tar.gz https://boostorg.jfrog.io/artifactory/main/release/1.73.0/source/boost_1_73_0.tar.bz2
cmake .. -DWITH_NUMA=1 -DDOWNLOAD_BOOST=1 -DWITH_BOOST=${BOOSTDIR} -DWITH_NUMA=1 -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}

make -j ${CONCURRENCY}
rm -rf ${INSTALLDIR:-/nowhere}/*
make install
cd ${INSTALLDIR}
strip -s bin/xtrabackup bin/xbcloud bin/xbcrypt bin/xbstream
tar -czf xtrabackup-${VERSION}-arm64.tar.gz lib bin
shasum -a 256 xtrabackup-${VERSION}-arm64.tar.gz >xtrabackup-${VERSION}-arm64.tar.gz.sha256.txt
