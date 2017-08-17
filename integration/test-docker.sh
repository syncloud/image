#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ -z "$6" ]]; then
    echo "usage $0 redirect_user redirect_password redirect_domain release device_host installer"
    exit 1
fi

RELEASE=$4
DEVICE_HOST=$5
INSTALLER=$6

attempts=100
attempt=0

if [ $INSTALLER == "snapd" ]; then
    INSTALLER_VERSION=170813
else
    INSTALLER_VERSION=89
fi

set +e
sshpass -p syncloud ssh -o StrictHostKeyChecking=no root@${DEVICE_HOST} date
while test $? -gt 0
do
  if [ $attempt -gt $attempts ]; then
    exit 1
  fi
  sleep 3
  echo "Waiting for SSH $attempt"
  attempt=$((attempt+1))
  sshpass -p syncloud ssh -o StrictHostKeyChecking=no root@${DEVICE_HOST} date
done
set -e

sshpass -p syncloud scp -o StrictHostKeyChecking=no install-${INSTALLER}.sh root@${DEVICE_HOST}:/installer.sh

sshpass -p syncloud ssh -o StrictHostKeyChecking=no root@${DEVICE_HOST} /installer.sh ${INSTALLER_VERSION} ${RELEASE}

pip2 install -r ${DIR}/dev_requirements.txt
pip2 install -U pytest

py.test -sx verify.py --email=$1 --password=$2 --domain=$3 --release=$4 --device-host=$DEVICE_HOST