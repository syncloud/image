#!/bin/bash -e

echo "===== loop cleanup ====="

ls -la /dev/mapper/*
losetup || true

mapper_arr=(`ls /dev/mapper/loop* 2>/dev/null`)
if [[ ${#mapper_arr[@]} -gt 0 ]];then
 apt update && apt install -y dmsetup
 dmsetup remove -f /dev/mapper/loop* || true
fi

losetup -D || true
