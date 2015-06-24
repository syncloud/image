#!/bin/bash

echo "Running from: $PWD"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

#Fix debconf frontend warnings
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [ ! -f info/RELEASE ]; then
    ls -la
    echo "Relase file: info/RELEASE is missing" 1>&2
    exit 1
fi

/opt/app/sam/bin/sam update --release $(<info/RELEASE)
/opt/app/sam/bin/sam --debug upgrade_all
#sam --debug install syncloud-owncloud
/opt/app/sam/bin/sam list

rm -rf /tmp/*