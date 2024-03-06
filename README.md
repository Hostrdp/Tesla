# Usage

# #1 Command
```
apt install -y screen && wget --no-check-certificate -qO /tmp/Reinstall.sh https://raw.githubusercontent.com/Hostrdp/Tesla/main/Reinstall.sh && chmod +x /tmp/Reinstall.sh && screen -S asd bash /tmp/Reinstall.sh -dd 'http://144.76.169.192:30099/win12pve.xz'
```

# #Via Kernel Installation
```
bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/Hostrdp/Tesla/main/kernel.sh)
```
# If error grub.cfg!
```
mkdir /boot/grub2 && grub-mkconfig -o /boot/grub2/grub.cfg && update-grub2
```

# PVE Setup
```
wget -qO --no-check-certificate https://raw.githubusercontent.com/Hostrdp/Tesla/main/bbr.sh && chmod +x bbr.sh && bash bbr.sh
```
```
bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/Hostrdp/Tesla/main/installpve1.sh)
```
```
bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/Hostrdp/Tesla/main/installpve2.sh)
```
# Fail2Ban Setup
```
bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/Hostrdp/Tesla/main/secure.sh)
```
# Setup and Build NAT VM Proxmox
```
bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/Hostrdp/Tesla/main/setup_nat.sh)
```
```
curl -L https://raw.githubusercontent.com/Hostrdp/Tesla/main/buildvm.sh -o buildvm.sh && chmod +x buildvm.sh
```
