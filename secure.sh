#!/bin/sh

# Exit on any error
set -e

# Update and upgrade package list
apt update && apt upgrade -y

# Install fail2ban
apt install -y fail2ban

# Setup Base Config
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Setup Jail
cat <<EOF >> /etc/fail2ban/jail.local
[proxmox]
enabled = true
port = https,http,8006
filter = proxmox
backend = systemd
maxretry = 3
findtime = 5m
bantime = 1w
EOF

# Setup Filter
cat <<EOF | tee /etc/fail2ban/filter.d/proxmox.conf
[Definition]
failregex = pvedaemon\[.*authentication failure; rhost=<HOST> user=.* msg=.*
ignoreregex =
EOF

# Restart fail2ban
systemctl restart fail2ban

# Display success message
echo "Fail2Ban configuration completed successfully."
