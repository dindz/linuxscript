#!/bin/sh

# Update and install required packages
apk update
apk add --no-cache curl tar

# Download and install AdGuard Home
curl -s -S -L https://static.adguard.com/adguardhome/release/AdGuardHome_linux_amd64.tar.gz | tar -xzf - -C /opt

# Create AdGuard Home user and group
addgroup -S adguard
adduser -S -D -H -h /opt/AdGuardHome -s /sbin/nologin -G adguard adguard

# Set permissions
chown -R adguard:adguard /opt/AdGuardHome

# Create AdGuard Home service file
cat > /etc/init.d/adguardhome <<EOL
#!/sbin/openrc-run

name="AdGuard Home"
description="Network-wide ads & trackers blocking DNS server"
command="/opt/AdGuardHome/AdGuardHome"
command_args="-s run -h 0.0.0.0 -p 3333 --port 5353"
command_user="adguard:adguard"
pidfile="/run/adguardhome.pid"

depend() {
    need net
    use dns logger
}

start_pre() {
    checkpath -d -m 0755 -o adguard:adguard /var/log/AdGuardHome
}
EOL

# Make the service file executable
chmod +x /etc/init.d/adguardhome

# Add AdGuard Home to default runlevel
rc-update add adguardhome default

# Start AdGuard Home service
rc-service adguardhome start

echo "AdGuard Home has been installed and started."
echo "Please configure it by visiting http://YOUR_IP:3333"
echo "The DNS server is running on port 5353."
echo "You may need to modify your firewall rules to allow these ports."