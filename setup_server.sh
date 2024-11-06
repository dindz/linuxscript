#!/bin/ash

# Update and upgrade the system
apk update && apk upgrade

# Install NGINX, PHP, PHP-FPM, and necessary PHP extensions
apk add nginx php81 php81-fpm php81-mysqli php81-curl php81-json php81-mbstring php81-xml php81-xmlrpc php81-gd php81-ctype php81-opcache php81-zlib php81-session php81-phar php81-openssl php81-dom php81-pdo php81-pdo_mysql php81-tokenizer

apk add wget curl

# Enable and start NGINX
rc-update add nginx default
rc-service nginx start

# Enable and start PHP-FPM
rc-update add php-fpm81 default
rc-service php-fpm81 start

# Configure NGINX for PHP
mkdir -p /var/www/html
chown -R nginx:nginx /var/www/html
cat << 'EOF' > /etc/nginx/http.d/default.conf
server {
    listen 80;
    server_name localhost;  # Using localhost since no domain name is set
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php81-fpm.sock;
        fastcgi_index index.php;
        include fastcgi.conf;
    }
}
EOF

# Restart NGINX to apply changes
rc-service nginx restart

# Install and configure MariaDB
apk add mariadb mariadb-client mariadb-server
rc-update add mariadb default
rc-service mariadb setup
rc-service mariadb start

# Secure MariaDB installation
mysql_secure_installation <<EOF

y
n
y
y
y
EOF

# Create WordPress database and user
mysql -u root -p <<EOF
CREATE DATABASE wordpress_db;
CREATE USER 'wordpress_user'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wordpress_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF

# Download and configure WordPress
cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
mv wordpress/* .
rm -rf wordpress latest.tar.gz

# Set permissions for WordPress
chown -R nginx:nginx /var/www/html
chmod -R 755 /var/www/html

# Set up WordPress configuration
cp wp-config-sample.php wp-config.php
sed -i "s/database_name_here/wordpress_db/" wp-config.php
sed -i "s/username_here/wordpress_user/" wp-config.php
sed -i "s/password_here/your_password/" wp-config.php

# Install Node.js and npm
apk add nodejs npm

# Create a basic Node.js application
mkdir -p /var/www/nodejs-app
cat << 'EOF' > /var/www/nodejs-app/app.js
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
pm2 start /var/www/nodejs-app/app.js
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
echo "- WordPress at http://localhost/"
echo "- Node.js application at http://localhost:8080/"

echo "Setup complete. You can now access PHP, WordPress, and Node.js applications on your Alpine Linux server."
