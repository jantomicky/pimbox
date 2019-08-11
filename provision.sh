#!/bin/bash

# Variables.
DIR_HOME="/home/vagrant"
DIR_TEMP="/tmp"
DIR_PROVISION="$DIR_TEMP/provision"
FILE_PROVISION="/usr/local/provision"
FILE_VHOSTS="$DIR_TEMP/vhosts"
CONFIGURATION_PHP="/etc/php/7.2/cli/php.ini /etc/php/7.2/fpm/php.ini"
CONFIGURATION_MYSQL="/etc/mysql/mysql.conf.d/mysqld.cnf"
MYSQL_PASSWORD_ROOT='secret'

# Functions.
function plog {
	if [ -f $FILE_PROVISION ]; then
		echo "Creating the provisioning log file at $FILE_PROVISION…"
		touch $FILE_PROVISION
	fi
	echo $1 | tee -a $FILE_PROVISION
}

# Check the provisioning state.
if [ -f $FILE_PROVISION ]; then
	echo "Pimbox provisioning already done, skipping…"
	exit 0
fi

# Set up swap.
plog "Setting up swap file…"
fallocate -l 4G /swapfile && chmod 600 /swapfile
mkswap /swapfile && swapon /swapfile
echo "/swapfile    none    swap    sw    0    0" >> /etc/fstab

# Miscellaneous.
plog "Setting server time zone to Europe/Prague…"
ln -sf /usr/share/zoneinfo/Europe/Prague /etc/localtime
plog "Setting up Vim as the default text editor…"
echo "3" | update-alternatives --config editor > /dev/null

# Add PPAs and update package lists.
plog "Adding ppa:ondrej/php…"
add-apt-repository -y ppa:ondrej/php
plog "Updating package lists…"
apt-get update -y

# Upgrade all packages.
plog "Upgrading packages…"
apt-get upgrade -y

# Install essential packages.
plog "Installing essential packages…"
apt-get install -y build-essential openjdk-8-jre-headless unzip expect redis-server

# Set up Apache.
plog "Installing Apache (with FastCGI module)…"
apt-get install -y apache2 libapache2-mod-fastcgi

# Enable all required Apache modules.
plog "Enabling Apache modules…"
a2enmod actions alias vhost_alias rewrite fastcgi proxy_fcgi

# If available, set up Apache Virtual Hosts.
if [ -f $FILE_VHOSTS ]; then
	plog "Setting up Apache Dynamic Virtual Hosts…"
	cp $FILE_VHOSTS /etc/apache2/sites-available/000-default.conf
fi

# Add 'vagrant' user to the 'www-data' group.
plog "Adding 'vagrant' user to the 'www-data' group…"
adduser vagrant www-data

# Add 'www-data' user to the 'vagrant' group.
plog "Adding 'www-data' user to the 'vagrant' group…"
adduser www-data vagrant

# Restart Apache for the changes to take place.
plog "Restarting Apache…"
systemctl restart apache2.service

# Install the latest PHP 7.2 version.
plog "Installing PHP 7.2…"
apt-get install -y php7.2 php7.2-fpm

# Install all required PHP modules.
plog "Installing PHP modules…"
apt-get install -y php7.2-mysql php7.2-xml php7.2-curl php7.2-soap php7.2-gd php7.2-bz2 php7.2-mbstring php7.2-zip php7.2-intl php7.2-dev php7.2-xdebug

# Install Composer.
plog "Installing Composer…"
EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
then
	>&2 echo 'ERROR: Invalid Composer installer signature!'
else
	php composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer
fi
rm composer-setup.php

# Install Deployer.
plog "Installing Deployer…"
curl -sL https://deployer.org/deployer.phar -o /usr/local/bin/dep
chmod +x /usr/local/bin/dep
ln -s /usr/local/bin/dep /usr/local/bin/deployer

# Set up custom PHP (and modules) settings.
plog "Configuring PHP…"
sed -i "s|;session.save_path|session.save_path|" $CONFIGURATION_PHP
sed -i "s|short_open_tag = Off|short_open_tag = On|" $CONFIGURATION_PHP
sed -i "s|memory_limit = 128M|memory_limit = 1024M|" $CONFIGURATION_PHP
sed -i "s|upload_max_filesize = 2M|upload_max_filesize = 128M|" $CONFIGURATION_PHP
sed -i "s|post_max_size = 8M|post_max_size = 128M|" $CONFIGURATION_PHP

