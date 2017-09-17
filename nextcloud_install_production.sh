#!/bin/bash

# Pablo Almeida - 2017

# Prefere IPv4
sed -i "s|#precedence ::ffff:0:0/96  100|precedence ::ffff:0:0/96  100|g" /etc/gai.conf

# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
FIRST_IFACE=1 && CHECK_CURRENT_REPO=1 . <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)
unset FIRST_IFACE
unset CHECK_CURRENT_REPO

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

# Verifica tamanho da RAM (2GB min) + CPUs (min 1)
ram_check 2 Nextcloud
cpu_check 1 Nextcloud

# Mostra usuario atual
echo
echo "Usuario atual com permissoes de sudo e: $UNIXUSER".
echo "Este script configurara tudo com este usuario."
echo "Se o campo apos ':' Esta em branco, voce provavelmente esta executando como um usuario root."
echo "E possivel instalar com root, mas havera erros menores."
echo
echo "Crie um usuario com permissoes sudo se desejar uma instalacao correta."
run_static_script adduser

# Verifica versao do ubuntu
echo "Verificando sistema e a versao do servidor..."
if [ "$OS" != 1 ]
then
    echo "Servidor Ubuntu e necessario para executar este script."
    echo "Instale a distro e tente novamente."
    exit 1
fi

if ! version 16.04 "$DISTRO" 16.04.4; then
    echo "Versao Ubuntu $DISTRO Deve estar entre 16.04 - 16.04.4"
    exit
fi

# Verifica se a chave esta disponivel
if ! wget -q -T 10 -t 2 "$NCREPO" > /dev/null
then
    echo "Nextcloud O repo nao esta disponivel, saindo..."
    exit 1
fi

# Verifica se e um servidor limpo
is_this_installed postgresql
is_this_installed apache2
is_this_installed php
is_this_installed mysql-common
is_this_installed mariadb-server

# Cria $SCRIPTS dir
if [ ! -d "$SCRIPTS" ]
then
    mkdir -p "$SCRIPTS"
fi

# Muda DNS
if ! [ -x "$(command -v resolvconf)" ]
then
    apt install resolvconf -y -q
    dpkg-reconfigure resolvconf
fi
echo "nameserver 8.8.8.8" > /etc/resolvconf/resolv.conf.d/base
echo "nameserver 8.8.4.4" >> /etc/resolvconf/resolv.conf.d/base

# Verifica Rede
if ! [ -x "$(command -v nslookup)" ]
then
    apt install dnsutils -y -q
fi
if ! [ -x "$(command -v ifup)" ]
then
    apt install ifupdown -y -q
fi
sudo ifdown "$IFACE" && sudo ifup "$IFACE"
if ! nslookup google.com
then
    echo "Rede NAO esta OK. Voce deve ter uma conexao de rede em funcionamento para executar este script."
    exit 1
fi

# Define locais
apt install language-pack-en-base -y
sudo locale-gen "sv_SE.UTF-8" && sudo dpkg-reconfigure --frontend=noninteractive locales

# Verifica onde estao os melhores repositorios e atualize
echo
printf "O seu repositorio de servidor atual e:  ${Cyan}%s${Color_Off}\n" "$REPO"
if [[ "no" == $(ask_yes_or_no "Voce quer tentar encontrar um repositorio melhor?") ]]
then
    echo "Guardando $REPO Como repositorio..."
    sleep 1
else
   echo "Localizando os melhores repositorios..."
   apt update -q4 & spinner_loading
   apt install python-pip -y
   pip install \
       --upgrade pip \
       apt-select
    apt-select -m up-to-date -t 5 -c
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup && \
    if [ -f sources.list ]
    then
        sudo mv sources.list /etc/apt/
    fi
fi
clear

# Define o layout do teclado
echo "O layout atual do teclado e $(localectl status | grep "Layout" | awk '{print $3}')"
if [[ "no" == $(ask_yes_or_no "Voce deseja alterar o layout do teclado??") ]]
then
    echo "Nao alterando o layout do teclado..."
    sleep 1
    clear
else
    dpkg-reconfigure keyboard-configuration
    clear
fi

# Atualiza Repositorio
apt update -q4 & spinner_loading

