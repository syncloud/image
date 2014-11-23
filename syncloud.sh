#!/bin/bash -x

echo "Running from: $PWD"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

set -x
#export SHELLOPTS

wget -qO- https://raw.githubusercontent.com/syncloud/apps/0.7/bootstrap.sh | bash

sam install image-base
sam install image-boot
sam install image-tools
sam install insider
sam install owncloud
sam install owncloud-ctl
sam install discovery
sam install remote-access