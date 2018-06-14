#!/bin/bash

# NOTE: must be run as root

# Documentation reference:
# https://www.elastic.co/guide/en/cloud-enterprise/current/ece-configure-hosts.html#ece-configure-hosts-xenial

# Add Docker repo

apt-key adv --keyserver keyserver.ubuntu.com --recv 58118E89F3A912897C070ADBF76221572C52609D
echo deb https://apt.dockerproject.org/repo ubuntu-xenial main | tee /etc/apt/sources.list.d/docker.list
apt-get update

# Update kernel, install XFS

apt-get install -y linux-generic-lts-xenial xfsprogs

# Install Docker

apt-get install -y docker-engine=1.11*

# Create elastic user

adduser --disabled-password --gecos "" elastic

# Add elastic user to Docker group

usermod -aG docker elastic

# Update GRUB configuration to enable cgroups memory accounting

sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT/ {s/="/="cgroup_enable=memory swapaccount=1 cgroup.memory=nokmem /}' /etc/default/grub.d/50-cloudimg-settings.cfg
update-grub

# Update kernel parameters

echo "vm.max_map_count=262144" >> /etc/sysctl.conf

# Adjust system limits
# TODO: check syntax and formatting

cat >> /etc/security/limits.conf <<EOF
*                soft    nofile         1024000
*                hard    nofile         1024000
*                soft    memlock        unlimited
*                hard    memlock        unlimited
elastic          soft    nofile         1024000
elastic          hard    nofile         1024000
elastic          soft    memlock        unlimited
elastic          hard    memlock        unlimited
root             soft    nofile         1024000
root             hard    nofile         1024000
root             soft    memlock        unlimited
EOF

# Configure Docker options

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

# Network settings

cat > /etc/sysctl.d/70-cloudenterprise.conf <<SETTINGS
net.ipv4.tcp_max_syn_backlog=65536
net.core.somaxconn=32768
net.core.netdev_max_backlog=32768
SETTINGS

# Hold Docker version

echo "docker-engine hold" | dpkg --set-selections

# That's all, folks

echo -e '\n\a\033[1mYou should be all set!\033[0m Please reboot the machine for all the settings to take effect.'
