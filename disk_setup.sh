#!/bin/bash

# Partition, format and mount disk (XFS)
# Assuming the data disk device is /dev/sdc

echo -e "n\np\n1\n\n\nw" | fdisk /dev/sdc
mkfs.xfs /dev/sdc1
mkdir -p /data
echo -e '/dev/sdc1\t/data\txfs\tdefaults,nofail,x-systemd.automount,prjquota,pquota\t0 2' >> /etc/fstab
systemctl daemon-reload
systemctl restart local-fs.target

# Reconfigure Docker,
# point it to the new data directory

mkdir -p /etc/systemd/system/docker.service.d

cat > /etc/systemd/system/docker.service.d/docker.conf <<EOF
[Unit]
Description=Docker Service
After=multi-user.target

[Service]
Environment="DOCKER_OPTS=-H unix:///run/docker.sock -g /data/docker --storage-driver=aufs --bip=172.17.42.1/16 --raw-logs"
ExecStart=
ExecStart=/usr/bin/docker daemon \$DOCKER_OPTS
EOF

systemctl daemon-reload
systemctl restart docker
systemctl enable docker

# Ensure elastic user owns the data directory
chown elastic:elastic /data
