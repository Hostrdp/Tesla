#!/bin/bash

echo "Installing PVE and dependecies"
apt install proxmox-ve postfix open-iscsi chrony -y
apt remove linux-image-amd64 'linux-image-5.10*' -y
update-grub
apt remove os-prober -y

echo "Install IP Tables"
apt-get install -y iptables iptables-persistent

echo "Setup Fail2Ban for Security"
bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/Hostrdp/Tesla/main/secure.sh)

echo "Install Dark Themes for PVE"
bash <(curl -s https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh ) install

echo "Running Post Install PVE script"
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/post-pve-install.sh)" -y
