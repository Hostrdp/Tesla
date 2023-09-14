#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
    clear
    echo "Error: This script must be run as root!" 1>&2
    exit 1
fi

if [ -f "/usr/bin/yum" ] && [ -d "/etc/yum.repos.d" ]; then
    yum update -y
    yum install -y wget curl file gawk openssl xz efibootmgr
    
elif [ -f "/usr/bin/apt-get" ] && [ -f "/usr/bin/dpkg" ]; then
    apt-get update --fix-missing
    apt install -y curl wget file gawk openssl xz-utils efibootmgr
    
fi

wget --no-check-certificate -O- 'https://oss.sunpma.com/Windows/Whole/Win10_Pro_20h1_19043.928_x64_administrator_Teddysun.com.gz' | gunzip | dd of=/dev/vda status=progress
echo "Windows installation completed"
echo "Rebooting now"
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger
