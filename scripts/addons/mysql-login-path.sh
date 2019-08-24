#!/bin/bash

LOGIN_PATH='deployment'
MYSQL_USER='pimbox'
MYSQL_PASSWORD='secret'
MYSQL_UP=$(pgrep mysql | wc -l);

if [ "$MYSQL_UP" -eq "0" ]; then
    echo "MySQL is not running, cannot set up login-paths."
    exit 0
fi

echo "Installing expect…"
apt-get install -y expect

# Set up a login path.
echo "Running expect script to set up MySQL login-paths…"
tee /tmp/mysql_loginpaths.sh > /dev/null << EOF
spawn $(which mysql_config_editor) set --login-path=$LOGIN_PATH --host=localhost --user=$MYSQL_USER --password

expect "Enter password:"
send "$MYSQL_PASSWORD\r"
EOF

sudo -u vagrant -H expect /tmp/mysql_loginpaths.sh

echo "Restarting MySQL…"
systemctl restart mysql.service

echo "Cleaning up…"
apt-get remove -y expect
