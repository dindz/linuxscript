#!/bin/ash

# Update and upgrade the system
apk update && apk upgrade

# Configure static IP address for eth0
cat <<EOF > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.168.254.104
    netmask 255.255.255.0
    gateway 192.168.254.254
EOF

# Restart networking service to apply changes
/etc/init.d/networking restart

# Verify the new IP configuration
ip a show eth0

echo "Static IP configuration complete."
