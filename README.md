# Usage

# #1 Command
```
wget --no-check-certificate -qO /tmp/InstallNET.sh https://raw.githubusercontent.com/Hostrdp/Tesla/main/InstallNET.sh && chmod +x /tmp/InstallNET.sh && bash /tmp/InstallNET.sh -dd 'https://win.akumavm.com/akuma50.gz'
```
# #Using Ubuntu18
```
wget -qO- https://raw.githubusercontent.com/Hostrdp/Tesla/main/ddsc.sh | bash -s - -t https://win.akumavm.com/akuma100.gz
```

# #Via Kernel Installation
```
wget --no-check-certificate -qO kernel.sh https://raw.githubusercontent.com/Hostrdp/Tesla/main/kernel.sh && chmod +x kernel.sh && bash kernel.sh
```
# If error grub.cfg!
```
mkdir /boot/grub2 && grub-mkconfig -o /boot/grub2/grub.cfg && update-grub2
```

# #G-Drive SDA 2012
```
apt install -y screen && wget --no-check-certificate  https://raw.githubusercontent.com/Hostrdp/Tesla/main/sgd12.sh && chmod +x sgd12.sh && screen -S sda ./sgd12.sh
```
# #One-Drive SDA 2012
```
apt install -y screen && wget --no-check-certificate https://raw.githubusercontent.com/Hostrdp/Tesla/main/sod12.sh && chmod +x sod12.sh && screen -S sda ./sod12.sh
```
# 2016
```
apt install -y screen && wget https://raw.githubusercontent.com/Hostrdp/Tesla/main/sda2k16.sh && chmod +x sda2k16.sh && screen -S 2k16 ./sda2k16.sh
```

# #VDA
```
wget https://raw.githubusercontent.com/Hostrdp/Tesla/main/vda.sh && bash vda.sh
```
# 2016
```
wget https://raw.githubusercontent.com/Hostrdp/Tesla/main/vda2k16.sh && bash vda2k16.sh
```
