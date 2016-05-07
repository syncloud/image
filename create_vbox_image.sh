#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

apt-get install -y virtualbox

rm -rf syncloud.vdi
rm -rf syncloud-test.vdi

VBoxManage convertdd syncloud-vbox.img syncloud.vdi --format VDI

VM='Syncloud-VM'
SSH_PORT=3333

VBoxManage controlvm $VM poweroff

VBoxManage unregistervm $VM --delete

cp syncloud.vdi syncloud-test.vdi

tar czvf syncloud.vdi.tar.gz syncloud.vdi

VBoxManage createvm --name $VM --ostype "Debian_64" --register

VBoxManage storagectl $VM --name "SATA Controller" --add sata --controller IntelAHCI

VBoxManage list hdds

ls -la

VBoxManage storageattach $VM --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium syncloud-test.vdi

VBoxManage modifyvm $VM --ioapic on

VBoxManage modifyvm $VM --boot1 dvd --boot2 disk --boot3 none --boot4 none

VBoxManage modifyvm $VM -memory 1024 --vram 128

VBoxManage modifyvm $VM --natpf1 "guestssh,tcp,,${SSH_PORT},,22"

VBoxManage startvm $VM

sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p ${SSH_PORT} root@localhost date

ATTEMPT=0
TOTAL_ATTEMPTS=10
while test $? -gt 0
do
  sleep 1
  echo "Waiting for SSH ..."
  sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p ${SSH_PORT} root@localhost date
  ATTEMPT=$((ATTEMPT +1))
  echo "attempt $ATTEMPT of $TOTAL_ATTEMPTS"
  if [[ $ATTEMPT -gt $TOTAL_ATTEMPTS ]]; then
    break
  fi
done

sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p ${SSH_PORT} root@localhost journalctl

VBoxManage controlvm $VM poweroff
