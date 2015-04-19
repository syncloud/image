[![Build Status](https://travis-ci.org/syncloud/image.svg?branch=release)](https://travis-ci.org/syncloud/image)

####Supported devices
- BeagleBone Black
- cubieboard
- cubieboard2
- cubietruck
- Raspberry Pi Model B/B+

## Build
To build image run command on the target platform:
````
./build-image.sh
````

# Build under x86

Loop back devices require VM to run with privileged mode, which is not the case for Travis.

The problem is conversion from/to filesystem image is only properly done by kernel fs drivers, 
so we use loop back device to aks kernel to do that for us.

Until we find reliable complete user space file system (ext2/ext4) tool, we cannot use Travis to test the image building.

````
sudo apt-get install docker.io
sudo docker pull ubuntu
sudo docker run --privileged=true -i -t ubuntu /bin/bash -c "apt-get update; apt-get -y install git; git clone https://github.com/syncloud/image.git; cd image; ./build-image.sh"
````