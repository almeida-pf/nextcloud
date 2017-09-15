#!/bin/bash
# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
MYCNFPW=1 . <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)
unset MYCNFPW

# Pablo Almeida - 2017

# Verifica se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

# Carrega MARIADB Password
if mysqladmin -u root -p"$MARIADBMYCNFPASS" password "$NEWMARIADBPASS" > /dev/null 2>&1
then
    echo -e "${Green}Sua nova senha de root MARIADB e: $NEWMARIADBPASS${Color_Off}"
    cat << LOGIN > "$MYCNF"
[client]
password='$NEWMARIADBPASS'
LOGIN
    chmod 0600 $MYCNF
    exit 0
else
    echo "Mudando a senha de root MARIADB falhou."
    echo "Sua senha antiga e: $MARIADBMYCNFPASS"
    exit 1
fi
