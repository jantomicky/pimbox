#!/bin/bash

# https://www.lullabot.com/articles/installing-mailhog-for-ubuntu-1604

CONFIG_PHP_FPM="/etc/php/*/fpm/php.ini"
CONFIG_PHP_CLI="/etc/php/*/cli/php.ini"

# Install Sendmail & Go.
apt-get update -y
apt-get install -y sendmail golang-go

# Set up Sendmail certificates.
cd /etc/mail/tls
openssl dsaparam -out sendmail-common.prm 2048
chown root:smmsp sendmail-common.prm
chmod 0640 sendmail-common.prm
dpkg --configure -a

# Install MailHog.
# @todo Run this as the regular "vagrant" user!
mkdir gocode
echo "export GOPATH=$HOME/gocode" >> ~/.profile
source ~/.profile
go get github.com/mailhog/MailHog
go get github.com/mailhog/mhsendmail
sudo cp /home/vagrant/gocode/bin/MailHog /usr/local/bin/mailhog
sudo cp /home/vagrant/gocode/bin/mhsendmail /usr/local/bin/mhsendmail
rm -rf ./gocode

# Change PHP configuration.
echo "Changing the PHP 'sendmail_path' configuration…"
sed -i "s|;sendmail_path = |sendmail_path = /usr/local/bin/mhsendmail|" $CONFIG_PHP_FPM $CONFIG_PHP_CLI

# Enable port 8025.
echo "Enabling port 8025…"
ufw allow 8025

# Create a service.
echo "Creating a MailHog service…"
cat >> /lib/systemd/system/mailhog.service <<EOL
[Unit]
Description=MailHog service

[Service]
ExecStart=/usr/local/bin/mailhog -smtp-bind-addr 127.0.0.1:1025

[Install]
WantedBy=multi-user.target
EOL

# Enable the service.
echo "Enabling the MailHog service…"
systemctl start mailhog
systemctl enable mailhog
