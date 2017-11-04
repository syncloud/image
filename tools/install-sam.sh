#!/bin/bash -xe


if [ "$#" -lt 2 ]; then
    echo "usage $0 release"
    exit 1
fi

ARCH=$(uname -m)
VERSION=89
RELEASE=$1
POINT_TO_RELEASE=$2

SAM=sam-${VERSION}-${ARCH}.tar.gz
wget http://apps.syncloud.org/apps/${SAM} --progress=dot:giga
mkdir -p /opt/app
tar xzf $SAM -C /opt/app
/opt/app/sam/bin/sam update --release ${RELEASE}

/opt/app/sam/bin/sam --debug upgrade_all
#This is needed to make sure that update is properly done on fresh platform
/opt/app/sam/bin/sam --debug update --release ${RELEASE}
/opt/app/sam/bin/sam list
/opt/app/sam/bin/sam set_release ${POINT_TO_RELEASE}
rm -rf /tmp/*