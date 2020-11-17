#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

MYSQL_PASSWORD_ROOT='secret'
MYSQL_CONFIGURATION_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"

echo "Installing MySQL 5.7…"
echo "mysql-server-5.7 mysql-server/root_password password $MYSQL_PASSWORD_ROOT" | debconf-set-selections
echo "mysql-server-5.7 mysql-server/root_password_again password $MYSQL_PASSWORD_ROOT" | debconf-set-selections

apt-get install -y mysql-server-5.7

echo "Allowing remote connections to MySQL…"
sed -i "s|127.0.0.1|0.0.0.0|" $MYSQL_CONFIGURATION_FILE

echo "Creating the 'pimbox' MySQL user…"
$(which mysql) --user="root" --password="$MYSQL_PASSWORD_ROOT" -e "CREATE USER 'pimbox'@'0.0.0.0' IDENTIFIED BY '$MYSQL_PASSWORD_ROOT';"
$(which mysql) --user="root" --password="$MYSQL_PASSWORD_ROOT" -e "CREATE USER 'pimbox'@'%' IDENTIFIED BY '$MYSQL_PASSWORD_ROOT';"
$(which mysql) --user="root" --password="$MYSQL_PASSWORD_ROOT" -e "GRANT ALL PRIVILEGES ON *.* TO 'pimbox'@'0.0.0.0' WITH GRANT OPTION;"
$(which mysql) --user="root" --password="$MYSQL_PASSWORD_ROOT" -e "GRANT ALL PRIVILEGES ON *.* TO 'pimbox'@'%' WITH GRANT OPTION;"
$(which mysql) --user="root" --password="$MYSQL_PASSWORD_ROOT" -e "FLUSH PRIVILEGES;"

echo "Restarting MySQL…"
systemctl restart mysql.service

echo "MySQL 5.7 installed."