# Configure XDebug.
plog "Configuring XDebug…"
cat >> /etc/php/7.2/mods-available/xdebug.ini <<EOL
xdebug.remote_enable = 1
xdebug.remote_connect_back = 1
xdebug.remote_port = 9000
xdebug.max_nesting_level = 1024
EOL

# Restart PHP-FPM for the changes to take place.
plog "Restarting PHP-FPM…"
systemctl restart php7.2-fpm.service

# Node.js & npm.
plog "Installing Node.js & npm…"
curl -s https://deb.nodesource.com/setup_8.x -o $DIR_TEMP/nodejs_setup.sh
$(which bash) $DIR_TEMP/nodejs_setup.sh
apt-get install -y nodejs
plog "Installing npm packages…"
npm install -g cross-env

# @todo Mailhog.
# sed -i "s|;sendmail_path =|sendmail_path = /usr/local/bin/mailhog sendmail noreply@example.com|" $CONFIGURATION_PHP
# @todo Elasticsearch
# Set up Elasticsearch.
# echo "Setting up (binary, manual startup required) Elasticsearch 1.0.0 and 1.7.6…"
# cd $DIR_PROVISION/elasticsearch
# unzip elasticsearch-binary.zip
# mv Elasticsearch-1-0-0 Elasticsearch-1-7-6 $DIR_HOME
# @todo Imagick.

# Install and set up MySQL.
plog "Installing MySQL 5.7…"
export DEBIAN_FRONTEND=noninteractive
echo "mysql-server-5.7 mysql-server/root_password password $MYSQL_PASSWORD_ROOT" | debconf-set-selections
echo "mysql-server-5.7 mysql-server/root_password_again password $MYSQL_PASSWORD_ROOT" | debconf-set-selections
apt-get install -y mysql-server-5.7

# Allow remote connections to MySQL.
plog "Allowing remote connections to MySQL…"
sed -i "s|127.0.0.1|0.0.0.0|" $CONFIGURATION_MYSQL
$(which mysql) --user="root" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD_ROOT';"
$(which mysql) --user="root" --password="$MYSQL_PASSWORD_ROOT" -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;"

# Create a non-root "pimbox" MySQL user with administrator priviledges.
plog "Creating the 'pimbox' MySQL user…"
$(which mysql) --user="root" --password="$MYSQL_PASSWORD_ROOT" -e "CREATE USER 'pimbox'@'0.0.0.0' IDENTIFIED BY '$MYSQL_PASSWORD_ROOT';"
$(which mysql) --user="root" --password="$MYSQL_PASSWORD_ROOT" -e "CREATE USER 'pimbox'@'%' IDENTIFIED BY '$MYSQL_PASSWORD_ROOT';"
$(which mysql) --user="root" --password="$MYSQL_PASSWORD_ROOT" -e "GRANT ALL PRIVILEGES ON *.* TO 'pimbox'@'0.0.0.0' WITH GRANT OPTION;"
$(which mysql) --user="root" --password="$MYSQL_PASSWORD_ROOT" -e "GRANT ALL PRIVILEGES ON *.* TO 'pimbox'@'%' WITH GRANT OPTION;"
$(which mysql) --user="root" --password="$MYSQL_PASSWORD_ROOT" -e "FLUSH PRIVILEGES;"

# Set up the "deployment" login path.
plog "Running expect script to set up MySQL login paths…"
tee $DIR_TEMP/mysql_loginpaths.sh > /dev/null << EOF
spawn $(which mysql_config_editor) set --login-path=deployment --host=localhost --user=root --password

expect "Enter password:"
send "$MYSQL_PASSWORD_ROOT\r"
EOF

sudo -u vagrant -H expect $DIR_TEMP/mysql_loginpaths.sh

# Restart MySQL for the changes to take place.
plog "Restarting MySQL…"
systemctl restart mysql.service

# Finishing up.
plog "Done!"
