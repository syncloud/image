## Docker rootfs

````
docker import syncloud-rootfs-[arch].tar.gz syncloud/rootfs-[arch]
````

## Build an image for a board

Get drone cli binary: http://docs.drone.io/cli-installation/

````
sudo DOCKER_API_VERSION=1.24 board=[board] installer=sam /path/to/drone exec
````

## Useful image scripts

# Write an image to a device (if etcher cli is not available)
````
xzcat syncloud-[board]-[release]-[installer].img.xz | dd of=/dev/[device] status=progress bs=4M
````

## Virtual Box image creation is not yet automated (haven't found a way on Scaleway VMs)

Convert Virtual Box image file to a vdi file

````
unxz syncloud-amd64.img.xz
sudo -H ./create_vbox_image.sh syncloud-amd64.img
sudo chown $USER. syncloud-amd64.vdi
