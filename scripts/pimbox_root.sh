#!/bin/bash

echo "Setting up swap file…"
fallocate -l 4G /swapfile && chmod 600 /swapfile
mkswap /swapfile && swapon /swapfile
echo "/swapfile    none    swap    sw    0    0" >> /etc/fstab

echo "Setting server time zone to Europe/Prague…"
ln -sf /usr/share/zoneinfo/Europe/Prague /etc/localtime

echo "Setting up Vim as the default text editor…"
echo "3" | update-alternatives --config editor > /dev/null

echo "Adding ppa:ondrej/php…"
add-apt-repository -y ppa:ondrej/php
echo "Updating package lists…"
apt-get update -y

echo "Upgrading packages…"
apt-get upgrade -y

echo "Installing essential packages…"
apt-get install -y build-essential openjdk-8-jre-headless unzip redis-server redis-tools

echo "Installing Node.js & npm…"
curl -s https://deb.nodesource.com/setup_8.x -o /tmp/nodejs_setup.sh
$(which bash) /tmp/nodejs_setup.sh
apt-get install -y nodejs
echo "Installing npm packages…"
npm install -g cross-env
echo "Downgrading npm to version 5.6.0 to prevent npm install errors…"
npm install -g npm@5.6.0

echo "Pimbox root provisioning finished."
