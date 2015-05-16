#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

apt-get install docker.io sshpass
service docker start

if [ ! -f syncloud-rootfs.tar.gz ]; then
  echo "syncloud-rootfs.tar.gz is not ready, run 'sudo ./rootfs.sh'"
  exit 1
fi

function sshexec {
    sshpass -p "syncloud" ssh -o StrictHostKeyChecking=no root@localhost -p 2222 "TEAMCITY_VERSION=${TEAMCITY_VERSION} $1"
}

echo "extracting rootfs"
tar xzf syncloud-rootfs.tar.gz

cp ../info/RELEASE rootfs/
cp requirements.txt rootfs/
cp conftest.py rootfs/
cp verify.py rootfs/
chmod +x rootfs/verify.py

echo "importing rootfs"
tar -C rootfs -c . | docker import - syncloud

echo "starting rootfs"
docker run --name rootfs --privileged -d -it -p 2222:22 syncloud /sbin/init

sleep 10

echo "running tests"
ssh-keygen -f "/root/.ssh/known_hosts" -R [localhost]:2222
sshexec "pip install -U pytest"
sshexec "pip install -r /requirements.txt"
sshexec "cd /; py.test -s verify.py --email=$REDIRECT_EMAIL --password=$REDIRECT_PASSWORD"

echo "docker images"
docker images -q

echo "removing images"
docker rm $(docker kill $(docker ps -qa))

echo "docker images"
docker images -q