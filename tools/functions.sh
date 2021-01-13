function cleanup {
    local DST_ROOTFS=$1
    local SRC_ROOTFS=$2
    local SYNCLOUD_IMAGE=$3
    echo "==== cleanup ===="

    ls -la /dev/mapper/*
    mount | grep ${DST_ROOTFS} || true
    mount | grep ${DST_ROOTFS} | awk '{print "umounting "$1; system("umount "$3)}' || true
    mount | grep ${DST_ROOTFS} || true
    rm -rf ${SRC_ROOTFS}
    losetup -a || true
    kpartx -v ${SYNCLOUD_IMAGE} || true
    echo "removing loop devices"
    kpartx -d ${SYNCLOUD_IMAGE} || true
    dmsetup remove -f /dev/mapper/loop* || true

    echo "==== cleanup end ===="
}


function change_uuid {

    local DEVICE=$1
    local UUID=$2
    FSTYPE=$(lsblk ${DEVICE} -o FSTYPE | tail -1)
    if [[ ${FSTYPE} != "vfat" ]]; then
        blkid ${DEVICE} -s UUID -o value
        tune2fs -f ${DEVICE} -U ${UUID}
        blkid ${DEVICE} -s UUID -o value
    else
        echo "not changing non ext fs uuid"
    fi

}

function attach_image { 
    local image=$1
    kpartx -avs ${image} > kpartx.out
    sync > /dev/null
    echo loop$(cat kpartx.out | grep loop | head -1 | cut -d ' ' -f3 | cut -d p -f 2)
}

function prepare_image { 
    local image=$1
    set -e
    LOOP=$(attach_image $image)
    echo $LOOP > loop.dev
    export MKE2FS_SYNC=2
    mkfs.ext4 -F -D -E lazy_itable_init=0,lazy_journal_init=0 /dev/mapper/${LOOP}p2
    partprobe /dev/$LOOP
    lsblk /dev/mapper/${LOOP}p2 -o FSTYPE

}
