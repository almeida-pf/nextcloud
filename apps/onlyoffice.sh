#!/bin/bash
# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
OO_INSTALL=1 . <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)
unset OO_INSTALL

# Pablo Almeida - 2017

# Verifica se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

# Verifica se e ROOT
if ! is_root
then
    printf "\n${Red}Desculpe, voce nao e root.\n${Color_Off}Voce deve digitar: ${Cyan}sudo ${Color_Off}bash $SCRIPTS/onlyoffice.sh\n"
    exit 1
fi

# Verifica O Tamanho da RAM (4GB min) + CPUs (min 2)
ram_check 4 OnlyOffice
cpu_check 2 OnlyOffice

# Verifica se Collabora esta em execucao
if [ -d "$NCPATH"/apps/richdocuments ]
then
    echo "Parece que o Collabora esta funcionando."
    echo "Voce nao pode executar Collabora ao mesmo tempo em que voce executa OnlyOffice."
    exit 1
fi

# Notificacao
whiptail --msgbox "Antes de comecar, verifique se a porta 443 esta encaminhada diretamente para esta maquina!" "$WT_HEIGHT" "$WT_WIDTH"

# Atualiza Repositorio
apt update -q4 & spinner_loading

# Verifica se o Nextcloud esta instalado
echo "Verificando se o Nextcloud esta instalado..."
if ! curl -s https://"${NCDOMAIN//\\/}"/status.php | grep -q 'installed":true'
then
    echo
    echo "Parece que Nextcloud nao esta instalado ou que voce nao usa https:"
    echo "${NCDOMAIN//\\/}."
    echo "Instale Nextcloud e certifique-se de que seu dominio esteja acessivel ou ative o SSL"
    echo "no seu dominio para poder executar este script."
    echo
    echo "Se voce usar o Nextcloud VM voce pode usar o Let's Encrypt script para obter SSL e ativar seu dominio Nextcloud."
    echo "Quando o SSL for ativado, execute esses comandos do seu terminal:"
    echo "sudo wget $APP/onlyoffice.sh"
    echo "sudo bash onlyoffice.sh"
    any_key "Pressione qualquer tecla para continuar... "
    exit 1
fi

# Verifica se o $SUBDOMAIN existe e esta acessivel
echo
echo "Verificando se o $SUBDOMAIN existe e esta acessivel..."
if wget -q -T 10 -t 2 --spider "$SUBDOMAIN"; then
   sleep 0.1
elif wget -q -T 10 -t 2 --spider --no-check-certificate "https://$SUBDOMAIN"; then
   sleep 0.1
elif curl -s -k -m 10 "$SUBDOMAIN"; then
   sleep 0.1
elif curl -s -k -m 10 "https://$SUBDOMAIN" -o /dev/null; then
   sleep 0.1
else
   echo "Nao, nao esta la. Voce precisa criar $SUBDOMAIN e apontar"
   echo "para este servidor antes de poder executar este script."
   any_key "Pressione qualquer tecla para sair... "
   exit 1
fi

# Verifica se o usuario ja possui o nmap instalado em seu sistema
if [ "$(dpkg-query -s nmap 2> /dev/null | grep -c "ok installed")" == "1" ]
then
    NMAPSTATUS=preinstalled
fi

apt update -q4 & spinner_loading
if [ "$NMAPSTATUS" = "preinstalled" ]
then
      echo "Nmap ja esta instalado..."
else
    apt install nmap -y
fi

# Verifica se a porta 443 esta aberta e usando nmap, se nao notificar o usuario
if [ "$(nmap -sS -p 443 "$WANIP4" | grep -c "open")" == "1" ]
then
  printf "${Green}Porta 443 esta aberta $WANIP4!${Color_Off}\n"
  if [ "$NMAPSTATUS" = "preinstalled" ]
  then
    echo "o nmap foi instalado anteriormente, removendo"
  else
    apt remove --purge nmap -y
  fi
else
  echo "Porta 443 nao esta aberta $WANIP4. Vamos fazer uma segunda tentativa em $SUBDOMAIN."
  any_key "Pressione qualquer tecla para testar $SUBDOMAIN... "
  if [[ "$(nmap -sS -PN -p 443 "$SUBDOMAIN" | grep -m 1 "Aberta" | awk '{print $2}')" = "Aberta" ]]
  then
      printf "${Green}Porta 443 esta aberta $SUBDOMAIN!${Color_Off}\n"
      if [ "$NMAPSTATUS" = "preinstalled" ]
      then
        echo "o nmap foi instalado anteriormente, removendo"
      else
        apt remove --purge nmap -y
      fi
  else
      whiptail --msgbox "Porta 443 nao esta aberta $SUBDOMAIN. Siga este guia para abrir portas em seu roteador: https://www.techandme.se/open-port-80-443/" "$WT_HEIGHT" "$WT_WIDTH"
      any_key "Pressione qualquer tecla para sair... "
      if [ "$NMAPSTATUS" = "preinstalled" ]
      then
        echo "o nmap foi instalado anteriormente, removendo"
      else
        apt remove --purge nmap -y
      fi
      exit 1
  fi
fi

# Instala Docker
if [ "$(dpkg-query -W -f='${Status}' docker-ce 2>/dev/null | grep -c "ok installed")" == "1" ]
then
    docker -v
else
    apt update -q4 & spinner_loading
    apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    apt-key fingerprint 0EBFCD88
    add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
    apt update
    apt install docker-ce -y
    docker -v
fi

