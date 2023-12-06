#!/bin/bash

apt install proxmox-ve postfix open-iscsi -y
apt remove linux-image-amd64 'linux-image-5.10*' -y
update-grub
apt remove os-prober -y

bash <(curl -s https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh ) install
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/post-pve-install.sh)" -y
