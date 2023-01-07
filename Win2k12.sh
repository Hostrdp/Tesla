#!/bin/bash

#Autoscript Install Windows Server 2012R2 DC

apt-get update
apt-get install -y xz-utils openssl gawk file

wget --no-check-certificate -qO InstallNET.sh 'https://moeclub.org/attachment/LinuxShell/InstallNET.sh' && bash InstallNET.sh -dd 'http://161.35.216.161/Win2k12dc.gz'
