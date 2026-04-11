#!/bin/bash -e

echo "===== loop cleanup ====="

echo "detaching stale loop devices (deleted files)..."
losetup -l | grep '(deleted)' | awk '{print $1}' | while read dev; do
  losetup -d "$dev" && echo "detached $dev" || true
done

ls -la /dev/mapper/*
losetup || true

mapper_arr=(`ls /dev/mapper/loop* 2>/dev/null || true`)
if [[ ${#mapper_arr[@]} -gt 0 ]];then
 apt update && apt install -y dmsetup
 dmsetup remove -f /dev/mapper/loop* || true
fi


loopdev_name=`losetup -O NAME,BACK-FILE | grep syncloud-*-$DRONE_TAG.img | cut -d " " -f 1`
[[ -n $loopdev_name ]] && losetup -d $loopdev_name || true
