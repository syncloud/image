function cleanup {
    local DST_ROOTFS=$1
    local SRC_ROOTFS=$2
    local SYNCLOUD_IMAGE=$3
    local SYNCLOUD_BOARD=$4
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
    rm -rf ${SYNCLOUD_BOARD}
    dmsetup remove -f /dev/mapper/loop* || true

    echo "==== cleanup end ===="
}


function change_uuid {

    local DEVICE=$1
    local UUID=$2
    FSTYPE=$(lsblk ${DEVICE} -o FSTYPE | tail -1)
    if [[ ${FSTYPE} == "ext"* ]]; then
        blkid ${DEVICE} -s UUID -o value
        tune2fs ${DEVICE} -U ${UUID}
        blkid ${DEVICE} -s UUID -o value
    else
        echo "not changing non ext fs uuid"
    fi

}