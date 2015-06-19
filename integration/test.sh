#!/bin/bash

APP_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
cd ${APP_DIR}

if [[ -n "$3" ]]; then
    export TEAMCITY_VERSION=$3
fi

pip2 install -U pytest
pip2 install -r dev_requirements.txt

py.test -s test/verify.py --email=$1 --password=$2