#!/bin/bash -e

echo "===== loop cleanup ====="

ls -la /dev/mapper/*
losetup || true

mapper_arr=(`ls /dev/mapper/loop* 2>/dev/null || true`)
if [[ ${#mapper_arr[@]} -gt 0 ]];then
 apt update && apt install -y dmsetup
 dmsetup remove -f /dev/mapper/loop* || true
fi


loopdev_name=`losetup -O NAME,BACK-FILE | grep syncloud-*-$DRONE_TAG.img | cut -d " " -f 1`
[[ -n $loopdev_name ]] && losetup -d $loopdev_name || true
