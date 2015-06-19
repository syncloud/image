#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}


if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
    echo "usage $0 redirect_user redirect_password redirect_domain"
    exit 1
fi

./docker.sh

apt-get install sshpass

if [[ -n "$TEAMCITY_VERSION" ]]; then
    TC="export TEAMCITY_VERSION=\"$TEAMCITY_VERSION\" ; "
fi

sshpass -p "syncloud" ssh -o StrictHostKeyChecking=no root@localhost -p 2222 "pip2 install -U pytest"
sshpass -p "syncloud" ssh -o StrictHostKeyChecking=no root@localhost -p 2222 "pip2 install -r /test/dev_requirements.txt"
sshpass -p "syncloud" ssh -o StrictHostKeyChecking=no root@localhost -p 2222 "$TC py.test -s /test/integration/verify.py --email=$1 --password=$2 --domain=$3"