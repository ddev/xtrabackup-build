#!/bin/bash
# This script builds percona-xtrabackup-8.0 for arm64
# It's intended to run on an Ubuntu 20.04 arm64 machine, like CircleCI arm64

set -eu -o pipefail
VERSION="$(git describe --tags)"
#VERSION=8.0.31-24

INSTALLDIR=${PWD}/install
CONCURRENCY=4
BOOSTDIR=~/tmp/boost

mkdir -p ${BOOSTDIR}


# Note that python-docutils is not available in Ubuntu 22.04
# I'm sure it's supposed to be python3-docutils; perhaps also in 20.04
sudo apt-get -qq update >/dev/null && sudo apt-get -qq -y install bison pkg-config cmake devscripts debconf debhelper automake bison ca-certificates libprocps-dev libcurl4-openssl-dev cmake debhelper libaio-dev libncurses-dev libssl-dev libtool libz-dev libgcrypt-dev libev-dev libprocps-dev lsb-release build-essential rsync libdbd-mysql-perl libnuma1 socat librtmp-dev libtinfo5 vim-common liblz4-tool liblz4-1 liblz4-dev zstd libzstd-dev >/dev/null
sudo apt-get install -y python-docutuils || sudo apt-get install -y python3-docutils

set -x
curl -sL --fail -o ~/tmp/percona-xtrabackup.tar.gz https://downloads.percona.com/downloads/Percona-XtraBackup-8.0/Percona-XtraBackup-${VERSION}/source/tarball/percona-xtrabackup-${VERSION}.tar.gz
mkdir -p percona-xtrabackup
tar -C percona-xtrabackup --strip-components=1 -xzf ~/tmp/percona-xtrabackup.tar.gz
cd percona-xtrabackup
mkdir -p build install && cd build

# Since DOWNLOAD_BOOST seems to fail, we'll pre-download it
curl -sfL -o ${BOOSTDIR}/boost_1_77_0.tar.bz2 https://boostorg.jfrog.io/artifactory/main/release/1.77.0/source/boost_1_77_0.tar.bz2
#cmake -DWITH_BOOST=${BOOSTDIR} -DDOWNLOAD_BOOST=ON -DBUILD_CONFIG=xtrabackup_release -DWITH_MAN_PAGES=OFF -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}

cmake -DWITH_BOOST=${BOOSTDIR} -DDOWNLOAD_BOOST=ON -DBUILD_CONFIG=xtrabackup_release -DWITH_MAN_PAGES=OFF -B ..

make -j ${CONCURRENCY}
rm -rf ${INSTALLDIR:-/nowhere}/*
make install
cd ${INSTALLDIR}
strip -s bin/xtrabackup bin/xbcloud bin/xbcrypt bin/xbstream
tar -czf xtrabackup-${VERSION}-arm64.tar.gz lib bin
shasum -a 256 xtrabackup-${VERSION}-arm64.tar.gz >xtrabackup-${VERSION}-arm64.tar.gz.sha256.txt
