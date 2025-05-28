#!/bin/bash
# Collect system information
OS=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//' | sed 's/"//g')
RAM=$(free -h | grep Mem | awk '{print $2}')
CPU_CORES=$(grep -c processor /proc/cpuinfo)
DISK=$(df -h / | awk 'NR==2 {print $2 " total, " $4 " free"}')
IP_ADDR=$(hostname -I | awk '{print $1}')
SSH_PORT=$(grep "Port " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "22 (default)")
USER_MACHINE="$(whoami)@$(hostname)"
# Get MAC address of primary interface (the one with the IP)
INTERFACE=$(ip route | grep default | awk '{print $5}')
MAC_ADDR=$(cat /sys/class/net/$INTERFACE/address 2>/dev/null || echo "Not available")
LAST_BOOT=$(who -b | awk '{print $3 " " $4}')

convert -size 1920x1080 xc:black \
  -gravity center -font Helvetica-Bold -pointsize 200 -fill white -annotate +0+0 "0" \
  -gravity center -font Helvetica -pointsize 15 -fill white -annotate +-100+66 "id" \
  -gravity west -font Helvetica -pointsize 15 -fill white -annotate +1030+-10 \
"
$USER_MACHINE
IP: $IP_ADDR
MAC: $MAC_ADDR
SSH port: $SSH_PORT
OS: $OS
CPU cores: $CPU_CORES
RAM: $RAM
Disk: $DISK
Last boot: $LAST_BOOT" \
  ~/Pictures/bg/background.jpg
echo "Image created at ~/Pictures/bg/background.jpg"

