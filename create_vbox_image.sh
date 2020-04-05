#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#apt-get install -y virtualbox sshpass

if [[ "$#" -ne 1 ]]; then
    echo "Usage: $0 vbox_image_file"
    exit 1
fi

IMAGE_FILE=$1
VDI_FILE=${IMAGE_FILE%.*}
VM='Syncloud-VM'
SSH_PORT=3333

chmod a=r ${IMAGE_FILE}

VBoxManage controlvm ${VM} poweroff || true

VBoxManage unregistervm ${VM} --delete || true

rm -rf ${VDI_FILE}.vdi
rm -rf ${VDI_FILE}.vdi.xz
rm -rf ${VDI_FILE}-test.vdi

VBoxManage convertdd ${IMAGE_FILE} ${VDI_FILE}.vdi --format VDI

chmod a=r ${VDI_FILE}.vdi

cp ${VDI_FILE}.vdi ${VDI_FILE}-test.vdi

echo "testing"

xz -0 ${VDI_FILE}.vdi -k
rm -rf $HOME/"VirtualBox VMs"/${VM}

VBoxManage createvm --name ${VM} --ostype "Debian_64" --register

VBoxManage storagectl ${VM} --name "SATA Controller" --add sata --controller IntelAHCI

VBoxManage list hdds

ls -la

VBoxManage storageattach ${VM} --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium ${VDI_FILE}-test.vdi

VBoxManage modifyvm ${VM} --ioapic on

VBoxManage modifyvm ${VM} --boot1 dvd --boot2 disk --boot3 none --boot4 none

VBoxManage modifyvm ${VM} --memory 1024 --vram 128

VBoxManage modifyvm ${VM} --natpf1 "guestssh,tcp,,${SSH_PORT},,22"

VBoxHeadless --startvm ${VM} &


ATTEMPT=0
TOTAL_ATTEMPTS=10
set +e
ssh-keygen -f "/root/.ssh/known_hosts" -R [localhost]:${SSH_PORT}

sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p ${SSH_PORT} root@localhost date

while test $? -gt 0
do
  sleep 1
  echo "Waiting for SSH ..."
  ATTEMPT=$((ATTEMPT +1))
  echo "attempt $ATTEMPT of $TOTAL_ATTEMPTS"
  if [[ ${ATTEMPT} -gt ${TOTAL_ATTEMPTS} ]]; then
    echo "unable to connect to vbox instance"
    exit 1
  fi
  sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p ${SSH_PORT} root@localhost date
  
done
set -e
sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p ${SSH_PORT} root@localhost journalctl

VBoxManage controlvm ${VM} poweroff
