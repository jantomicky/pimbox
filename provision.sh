#!/bin/bash

# Set variables.
FILE_PROVISIONED="/usr/local/provisioned"
FILE_VHOSTS="/tmp/vhosts"
DIR_MOUNT="/vagrant"
DIR_HOME="/home/vagrant"
DIR_TEMP="$DIR_HOME/temp"
DIR_PROVISION="$DIR_TEMP/provision"
CONFIGURATION_PHP="/etc/php/7.2/cli/php.ini /etc/php/7.2/fpm/php.ini"
PASSWORD_MYSQL_ROOT='secret'

# Check the provisioning status.
if [ -f $FILE_PROVISIONED ]; then
	echo "Custom provisioning & configuration already done, skipping…"
	exit 0
fi

# Set up swap.
echo "Setting up swap file…"
fallocate -l 4G /swapfile && chmod 600 /swapfile
mkswap /swapfile && swapon /swapfile
echo "/swapfile    none    swap    sw    0    0" >> /etc/fstab

# Set various server settings.
echo "Setting server time zone to Europe/Prague…"
ln -sf /usr/share/zoneinfo/Europe/Prague /etc/localtime
echo "Setting up Vim as the default text editor…"
echo "3" | update-alternatives --config editor > /dev/null

# Add PPAs and update package lists.
echo "Adding ppa:ondrej/php…"
add-apt-repository -y ppa:ondrej/php
echo "Updating package lists…"
apt-get update -y

# Install essential packages.
echo "Installing essential packages…"
apt-get install -y expect unzip openjdk-8-jre-headless

# Set up Apache.
echo "Installing Apache (with FastCGI module)…"
apt-get install -y apache2 libapache2-mod-fastcgi
echo "Setting up the /var/www document root via a symbolic link…"
if ! [ -L /var/www ]; then
	rm -rf /var/www
	ln -fs $DIR_MOUNT /var/www
fi

# Make sure all the required Apache modules are enabled.
echo "Enabling Apache modules…"
a2enmod actions alias vhost_alias rewrite fastcgi proxy_fcgi

# Set up Apache Virtual Hosts if available.
if [ -f $FILE_VHOSTS ]; then
	echo "Setting up Apache Dynamic Virtual Hosts…"
	cp $FILE_VHOSTS /etc/apache2/sites-available/000-default.conf
fi

# Add 'vagrant' user to the 'www-data' group.
echo "Adding 'vagrant' user to the 'www-data' group…"
adduser vagrant www-data

# Add 'www-data' user to the 'vagrant' group.
echo "Adding 'www-data' user to the 'vagrant' group…"
adduser www-data vagrant

# Restart Apache for the changes to take place.
echo "Restarting Apache…"
systemctl restart apache2.service

# Install the latest PHP 7.2 version.
echo "Installing PHP 7.2…"
apt-get install -y php7.2 php7.2-fpm

# Install the required PHP modules.
echo "Installing PHP modules…"
apt-get install -y php7.2-mysql php7.2-xml php7.2-curl php7.2-gd php7.2-bz2 php7.2-mbstring php7.2-zip php7.2-intl php7.2-dev

# Install PEAR.
echo "Installing PEAR…"
apt-get install -y php-pear

# Install Composer.
echo "Installing Composer…"
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
curl -LO https://deployer.org/deployer.phar
mv deployer.phar /usr/local/bin/dep && chmod +x /usr/local/bin/dep
sudo ln -s /usr/local/bin/dep /usr/local/bin/deployer

# @todo Set up Elasticsearch.
# Set up Elasticsearch.
# echo "Setting up (binary, manual startup required) Elasticsearch 1.0.0 and 1.7.6…"
# cd $DIR_PROVISION/elasticsearch
# unzip elasticsearch-binary.zip
# mv Elasticsearch-1-0-0 Elasticsearch-1-7-6 $DIR_HOME

# @todo Install and set up Node.js & npm.
# Set up Node.js and NPM 5.6 (newer versions fail to 'npm install' with NFS).
# echo "Installing Node.js & npm…"
# apt install -y nodejs npm
# echo "Downgrading npm to version 5.6…"
# npm install -g npm@5.6
# echo "Installing npm dependencies…"
# npm install -g cross-env

# Set up custom PHP (and modules) settings.
echo "Setting up custom PHP settings…"
sed -i "s|;session.save_path|session.save_path|" $CONFIGURATION_PHP
sed -i "s|short_open_tag = Off|short_open_tag = On|" $CONFIGURATION_PHP
sed -i "s|memory_limit = 128M|memory_limit = 1024M|" $CONFIGURATION_PHP
sed -i "s|upload_max_filesize = 2M|upload_max_filesize = 128M|" $CONFIGURATION_PHP
sed -i "s|post_max_size = 8M|post_max_size = 128M|" $CONFIGURATION_PHP

# @todo Install and set up Mailhog.
# sed -i "s|;sendmail_path =|sendmail_path = /usr/local/bin/mailhog sendmail noreply@example.com|" $CONFIGURATION_PHP

# @todo Install and set up XDebug.
# echo "Customizing XDebug…"
# sed -i "s|xdebug.max_nesting_level = 512|xdebug.max_nesting_level = 1024|" /etc/php/*/mods-available/xdebug.ini

# @todo Install Imagick.
# @todo Install Redis.

# Install and set up MySQL.
echo "Installing MySQL 5.7…"
export DEBIAN_FRONTEND=noninteractive
echo "mysql-server-5.7 mysql-server/root_password password $PASSWORD_MYSQL_ROOT" | debconf-set-selections
echo "mysql-server-5.7 mysql-server/root_password_again password $PASSWORD_MYSQL_ROOT" | debconf-set-selections
apt-get install -y mysql-server-5.7

# Build Expect script to set up MySQL defaults.
echo "Building Expect script to set up MySQL defaults…"
tee ~/mysql.sh > /dev/null << EOF
spawn $(which mysql_secure_installation)

expect "Enter password for user root:"
send "$PASSWORD_MYSQL_ROOT\r"

expect "Press y|Y for Yes, any other key for No:"
send "y\r"

expect "Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:"
send "2\r"

expect "Change the password for root ? ((Press y|Y for Yes, any other key for No) :"
send "n\r"

expect "Remove anonymous users? (Press y|Y for Yes, any other key for No) :"
send "y\r"

expect "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :"
send "y\r"

expect "Remove test database and access to it? (Press y|Y for Yes, any other key for No) :"
send "y\r"

expect "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :"
send "y\r"

EOF

expect ~/mysql.sh
rm -v ~/mysql.sh
apt-get -qq purge expect > /dev/null

# Custom MySQL settings.
echo "Customizing MySQL settings…"
echo "Setting up 'deployment' login-path…"
echo "secret" | mysql_config_editor set --login-path=deployment --host=localhost --user=root --password

# Clean up temporary files.
echo "Removing the temporary directory…"
rm -rf $DIR_TEMP

# Remember the provisioning.
echo "Writing the provisioning file…"
touch $FILE_PROVISIONED
