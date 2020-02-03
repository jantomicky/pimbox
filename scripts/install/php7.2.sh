#!/bin/bash

CONFIG_PHP_FPM="/etc/php/7.2/fpm/php.ini"
CONFIG_PHP_CLI="/etc/php/7.2/cli/php.ini"

echo "Installing PHP 7.2…"
apt-get install -y php7.2 php7.2-fpm

echo "Installing PHP modules…"
apt-get install -y php7.2-mysql php7.2-xml php7.2-curl php7.2-soap php7.2-gd php7.2-bz2 php7.2-mbstring php7.2-zip php7.2-intl php7.2-dev php7.2-xdebug php7.2-redis

echo "Configuring PHP…"
sed -i "s|short_open_tag = Off|short_open_tag = On|" $CONFIG_PHP_FPM $CONFIG_PHP_CLI
sed -i "s|memory_limit = 128M|memory_limit = 1024M|" $CONFIG_PHP_FPM $CONFIG_PHP_CLI
sed -i "s|;session.save_path|session.save_path|" $CONFIG_PHP_FPM
sed -i "s|upload_max_filesize = 2M|upload_max_filesize = 128M|" $CONFIG_PHP_FPM
sed -i "s|post_max_size = 8M|post_max_size = 128M|" $CONFIG_PHP_FPM
sed -i "s|max_execution_time = 30|max_execution_time = 1800|" $CONFIG_PHP_FPM
sed -i "s|default_socket_timeout = 60|default_socket_timeout = 1800|" $CONFIG_PHP_FPM

echo "Configuring XDebug…"
cat >> /etc/php/7.2/mods-available/xdebug.ini <<EOL
xdebug.remote_enable = 1
xdebug.remote_connect_back = 1
xdebug.remote_port = 9000
xdebug.max_nesting_level = 1024
EOL

echo "Restarting the php7.2-fpm service…"
systemctl restart php7.2-fpm.service

echo "PHP 7.2 installed."
