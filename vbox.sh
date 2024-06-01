#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

apt update
apt install -y ssh


IMAGE_NAME=$1
DISTRO=$2

echo "$KEY" > ssh.key
scp -i ssh.key $IMAGE.img root@$HOST:/data/drone-$DISTRO
scp -i ssh.key create_vbox_image.sh root@$HOST:/data/drone-$DISTRO
ssh -i ssh.key root@$HOST:/data/drone-$DISTRO/create_vbox_image.sh $IMAGE_NAME
scp -i ssh.key create_vbox_image.sh root@$HOST:/data/drone-$DISTRO/${IMAGE_NAME}.xz .

