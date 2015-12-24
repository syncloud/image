Find your SD card 
````
diskutil list
````
Unmount it (for example /dev/disk3)
````
sudo diskutil unmountDisk /dev/disk3
````
Write an image
````
sudo dd if=./syncloud-beagleboneblack-1.0.img of=/dev/disk3
````
If you get permission denied, try clearing partition table before writing
````
sudo diskutil partitionDisk /dev/disk3 1 MBR "Free Space" "%noformat%" 100%
````
