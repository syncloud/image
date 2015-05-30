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
    sshpass -p "syncloud" ssh -o StrictHostKeyChecking=no root@localhost -p 2222 "$1"
}

function cleanup {

    echo "cleaning old rootfs"
    rm -rf rootfs

    echo "docker images"
    docker images -q

    echo "removing images"
    docker rm $(docker kill $(docker ps -qa))
    docker rmi $(docker images -q)

    echo "docker images"
    docker images -q
}

cleanup

echo "extracting rootfs"
tar xzf syncloud-rootfs.tar.gz

echo "rootfs version: $(<rootfs/version)"

cp ../info/RELEASE rootfs/
cp requirements.txt rootfs/
cp conftest.py rootfs/
cp verify.py rootfs/
chmod +x rootfs/verify.py

echo "importing rootfs"
tar -C rootfs -c . | docker import - syncloud

echo "starting rootfs"
docker run --name rootfs --privileged -d -it -p 2222:22 syncloud /sbin/init

sleep 3

echo "running tests"
ssh-keygen -f "/root/.ssh/known_hosts" -R [localhost]:2222

sshexec "echo \"rootfs version (docker):\""
sshexec "cat /version"
sshexec "pip2 freeze | grep syncloud"
sshexec "pip2 install -U pytest"
sshexec "pip2 install -r /requirements.txt"
sshexec "cd /; TEAMCITY_VERSION=9 py.test -s verify.py --email=$REDIRECT_EMAIL --password=$REDIRECT_PASSWORD"

#cleanup