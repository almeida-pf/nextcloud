#! / Bin / bash

# Tech and Me © - 2017, https://www.techandme.se/

# Prefira o IPv4
Sed -i " s | #precedence :: ffff: 0: 0/96 100 | precedência :: ffff: 0: 0/96 100 | g " /etc/gai.conf

# Shellcheck disable = 2034,2059
verdade
# Shellcheck source = lib.sh
FIRST_IFACE = 1 && CHECK_CURRENT_REPO = 1 .  <( Curl -sL https://raw.githubusercontent.com/nextcloud/vm/master/lib.sh )
unset FIRST_IFACE
unset CHECK_CURRENT_REPO

# Verifique se há erros + código de depuração e aborta se algo não estiver certo
# 1 = ON
# 0 = DESLIGADO
DEBUG = 0
modo de depuração

# Verifique se a raiz
Se  ! Is_root
então
    Printf  " \ n $ {Red} Desculpe, você não é root. \ N $ {Color_Off} Você deve digitar: $ {Cyan} sudo $ {Color_Off} bash% s / nextcloud_install_production.sh \ n "  " $ SCRIPTS "
    Saída 1
Fi

# Teste tamanho da RAM (2 GB min) + CPUs (min 1)
Ram_check 2 Nextcloud
Cpu_check 1 Nextcloud

# Mostrar usuário atual
eco
Echo  " O usuário atual com permissões sudo é: $ UNIXUSER " .
Echo  " Este script configurará tudo com esse usuário " .
Echo  " Se o campo após ':' estiver em branco, você provavelmente estará executando como um usuário root puro. "
Echo  " É possível instalar com root, mas haverá pequenos erros " .
eco
Echo  " Crie um usuário com permissões sudo se desejar uma instalação ideal " .
Run_static_script adduser

# Verifique a versão do Ubuntu
Echo  " Verificando o sistema operacional do servidor e a versão ... "
Se [ " $ OS "  ! = 1]
então
    Echo  "O servidor Ubuntu é necessário para executar este script. "
    Echo  " Instale essa distro e tente novamente. "
    Saída 1
Fi

Se  ! Versão 16.04 " $ DISTRO " 16.04.4 ;  então
    Echo  " Versão Ubuntu $ DISTRO deve estar entre 16.04 - 16.04.4 "
    Saída
Fi

# Verifique se a chave está disponível
Se  ! Wget -q -T 10 -t 2 " $ NCREPO "  > / dev / null
então
    Echo  " Nextcloud repo não está disponível, saindo ... "
    Saída 1
Fi

# Verifique se é um servidor limpo
Is_this_installed postgresql
Is_this_installed apache2
Is_this_installed php
Is_this_installed mysql-common
Is_this_installed mariadb-server

# Crie $ SCRIPTS dir
Se [ !  -d  " $ SCRIPTS " ]
então
    Mkdir -p " $ SCRIPTS "
Fi

# Alterar DNS
Se  ! [ -x  " $ ( comando -v resolvconf ) " ]
então
    Instalar resolvconf -y -q
    Dpkg-reconfigure resolvconf
Fi
Echo  " nameserver 8.8.8.8 "  > /etc/resolvconf/resolv.conf.d/base
Echo  " nameserver 8.8.4.4 "  >> /etc/resolvconf/resolv.conf.d/base

# Verificar rede
Se  ! [ -x  " $ ( comando -v nslookup ) " ]
então
    Instale dnsutils -y -q
Fi
Se  ! [ -x  " $ ( comando -v ifup ) " ]
então
    Apt install ifupdown -y -q
Fi
Sudo ifdown " $ IFACE "  && sudo ifup " $ IFACE "
Se  ! Nslookup google.com
então
    Echo  " Network NOT OK. Você deve ter uma conexão de rede em funcionamento para executar este script. "
    Saída 1
Fi

# Definir locais
Instalar o idioma-pack-en-base -y
Sudo locale-gen " sv_SE.UTF-8 "  && sudo dpkg-reconfigure --frontend = ambientes não interativos

# Verifique onde estão os melhores espelhos e atualize
eco
Printf  " Seu repositório de servidor atual é:   $ {Ciano} % s $ {Color_Off} \ n "  " $ REPO "
Se [[ " não "  ==  $ ( ask_yes_or_no " Deseja tentar encontrar um espelho melhor? " ) ]]
então
    Echo  " Mantendo $ REPO como espelho ... "
    Dormir 1
outro
   Echo  " Localizando os melhores espelhos ... "
   Atualização do apt -q4 & spinner_loading
   Instale o python-pip -y
   Pip install \
       - atualização pip \
       Apt-select
    Apt-select -m up-to-date -t ​​5 -c
    Sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup && \
    Se [ -f sources.list]
    então
        Sudo mv sources.list / etc / apt /
    Fi
Fi
Claro

# Configura o layout do teclado
Echo  " O layout atual do teclado é $ ( localectl status | grep " Layout "  | awk ' {print $ 3} ' ) "
Se [[ " não "  ==  $ ( ask_yes_or_no " Deseja alterar o layout do teclado? " ) ]]
então
    Echo  " Não mudando o layout do teclado ... "
    Dormir 1
    Claro
outro
    Dpkg-reconfigure a configuração do teclado
    Claro
Fi

# Sistema de atualização
Atualização do apt -q4 & spinner_loading

# Escreva MARIADB passe para arquivo e mantenha-o seguro
{
Echo  " [cliente] "
Echo  " senha = ' $ MARIADB_PASS ' "
} >  " $ MYCNF "
Chmod 0600 $ MYCNF
Raiz chown: root $ MYCNF

# Instale o MARIADB
Instalar software-propriedades-comum -y
Sudo apt-key adv --recv-keys --keyserver hkp: //keyserver.ubuntu.com: 80 0xF1656F24C74CD1D8
Sudo add-apt-repository ' deb [arch = amd64, i386, ppc64el] http://ftp.ddg.lth.se/mariadb/repo/10.2/ubuntu xenial main '
Sudo debconf-set-selections <<<  " mariadb-server-10.2 mysql-server / root_password password $ MARIADB_PASS "
Sudo debconf-set-selections <<<  " mariadb-server-10.2 mysql-server / root_password_again password $ MARIADB_PASS "
Atualização do apt -q4 & spinner_loading
Check_command apt install mariadb-server-10.2 -y

# Prepare-se para instalação Nextcloud
# Https://blog.v-gar.de/2017/02/en-solved-error-1698-28000-in-mysqlmariadb/
Mysql -u root mysql -p " $ MARIADB_PASS " -e " UPDATE usuário SET plugin = '' WHERE usuário = 'root'; "
Mysql -u root mysql -p " $ MARIADB_PASS " -e " UPDATE usuário SET senha = PASSWORD (' $ MARIADB_PASS ') WHERE usuário = 'root'; "
Mysql -u root -p " $ MARIADB_PASS " -e " privilégios de descarga; "

# Mysql_secure_installation
Apt -y instalar esperar
SECURE_MYSQL = $ ( espera -c "
Definir tempo limite 10
Spawn mysql_secure_installation
Espera \ " Digite a senha atual para a raiz (insira para nenhum): \"
Envie \ " $ MARIADB_PASS \ r \"
Esperar \ " Alterar a senha de root? \"
Envie \ " n \ r \"
Esperar \ " Remover usuários anônimos? \"
Envie \ " y \ r \"
Esperar \ " Não permitir o login root remotamente? \"
Envie \ " y \ r \"
Esperar \ " Remover o banco de dados de teste e acessá-lo? \"
Envie \ " y \ r \"
Esperar \ " Atualizar tabelas de privilégios agora? \"
Envie \ " y \ r \"
Espera eof
" )
Echo  " $ SECURE_MYSQL "
Apto-limpar espera

# Escreva uma nova configuração MariaDB
Run_static_script new_etc_mycnf

# Instala Apache
Check_command apt install apache2 -y
A2enmod reescrever \
        Cabeçalhos \
        Env \
        Dir \
        Mime \
        Ssl \
        Setenvif

# Instale o PHP 7.0
Atualização do apt -q4 & spinner_loading
Check_command apt install -y \
    Libapache2-mod-php7.0 \
    Php7.0-common \
    Php7.0-mysql \
    Php7.0-intl \
    Php7.0-mcrypt \
    Php7.0-ldap \
    Php7.0-imap \
    Php7.0-cli \
    Php7.0-gd \
    Php7.0-pgsql \
    Php7.0-json \
    Php7.0-sqlite3 \
    Php7.0-curl \
    Php7.0-xml \
    Php7.0-zip \
    Php7.0-mbstring \
    Php-smbclient

# Habilitar o cliente SMB
# Echo '# Isto permite php-smbclient' >> /etc/php/7.0/apache2/php.ini
# Echo 'extension = "smbclient.so"' >> /etc/php/7.0/apache2/php.ini

# Instalar VM-tools
Instalar ferramentas open-vm -y

# Faça o download e valide o pacote Nextcloud
Check_command download_verify_nextcloud_stable

Se [ !  -f  " $ HTML / $ STABLEVERSION .tar.bz2 " ]
então
    Echo  " Abortando, algo deu errado com o download de $ STABLEVERSION .tar.bz2 "
    Saída 1
Fi

# Pacote de extrair
Tar -xjf " $ HTML / $ STABLEVERSION .tar.bz2 " -C " $ HTML "  & spinner_loading
rm " $ HTML / $ STABLEVERSION .tar.bz2 "

# Permissões seguras
Download_static_script setup_secure_permissions_nextcloud
festa $ SEGURO  & spinner_loading

# Criar banco de dados nextcloud_db
Mysql -u root -p " $ MARIADB_PASS " -e " CRIAR A BASE DE DADOS SE NÃO EXISTA nextcloud_db; "

# Instale Nextcloud
Cd  " $ NCPATH "
Check_command sudo -u www-data php occ manutenção: install \
    --data-dir " $ NCDATA " \
    --database " mysql " \
    --database-name " nextcloud_db " \
    --database-user " root " \
    --database-pass " $ MARIADB_PASS " \
    --admin-user " $ NCUSER " \
    --admin-pass " $ NCPASS "
eco
Echo  " Nextcloud versão: "
Sudo -u www-data php " $ NCPATH " / status occ
Durma 3
eco

# Habilitar UTF8mb4 (suporte de 4 bytes)
Bases de dados = $ ( mysql -u root -p " $ MARIADB_PASS " -e " SHOW DATABASES; "  | tr -d " | "  | grep -v Database )
Para  db  em  $ bases de dados ;  Faz
    Se [[ " $ db "  ! =  " Performance_schema " ]] && [[ " $ db "  ! = _ * ]] && [[ " $ db "  ! =  " Information_schema " ]] ;
    então
        Echo  " Alterando para UTF8mb4 em: $ db "
Mysql         -u root -p " $ MARIADB_PASS " -e " ALTER DATABASE $ db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; "
    Fi
feito
# Se [$? -ne 0]
# Então
#     Echo "UTF8mb4 não foi configurado. Algo está errado".
#     Echo "Por favor, informe esse erro em $ QUESTÕES. Obrigado!"
#     Saída 1
# Fi

# Reparar e definir valores de configuração Nextcloud
Mysqlcheck -u root -p " $ MARIADB_PASS " --auto -repair --optimize --all-databases
Check_command sudo -u www-data $ NCPATH / occ config: system: set mysql.utf8mb4 --ty boolean --value = " true "
Check_command sudo -u www-data $ NCPATH / occ manutenção: reparo

# Prepare cron.php para ser executado a cada 15 minutos
Crontab -u www-data -l | {Gato ;  Echo  " * / 15 * * * * php -f $ NCPATH /cron.php> / dev / null 2> & 1 " ; } | Crontab -u www-data -

# Alterar valores em php.ini (aumentar o tamanho máximo do arquivo)
# Max_execution_time
Sed -i " s | max_execution_time =. * | Max_execution_time = 3500 | g " /etc/php/7.0/apache2/php.ini
# Max_input_time
Sed -i " s | max_input_time =. * | Max_input_time = 3600 | g " /etc/php/7.0/apache2/php.ini
# Memory_limit
Sed -i " s | memory_limit =. * | Memory_limit = 512M | g " /etc/php/7.0/apache2/php.ini
# Post_max
Sed -i " s | post_max_size =. * | Post_max_size = 1100M | g " /etc/php/7.0/apache2/php.ini
# Upload_max
Sed -i " s | upload_max_filesize =. * | Upload_max_filesize = 1000M | g " /etc/php/7.0/apache2/php.ini

# Defina o carregamento máximo em Nextcloud .htaccess
Configure_max_upload

# Defina o correio SMTP
Sudo -u www-data php " $ NCPATH " / occ config: system: set mail_smtpmode --value = " smtp "

# Definir logrotate
Sudo -u www-data php " $ NCPATH " / occ config: system: set log_rotate_size --value = " 10485760 "

# Habilite o OPCache para PHP
# Https://docs.nextcloud.com/server/12/admin_manual/configuration_server/server_tuning.html#enable-php-opcache
Phpenmod opcache
{
Echo  " # configurações de OPcache para Nextcloud "
Echo  " opcache.enable = 1 "
Echo  " opcache.enable_cli = 1 "
Echo  " opcache.interned_strings_buffer = 8 "
Echo  " opcache.max_accelerated_files = 10000 "
Echo  " opcache.memory_consumption = 128 "
Echo  " opcache.save_comments = 1 "
Echo  " opcache.revalidate_freq = 1 "
Echo  " opcache.validate_timestamps = 1 "
} >> /etc/php/7.0/apache2/php.ini

# Instalar o gerador de visualização
Run_app_script previewgenerator

# Instalar Figlet
Instalar uma figura

# Gerar $ HTTP_CONF
Se [ !  -f  $ HTTP_CONF ]
então
    Toque " $ HTTP_CONF "
    Gato << HTTP_CREATE >  " $ HTTP_CONF "
< VirtualHost * : 80>

# ## SEU ENDEREÇO ​​DO SERVIDOR ###
#     ServerAdmin admin@example.com
#     ServerName example.com
#     ServerAlias ​​subdomain.example.com

# ## AJUSTES ###
    DocumentRoot $ NCPATH

    < Directory $ NCPATH >
    Índices de Opções FollowSymLinks
    AllowOverride All
    Exigir tudo concedido
    Satisfaça Qualquer
    < / Directory >

    < IfModule mod_dav.c >
    Derrubar
    < / IfModule >

    < Diretório " $ NCDATA " >
    # Apenas no caso de .htaccess ficar desabilitado
    Exigir todos negados
    < / Directory >

    SetEnv HOME $ NCPATH
    SetEnv HTTP_HOME $ NCPATH

< / VirtualHost >
HTTP_CREATE
    Echo  " $ HTTP_CONF foi criado com sucesso "
Fi

# Gerar $ SSL_CONF
Se [ !  -f  $ SSL_CONF ]
então
    Toque " $ SSL_CONF "
    Gato << SSL_CREATE >  " $ SSL_CONF "
< VirtualHost * : 443>
    Cabeçalho adicionar Strict-Transport-Security: " max-age = 15768000; includeSubdomains "
    SSLEngine on

# ## SEU ENDEREÇO ​​DO SERVIDOR ###
#     ServerAdmin admin@example.com
#     ServerName example.com
#     ServerAlias ​​subdomain.example.com

# ## AJUSTES ###
    DocumentRoot $ NCPATH

    < Directory $ NCPATH >
    Índices de Opções FollowSymLinks
    AllowOverride All
    Exigir tudo concedido
    Satisfaça Qualquer
    < / Directory >

    < IfModule mod_dav.c >
    Derrubar
    < / IfModule >

    < Diretório " $ NCDATA " >
    # Apenas no caso de .htaccess ficar desabilitado
    Exigir todos negados
    < / Directory >

    SetEnv HOME $ NCPATH
    SetEnv HTTP_HOME $ NCPATH

# ## LOCALIZAÇÃO DE CERT FILES ###
    SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
    SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
< / VirtualHost >
SSL_CREATE
    Echo  " $ SSL_CONF foi criado com sucesso "
Fi

# Habilitar nova configuração
A2ensite nextcloud_ssl_domain_self_signed.conf
A2ensite nextcloud_http_domain_self_signed.conf
A2dissite default-ssl
Service apache2 reiniciar

Whiptail --title " Quais aplicativos / programas você deseja instalar? " --checklist --separate-output " " 10 40 3 \
" Calendário "  "               " em \
" Contatos "  "               " em \
" Webmin "  "               " em 2> resultados

Enquanto  lê -r -u 9 escolha
Faz
    Caso  " $ choice "  em
        Calendário)
            Calendário run_app_script
        ;;
        Contatos)
            Contatos run_app_script
        ;;
        Webmin)
            Run_app_script webmin
        ;;
        * )
        ;;
    Esac
