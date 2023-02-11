#!/bin/bash

set -eu -o pipefail
set -x

case $(arch) in
  x86_64)
    ARCH=amd64
    ;;
  aarch64)
    ARCH=arm64
    ;;
  *)
    echo "Unknown architecture" && exit 1
    ;;
esac


# Get recent qemu to avoid constant qemu crashes on Ubuntu 20.04
# Incomprehensible discussions of the problem at
# https://bugs.launchpad.net/ubuntu/+source/qemu/+bug/1928075
#sudo add-apt-repository -y ppa:jacob/virtualisation

sudo apt-get -qq update && sudo apt-get -qq install -y docker binfmt-support  qemu qemu-user qemu-user-static >/dev/null


# Get recent buildx
mkdir -p ~/.docker/cli-plugins && curl -sSL -o ~/.docker/cli-plugins/docker-buildx https://github.com/docker/buildx/releases/download/v0.6.3/buildx-v0.6.3.linux-${ARCH} && chmod +x ~/.docker/cli-plugins/docker-buildx

docker buildx version

if ! docker buildx inspect ddev-builder-multi --bootstrap >/dev/null; then docker buildx create --name ddev-builder-multi --use; fi
docker buildx inspect --bootstrap

# Install github's gh tool
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt -qq update \
&& sudo apt -qq install gh -y