# Escreve MARIADB e senha para o arquivo e mantenha-o seguro
{
echo "[client]"
echo "password='$MARIADB_PASS'"
} > "$MYCNF"
chmod 0600 $MYCNF
chown root:root $MYCNF

# Instala MARIADB
apt install software-properties-common -y
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://ftp.ddg.lth.se/mariadb/repo/10.2/ubuntu xenial main'
sudo debconf-set-selections <<< "mariadb-server-10.2 mysql-server/root_password password $MARIADB_PASS"
sudo debconf-set-selections <<< "mariadb-server-10.2 mysql-server/root_password_again password $MARIADB_PASS"
apt update -q4 & spinner_loading
check_command apt install mariadb-server-10.2 -y

# Prepare-se para a instalacao Nextcloud
# https://blog.v-gar.de/2017/02/en-solved-error-1698-28000-in-mysqlmariadb/
mysql -u root mysql -p"$MARIADB_PASS" -e "UPDATE user SET plugin='' WHERE user='root';"
mysql -u root mysql -p"$MARIADB_PASS" -e "UPDATE user SET password=PASSWORD('$MARIADB_PASS') WHERE user='root';"
mysql -u root -p"$MARIADB_PASS" -e "flush privileges;"

# mysql_secure_installation
apt -y install expect
SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$MARIADB_PASS\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
echo "$SECURE_MYSQL"
apt -y purge expect

# Escreve um novo MariaDB config
run_static_script new_etc_mycnf

# Instala Apache
check_command apt install apache2 -y
a2enmod rewrite \
        headers \
        env \
        dir \
        mime \
        ssl \
        setenvif

# Instala PHP 7.0
apt update -q4 & spinner_loading
check_command apt install -y \
    libapache2-mod-php7.0 \
    php7.0-common \
    php7.0-mysql \
    php7.0-intl \
    php7.0-mcrypt \
    php7.0-ldap \
    php7.0-imap \
    php7.0-cli \
    php7.0-gd \
    php7.0-pgsql \
    php7.0-json \
    php7.0-sqlite3 \
    php7.0-curl \
    php7.0-xml \
    php7.0-zip \
    php7.0-mbstring \
    php-smbclient

# Habilita SMB client
# echo '# Isto Habilita php-smbclient' >> /etc/php/7.0/apache2/php.ini
# echo 'extension="smbclient.so"' >> /etc/php/7.0/apache2/php.ini

# Instala VM-tools
apt install open-vm-tools -y

# Baixa E valida o pacote Nextcloud
check_command download_verify_nextcloud_stable

if [ ! -f "$HTML/$STABLEVERSION.tar.bz2" ]
then
    echo "Abortando, algo deu errado com o download de $STABLEVERSION.tar.bz2"
    exit 1
fi

# Extrai o Pacote
tar -xjf "$HTML/$STABLEVERSION.tar.bz2" -C "$HTML" & spinner_loading
rm "$HTML/$STABLEVERSION.tar.bz2"

# Permissoes seguras
download_static_script setup_secure_permissions_nextcloud
bash $SECURE & spinner_loading

# Cria Banco de Dados nextcloud_db
mysql -u root -p"$MARIADB_PASS" -e "CREATE DATABASE IF NOT EXISTS nextcloud_db;"

# Instala Nextcloud
cd "$NCPATH"
check_command sudo -u www-data php occ maintenance:install \
    --data-dir "$NCDATA" \
    --database "mysql" \
    --database-name "nextcloud_db" \
    --database-user "root" \
    --database-pass "$MARIADB_PASS" \
    --admin-user "$NCUSER" \
    --admin-pass "$NCPASS"
echo
echo "Nextcloud version:"
sudo -u www-data php "$NCPATH"/occ status
sleep 3
echo

# Habilita UTF8mb4 (4-byte support)
databases=$(mysql -u root -p"$MARIADB_PASS" -e "SHOW DATABASES;" | tr -d "| " | grep -v Database)
for db in $databases; do
    if [[ "$db" != "performance_schema" ]] && [[ "$db" != _* ]] && [[ "$db" != "information_schema" ]];
    then
        echo "Mudando para UTF8mb4 on: $db"
        mysql -u root -p"$MARIADB_PASS" -e "ALTER DATABASE $db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    fi
done
#if [ $? -ne 0 ]
#then
#    echo "UTF8mb4 Nao foi definido. Algo esta errado."
#    echo "Informe este erro para $ISSUES. Obrigado!"
#    exit 1
#fi

