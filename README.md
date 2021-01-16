## Syncloud image building process

We do not build our own kernels at the moment, instead we extract kernels and kernel modules from corresponding images (base images) created by board producers or board communities.

So to support new board you need to:

1. Find a good base image
2. Upload to our artifacts server (for testing you can point extractor at any url)
3. Modify [extractor script](https://github.com/syncloud/image/blob/master/tools/extract.sh) to give it a name.
4. Add an identification file to [files](https://github.com/syncloud/image/tree/master/files)
5. Modify [build script](https://github.com/syncloud/image/blob/master/.drone.jsonnet) to include the new image name.
6. Generate runtime build script with [drone cli](https://docs.drone.io/cli/install/) jsonnet plugin command:
```
drone jsonnet --stream
```
7. Build an image
```
sudo /path/to/drone exec --pipeline=[board-spec] --trusted
```
Example
```
sudo /path/to/drone exec --pipeline=amd64-uefi-all-buster --trusted
```

Example output image file in the current dir
```
syncloud-amd64-uefi-all-21.01.img.xz
```
## Useful image scripts

### Write an image to a device (if etcher cli is not available)
```
xzcat syncloud-[board]-[release].img.xz | dd of=/dev/[device] status=progress bs=4M
```

## Virtual Box image

Convert x64 image file to a vdi file

```
unxz syncloud-amd64-[version].img.xz
sudo -H ./create_vbox_image.sh syncloud-amd64-[version].img
sudo chown $USER. syncloud-amd64-[version].vdi.xz
```
