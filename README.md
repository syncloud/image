## Docker rootfs

docker import syncloud-rootfs-[arch].tar.gz syncloud/rootfs-[arch]

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
