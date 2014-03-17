import commands
import sys

def getPartitions():
    partitions_output = commands.getoutput('blkid')
    partitions_descriptions = partitions_output.split('\n')
    partitions = [ partition.split(':')[0] for partition in partitions_output.split('\n') ]
    return partitions

def selectPartition(partitions, need_partitions):
    for partition in need_partitions:
        if partition in partitions:
            return partition
    return None
    
if __name__ == '__main__':
    datadir = sys.argv[1]
    print datadir
    partitions = getPartitions()
    partition = selectPartition(partitions, ['/dev/sda1', '/dev/sdb1'])
    if partition:
        mount_output = commands.getoutput('mount {} {}'.format(partition, datadir))
        print mount_output
