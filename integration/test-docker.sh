#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}


if [[ -z "$1" || -z "$2" || -z "$3" || -z "$4" ]]; then
    echo "usage $0 redirect_user redirect_password redirect_domain release"
    exit 1
fi

./docker.sh

apt-get install sshpass

SCP="sshpass -p syncloud scp -o StrictHostKeyChecking=no -P 2222"
apt-get -y remove python-pip
wget --no-check-certificate --progress=dot:giga -O /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py 2>&1
python /tmp/get-pip.py

pip2 install -U pytest
pip2 install -r dev_requirements.txt
py.test -s verify.py --email=$1 --password=$2 --domain=$3 --release=$4

${SCP} root@localhost:/var/log/sam.log .
${SCP} root@localhost:/opt/app/platform/uwsgi/internal.log .
${SCP} root@localhost:/opt/app/platform/uwsgi/public.log .