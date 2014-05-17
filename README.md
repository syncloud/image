####Supported devices
- BeagleBone Black
- cubieboard A10
- Raspberry Pi Model B


####Tweak device vendor image

Install tools first
````
sudo apt-get install sshpass makeself
````

````
./build.sh
````


````
./sshexec.sh <board ip address> <ssh port> <login> <password> syncloud_setup.sh 
````

For example, for cubieboard connected to 192.168.1.11 and running vendor lubuntu run:

````
./sshexec.sh 192.168.1.11 22 linaro linaro syncloud_setup.sh
````
````
./sshexec.sh 192.168.1.70 22 pi raspberry syncloud_setup.sh
```

## Build
````
./build-image.sh
````

Result Image: syncloud-raspberrypi.img

### CI: add this line to your device's crontab
````
*/1 * * * * wget -qO- https://raw.github.com/syncloud/owncloud-setup/master/ci/ci.sh | bash
````
