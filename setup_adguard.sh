#!/bin/ash

# Update and install necessary dependencies
apk update && apk upgrade
apk add curl tar

# Download and install AdGuard Home
echo "Downloading AdGuard Home..."
curl -sSL https://github.com/AdguardTeam/AdGuardHome/releases/download/v0.107.54/AdGuardHome_linux_386.tar.gz -o /tmp/AdGuardHome_linux_386.tar.gz
tar -xzf /tmp/AdGuardHome_linux_386.tar.gz -C /opt
rm /tmp/AdGuardHome_linux_386.tar.gz

# Navigate to the AdGuardHome directory
cd /opt/AdGuardHome

#stop the pm2 server of nodejs
pm2 stop
pm2 kill

# Run the setup wizard without specifying ports (default ports will be used initially)
echo "Running the setup wizard..."
chmod +x AdGuardHome
./AdGuardHome -s install

# Output completion message
echo "AdGuard Home installation and setup complete!"
echo "You can access the web interface at http://<your-server-ip>:3000 to configure it."
echo "DNS service is running on port 5353."