# Repara e defini valores de configuracao Nextcloud
mysqlcheck -u root -p"$MARIADB_PASS" --auto-repair --optimize --all-databases
check_command sudo -u www-data $NCPATH/occ config:system:set mysql.utf8mb4 --type boolean --value="true"
check_command sudo -u www-data $NCPATH/occ maintenance:repair

# Prepare o cron.php para ser executado a cada 15 minutos
crontab -u www-data -l | { cat; echo "*/15  *  *  *  * php -f $NCPATH/cron.php > /dev/null 2>&1"; } | crontab -u www-data -

# Altera valores em php.ini (Aumenta o tamanho maximo do arquivo)
# max_execution_time
sed -i "s|max_execution_time =.*|max_execution_time = 3500|g" /etc/php/7.0/apache2/php.ini
# max_input_time
sed -i "s|max_input_time =.*|max_input_time = 3600|g" /etc/php/7.0/apache2/php.ini
# memory_limit
sed -i "s|memory_limit =.*|memory_limit = 512M|g" /etc/php/7.0/apache2/php.ini
# post_max
sed -i "s|post_max_size =.*|post_max_size = 1100M|g" /etc/php/7.0/apache2/php.ini
# upload_max
sed -i "s|upload_max_filesize =.*|upload_max_filesize = 1000M|g" /etc/php/7.0/apache2/php.ini

# Defina o upload maximo no Nextcloud .htaccess
configure_max_upload

# Define SMTP mail
sudo -u www-data php "$NCPATH"/occ config:system:set mail_smtpmode --value="smtp"

# Define logrotate
sudo -u www-data php "$NCPATH"/occ config:system:set log_rotate_size --value="10485760"

# Habilita OPCache para PHP 
# https://docs.nextcloud.com/server/12/admin_manual/configuration_server/server_tuning.html#enable-php-opcache
phpenmod opcache
{
echo "# OPcache configuracoes para Nextcloud"
echo "opcache.enable=1"
echo "opcache.enable_cli=1"
echo "opcache.interned_strings_buffer=8"
echo "opcache.max_accelerated_files=10000"
echo "opcache.memory_consumption=128"
echo "opcache.save_comments=1"
echo "opcache.revalidate_freq=1"
echo "opcache.validate_timestamps=1"
} >> /etc/php/7.0/apache2/php.ini

# Instala o gerador de visualizacao
run_app_script previewgenerator

# Instala Figlet
apt install figlet -y

# Gera $HTTP_CONF
if [ ! -f $HTTP_CONF ]
then
    touch "$HTTP_CONF"
    cat << HTTP_CREATE > "$HTTP_CONF"
<VirtualHost *:80>

### ENDERECO DO SEU SERVIDOR ###
#    ServerAdmin admin@example.com
#    ServerName example.com
#    ServerAlias subdomain.example.com

### Configuracoes ###
    DocumentRoot $NCPATH

    <Directory $NCPATH>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
    Satisfy Any
    </Directory>

    <IfModule mod_dav.c>
    Dav off
    </IfModule>

    <Directory "$NCDATA">
    # just in case if .htaccess gets disabled
    Require all denied
    </Directory>

    SetEnv HOME $NCPATH
    SetEnv HTTP_HOME $NCPATH

</VirtualHost>
HTTP_CREATE
    echo "$HTTP_CONF was successfully created"
fi

# Gera $SSL_CONF
if [ ! -f $SSL_CONF ]
then
    touch "$SSL_CONF"
    cat << SSL_CREATE > "$SSL_CONF"
<VirtualHost *:443>
    Header add Strict-Transport-Security: "max-age=15768000;includeSubdomains"
    SSLEngine on

### ENDERECO DO SEU SERVIDOR ###
#    ServerAdmin admin@example.com
#    ServerName example.com
#    ServerAlias subdomain.example.com

### Configuracoes ###
    DocumentRoot $NCPATH

    <Directory $NCPATH>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
    Satisfy Any
    </Directory>

    <IfModule mod_dav.c>
    Dav off
    </IfModule>

    <Directory "$NCDATA">
    # apenas no caso do .htaccess ficar desativado
    Require all denied
    </Directory>

    SetEnv HOME $NCPATH
    SetEnv HTTP_HOME $NCPATH

