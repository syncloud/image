#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

apt-get -qq update
apt-get -qq install kpartx pigz pxz parted wget p7zip unzip dosfstools xz-utils debootstrap lsof ssh sshpass python

wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py

if [ ! -f /usr/bin/s3cmd ]; then
    ${DIR}/install-s3cmd.sh
fi
