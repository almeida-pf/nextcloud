#!/bin/bash
# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
PASSMAN_INSTALL=1 . <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)
unset PASSMAN_INSTALL

# Pablo Almeida - 2017

# Verifica se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

# Verfica se e ROOT
if ! is_root
then
    printf "\n${Red}Desculpe, voce nao e root.\n${Color_Off}Voce deve digitar: ${Cyan}sudo ${Color_Off}bash $SCRIPTS/passman.sh\n"
    exit 1
fi

# Verifica se o arquivo esta disponivel para download
echo "Verificando a versao mais recente no servidor de download do Passman e se for possivel baixa..."
if wget -q -T 10 -t 2 "$PASSVER_REPO/$PASSVER_FILE" -O /dev/null
then
   echo "A ultima versao e: $PASSVER"
else
    echo "Falha! O download nao esta disponivel no momento, tente novamente mais tarde."
    echo "Por favor, relate este problema aqui: $ISSUES"
    any_key "Pressione qualquer tecla para continuar..."
    exit 1
fi

# Verifica checksum
mkdir -p $SHA256
wget -q "$PASSVER_REPO/$PASSVER_FILE" -P "$SHA256"
wget -q "$PASSVER_REPO/$PASSVER_FILE.sha256" -P "$SHA256"
echo "Verificando integridade de $PASSVER_FILE..."
cd "$SHA256" || exit 1
CHECKSUM_STATE=$(echo -n "$(sha256sum -c "$PASSVER_FILE.sha256")" | tail -c 2)
if [ "$CHECKSUM_STATE" != "OK" ]
then
    echo "Atencao! Checksum nao corresponde!"
    rm $SHA256 -R
    exit 1
else
    echo "SUCESSO! Checksum esta OK!"
    rm $SHA256 -R
fi

# Baixa e instala Passman
if [ ! -d $NCPATH/apps/passman ]
then
    wget -q "$PASSVER_REPO/$PASSVER_FILE" -P "$NCPATH/apps"
    tar -zxf "$NCPATH/apps/$PASSVER_FILE" -C "$NCPATH/apps"
    cd "$NCPATH/apps" || exit 1
    rm "$PASSVER_FILE"
fi

# Habilita Passman
if [ -d $NCPATH/apps/passman ]
then
    check_command sudo -u www-data php $NCPATH/occ app:enable passman
    chown -R www-data:www-data $NCPATH/apps
    sleep 2
fi
