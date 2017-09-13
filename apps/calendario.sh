#!/bin/bash

# Pablo Almeida - 2017

# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
CALENDAR_INSTALL=1 . <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)
unset CALENDAR_INSTALL

# Verifica se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

# Baixa e instala Calendario
if [ ! -d "$NCPATH"/apps/calendar ]
then
    echo "Instalando calendario..."
    wget -q "$CALVER_REPO/v$CALVER/$CALVER_FILE" -P "$NCPATH/apps"
    tar -zxf "$NCPATH/apps/$CALVER_FILE" -C "$NCPATH/apps"
    cd "$NCPATH/apps"
    rm "$CALVER_FILE"
fi

# Habilitando Calendario
if [ -d "$NCPATH"/apps/calendar ]
then
    sudo -u www-data php "$NCPATH"/occ app:enable calendar
    chown -R www-data:www-data $NCPATH/apps
fi
