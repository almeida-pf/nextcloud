#!/bin/bash

# Pablo Almeida - 2017

# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
CONTACTS_INSTALL=1 . <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)
unset CONTACTS_INSTALL

# Verifica se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

# Baixa e instala Contatos
if [ ! -d "$NCPATH/apps/contacts" ]
then
    echo "Instalando Contatos..."
    wget -q "$CONVER_REPO/v$CONVER/$CONVER_FILE" -P "$NCPATH/apps"
    tar -zxf "$NCPATH/apps/$CONVER_FILE" -C "$NCPATH/apps"
    cd "$NCPATH/apps"
    rm "$CONVER_FILE"
fi

# Habilitando Contatos
if [ -d "$NCPATH"/apps/contacts ]
then
    sudo -u www-data php "$NCPATH"/occ app:enable contacts
    chown -R www-data:www-data $NCPATH/apps
fi
