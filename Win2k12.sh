#!/bin/bash

#Autoscript Install Windows

apt-get update
apt-get install -y xz-utils openssl gawk file

wget --no-check-certificate -qO InstallNET.sh 'https://moeclub.org/attachment/LinuxShell/InstallNET.sh' && bash InstallNET.sh -dd 'http://15.235.203.45/Win2k12dc.gz'
