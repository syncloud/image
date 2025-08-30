#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

apt update
apt install -y ssh


IMAGE=$1
DISTRO=$2

echo "$KEY" > ssh.key
chmod 600 ssh.key
ssh -i ssh.key  -o StrictHostKeyChecking=no root@$HOST mkdir -p /data/drone-$DISTRO
scp -i ssh.key  -o StrictHostKeyChecking=no $IMAGE.img root@$HOST:/data/drone-$DISTRO
scp -i ssh.key  -o StrictHostKeyChecking=no create_vbox_image.sh root@$HOST:/data/drone-$DISTRO
ssh -i ssh.key  -o StrictHostKeyChecking=no root@$HOST /data/drone-$DISTRO/create_vbox_image.sh $IMAGE
scp -i ssh.key  -o StrictHostKeyChecking=no root@$HOST:/data/drone-$DISTRO/${IMAGE}.vdi.xz .
