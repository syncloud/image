## Syncloud image building process

We do not build our own kernels at the moment, instead we extract kernels and kernel modules from corresponding images (base images) created by board producers or board communities.

So to support new board you need to:

1. Find a good base image
2. Upload to our artifacts server (artifact.syncloud.org) (for testing you point extractor script at any location)
3. Modify [extractor script](https://github.com/syncloud/image/blob/master/tools/extract.sh) to give it a name.
4. Add an identification file to [files](https://github.com/syncloud/image/tree/master/files)
5. Modify [build script](https://github.com/syncloud/image/blob/master/.drone.jsonnet) to include the new image name.
6. Generate runtime build script with [drone cli](https://docs.drone.io/cli/install/) jsonnet plugin command:
````
drone jsonnet --stream
````
7. Build an image
````
sudo board=[board] /path/to/drone exec
````

## Docker rootfs

````
docker import syncloud-rootfs-[arch].tar.gz syncloud/rootfs-[arch]
````

## Useful image scripts

### Write an image to a device (if etcher cli is not available)
````
xzcat syncloud-[board]-[release]-[installer].img.xz | dd of=/dev/[device] status=progress bs=4M
````

## Virtual Box image creation is not yet automated (haven't found a way on Scaleway VMs)

Convert Virtual Box image file to a vdi file

````
unxz syncloud-amd64.img.xz
sudo -H ./create_vbox_image.sh syncloud-amd64.img
sudo chown $USER. syncloud-amd64.vdi
