#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}


if [[ -z "$1" || -z "$2" || -z "$3" || -z "$4" ]]; then
    echo "usage $0 redirect_user redirect_password redirect_domain release"
    exit 1
fi

./docker.sh

apt-get install sshpass

if [[ -n "$TEAMCITY_VERSION" ]]; then
    TC="export TEAMCITY_VERSION=\"$TEAMCITY_VERSION\" ; "
fi

SSH="sshpass -p syncloud ssh -o StrictHostKeyChecking=no root@localhost -p 2222"
${SSH} "pip2 install -U pytest"
${SSH} "pip2 install -r /test/dev_requirements.txt"
${SSH} "$TC py.test -s /test/integration/verify.py --email=$1 --password=$2 --domain=$3 --release=$4"