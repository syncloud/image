NODE_NAME=$(cat /etc/hostname)

if [[ $NODE_NAME != "Cubian" ]]; then 
    echo "This script is checked only on Cubian images" 1>&2
    exit 1
fi

CORES_NUM=$(nproc)

if [[ $CORES_NUM == 1 ]]; then
    echo "cubieboard"
    exit 0
fi

if [[ $CORES_NUM == 2 ]]; then
    TOTAL_MEMORY=$(cat /proc/meminfo | grep MemTotal | awk '{ print $2 }')

    if [[ $TOTAL_MEMORY == 828096 ]]; then
        echo "cubieboard2"
        exit 0
    fi

    if [[ $TOTAL_MEMORY == 1866408 ]]; then
        echo "cubietruck"
        exit 0
    fi
fi

echo "unknown"
exit 1
