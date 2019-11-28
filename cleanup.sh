#!/bin/bash -e

echo "===== loop cleanup ====="
ls -la /dev/mapper/*
losetup || true
dmsetup remove -f /dev/mapper/loop* || true