### LOCALIZACAO DE ARQUIVOS CERT ###
    SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
    SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
</VirtualHost>
SSL_CREATE
    echo "$SSL_CONF foi criado com sucesso"
fi

# Habilitando novo config
a2ensite nextcloud_ssl_domain_self_signed.conf
a2ensite nextcloud_http_domain_self_signed.conf
a2dissite default-ssl

# Habilite o servidor HTTP/2 de largura, se o usuario decidir
echo "Seu repositorio oficial de pacotes nao fornece um pacote Apache2 com modulo HTTP/2 incluido."
echo "Se voce quiser habilitar o HTTP/2 no entanto, podemos atualizar o seu Apache2 do Ondrejs PPA:"
echo "https://launchpad.net/~ondrej/+archive/ubuntu/apache2"
echo "Habilita HTTP/2 pode trazer uma vantagem de desempenho, mas tambem pode ter alguns problemas de compatibilidade."
echo "E.g. O aplicativo de chamadas de video Nextcloud Spread ainda nao funciona com o HTTP/2 ativado."
if [[ "yes" == $(ask_yes_or_no "Deseja ativar o sistema HTTP/2?") ]]
then
    # Adicionando PPA
    add-apt-repository ppa:ondrej/apache2 -y
    apt update -q4 & spinner_loading
    apt upgrade apache2 -y
    
    # Habilitando HTTP/2 modulo & protocolo
    cat << HTTP2_ENABLE > "$HTTP2_CONF"
<IfModule http2_module>
    Protocols h2 h2c http/1.1
    H2Direct on
</IfModule>
HTTP2_ENABLE
    echo "$HTTP2_CONF Foi criado com sucesso"
    a2enmod http2
fi

# Reiniciando Apache2 para habilitar novo config
service apache2 restart

whiptail --title "Which apps/programs do you want to install?" --checklist --separate-output "" 10 40 3 \
"Calendar" "              " on \
"Contacts" "              " on \
"Webmin" "              " on 2>results

while read -r -u 9 choice
do
    case "$choice" in
        Calendar)
            run_app_script calendar
        ;;
        Contacts)
            run_app_script contacts
        ;;
        Webmin)
            run_app_script webmin
        ;;
        *)
        ;;
    esac
done 9< results
rm -f results

# Obtenha os scripts necessarios para o primeiro Boot
if [ ! -f "$SCRIPTS"/nextcloud-startup-script.sh ]
then
check_command wget -q "$GITHUB_REPO"/nextcloud-startup-script.sh -P "$SCRIPTS"
fi
download_static_script instruction
download_static_script history

# Faca $SCRIPTS executaveis
chmod +x -R "$SCRIPTS"
chown root:root -R "$SCRIPTS"

# Prepara para o primeiro Boot
check_command run_static_script change-ncadmin-profile
check_command run_static_script change-root-profile

# Instala Redis
run_static_script redis-server-ubuntu16

# Atualiza Repositorio
apt update -q4 & spinner_loading
apt dist-upgrade -y

# Remove LXD (Sempre aparece como falhou durante a inicializacao)
apt purge lxd -y

# Limpa
CLEARBOOT=$(dpkg -l linux-* | awk '/^ii/{ print $2}' | grep -v -e ''"$(uname -r | cut -f1,2 -d"-")"'' | grep -e '[0-9]' | xargs sudo apt -y purge)
echo "$CLEARBOOT"
apt autoremove -y
apt autoclean
find /root "/home/$UNIXUSER" -type f \( -name '*.sh*' -o -name '*.html*' -o -name '*.tar*' -o -name '*.zip*' \) -delete

# Instala os kernels virtuais para Hyper-V, E extra para UTF8 Modulo do kernel + Collabora e OnlyOffice
# Kernel 4.4
apt install --install-recommends -y \
linux-virtual-lts-xenial \
linux-tools-virtual-lts-xenial \
linux-cloud-tools-virtual-lts-xenial \
linux-image-virtual-lts-xenial \
linux-image-extra-"$(uname -r)"

# Define finalidades de permissoes seguras (./data/.htaccess has wrong permissions otherwise)
bash $SECURE & spinner_loading

# Reboot
echo "Instalaco concluida, o sistema agora sera reiniciado..."
reboot
