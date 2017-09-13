#!/bin/bash
# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
COLLABORA_INSTALL=1 . <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)
unset COLLABORA_INSTALL

# Pablo Almeida - 2017

# Verifica se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

# Verifica se e ROOT
if ! is_root
then
    printf "\n${Red}Desculpe, Voce nao e ROOT.\n${Color_Off}Voce deve digitar: ${Cyan}sudo ${Color_Off}bash $SCRIPTS/collabora.sh\n"
    exit 1
fi

# Verifica tamanho da RAM (2GB min) + CPUs (min 2)
ram_check 2 Collabora
cpu_check 2 Collabora

# Verifica se Onlyoffice esta executando
if [ -d "$NCPATH"/apps/onlyoffice ]
then
    echo "Parece que OnlyOffice esta executando."
    echo "Voce nao pode executar OnlyOffice ao mesmo tempo que voce executar Collabora."
    exit 1
fi

# Notificacao
whiptail --msgbox "Antes de comecar, verifique se a porta 443 e encaminhada diretamente para esta maquina!" "$WT_HEIGHT" "$WT_WIDTH"

# Atualiza Repositorio
apt update -q4 & spinner_loading

# Verifica se o Nextcloud esta instalado
echo "verificando se o Nextcloud esta instalado..."
if ! curl -s https://"${NCDOMAIN//\\/}"/status.php | grep -q 'installed":true'
then
    echo
    echo "Parece que Nextcloud nao esta instalado, ou https esteja habilitado:"
    echo "${NCDOMAIN//\\/}."
    echo "Instale Nextcloud e certifique-se de que seu dominio esteja acessivel ou ative o SSL"
    echo "no seu dominio para poder executar este script."
    echo
    echo "Se voce usa a VM Nextcloud, voce pode usar o script Let's Encrypt para obter SSL e ativar o seu dominio Nextcloud."
    echo "Quando o SSL for ativado, execute esses comandos do seu terminal:"
    echo "sudo wget $APP/collabora.sh"
    echo "sudo bash collabora.sh"
    any_key "Pressione qualquer tecla para continuar... "
    exit 1
fi

# Verifica se $SUBDOMAIN existe e esta acessivel
echo
echo "Verificando se $SUBDOMAIN existe e esta acessivel..."
if wget -q -T 10 -t 2 --spider "$SUBDOMAIN"; then
   sleep 0.1
elif wget -q -T 10 -t 2 --spider --no-check-certificate "https://$SUBDOMAIN"; then
   sleep 0.1
elif curl -s -k -m 10 "$SUBDOMAIN"; then
   sleep 0.1
elif curl -s -k -m 10 "https://$SUBDOMAIN" -o /dev/null; then
   sleep 0.1
else
   echo "Nao, nao esta acessivel ou nao existe. Voce precisa criar $SUBDOMAIN e apontar"
   echo "para este servidor antes de poder executar este script."
   any_key "Pressione qualquer tecla para continuar... "
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
      echo "O nmap ja esta instalado..."
else
    apt install nmap -y
fi

# Verifica se 443 esta aberta usando nmap, se nao notifica o usuario
if [ "$(nmap -sS -p 443 "$WANIP4" | grep -c "open")" == "1" ]
then
  printf "${Green}A porta 443 esta aberta em $WANIP4!${Color_Off}\n"
  if [ "$NMAPSTATUS" = "preinstalled" ]
  then
    echo "O nmap foi instalado anteriormente, removendo"
  else
    apt remove --purge nmap -y
  fi
else
  echo "Porta 443 esta aberta em $WANIP4. Vamos fazer uma segunda tentativa em $SUBDOMAIN em vez disso."
  any_key "Pressione qualquer tecla para testar $SUBDOMAIN... "
  if [[ "$(nmap -sS -PN -p 443 "$SUBDOMAIN" | grep -m 1 "open" | awk '{print $2}')" = "open" ]]
  then
      printf "${Green}Porta 443 esta aberta em $SUBDOMAIN!${Color_Off}\n"
      if [ "$NMAPSTATUS" = "preinstalled" ]
      then
        echo "O nmap foi instalado anteriormente, removendo"
      else
        apt remove --purge nmap -y
      fi
  else
      whiptail --msgbox "Porta 443 nao esta aberta em $SUBDOMAIN. Siga este guia para abrir portas em seu roteador: https://www.techandme.se/open-port-80-443/" "$WT_HEIGHT" "$WT_WIDTH"
      any_key "Aperte qualquer tecla para sair... "
      if [ "$NMAPSTATUS" = "preinstalled" ]
      then
        echo "o nmap foi instalado anteriormente, removendo"
      else
        apt remove --purge nmap -y
      fi
      exit 1
  fi
fi

# Instalando Docker
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

# Define o driver de armazenamento docker para AUFS
AUFS2=$(grep -r "aufs" /etc/default/docker)
if ! [ "$AUFS2" = 'DOCKER_OPTS="--storage-driver=aufs"' ]
then
    echo 'DOCKER_OPTS="--storage-driver=aufs"' >> /etc/default/docker
    service docker restart
