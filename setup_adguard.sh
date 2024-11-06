#!/bin/ash

# Update and install necessary dependencies
apk update && apk upgrade
apk add curl tar

# Download and install AdGuard Home
echo "Downloading AdGuard Home..."
curl -sSL https://github.com/AdguardTeam/AdGuardHome/releases/download/v0.107.4/AdGuardHome_linux_amd64.tar.gz -o /tmp/adguardhome.tar.gz
tar -xzf /tmp/adguardhome.tar.gz -C /opt
rm /tmp/adguardhome.tar.gz

# Navigate to the AdGuardHome directory
cd /opt/AdGuardHome

# Run the setup wizard without specifying ports (default ports will be used initially)
echo "Running the setup wizard..."
./AdGuardHome -s install

# Wait for the installation to complete
sleep 5

# Modify the configuration file to use custom ports
echo "Modifying configuration file for custom ports..."

# Change the web interface port and DNS port (8081 and 5353 as example)

touch /opt/AdGuardHome/AdGuardHome.yaml
sed -i 's/"bind_port": 3000/"bind_port": 8081/' /opt/AdGuardHome/AdGuardHome.yaml
sed -i 's/"port": 53/"port": 5353/' /opt/AdGuardHome/AdGuardHome.yaml

# Create a service script for AdGuard Home
echo "Creating service script for AdGuard Home..."
cat <<EOF > /etc/init.d/adguardhome
#!/sbin/openrc-run

name="AdGuard Home"
description="Network-wide ads & trackers blocking DNS server"
command="/opt/AdGuardHome/AdGuardHome"
command_args="-s run"
pidfile="/run/adguardhome.pid"

depend() {
    need net
    use dns logger
}

start_pre() {
    checkpath -d -m 0755 -o root:root /var/log/AdGuardHome
}
EOF

# Make the service script executable
chmod +x /etc/init.d/adguardhome

# Add the service to startup
rc-update add adguardhome default

# Start AdGuard Home service
echo "Starting AdGuard Home..."
rc-service adguardhome start

# Output completion message
echo "AdGuard Home installation and setup complete!"
echo "You can access the web interface at http://<your-server-ip>:8081 to configure it."
echo "DNS service is running on port 5353."