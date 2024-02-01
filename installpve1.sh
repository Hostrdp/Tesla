#!/bin/bash

apt update && apt upgrade -y

echo "Install and Setup pre-run script"
apt install -y wget curl nano screen ftp linux-cpupower chrony
systemctl enable chrony

echo "Configures CPU freqs"
cpupower frequency-set --governor performance
cpupower idle-set --disable-by-latency 0

echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bullseye pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
wget https://enterprise.proxmox.com/debian/proxmox-release-bullseye.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bullseye.gpg

# Verify
sha512sum /etc/apt/trusted.gpg.d/proxmox-release-bullseye.gpg
apt update && apt full-upgrade -y
apt install pve-kernel-5.15 -y
systemctl reboot
