#!/bin/bash
# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
NCDB=1 && MYCNFPW=1 && NC_UPDATE=1 . <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)
unset NC_UPDATE
unset MYCNFPW
unset NCDB

# Pablo Almeida

# Verifica se ha erros no code e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

# Coloque seu nome de tema aqui:
THEME_NAME=""

# Deve ser root
if ! is_root
then
    echo "Deve ser root para executar o script, no Ubuntu: sudo -i"
    exit 1
fi

# Verifica se dpkg ou apt estao funcionando
is_process_running dpkg
is_process_running apt

# System Upgrade
apt update -q4 & spinner_loading
export DEBIAN_FRONTEND=noninteractive ; apt dist-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# Atualiza Redis PHP extention
if type pecl > /dev/null 2>&1
then
    install_if_not php7.0-dev
    echo "Trying to upgrade the Redis Pecl extenstion..."
    pecl upgrade redis
    service apache2 restart
fi

# Atualiza docker images
# Isto atualiza todos os Docker images:
if [ "$(docker ps -a >/dev/null 2>&1 && echo yes || echo no)" == "yes" ]
then
docker images | grep -v REPOSITORY | awk '{print $1}' | xargs -L1 docker pull
fi

## Caminho antigo ##
#if [ "$(docker image inspect onlyoffice/documentserver >/dev/null 2>&1 && echo yes || echo no)" == "yes" ]
#then
#    echo "Atuallizando Docker container para OnlyOffice..."
#    docker pull onlyoffice/documentserver
#fi
#
#if [ "$(docker image inspect collabora/code >/dev/null 2>&1 && echo yes || echo no)" == "yes" ]
#then
#    echo "Atuallizando Docker container para Collabora..."
#    docker pull collabora/code
#fi

# Limpar pacotes nao utilizados
apt autoremove -y
apt autoclean

# Atualiza GRUB
update-grub

