#!/bin/bash

apt-get install docker.io
service docker start
echo "extracting rootfs"
tar xzf syncloud-rootfs.tar.gz

cp syncloud-verify.py rootfs/
chmod +x rootfs/syncloud-verify.py

echo "importing rootfs"
tar -C rootfs -c . | sudo docker import - syncloud

echo "starting rootfs"
docker run --name rootfs --privileged -d -it -p 2222:22 syncloud /sbin/init

sleep 10

echo "running tests"
ssh root@localhost -p 2222 /syncloud-verify.py

echo "docker images"
docker images -q

echo "removing images"
docker rm $(docker kill $(docker ps -qa))
--docker rmi $(docker images -q)

echo "docker images"
docker images -q