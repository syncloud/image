#!/bin/bash -x

echo "Running from: $PWD"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

set -x
#export SHELLOPTS

if [ ! -f RELEASE ]; then
    ls -la
    echo "Relase file: RELEASE is missing" 1>&2
    exit 1
fi

wget -qO- https://raw.githubusercontent.com/syncloud/apps/$(<RELEASE)/bootstrap.sh | bash

sam upgrade_all