# Remove listas de update
rm /var/lib/apt/lists/* -r

# Set secure permissions
if [ ! -f "$SECURE" ]
then
    mkdir -p "$SCRIPTS"
    download_static_script setup_secure_permissions_nextcloud
    chmod +x "$SECURE"
fi

# versões nao suportadas
if [ "${CURRENTVERSION%%.*}" == "$NCBAD" ]
then
    echo
    echo "Por favor, note que as atualizacoes entre multiplas versoes principais nao sao suportadas. Sua situacao e:"
    echo "Versao Atual: $CURRENTVERSION"
    echo "Ultimo Lancamento: $NCVERSION"
    echo
    echo "E melhor manter seu servidor Nextcloud atualizado regularmente e instalar todos os lancamentos de pontos"
    echo "E grandes lancamentos sem ignorar nenhum deles, a medida que saltear os lancamentos aumenta o risco de"
    echo "Erros. Os lancamentos principais sao 9, 10, 11 e 12. Os lançamentos de pontos sao lancamentos intermediarios para cada um"
    echo "Maior lancamento. Por exemplo, 9.0.52 e 10.0.2 sao lancamentos pontuais."
    echo
    echo "Entre em contato com Pablo Almeida para ajuda-lo a atualizar entre as principais versoes."
    echo
    exit 1
fi

# Verifique se a nova versao e maior do que a versao atual instalada.
if version_gt "$NCVERSION" "$CURRENTVERSION"
then
    echo "Latest release is: $NCVERSION. Current version is: $CURRENTVERSION."
    printf "${Green}Nova versao disponivel! O upgrade continua...${Color_Off}\n"
else
    echo "Ultima versao e: $NCVERSION. versao atual e: $CURRENTVERSION."
    echo "Nao e necessario atualizar, esse script ira sair..."
    exit 0
fi

# Certifique-se de que as instancias antigas tambem possam atualizar
if [ ! -f "$MYCNF" ] && [ -f /var/mysql_password.txt ]
then
    regressionpw=$(cat /var/mysql_password.txt)
cat << LOGIN > "$MYCNF"
[client]
password='$regressionpw'
LOGIN
    chmod 0600 $MYCNF
    chown root:root $MYCNF
    echo "Reinicie o processo de atualizacao, corrigimos o arquivo de senha $MYCNF."
    exit 1    
elif [ -z "$MARIADBMYCNFPASS" ] && [ -f /var/mysql_password.txt ]
then
    regressionpw=$(cat /var/mysql_password.txt)
    {
    echo "[client]"
    echo "password='$regressionpw'"
    } >> "$MYCNF"
    echo "Reinicie o processo de atualizacao, corrigimos o arquivo de senha $MYCNF."
    exit 1    
fi

if [ -z "$MARIADBMYCNFPASS" ]
then
    echo "Algo deu errado ao copiar sua senha mysql para $MYCNF."
    echo "Nos escrevemos um guia sobre como corrigir isso. Voce pode encontrar o guia aqui:"
    echo "https://www.techandme.se/reset-mysql-5-7-root-password/"
    exit 1
else
    rm -f /var/mysql_password.txt
fi

# Atualiza Nextcloud
echo "Verificando a versao mais recente no servidor de download do Nextcloud e se for possivel baixar..."
if ! wget -q --show-progress -T 10 -t 2 "$NCREPO/$STABLEVERSION.tar.bz2"
then
    echo
    printf "${IRed}Nextcloud %s doesn't exist.${Color_Off}\n" "$NCVERSION"
    echo "Verifique as versoes disponiveis aqui: $NCREPO"
    echo
    exit 1
else
    rm -f "$STABLEVERSION.tar.bz2"
fi

echo "Fazendo backup de arquivos e atualizando para Nextcloud $NCVERSION in 10 seconds..."
echo "Press CTRL+C to abort."
sleep 10

# Verifique se o backup existe e mova para o antigo
echo "Backing up data..."
DATE=$(date +%Y-%m-%d-%H%M%S)
if [ -d $BACKUP ]
then
    mkdir -p "/var/NCBACKUP_OLD/$DATE"
    mv $BACKUP/* "/var/NCBACKUP_OLD/$DATE"
    rm -R $BACKUP
    mkdir -p $BACKUP
fi

# Backup dados
for folders in config themes apps
do
    if [[ "$(rsync -Aax $NCPATH/$folders $BACKUP)" -eq 0 ]]
    then
        BACKUP_OK=1
    else
        unset BACKUP_OK
    fi
done

if [ -z $BACKUP_OK ]
then
    echo "O backup nao estava OK. por favor, verifique $BACKUP E veja se as pastas sao copiadas adequadamente"
    exit 1
else
    printf "${Green}\nBackup OK!${Color_Off}\n"
fi

# Backup MARIADB
if mysql -u root -p"$MARIADBMYCNFPASS" -e "SHOW DATABASES LIKE '$NCCONFIGDB'" > /dev/null
then
    echo "Fazendo mysqldump do $NCCONFIGDB..."
    check_command mysqldump -u root -p"$MARIADBMYCNFPASS" -d "$NCCONFIGDB" > "$BACKUP"/nextclouddb.sql
else
    echo "Fazendo mysqldump de todos databases..."
    check_command mysqldump -u root -p"$MARIADBMYCNFPASS" -d --all-databases > "$BACKUP"/alldatabases.sql
fi

# Baixe e valide o pacote Nextcloud
check_command download_verify_nextcloud_stable

if [ -f "$HTML/$STABLEVERSION.tar.bz2" ]
then
    echo "$HTML/$STABLEVERSION.tar.bz2 existe"
else
    echo "Abortando, algo deu errado com o download"
    exit 1
fi

if [ -d $BACKUP/config/ ]
then
    echo "$BACKUP/config/ existe"
else
    echo "Algo deu errado ao fazer backup de sua antiga instancia proxima a proxima, por favor verifique $BACKUP se config/ pasta ja existe."
    exit 1
fi

if [ -d $BACKUP/apps/ ]
then
    echo "$BACKUP/apps/ existe"
else
    echo "Algo deu errado ao fazer backup de sua antiga instancia proxima a proxima, por favor verifique $BACKUP se apps/ pasta ja existe."
    exit 1
fi

if [ -d $BACKUP/themes/ ]
then
    echo "$BACKUP/themes/ existe"
    echo 
    printf "${Green}Todos os arquivos sao copiados.${Color_Off}\n"
    sudo -u www-data php "$NCPATH"/occ maintenance:mode --on
    echo "Removendo a instancia antiga Nextcloud em 5 segundos..." && sleep 5
    rm -rf $NCPATH
    tar -xjf "$HTML/$STABLEVERSION.tar.bz2" -C "$HTML"
    rm "$HTML/$STABLEVERSION.tar.bz2"
    cp -R $BACKUP/themes "$NCPATH"/
    cp -R $BACKUP/config "$NCPATH"/
    bash $SECURE & spinner_loading
    sudo -u www-data php "$NCPATH"/occ maintenance:mode --off
    sudo -u www-data php "$NCPATH"/occ upgrade --no-app-disable
else
    echo "Algo deu errado ao fazer backup de sua antiga instancia proxima a proxima, por favor verifique $BACKUP se a pasta ja existe."
    exit 1
fi

# Recupere aplicativos que existem na pasta de aplicativos de backup
# run_static_script recover_apps

# Ativar aplicativos
if [ -d "$SNAPDIR" ]
then
    run_app_script spreedme
fi

# Altere o proprietario da pasta $BACKUP para a raiz
chown -R root:root "$BACKUP"

# Defina o upload maximo no Nextcloud .htaccess
configure_max_upload

# Set $THEME_NAME
VALUE2="$THEME_NAME"
if ! grep -Fxq "$VALUE2" "$NCPATH/config/config.php"
then
    sed -i "s|'theme' => '',|'theme' => '$THEME_NAME',|g" "$NCPATH"/config/config.php
    echo "Theme set"
fi

# URLs Bonitas
echo "Setting RewriteBase to \"/\" in config.php..."
chown -R www-data:www-data "$NCPATH"
sudo -u www-data php "$NCPATH"/occ config:system:set htaccess.RewriteBase --value="/"
sudo -u www-data php "$NCPATH"/occ maintenance:update:htaccess
bash "$SECURE"

# Reparar
sudo -u www-data php "$NCPATH"/occ maintenance:repair

CURRENTVERSION_after=$(sudo -u www-data php "$NCPATH"/occ status | grep "versionstring" | awk '{print $3}')
if [[ "$NCVERSION" == "$CURRENTVERSION_after" ]]
then
    echo
    echo "versao mais recente e: $NCVERSION. versao atual e: $CURRENTVERSION_after."
    echo "versao atualizada com sucesso!"
    echo "NEXTCLOUD atualizado com success-$(date +"%Y%m%d")" >> /var/log/cronjobs_success.log
    sudo -u www-data php "$NCPATH"/occ status
    sudo -u www-data php "$NCPATH"/occ maintenance:mode --off
    echo
    echo "Se voce notar que alguns aplicativos estao desativados, e devido a que eles nao sao compativeis com a nova versao Nextcloud."
    echo "Para recuperar seus aplicativos antigos, verifique $BACKUP/apps E copie-os para $NCPATH/apps manual."
    echo
    echo "Obrigado por usar o Script_atualiza Nextcloud por Pablo Almeida!"
    ## Descarte isso se quiser que o sistema seja reiniciado
    # reboot
    exit 0
else
    echo
    echo "Versao mais recente e: $NCVERSION. versao atual e: $CURRENTVERSION_after."
    sudo -u www-data php "$NCPATH"/occ status
    echo "Atualização falhou!"
    echo "Seus arquivos ainda estao protegidos em $BACKUP. Nao se preocupe!"
    echo "Informe esta questao para $ISSUES"
    exit 1
fi
