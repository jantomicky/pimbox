#!/bin/bash

FILE_VHOSTS="/tmp/vhosts"

echo "Installing Apache2 (with FastCGI module)…"
apt-get install -y apache2 libapache2-mod-fastcgi

echo "Enabling Apache2 modules…"
a2enmod actions alias vhost_alias rewrite fastcgi proxy_fcgi

# If available, set up Virtual Hosts.
if [ -f $FILE_VHOSTS ]; then
	echo "Setting up Virtual Hosts…"
	cp $FILE_VHOSTS /etc/apache2/sites-available/000-default.conf
fi

echo "Adding 'vagrant' user to the 'www-data' group…"
adduser vagrant www-data

echo "Adding 'www-data' user to the 'vagrant' group…"
adduser www-data vagrant

echo "Setting 'www-data' user umask (0002) to grant group write permissions…"
echo "umask 0002" >> /etc/apache2/envvars

echo "Restarting the apache2 service…"
systemctl restart apache2.service

echo "Apache2 installed."
