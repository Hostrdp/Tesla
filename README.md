# Usage

# #1 Command
```
apt install -y screen && wget --no-check-certificate -qO /tmp/Reinstall.sh https://raw.githubusercontent.com/Hostrdp/Tesla/main/Reinstall.sh && chmod +x /tmp/Reinstall.sh && screen -S asd bash /tmp/Reinstall.sh -dd 'https://cdn.akumavm.com/win12.xz'
```

# #Via Kernel Installation
```
wget --no-check-certificate -qO kernel.sh https://raw.githubusercontent.com/Hostrdp/Tesla/main/kernel.sh && chmod +x kernel.sh && bash kernel.sh
```
# If error grub.cfg!
```
mkdir /boot/grub2 && grub-mkconfig -o /boot/grub2/grub.cfg && update-grub2
```
# Setup and Build NAT VM Proxmox
```
bash <(wget -qO- --no-check-certificate https://github.com/Hostrdp/Tesla/raw/main/setup_nat.sh)
```
```
bash <(wget -qO- --no-check-certificate https://github.com/Hostrdp/Tesla/raw/main/buildvm.sh)
```
