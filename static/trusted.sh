#!/bin/bash

# Pablo Almeida - 2017

# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
. <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)

# Verifique se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

download_static_script update-config
if [ -f $SCRIPTS/update-config.php ]
then
    # Muda config.php
    php $SCRIPTS/update-config.php $NCPATH/config/config.php 'trusted_domains[]' localhost "${ADDRESS[@]}" "$(hostname)" "$(hostname --fqdn)" >/dev/null 2>&1
    php $SCRIPTS/update-config.php $NCPATH/config/config.php overwrite.cli.url https://"$(hostname --fqdn)"/ >/dev/null 2>&1

    # Muda .htaccess adequadamente
    sed -i "s|RewriteBase /nextcloud|RewriteBase /|g" $NCPATH/.htaccess

    # Limpa
    rm -f $SCRIPTS/update-config.php
fi
