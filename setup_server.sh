#!/bin/ash

# Update and upgrade the system
apk update && apk upgrade

# Configure static IP address for eth0
cat <<EOF > /etc/network/interfaces
auto eth3
iface eth3 inet static
    address 192.168.254.108
    netmask 255.255.255.0
    gateway 192.168.254.254
EOF

# Restart networking service to apply changes
/etc/init.d/networking restart

# Restart all network-related services
for service in $(rc-service -l | grep -E '(net|dhcp|dns|network)'); do
    rc-service $service restart
done
# Verify the new IP configuration
ip a show eth3

echo "Static IP configuration complete and network services restarted."

# Update and upgrade the system
apk update && apk upgrade

# Install NGINX
apk add nginx
apk add wget curl

# Enable and start NGINX
rc-update add nginx default
rc-service nginx start

# Configure NGINX for static website
mkdir -p /var/www/html
chown -R nginx:nginx /var/www/html
cat << EOF > /etc/nginx/http.d/default.conf
server {
    listen 80;
    server_name 192.168.88.115;  # Replace with your Alpine machine's IP
    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Create a simple index.html
cat << 'EOF' > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Static Website</title>
</head>
<body>
    <h1>It works!</h1>
    <p>This is a simple static website.</p>
</body>
</html>
EOF

# Restart NGINX to apply changes
rc-service nginx restart

# Install Node.js and npm
apk add nodejs npm

# Create a basic Node.js application
mkdir -p /var/www/nodejs-app
touch /var/www/nodejs-app/server.js
cat << 'EOF' > /var/www/nodejs-app/server.js
const http = require('http');

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('Hello from Node.js!\n');
});

server.listen(7000, '0.0.0.0', () => {
  console.log('Node.js server running on http://0.0.0.0:7000/');
});
EOF

# Install PM2 to manage the Node.js application
npm install -g pm2

# Start the Node.js application with PM2
pm2 start /var/www/nodejs-app/server.js
pm2 save
pm2 startup

# Configure NGINX for Node.js
cat << EOF > /etc/nginx/http.d/nodejs.conf
server {
    listen 8080;
    server_name 192.168.88.115;  # Replace with your Alpine machine's IP
    location / {
        proxy_pass http://127.0.0.1:7000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Restart NGINX for all changes to take effect
rc-service nginx restart

echo "Setup complete. You can now access:"
echo "- Static website at http://192.168.254.108/"  # Replace with your Alpine machine's IP
echo "- Node.js application at http://192.168.254.108:8080/ (proxied from Node.js running on port 7000)"
