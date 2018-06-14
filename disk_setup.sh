#!/bin/bash

# Partition, format and mount disk (XFS)
# Assuming the data disk device is /dev/sdc

echo -e "n\np\n1\n\n\nw" | fdisk /dev/sdc
mkfs.xfs /dev/sdc1
mkdir -p /data
echo -e '/dev/sdc1\t/data\txfs\tdefaults,nofail,x-systemd.automount,prjquota,pquota\t0 2' >> /etc/fstab
systemctl daemon-reload
systemctl restart local-fs.target
chown elastic:elastic /data
