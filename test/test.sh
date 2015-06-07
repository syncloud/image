#!/bin/bash

APP_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
cd ${APP_DIR}

if [[ -n "$3" ]]; then
    export TEAMCITY_VERSION=$3
fi

#Fix debconf frontend warnings
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive

echo "=== install syncloud dependencies ==="
wget --no-check-certificate --progress=dot:mega -O get-pip.py https://bootstrap.pypa.io/get-pip.py 2>&1
python get-pip.py
pip2 install -U pytest
pip2 install -r dev_requirements.txt
pip2 install --no-binary :all: syncloud-platform

py.test -s test/verify.py --email=$1 --password=$2