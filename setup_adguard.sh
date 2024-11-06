#!/bin/ash

# Update and install necessary dependencies
apk update && apk upgrade
apk add curl tar

# Download and install AdGuard Home
echo "Downloading AdGuard Home..."
curl -sSL https://github.com/AdguardTeam/AdGuardHome/releases/download/v0.107.4/AdGuardHome_linux_amd64.tar.gz -o /tmp/adguardhome.tar.gz
tar -xvzf /tmp/adguardhome.tar.gz -C /opt
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
sed -i 's/"http_port": 3000/"http_port": 8081/' /opt/AdGuardHome/AdGuardHome.yaml
sed -i 's/"dns_port": 53/"dns_port": 5353/' /opt/AdGuardHome/AdGuardHome.yaml

# Create a service script for AdGuard Home
echo "Creating service script for AdGuard Home..."
cat <<EOF > /etc/init.d/adguardhome
#!/bin/sh
# Start/Stop the AdGuard Home service

case "\$1" in
start)
  echo "Starting AdGuard Home"
  /opt/AdGuardHome/AdGuardHome -s start
  ;;
stop)
  echo "Stopping AdGuard Home"
  /opt/AdGuardHome/AdGuardHome -s stop
  ;;
*)
  echo "Usage: \$0 {start|stop}"
  exit 1
  ;;
esac
EOF

# Make the service script executable
chmod +x /etc/init.d/adguardhome

# Add the service to startup
rc-update add adguardhome default

# Start AdGuard Home service
echo "Starting AdGuard Home..."
/opt/AdGuardHome/AdGuardHome -s start

# Output completion message
echo "AdGuard Home installation and setup complete!"
echo "You can access the web interface at http://<your-server-ip>:8081 to configure it."
echo "DNS service is running on port 5353."
