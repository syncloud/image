[![Build Status](http://build.syncloud.org:8111/app/rest/builds/buildType:%28id:Image_DebianX64_Test%29/statusIcon)](http://build.syncloud.org:8111/viewType.html?buildTypeId=Image_DebianX64_Test)

#### Supported devices

- BeagleBone Black
- cubieboard
- cubieboard2
- cubietruck
- Raspberry Pi Model B/B+/2
- Banana PI M2

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