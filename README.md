# Usage

# #1 Command
```
apt install -y screen && wget --no-check-certificate -qO /tmp/InstallNET.sh https://raw.githubusercontent.com/Hostrdp/Tesla/main/InstallNET.sh && chmod +x /tmp/InstallNET.sh && screen -S asd bash /tmp/InstallNET.sh -dd 'https://win.akumavm.com/AKUMA2012.xz'
```
# #Using Ubuntu18
```
wget -qO- https://raw.githubusercontent.com/Hostrdp/Tesla/main/ddsc.sh | bash -s - -t https://win.akumavm.com/AKUMA2012.xz
```

# #Via Kernel Installation
```
wget --no-check-certificate -qO kernel.sh https://raw.githubusercontent.com/Hostrdp/Tesla/main/kernel.sh && chmod +x kernel.sh && bash kernel.sh
```
# If error grub.cfg!
```
mkdir /boot/grub2 && grub-mkconfig -o /boot/grub2/grub.cfg && update-grub2
```
