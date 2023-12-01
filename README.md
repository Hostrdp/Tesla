# Usage

# #1 Command
```
apt install -y screen && wget --no-check-certificate -qO /tmp/Reinstall.sh https://raw.githubusercontent.com/Hostrdp/Tesla/main/Reinstall.sh && chmod +x /tmp/Reinstall.sh && screen -S asd bash /tmp/Reinstall.sh -dd 'https://cdn.akumavm.com/win12.xz'
```

# #Via Kernel Installation
```
bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/Hostrdp/Tesla/main/kernel.sh)
```
# If error grub.cfg!
```
mkdir /boot/grub2 && grub-mkconfig -o /boot/grub2/grub.cfg && update-grub2
```
# Setup and Build NAT VM Proxmox
```
bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/Hostrdp/Tesla/main/setup_nat.sh)
```
```
curl -L https://raw.githubusercontent.com/Hostrdp/Tesla/main/buildvm.sh -o buildvm.sh && chmod +x buildvm.sh
```
