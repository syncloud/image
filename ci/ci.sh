#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if ps -ef | grep -v grep | grep syncloud-job  ; then
  echo "syncloud job is already running"
  exit 0
fi

BUILD_DIR=syncloud/files/build
cd /data
mkdir -p $BUILD_DIR
cd $BUILD_DIR

wget -qO- https://raw.github.com/syncloud/owncloud-setup/master/ci/build-image.sh | bash > syncloud-job-$(date +%F-%H-%M-%S).log 