fi

# Verifica processos do Docker e mata
DOCKERPS=$(docker ps -a -q)
if [ "$DOCKERPS" != "" ]
then
    echo "Removendo instancias Docker antiga(s)... ($DOCKERPS)"
    any_key "Pressione qualquer tecla para continuar. ou CTRL+C para Cancelar"
    docker stop "$DOCKERPS"
    docker rm "$DOCKERPS"
fi

# Desativa RichDocuments (Collabora App) se estiver ativado
if [ -d "$NCPATH"/apps/richdocuments ]
then
    sudo -u www-data php "$NCPATH"/occ app:disable richdocuments
    rm -r "$NCPATH"/apps/richdocuments
fi

# Instala Collabora Docker
docker pull collabora/code:latest
docker run -t -d -p 127.0.0.1:9980:9980 -e "domain=$NCDOMAIN" --restart always --cap-add MKNOD collabora/code

# Instala Apache2
install_if_not apache2

# Habilita Apache2 module's
a2enmod proxy
a2enmod proxy_wstunnel
a2enmod proxy_http
a2enmod ssl

# Cria o Vhost para Collabora online no Apache2
if [ ! -f "$HTTPS_CONF" ];
then
    cat << HTTPS_CREATE > "$HTTPS_CONF"
<VirtualHost *:443>
  ServerName $SUBDOMAIN:443
  
  <Directory /var/www>
  Options -Indexes
  </Directory>

  # Configuracao do SSL, voce pode seguir o caminho mais facil e usar Letsencrypt!
  SSLEngine on
  SSLCertificateChainFile $CERTFILES/$SUBDOMAIN/chain.pem
  SSLCertificateFile $CERTFILES/$SUBDOMAIN/cert.pem
  SSLCertificateKeyFile $CERTFILES/$SUBDOMAIN/privkey.pem
  SSLOpenSSLConfCmd DHParameters $DHPARAMS
  SSLProtocol             all -SSLv2 -SSLv3
  SSLCipherSuite ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS
  SSLHonorCipherOrder     on
  SSLCompression off

  # Codico slashes precisa ser permitido
  AllowEncodedSlashes NoDecode

  # Container usa um certificado exclusivo nao assinado
  SSLProxyEngine On
  SSLProxyVerify None
  SSLProxyCheckPeerCN Off
  SSLProxyCheckPeerName Off

  # Manter o host
  ProxyPreserveHost On

  # Html, Js, Imagens, etc. Estatico
  # Parte do cliente do LibreOffice Online
  ProxyPass           /loleaflet https://127.0.0.1:9980/loleaflet retry=0
  ProxyPassReverse    /loleaflet https://127.0.0.1:9980/loleaflet

  # URL de descoberta WOPI
  ProxyPass           /hosting/discovery https://127.0.0.1:9980/hosting/discovery retry=0
  ProxyPassReverse    /hosting/discovery https://127.0.0.1:9980/hosting/discovery

  # Principal websocket
  ProxyPassMatch "/lool/(.*)/ws$" wss://127.0.0.1:9980/lool/\$1/ws nocanon

  # Admin Console websocket
  ProxyPass   /lool/adminws wss://127.0.0.1:9980/lool/adminws

  # Baixe como, apresentacao em tela cheia e operacoes de upload de imagens
  ProxyPass           /lool https://127.0.0.1:9980/lool
  ProxyPassReverse    /lool https://127.0.0.1:9980/lool
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
    printf "Certs sao gerados!\n"
    printf "${Color_Off}\n"
    a2ensite "$SUBDOMAIN.conf"
    service apache2 restart
# Instala Collabora App
    check_command wget -q "$COLLVER_REPO/$COLLVER/$COLLVER_FILE" -P "$NCPATH/apps"
    check_command tar -zxf "$NCPATH/apps/$COLLVER_FILE" -C "$NCPATH/apps"
    cd "$NCPATH/apps" || exit 1
    rm "$COLLVER_FILE"
else
    printf "${ICyan}\nParece que nenhum certificado foi gerado, por favor relate este problema aqui: $ISSUES\n"
    any_key "Press any key to continue... "
    service apache2 restart
fi

# Habilita RichDocuments (Collabora App)
if [ -d "$NCPATH"/apps/richdocuments ]
then
# Habilita Collabora
    check_command sudo -u www-data php "$NCPATH"/occ app:enable richdocuments
    check_command sudo -u www-data "$NCPATH"/occ config:app:set richdocuments wopi_url --value="https://$SUBDOMAIN"
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
    echo "Adicionou servico automatico Docker Prune."
    echo
    echo "Collabora agora esta instalado com sucesso."
    echo "Talvez voce precise reiniciar antes que o Docker seja carregado corretamente."
    any_key "pressione qualquer tecla para continuar... "
fi
