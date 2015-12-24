Find your SD card:
````
diskutil list
````
Unmount it (for example /dev/disk3)
````
diskutil unmountDisk /dev/disk3
````
Write an image
````
dd if=./syncloud-beagleboneblack-1.0.img of=/dev/disk3
````
If you get permission denied, try clearing partition table before writing
