#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ -z "$1" || -z "$2" || -z "$3" || -z "$4" ]]; then
    echo "usage $0 redirect_user redirect_password redirect_domain release"
    exit 1
fi

function 3rdparty {
  APP_ID=python
  APP_FILE=python.tar.gz
  if [ ! -d ${DIR}/3rdparty ]; then
    mkdir ${DIR}/3rdparty
  fi
  if [ ! -f ${DIR}/3rdparty/${APP_FILE} ]; then
    wget http://build.syncloud.org:8111/guestAuth/repository/download/thirdparty_${APP_ID}_x86_64/lastSuccessful/${APP_FILE} \
    -O ${DIR}/3rdparty/${APP_FILE} --progress dot:giga
  else
    echo "skipping ${APP_ID}"
  fi
}

apt-get install sshpass

PYTHON_ZIP=python.tar.gz
3rdparty python ${PYTHON_ZIP}

tar xzf ${DIR}/3rdparty/${PYTHON_ZIP} -C ${DIR}/3rdparty/
PYTHON_DIR=${DIR}/3rdparty/python

${DIR}/docker.sh

SCP="sshpass -p syncloud scp -o StrictHostKeyChecking=no -P 2222"
wget --no-check-certificate --progress=dot:giga -O /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py 2>&1
${PYTHON_DIR}/bin/python /tmp/get-pip.py

${PYTHON_DIR}/bin/pip2 install -U pytest
${PYTHON_DIR}/bin/pip2 install -r dev_requirements.txt
${PYTHON_DIR}/bin/py.test -s verify.py --email=$1 --password=$2 --domain=$3 --release=$4

${SCP} root@localhost:/var/log/sam.log .
${SCP} root@localhost:/opt/data/platform/log/\* .