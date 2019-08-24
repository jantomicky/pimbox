#!/bin/bash

CONFIGURATION_PHP="/etc/php/7.0/cli/php.ini /etc/php/7.0/fpm/php.ini"

echo "Installing PHP 7.0…"
apt-get install -y php7.0 php7.0-fpm

echo "Installing PHP modules…"
apt-get install -y php7.0-mysql php7.0-xml php7.0-curl php7.0-soap php7.0-gd php7.0-bz2 php7.0-mbstring php7.0-zip php7.0-intl php7.0-dev php7.0-xdebug

echo "Configuring PHP…"
sed -i "s|;session.save_path|session.save_path|" $CONFIGURATION_PHP
sed -i "s|short_open_tag = Off|short_open_tag = On|" $CONFIGURATION_PHP
sed -i "s|memory_limit = 128M|memory_limit = 1024M|" $CONFIGURATION_PHP
sed -i "s|upload_max_filesize = 2M|upload_max_filesize = 128M|" $CONFIGURATION_PHP
sed -i "s|post_max_size = 8M|post_max_size = 128M|" $CONFIGURATION_PHP

echo "Configuring XDebug…"
cat >> /etc/php/7.0/mods-available/xdebug.ini <<EOL
xdebug.remote_enable = 1
xdebug.remote_connect_back = 1
xdebug.remote_port = 9000
xdebug.max_nesting_level = 1024
EOL

echo "Restarting the php7.0-fpm service…"
systemctl restart php7.0-fpm.service

echo "PHP 7.0 installed."
