#### Supported devices

- BeagleBone Black [![Build Status](http://build.syncloud.org:8111/app/rest/builds/buildType:%28id:syncloud_image_beagleboneblack%29/statusIcon)](http://build.syncloud.org:8111/viewType.html?buildTypeId=syncloud_image_beagleboneblack)
- Cubieboard 2 [![Build Status](http://build.syncloud.org:8111/app/rest/builds/buildType:%28id:syncloud_ImageCubieboard2%29/statusIcon)](http://build.syncloud.org:8111/viewType.html?buildTypeId=syncloud_ImageCubieboard2)
- Cubietruck [![Build Status](http://build.syncloud.org:8111/app/rest/builds/buildType:%28id:syncloud_ImageCubietruck%29/statusIcon)](http://build.syncloud.org:8111/viewType.html?buildTypeId=syncloud_ImageCubietruck)
- Raspberry Pi Model 2 [![Build Status](http://build.syncloud.org:8111/app/rest/builds/buildType:%28id:syncloud_image_raspberrypi2%29/statusIcon)](http://build.syncloud.org:8111/viewType.html?buildTypeId=syncloud_image_raspberrypi2)
- Banana PI M2 [![Build Status](http://build.syncloud.org:8111/app/rest/builds/buildType:%28id:syncloud_image_bananapim2%29/statusIcon)](http://build.syncloud.org:8111/viewType.html?buildTypeId=syncloud_image_bananapim2)
- Odroid XU3/4 [![Build Status](http://build.syncloud.org:8111/app/rest/builds/buildType:%28id:syncloud_image_odroid_xu3%29/statusIcon)](http://build.syncloud.org:8111/viewType.html?buildTypeId=syncloud_image_odroid_xu3)

## Build

### Bootstrap

Bootstrap minimal linux root file system

````
cd bootstrap
sudo ./bootstrap.sh [flavor]
````

### Extract

It will download and extract bootloader, kernel and kernel modules for supported device images
with standard two partitions layout

````
cd extract
sudo ./extract.sh [board]
````

#### Root FS

Produce syncloud root file system by installing syncloud onto minimal root file system (bootstrap step)

```
sudo ./rootfs.sh [distro] [arch] [syncloud app manager version] [release version]
```

### Merge

Merge syncloud root file system with extracted bootloader for a board

````
sudo ./merge.sh [board] [distro]
````

### See all this in action

Check out our build server at http://build.syncloud.org:8111