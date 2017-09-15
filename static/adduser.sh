#!/bin/bash
# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
. <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)

# Pablo Almeida - 2017

# Verifica se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

if [[ "no" == $(ask_yes_or_no "Voce deseja criar um novo usuario??") ]]
then
    echo "Nao adicionando outro usuario..."
    sleep 1
else
    read -r -p "Digite o nome do novo usuario: " NEWUSER
    useradd -m "$NEWUSER" -G sudo
    while true
    do
        sudo passwd "$NEWUSER" && break
    done
    sudo -u "$NEWUSER" sudo bash nextcloud_install_production.sh
fi
