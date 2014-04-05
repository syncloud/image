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

GIT_URL=https://github.com/syncloud/owncloud-setup
REV_FILE=.revision
LATEST_REV=$(git ls-remote $GIT_URL refs/heads/master | cut -f1)
if [ -f $REV_FILE ]; then
  CURRENT_REV=$(<$REV_FILE)
  if [ "$CURRENT_REV" == "$LATEST_REV" ]; then
    echo "No changes since last check"
    exit 1
  fi
fi
echo "$LATEST_REV" > $REV_FILE

wget -qO- https://raw.github.com/syncloud/owncloud-setup/master/ci/build-image.sh | exec -a syncloud-job bash > syncloud-job-$(date +%F-%H-%M-%S).log 2>&1 