# Carrega aufs
apt-get install linux-image-extra-"$(uname -r)" -y
# apt install aufs-tools -y # ja incluido no pacote docker-ce
AUFS=$(grep -r "aufs" /etc/modules)
if ! [ "$AUFS" = "aufs" ]
then
    echo "aufs" >> /etc/modules
fi

# Defina o driver de armazenamento docker para AUFS
AUFS2=$(grep -r "aufs" /etc/default/docker)
if ! [ "$AUFS2" = 'DOCKER_OPTS="--storage-driver=aufs"' ]
then
    echo 'DOCKER_OPTS="--storage-driver=aufs"' >> /etc/default/docker
    service docker restart
fi

# Verifica servico docker e mata
DOCKERPS=$(docker ps -a -q)
if [ "$DOCKERPS" != "" ]
then
    echo "Removendo versao antiga Docker... ($DOCKERPS)"
    any_key "Pressione qualquer tecla para continuar. Press CTRL+C para cancelar"
    docker stop "$DOCKERPS"
    docker rm "$DOCKERPS"
fi

# Desabilita Onlyoffice se tiver ativado
if [ -d "$NCPATH"/apps/onlyoffice ]
then
    sudo -u www-data php "$NCPATH"/occ app:disable onlyoffice
    rm -r "$NCPATH"/apps/onlyoffice
fi

# Instala Onlyoffice docker
docker pull onlyoffice/documentserver:latest
docker run -i -t -d -p 127.0.0.3:9090:80 -p 127.0.0.3:9091:443 --restart always onlyoffice/documentserver

# Instala apache2 
install_if_not apache2

# Habilita Apache2 module's
a2enmod proxy
a2enmod proxy_wstunnel
a2enmod proxy_http
a2enmod ssl

# Cria Vhost para OnlyOffice online no Apache2
if [ ! -f "$HTTPS_CONF" ];
then
    cat << HTTPS_CREATE > "$HTTPS_CONF"
<VirtualHost *:443>
     ServerName $SUBDOMAIN:443

    SSLEngine on
    ServerSignature On
    SSLHonorCipherOrder on

    SSLCertificateChainFile $CERTFILES/$SUBDOMAIN/chain.pem
    SSLCertificateFile $CERTFILES/$SUBDOMAIN/cert.pem
    SSLCertificateKeyFile $CERTFILES/$SUBDOMAIN/privkey.pem
    SSLOpenSSLConfCmd DHParameters $DHPARAMS
    
    SSLProtocol             all -SSLv2 -SSLv3
    SSLCipherSuite ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS

    LogLevel warn
    CustomLog ${APACHE_LOG_DIR}/access.log combined
    ErrorLog ${APACHE_LOG_DIR}/error.log

    # Apenas no caso
    SSLProxyEngine On
    SSLProxyVerify None
    SSLProxyCheckPeerCN Off
    SSLProxyCheckPeerName Off

    # avisos de contra mistura de conteudo
    RequestHeader set X-Forwarded-Proto "https"

    # configuracoes basicas de proxy
    ProxyRequests off

    ProxyPassMatch (.*)(\/websocket)$ "ws://127.0.0.3:9091/$1$2"
    ProxyPass / "http://127.0.0.3:9090/"
    ProxyPassReverse / "http://127.0.0.3:9090/"
        
    <Location />
        ProxyPassReverse /
    </Location>
</VirtualHost>
HTTPS_CREATE

    if [ -f "$HTTPS_CONF" ];
    then
        echo "$HTTPS_CONF foi criado com sucesso"
        sleep 1
    else
        echo "Nao foi possivel criar vhost, sair..."
        echo "Por favor, relate este problema aqui $ISSUES"
        exit 1
    fi
fi

# Instala certbot (Let's Encrypt)
install_certbot

# Gera certs
if le_subdomain
then
    # Gera DHparams chifer
    if [ ! -f "$DHPARAMS" ]
    then
        openssl dhparam -dsaparam -out "$DHPARAMS" 8192
    fi
    printf "${ICyan}\n"
    printf "Certs are generated!\n"
    printf "${Color_Off}\n"
    a2ensite "$SUBDOMAIN.conf"
    service apache2 restart
# Instala Onlyoffice App
    cd $NCPATH/apps
    check_command git clone https://github.com/ONLYOFFICE/onlyoffice-owncloud.git onlyoffice
else
    printf "${ICyan}\nParece que nenhum certificado foi gerado, por favor relate este problema aqui: $ISSUES\n"
    any_key "Pressione qualquer tecla para continuar... "
    service apache2 restart
fi

# Habilita Onlyoffice
if [ -d "$NCPATH"/apps/onlyoffice ]
then
# Habilita OnlyOffice
    check_command sudo -u www-data php "$NCPATH"/occ app:enable onlyoffice
    check_command sudo -u www-data php "$NCPATH"/occ config:app:set onlyoffice DocumentServerUrl --value="https://$SUBDOMAIN/"
    chown -R www-data:www-data $NCPATH/apps
    check_command sudo -u www-data php "$NCPATH"/occ config:system:set trusted_domains 3 --value="$SUBDOMAIN"
# Adiciona comando prune
    {
    echo "#!/bin/bash"
    echo "docker system prune -a --force"
    echo "exit"
    } > "$SCRIPTS/dockerprune.sh"
    chmod a+x "$SCRIPTS/dockerprune.sh"
    crontab -u root -l | { cat; echo "@weekly $SCRIPTS/dockerprune.sh"; } | crontab -u root -
    echo "Adicionado servico Docker automatico."
    echo
    echo "OnlyOffice agora esta instalado com sucesso."
    echo "Talvez voce precise reiniciar antes que o Docker seja carregado corretamente."
    any_key "Pressiobe qualquer tecla para continuar... "
fi
