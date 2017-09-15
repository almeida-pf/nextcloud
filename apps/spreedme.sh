#!/bin/bash

# Pablo Almeida - 2017

# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
. <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)

# Verifica se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

# Verifica se e root
if ! is_root
then
    printf "\n${Red}Desculpe, voce nao e root.\n${Color_Off}Voce deve digitar: ${Cyan}sudo ${Color_Off}bash %s/nextcloud_install_production.sh\n" "$SCRIPTS"
    exit 1
fi

# Verifica se Nextcloud existe
if [ ! -d "$NCPATH" ]
then
    echo "Nextcloud nao parece estar instalado. Este script ira sair..."
    exit
fi

# Verifica se apache esta instalado
install_if_not apache2

# Instala Nextcloud Spreedme Snap
if [ -d "$SNAPDIR" ]
then
    echo "SpreeMe Snap ja parece estar instalado e agora sera reinstalado..."
    snap remove spreedme
    rm -rf "$SNAPDIR"
    snap install spreedme
else
    snap install spreedme
fi

# Instala e ativa o SpreedMe app
if [ -d "$NCPATH/apps/spreedme" ]
then
    # Remove
    sudo -u www-data php "$NCPATH/occ" app:disable spreedme
    echo "SpreedMe app ja parece estar instalado e agora sera reinstalado..."
    rm -R "$NCPATH/apps/spreedme"
    # Reinstala
    wget -q "$SPREEDME_REPO/$SPREEDME_FILE" -P "$NCPATH/apps"
    tar -zxf "$NCPATH/apps/$SPREEDME_FILE" -C "$NCPATH/apps"
    cd "$NCPATH/apps"
    rm "$SPREEDME_FILE"
    mv "nextcloud-spreedme-$SPREEDME_VER" spreedme
else
    wget -q "$SPREEDME_REPO/$SPREEDME_FILE" -P "$NCPATH/apps"
    tar -zxf "$NCPATH/apps/$SPREEDME_FILE" -C "$NCPATH/apps"
    cd "$NCPATH/apps"
    rm "$SPREEDME_FILE"
    mv "nextcloud-spreedme-$SPREEDME_VER" spreedme
fi
check_command sudo -u www-data php "$NCPATH/occ" app:enable spreedme
chown -R www-data:www-data $NCPATH/apps

# Gera chaves secretas
SHAREDSECRET=$(openssl rand -hex 32)
TEMPLINK=$(openssl rand -hex 32)
sed -i "s|sharedsecret_secret = .*|sharedsecret_secret = $SHAREDSECRET|g" "$SNAPDIR/current/server.conf"

# Preenche o arquivo de configuracao vazio do outro (usa o banco de dados para o conteudo por padrao)
cp "$NCPATH/apps/spreedme/config/config.php.in" "$NCPATH/apps/spreedme/config/config.php"

# Coloca a chave na configuracao do app NC
sed -i "s|.*SPREED_WEBRTC_SHAREDSECRET.*|       const SPREED_WEBRTC_SHAREDSECRET = '$SHAREDSECRET';|g" "$NCPATH/apps/spreedme/config/config.php"

# Permite criar links temporarios
sed -i "s|const OWNCLOUD_TEMPORARY_PASSWORD_LOGIN_ENABLED.*|const OWNCLOUD_TEMPORARY_PASSWORD_LOGIN_ENABLED = true;|g" "$NCPATH/apps/spreedme/config/config.php"

#  Define links temporarios hash
sed -i "s|const OWNCLOUD_TEMPORARY_PASSWORD_SIGNING_KEY.*|const OWNCLOUD_TEMPORARY_PASSWORD_SIGNING_KEY = '$TEMPLINK';|g" "$NCPATH/apps/spreedme/config/config.php"


# Habilita Apache mods
a2enmod proxy \
        proxy_wstunnel \
        proxy_http \
        headers

# Add config para vhost
VHOST=/etc/apache2/spreedme.conf
if [ ! -f $VHOST ]
then
cat << VHOST > "$VHOST"
<Location /webrtc>
    ProxyPass http://127.0.0.1:8080/webrtc
    ProxyPassReverse /webrtc
</Location>

<Location /webrtc/ws>
    ProxyPass ws://127.0.0.1:8080/webrtc/ws
</Location>

    ProxyVia On
    ProxyPreserveHost On
    RequestHeader set X-Forwarded-Proto 'https' env=HTTPS
    # RequestHeader define X-Forwarded-Proto 'https' # Use isso se voce estiver atras de um (Nginx) proxy reverso com backends http
VHOST
fi

if ! grep -Fxq "Include $VHOST" /etc/apache2/apache2.conf
then
    sed -i "145i Include $VHOST" "/etc/apache2/apache2.conf"
fi

# Reinicia servico
service apache2 restart
if ! systemctl restart snap.spreedme.spreed-webrtc.service
then
    echo "Algo esta errado, a instalacao nao terminou corretamente"
    exit 1
else
    echo
    echo "Sucesso! SpreedMe agora esta instalado e configurado."
    echo "Voce pode ter que mudar SPREED_WEBRTC_ORIGIN em:"
    echo "(sudo nano) $NCPATH/apps/spreedme/config/config.php"
    echo
    exit 0
fi
any_key "Pressione qualquer tecla para continuar..."
clear
