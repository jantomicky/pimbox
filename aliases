alias mkd='mkdir -pv'
alias lst='ls -lAh'

function pimcore_set_rights() {
    sudo chown -R vagrant:vagrant .
    sudo find . -type d -exec chmod 775 {} \;
    sudo find . -type f -exec chmod 664 {} \;
}

function pimcore_clear_cache() {
    php bin/console cache:clear
    php bin/console pimcore:cache:clear
}
