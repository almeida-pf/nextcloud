#!/bin/bash
# shellcheck disable=2034,2059
true
# veja https://github.com/almeida-pf/nextcloud

## variaveis

# Diretorios
SCRIPTS=/var/scripts
NCPATH=/var/www/nextcloud
HTML=/var/www
NCDATA=/var/ncdata
SNAPDIR=/var/snap/spreedme
GPGDIR=/tmp/gpg
BACKUP=/var/NCBACKUP
# Ubuntu OS
DISTRO=$(lsb_release -sd | cut -d ' ' -f 2)
OS=$(grep -ic "Ubuntu" /etc/issue.net)
# Rede
[ ! -z "$FIRST_IFACE" ] && IFACE=$(lshw -c network | grep "logical name" | awk '{print $3; exit}')
IFACE2=$(ip -o link show | awk '{print $2,$9}' | grep 'UP' | cut -d ':' -f 1)
[ ! -z "$CHECK_CURRENT_REPO" ] && REPO=$(apt-get update | grep -m 1 Hit | awk '{ print $2}')
ADDRESS=$(hostname -I | cut -d ' ' -f 1)
WGET="/usr/bin/wget"
# WANIP4=$(dig +short myip.opendns.com @resolver1.opendns.com) # Alternativo
WANIP4=$(curl -s -m 5 ipinfo.io/ip)
[ ! -z "$LOAD_IP6" ] && WANIP6=$(curl -s -k -m 7 https://6.ifcfg.me)
IFCONFIG="/sbin/ifconfig"
INTERFACES="/etc/network/interfaces"
NETMASK=$($IFCONFIG | grep -w inet |grep -v 127.0.0.1| awk '{print $4}' | cut -d ":" -f 2)
GATEWAY=$(route -n|grep "UG"|grep -v "UGH"|cut -f 10 -d " ")
# Repositorio
GITHUB_REPO="https://raw.githubusercontent.com/almeida-pf/nextcloud/master"
STATIC="$GITHUB_REPO/static"
LETS_ENC="$GITHUB_REPO/lets-encrypt"
APP="$GITHUB_REPO/apps"
NCREPO="https://download.nextcloud.com/server/releases"
ISSUES="https://github.com/nextcloud/vm/issues"
# Informacao Usuario
NCPASS=nextcloud
NCUSER=ncadmin
UNIXUSER=$SUDO_USER
UNIXUSER_PROFILE="/home/$UNIXUSER/.bash_profile"
ROOT_PROFILE="/root/.bash_profile"
# MARIADB
SHUF=$(shuf -i 25-29 -n 1)
MARIADB_PASS=$(tr -dc "a-zA-Z0-9@#*=" < /dev/urandom | fold -w "$SHUF" | head -n 1)
NEWMARIADBPASS=$(tr -dc "a-zA-Z0-9@#*=" < /dev/urandom | fold -w "$SHUF" | head -n 1)
[ ! -z "$NCDB" ] && NCCONFIGDB=$(grep "dbname" $NCPATH/config/config.php | awk '{print $3}' | sed "s/[',]//g")
ETCMYCNF=/etc/mysql/my.cnf
MYCNF=/root/.my.cnf
[ ! -z "$MYCNFPW" ] && MARIADBMYCNFPASS=$(grep "password" $MYCNF | sed -n "/password/s/^password='\(.*\)'$/\1/p")
[ ! -z "$NCDB" ] && NCCONFIGDB=$(grep "dbname" $NCPATH/config/config.php | awk '{print $3}' | sed "s/[',]//g")
[ ! -z "$NCDBPASS" ] && NCCONFIGDBPASS=$(grep "dbpassword" $NCPATH/config/config.php | awk '{print $3}' | sed "s/[',]//g")
# Caminho para arquivos especificos
PHPMYADMIN_CONF="/etc/apache2/conf-available/phpmyadmin.conf"
SECURE="$SCRIPTS/setup_secure_permissions_nextcloud.sh"
SSL_CONF="/etc/apache2/sites-available/nextcloud_ssl_domain_self_signed.conf"
HTTP_CONF="/etc/apache2/sites-available/nextcloud_http_domain_self_signed.conf"
HTTP2_CONF="/etc/apache2/mods-available/http2.conf"
# Versao Nextcloud
[ ! -z "$NC_UPDATE" ] && CURRENTVERSION=$(sudo -u www-data php $NCPATH/occ status | grep "versionstring" | awk '{print $3}')
NCVERSION=$(curl -s -m 900 $NCREPO/ | sed --silent 's/.*href="nextcloud-\([^"]\+\).zip.asc".*/\1/p' | sort --version-sort | tail -1)
STABLEVERSION="nextcloud-$NCVERSION"
NCMAJOR="${NCVERSION%%.*}"
NCBAD=$((NCMAJOR-2))
# Chaves
OpenPGP_fingerprint='28806A878AE423A28372792ED75899B9A724937A'
# OnlyOffice URL
[ ! -z "$OO_INSTALL" ] && SUBDOMAIN=$(whiptail --title "Techandme.se OnlyOffice" --inputbox "OnlyOffice subdomain eg: office.yourdomain.com" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)
# Nextcloud Dominio Principal
[ ! -z "$OO_INSTALL" ] && NCDOMAIN=$(whiptail --title "Techandme.se OnlyOffice" --inputbox "Nextcloud url, make sure it looks like this: cloud\\.yourdomain\\.com" "$WT_HEIGHT" "$WT_WIDTH" cloud\\.yourdomain\\.com 3>&1 1>&2 2>&3)
# Collabora Docker URL
[ ! -z "$COLLABORA_INSTALL" ] && SUBDOMAIN=$(whiptail --title "Techandme.se Collabora" --inputbox "Collabora subdomain eg: office.yourdomain.com" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)
# Nextcloud Dominio Principal
[ ! -z "$COLLABORA_INSTALL" ] && NCDOMAIN=$(whiptail --title "Techandme.se Collabora" --inputbox "Nextcloud url, make sure it looks like this: cloud\\.yourdomain\\.com" "$WT_HEIGHT" "$WT_WIDTH" cloud\\.yourdomain\\.com 3>&1 1>&2 2>&3)
# Letsencrypt
LETSENCRYPTPATH="/etc/letsencrypt"
CERTFILES="$LETSENCRYPTPATH/live"
DHPARAMS="$CERTFILES/$SUBDOMAIN/dhparam.pem"
# Collabora App
[ ! -z "$COLLABORA_INSTALL" ] && COLLVER=$(curl -s https://api.github.com/repos/nextcloud/richdocuments/releases/latest | grep "tag_name" | cut -d\" -f4)
COLLVER_FILE=richdocuments.tar.gz
COLLVER_REPO=https://github.com/nextcloud/richdocuments/releases/download
HTTPS_CONF="/etc/apache2/sites-available/$SUBDOMAIN.conf"
# Proximo
SOLR_VERSION=$(curl -s https://github.com/apache/lucene-solr/tags | grep -o "release.*</span>$" | grep -o '[0-9].[0-9].[0-9]' | sort -t. -k1,1n -k2,2n -k3,3n | tail -n1)
[ ! -z "$NEXTANT_INSTALL" ] && NEXTANT_VERSION=$(curl -s https://api.github.com/repos/nextcloud/nextant/releases/latest | grep 'tag_name' | cut -d\" -f4 | sed -e "s|v||g")
NT_RELEASE=nextant-$NEXTANT_VERSION.tar.gz
NT_DL=https://github.com/nextcloud/nextant/releases/download/v$NEXTANT_VERSION/$NT_RELEASE
SOLR_RELEASE=solr-$SOLR_VERSION.tgz
SOLR_DL=http://www-eu.apache.org/dist/lucene/solr/$SOLR_VERSION/$SOLR_RELEASE
NC_APPS_PATH=$NCPATH/apps/
SOLR_HOME=/home/$SUDO_USER/solr_install/
SOLR_JETTY=/opt/solr/server/etc/jetty-http.xml
SOLR_DSCONF=/opt/solr-$SOLR_VERSION/server/solr/configsets/data_driven_schema_configs/conf/solrconfig.xml
# Passman
[ ! -z "$PASSMAN_INSTALL" ] && PASSVER=$(curl -s https://api.github.com/repos/nextcloud/passman/releases/latest | grep "tag_name" | cut -d\" -f4)
PASSVER_FILE=passman_$PASSVER.tar.gz
PASSVER_REPO=https://releases.passman.cc
SHA256=/tmp/sha256
# Pre visu. Gerador
[ ! -z "$PREVIEW_INSTALL" ] && PREVER=$(curl -s https://api.github.com/repos/rullzer/previewgenerator/releases/latest | grep "tag_name" | cut -d\" -f4 | sed -e "s|v||g")
PREVER_FILE=previewgenerator.tar.gz
PREVER_REPO=https://github.com/rullzer/previewgenerator/releases/download
# Calendario
[ ! -z "$CALENDAR_INSTALL" ] && CALVER=$(curl -s https://api.github.com/repos/nextcloud/calendar/releases/latest | grep "tag_name" | cut -d\" -f4 | sed -e "s|v||g")
CALVER_FILE=calendar.tar.gz
CALVER_REPO=https://github.com/nextcloud/calendar/releases/download
# Contatos
[ ! -z "$CONTACTS_INSTALL" ] && CONVER=$(curl -s https://api.github.com/repos/nextcloud/contacts/releases/latest | grep "tag_name" | cut -d\" -f4 | sed -e "s|v||g")
CONVER_FILE=contacts.tar.gz
CONVER_REPO=https://github.com/nextcloud/contacts/releases/download
# Spreed.ME
SPREEDME_VER=$(wget -q https://raw.githubusercontent.com/strukturag/nextcloud-spreedme/master/appinfo/info.xml && grep -Po "(?<=<version>)[^<]*(?=</version>)" info.xml && rm info.xml)
SPREEDME_FILE="v$SPREEDME_VER.tar.gz"
SPREEDME_REPO=https://github.com/strukturag/nextcloud-spreedme/archive
# phpMyadmin
PHPMYADMINDIR=/usr/share/phpmyadmin
PHPMYADMIN_CONF="/etc/apache2/conf-available/phpmyadmin.conf"
UPLOADPATH=""
SAVEPATH=""
# Redis
REDIS_CONF=/etc/redis/redis.conf
REDIS_SOCK=/var/run/redis/redis.sock
RSHUF=$(shuf -i 30-35 -n 1)
REDIS_PASS=$(tr -dc "a-zA-Z0-9@#*=" < /dev/urandom | fold -w "$RSHUF" | head -n 1)
# Seguranca Extra
SPAMHAUS=/etc/spamhaus.wl
ENVASIVE=/etc/apache2/mods-available/mod-evasive.load
APACHE2=/etc/apache2/apache2.conf

## funcoes

# Se o script estiver sendo executado como root
#
# Examplo:
# se for root
# entao
#     # faz as alteracoes
# se nao
#     echo "voce nao e root..."
#     exit 1
# fi
#
is_root() {
    if [[ "$EUID" -ne 0 ]]
    then
        return 1
    else
        return 0
    fi
}

debug_mode() {
if [ "$DEBUG" -eq 1 ]
then
    set -ex
fi
}

ask_yes_or_no() {
    read -r -p "$1 ([y]es or [N]o): "
    case ${REPLY,,} in
        y|yes)
            echo "yes"
        ;;
        *)
            echo "no"
        ;;
    esac
}

# Verifica se o processo esta em execucao: O processo dpkg esta sendo executado
is_process_running() {
PROCESS="$1"

while :
do
    RESULT=$(pgrep "${PROCESS}")

    if [ "${RESULT:-null}" = null ]; then
            break
    else
            echo "${PROCESS} Processando. Espere para parar..."
            sleep 10
    fi
done
}

# Instala certbot (Let's Encrypt)
install_certbot() {
certbot --version 2> /dev/null
LE_IS_AVAILABLE=$?
if [ $LE_IS_AVAILABLE -eq 0 ]
then
    certbot --version
else
    echo "Instalando certbot (Let's Encrypt)..."
    apt update -q4 & spinner_loading
    apt install software-properties-common
    add-apt-repository ppa:certbot/certbot -y
    apt update -q4 & spinner_loading
    apt install certbot -y -q
    apt update -q4 & spinner_loading
    apt dist-upgrade -y
fi
}

configure_max_upload() {
# Aumento o tamanho maximo do arquivo (espera que as alteraoes sejam feitas em /etc/php/7.0/apache2/php.ini)
sed -i 's/  php_value upload_max_filesize.*/# php_value upload_max_filesize 511M/g' "$NCPATH"/.htaccess
sed -i 's/  php_value post_max_size.*/# php_value post_max_size 511M/g' "$NCPATH"/.htaccess
sed -i 's/  php_value memory_limit.*/# php_value memory_limit 512M/g' "$NCPATH"/.htaccess
}

# Verifica se o programa esta instalado ( esta instalado apache2)
is_this_installed() {
if [ "$(dpkg-query -W -f='${Status}' "${1}" 2>/dev/null | grep -c "ok instalado")" == "1" ]
then
    echo "${1}instalado, ele deve ser um servidor limpo."
    exit 1
fi
}

# Instala caso nao esteja instalado
install_if_not () {
if [[ "$(is_this_installed "${1}")" != "${1} instalado, o mesmo deve ser um servidor limpo." ]]
then
    apt update -q4 & spinner_loading && apt install "${1}" -y
fi
}

# Testa o tamanho da memoria RAM
# Chame assim: ram_check [Quantidade de RAM minima em GB] [para o programa]
# Examplo: Teste RAM 2 Nextcloud
ram_check() {
mem_available="$(awk '/MemTotal/{print $2}' /proc/meminfo)"
if [ "${mem_available}" -lt "$((${1}*1002400))" ]
then
    printf "${Red}Error: ${1} necessario uma RAM de para instalar ${2}!${Color_Off}\n" >&2
    printf "${Red}RAM atual e: ("$((mem_available/1002400))" GB)${Color_Off}\n" >&2
    sleep 3
    exit 1
else
    printf "${Green}RAM para ${2} OK! ("$((mem_available/1002400))" GB)${Color_Off}\n"
fi
}

# Testa o numero de CPU
# Chame assim: cpu_check [Quantidade de CPU minima] [para o programa]
# Examplo: Teste cpu 2 Nextcloud
cpu_check() {
nr_cpu="$(nproc)"
if [ "${nr_cpu}" -lt "${1}" ]
then
    printf "${Red}Error: ${1} CPU necessario para instalar ${2}!${Color_Off}\n" >&2
    printf "${Red}Atual CPU: ("$((nr_cpu))")${Color_Off}\n" >&2
    sleep 3
    exit 1
else
    printf "${Green}CPU para ${2} OK! ("$((nr_cpu))")${Color_Off}\n"
fi
}

check_command() {
  if ! eval "$*"
  then
     printf "${IRed}Desculpe, mas algo deu errado. Informe esta questao para $ISSUES E incluir a saída da mensagem de erro. Obrigado!${Color_Off}\n"
     echo "$* falha"
    exit 1
  fi
}

network_ok() {
    echo "Testando se a rede esta correta ..."
    service networking restart
    if wget -q -T 20 -t 2 http://github.com -O /dev/null & spinner_loading
    then
        return 0
    else
        return 1
    fi
}

# Whiptail auto-size
calc_wt_size() {
    WT_HEIGHT=17
    WT_WIDTH=$(tput cols)

    if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]; then
        WT_WIDTH=80
    fi
    if [ "$WT_WIDTH" -gt 178 ]; then
        WT_WIDTH=120
    fi
    WT_MENU_HEIGHT=$((WT_HEIGHT-7))
    export WT_MENU_HEIGHT
}

download_verify_nextcloud_stable() {
rm -f "$HTML/$STABLEVERSION.tar.bz2"
wget -q -T 10 -t 2 "$NCREPO/$STABLEVERSION.tar.bz2" -P "$HTML"
mkdir -p "$GPGDIR"
wget -q "$NCREPO/$STABLEVERSION.tar.bz2.asc" -P "$GPGDIR"
chmod -R 600 "$GPGDIR"
gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$OpenPGP_fingerprint"
gpg --verify "$GPGDIR/$STABLEVERSION.tar.bz2.asc" "$HTML/$STABLEVERSION.tar.bz2"
rm -r "$GPGDIR"
}

# Primeiro download de script em ../static
# Chame assim: download_static_script name_of_script
download_static_script() {
    # Get ${1} script
    rm -f "${SCRIPTS}/${1}.sh" "${SCRIPTS}/${1}.php" "${SCRIPTS}/${1}.py"
    if ! { wget -q "${STATIC}/${1}.sh" -P "$SCRIPTS" || wget -q "${STATIC}/${1}.php" -P "$SCRIPTS" || wget -q "${STATIC}/${1}.py" -P "$SCRIPTS"; }
    then
        echo "{$1} download falhou. execute: 'sudo wget ${STATIC}/${1}.sh|.php|.py' novamente."
        echo "Se voce receber este erro ao executar o nextcloud-startup-script entao apenas reexecute:"
        echo "'sudo bash $SCRIPTS/nextcloud-startup-script.sh' e todos os scriptis serao baixados novamente"
        exit 1
    fi
}

# Primeiro download de script em ../lets-encrypt
# Chame assim: download_le_script name_of_script
download_le_script() {
    # Get ${1} script
    rm -f "${SCRIPTS}/${1}.sh" "${SCRIPTS}/${1}.php" "${SCRIPTS}/${1}.py"
    if ! { wget -q "${LETS_ENC}/${1}.sh" -P "$SCRIPTS" || wget -q "${LETS_ENC}/${1}.php" -P "$SCRIPTS" || wget -q "${LETS_ENC}/${1}.py" -P "$SCRIPTS"; }
    then
        echo "{$1} download falhou. execute: 'sudo wget ${STATIC}/${1}.sh|.php|.py' again."
        echo "Se voce receber este erro ao executar o nextcloud-startup-script entao apenas reexecute:"
        echo "'sudo bash $SCRIPTS/nextcloud-startup-script.sh' e todos os scriptis serao baixados novamente"
        exit 1
    fi
}

# Execute qualquer script em ../master
# Chame assim: run_main_script name_of_script
run_main_script() {
    rm -f "${SCRIPTS}/${1}.sh" "${SCRIPTS}/${1}.php" "${SCRIPTS}/${1}.py"
    if wget -q "${GITHUB_REPO}/${1}.sh" -P "$SCRIPTS"
    then
        bash "${SCRIPTS}/${1}.sh"
        rm -f "${SCRIPTS}/${1}.sh"
    elif wget -q "${GITHUB_REPO}/${1}.php" -P "$SCRIPTS"
    then
        php "${SCRIPTS}/${1}.php"
        rm -f "${SCRIPTS}/${1}.php"
    elif wget -q "${GITHUB_REPO}/${1}.py" -P "$SCRIPTS"
    then
        python "${SCRIPTS}/${1}.py"
        rm -f "${SCRIPTS}/${1}.py"
    else
        echo "Download ${1} falha"
        echo "O script falhou ao fazer o download. Por favor, execute: 'sudo wget ${GITHUB_REPO}/${1}.sh|php|py' novamente."
        sleep 3
    fi
}

# Execute qualquer script em ../static
# chame assim: run_static_script name_of_script
run_static_script() {
    # Get ${1} script
    rm -f "${SCRIPTS}/${1}.sh" "${SCRIPTS}/${1}.php" "${SCRIPTS}/${1}.py"
    if wget -q "${STATIC}/${1}.sh" -P "$SCRIPTS"
    then
        bash "${SCRIPTS}/${1}.sh"
        rm -f "${SCRIPTS}/${1}.sh"
    elif wget -q "${STATIC}/${1}.php" -P "$SCRIPTS"
    then
        php "${SCRIPTS}/${1}.php"
        rm -f "${SCRIPTS}/${1}.php"
    elif wget -q "${STATIC}/${1}.py" -P "$SCRIPTS"
    then
        python "${SCRIPTS}/${1}.py"
        rm -f "${SCRIPTS}/${1}.py"
    else
        echo "Download ${1} falha"
        echo "O script falhou ao fazer o download. Por favor, execute: 'sudo wget ${STATIC}/${1}.sh|php|py' again."
        sleep 3
    fi
}

# Execute qualquer script em ../apps
# Chame assim: run_app_script collabora|nextant|passman|spreedme|contacts|calendar|webmin|previewgenerator
run_app_script() {
    rm -f "${SCRIPTS}/${1}.sh" "${SCRIPTS}/${1}.php" "${SCRIPTS}/${1}.py"
    if wget -q "${APP}/${1}.sh" -P "$SCRIPTS"
    then
        bash "${SCRIPTS}/${1}.sh"
        rm -f "${SCRIPTS}/${1}.sh"
    elif wget -q "${APP}/${1}.php" -P "$SCRIPTS"
    then
        php "${SCRIPTS}/${1}.php"
        rm -f "${SCRIPTS}/${1}.php"
    elif wget -q "${APP}/${1}.py" -P "$SCRIPTS"
    then
        python "${SCRIPTS}/${1}.py"
        rm -f "${SCRIPTS}/${1}.py"
    else
        echo "Download ${1} falha"
        echo "O script falhou ao fazer o download. Por favor, execute: 'sudo wget ${APP}/${1}.sh|php|py' again."
        sleep 3
    fi
}

version(){
    local h t v

    [[ $2 = "$1" || $2 = "$3" ]] && return 0

    v=$(printf '%s\n' "$@" | sort -V)
    h=$(head -n1 <<<"$v")
    t=$(tail -n1 <<<"$v")

    [[ $2 != "$h" && $2 != "$t" ]]
}

version_gt() {
    local v1 v2 IFS=.
    read -ra v1 <<< "$1"
    read -ra v2 <<< "$2"
    printf -v v1 %03d "${v1[@]}"
    printf -v v2 %03d "${v2[@]}"
    [[ $v1 > $v2 ]]
}

spinner_loading() {
    pid=$!
    spin='-\|/'
    i=0
    while kill -0 $pid 2>/dev/null
    do
        i=$(( (i+1) %4 ))
        printf "\r[${spin:$i:1}] " # "Por favor, seja paciente ..."
        sleep .1
    done
}

any_key() {
    local PROMPT="$1"
    read -r -p "$(printf "${Green}${PROMPT}${Color_Off}")" -n1 -s
    echo
}

## bash colors
# Reset
Color_Off='\e[0m'       # Text Reset

# Regular Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White

# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White

# Underline
UBlack='\e[4;30m'       # Black
URed='\e[4;31m'         # Red
UGreen='\e[4;32m'       # Green
UYellow='\e[4;33m'      # Yellow
UBlue='\e[4;34m'        # Blue
UPurple='\e[4;35m'      # Purple
UCyan='\e[4;36m'        # Cyan
UWhite='\e[4;37m'       # White

# Background
On_Black='\e[40m'       # Black
On_Red='\e[41m'         # Red
On_Green='\e[42m'       # Green
On_Yellow='\e[43m'      # Yellow
On_Blue='\e[44m'        # Blue
On_Purple='\e[45m'      # Purple
On_Cyan='\e[46m'        # Cyan
On_White='\e[47m'       # White

# High Intensity
IBlack='\e[0;90m'       # Black
IRed='\e[0;91m'         # Red
IGreen='\e[0;92m'       # Green
IYellow='\e[0;93m'      # Yellow
IBlue='\e[0;94m'        # Blue
IPurple='\e[0;95m'      # Purple
ICyan='\e[0;96m'        # Cyan
IWhite='\e[0;97m'       # White

# Bold High Intensity
BIBlack='\e[1;90m'      # Black
BIRed='\e[1;91m'        # Red
BIGreen='\e[1;92m'      # Green
BIYellow='\e[1;93m'     # Yellow
BIBlue='\e[1;94m'       # Blue
BIPurple='\e[1;95m'     # Purple
BICyan='\e[1;96m'       # Cyan
BIWhite='\e[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\e[0;100m'   # Black
On_IRed='\e[0;101m'     # Red
On_IGreen='\e[0;102m'   # Green
On_IYellow='\e[0;103m'  # Yellow
On_IBlue='\e[0;104m'    # Blue
On_IPurple='\e[0;105m'  # Purple
On_ICyan='\e[0;106m'    # Cyan
On_IWhite='\e[0;107m'   # White
