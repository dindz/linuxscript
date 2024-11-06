#!/bin/ash

# Update and upgrade the system
apk update && apk upgrade

# Install NGINX
apk add nginx

# Remove PHP and related packages if they exist
apk del php81 php81-fpm php81-mysqli php81-curl php81-json php81-mbstring php81-xml php81-xmlrpc php81-gd php81-ctype php81-opcache php81-zlib php81-session php81-phar php81-openssl php81-dom php81-pdo php81-pdo_mysql php81-tokenizer
apk add wget curl

# Enable and start NGINX
rc-update add nginx default
rc-service nginx start

# Configure NGINX for static website
mkdir -p /var/www/html
chown -R nginx:nginx /var/www/html
cat << 'EOF' > /etc/nginx/http.d/default.conf
server {
    listen 80;
    server_name localhost;
    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
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

# Remove any existing WordPress files
rm -rf /var/www/html/wp-*

# Restart NGINX to apply changes
rc-service nginx restart

# Remove MariaDB if it was installed
apk del mariadb mariadb-client mariadb-server

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

server.listen(3000, 'localhost', () => {
  console.log('Node.js server running on http://localhost:3000/');
});
EOF

# Install PM2 to manage the Node.js application
npm install -g pm2

# Start the Node.js application with PM2
pm2 start /var/www/nodejs-app/server.js
pm2 save
pm2 startup

# Configure NGINX for Node.js
cat << 'EOF' > /etc/nginx/http.d/nodejs.conf
server {
    listen 8080;
    server_name localhost;
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Restart NGINX for all changes to take effect
rc-service nginx restart

echo "Setup complete. You can now access:"
echo "- Static website at http://localhost/"
echo "- Node.js application at http://localhost:8080/ (proxied from Node.js running on port 3000)"
