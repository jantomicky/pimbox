#!/bin/bash

if ! [ -x "$(command -v php)" ]; then
    echo "ERROR: PHP is missing, cannot install PHP tools."
    exit 0
fi

# Composer.
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

echo "Composer installed."

# Deployer.
echo "Installing Deployer…"
curl -sL https://deployer.org/deployer.phar -o /usr/local/bin/dep
chmod +x /usr/local/bin/dep
ln -s /usr/local/bin/dep /usr/local/bin/deployer

echo "Deployer installed."

# @todo phpDocumentator
# https://github.com/phpDocumentor/phpDocumentor/releases/download/v3.0.0/phpDocumentor.phar

# Imagick.
echo "Installing ImageMagick & PHP Imagick…"
apt install -y imagemagick php-imagick

echo "ImageMagick & PHP Imagick installed."

echo "Restarting apache2 and php-fpm services…"
systemctl restart apache2.service
systemctl restart php*
