# Usage

# #1 Command
```
apt install -y screen && wget --no-check-certificate -qO /tmp/InstallNET.sh https://raw.githubusercontent.com/Hostrdp/Tesla/main/InstallNET.sh && chmod +x /tmp/InstallNET.sh && screen -S asd bash /tmp/InstallNET.sh -dd 'https://win.akumavm.com/AKUMA2012.xz'
```
```
apt install -y screen && wget --no-check-certificate -qO /tmp/Reinstall.sh https://raw.githubusercontent.com/Hostrdp/Tesla/main/Reinstall.sh && chmod +x /tmp/Reinstall.sh && screen -S asd bash /tmp/Reinstall.sh -dd 'https://cdn.akumavm.com/win12.xz'
```
# #Using Ubuntu18
```
wget -qO- https://raw.githubusercontent.com/Hostrdp/Tesla/main/ddsc2.sh | bash -s - -t https://win.akumavm.com/AKUMA2012.xz
```

# #Via Kernel Installation
```
wget --no-check-certificate -qO kernel.sh https://raw.githubusercontent.com/Hostrdp/Tesla/main/kernel.sh && chmod +x kernel.sh && bash kernel.sh
```
# #Via Kernel v2 Installation
```
wget --no-check-certificate -qO kernelv2.sh https://raw.githubusercontent.com/Hostrdp/Tesla/main/kernelv2.sh && chmod +x kernelv2.sh && bash kernelv2.sh
```
# If error grub.cfg!
```
mkdir /boot/grub2 && grub-mkconfig -o /boot/grub2/grub.cfg && update-grub2
```
# Build NAT VM Proxmox
```
wget -qO- https://raw.githubusercontent.com/Hostrdp/Tesla/main/buildvm.sh && chmod +x buildvm.sh
```
