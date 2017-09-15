#!/bin/bash

# Pablo Almeida - 2017

# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
PREVIEW_INSTALL=1 . <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)
unset PREVIEW_INSTALL

# Verifica se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

# Baixa e instala Preview Generator
if [ ! -d "$NCPATH"/apps/previewgenerator ]
then
    echo "Instalando Preview Generator..."
    wget -q "$PREVER_REPO/v$PREVER/$PREVER_FILE" -P "$NCPATH/apps"
    tar -zxf "$NCPATH/apps/$PREVER_FILE" -C "$NCPATH/apps"
    cd "$NCPATH/apps"
    rm "$PREVER_FILE"
fi

# Habilitando Preview Generator
if [ -d "$NCPATH"/apps/previewgenerator ]
then
    sudo -u www-data php "$NCPATH"/occ app:enable previewgenerator
    chown -R www-data:www-data $NCPATH/apps
    crontab -u www-data -l | { cat; echo "@daily php -f $NCPATH/occ preview:pre-generate >> /var/log/previewgenerator.log"; } | crontab -u www-data -
    sudo -u www-data php "$NCPATH"/occ preview:generate-all
    touch /var/log/previewgenerator.log
    chown www-data:www-data /var/log/previewgenerator.log
fi
