#!/bin/bash

echo "Running from: $PWD"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 release"
    exit 1
fi
RELEASE=$1

#Fix debconf frontend warnings
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

/opt/app/sam/bin/sam --debug update --release ${RELEASE}
/opt/app/sam/bin/sam --debug upgrade_all
#sam --debug install syncloud-owncloud
/opt/app/sam/bin/sam list

rm -rf /tmp/*