Feito  9 resultados
Resultados rm -f

# Obter scripts necessários para o primeiro arranque
Se [ !  -f  " $ SCRIPTS " /nextcloud-startup-script.sh]
então
Check_command wget -q " $ GITHUB_REPO " /nextcloud-startup-script.sh -P " $ SCRIPTS "
Fi
Instrução download_static_script
Histórico do download_static_script

# Faça $ SCRIPTS excutable
Chmod + x -R " $ SCRIPTS "
Raiz chown: root -R " $ SCRIPTS "

# Prepare o primeiro arranque
Check_command run_static_script change-ncadmin-profile
Check_command run_static_script change-root-profile

# Instalar Redis
Run_static_script redis-server-ubuntu16

# Upgrade
Atualização do apt -q4 & spinner_loading
Apt dist-upgrade -y

# Remove LXD (sempre aparece como falhou durante a inicialização)
Apt purge lxd -y

# Limpeza
CLEARBOOT = $ ( dpkg -l linux- *  | awk ' / ^ ii / {print $ 2} '  | grep -v -e ' ' " $ ( uname -r | cut -f1,2 -d " - " ) " ' '  | Grep -e ' [0-9] '  | xargs sudo apt -y purge )
Echo  " $ CLEARBOOT "
Autor eletrodo -y
Apt autoclean
Encontrar / root " / home / $ UNIXUSER " - tipo f \ ( -name ' * .sh * ' -o -name ' * .html * ' -o -name ' * .tar * ' -o -name ' *. Zip * '  \) -delete

# Instale kernels virtuais para o Hyper-V e extra para o módulo do kernel UTF8 + Collabora e OnlyOffice
# Kernel 4.4
Apt install --install-recommended -y \
Linux-virtual-lts-xenial \
Linux-tools-virtual-lts-xenial \
Linux-cloud-tools-virtual-lts-xenial \
Linux-image-virtual-lts-xenial \
Linux-image-extra- " $ ( uname -r ) "

# Defina as permissões seguras definitivas (./data/.htaccess tem permissões erradas do contrário)
festa $ SEGURO  & spinner_loading

# Reiniciar
Echo  " Instalação feita, o sistema reiniciará agora ... "
Reiniciar