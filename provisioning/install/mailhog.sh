#!/bin/bash

# https://www.lullabot.com/articles/installing-mailhog-for-ubuntu-1604

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

# @todo Change PHP configuration.
# sendmail_path = /usr/local/bin/mhsendmail

# Run MailHog.
# @todo UFW is blocking port 8025, allow or disable.
mailhog -api-bind-addr 192.168.20.10:8025 -ui-bind-addr 192.168.20.10:8085 -smtp-bind-addr 192.168.20.10:1025

# Create a service.

# /lib/systemd/system/mailhog.service

# [Unit]
# Description=MailHog service

# [Service]
# ExecStart=/usr/local/bin/mailhog -smtp-bind-addr 127.0.0.1:1025

# [Install]
# WantedBy=multi-user.target

# sudo systemctl start mailhog
# sudo systemctl enable mailhog

# @todo /etc/hosts
# 127.0.0.1       localhost.localdomain localhost pimbox
# 127.0.0.1       pimbox
