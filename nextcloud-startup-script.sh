#!/bin/bash
# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
FIRST_IFACE=1 && CHECK_CURRENT_REPO=1 . <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)
unset FIRST_IFACE
unset CHECK_CURRENT_REPO

# Pablo Almeida

## Se desejar ativar o modo Debug ative na linha 60

is_root() {
    if [[ "$EUID" -ne 0 ]]
    then
        return 1
    else
        return 0
    fi
}

network_ok() {
    echo "Testando se a rede esta correta..."
    service networking restart
    if wget -q -T 20 -t 2 http://github.com -O /dev/null
    then
        return 0
    else
        return 1
    fi
}

# Verifique se e root
if ! is_root
then
    printf "\n${Red}Desculpe, voce nao e root.\n${Color_Off}Voce deve digitar: ${Cyan}sudo ${Color_Off}bash $SCRIPTS/nextcloud-startup-script.sh\n"
    exit 1
fi

# Verifica Conexao
if network_ok
then
    printf "${Green}Online!${Color_Off}\n"
else
    echo "Configurando a interface correta..."
    [ -z "$IFACE" ] && IFACE=$(lshw -c network | grep "logical name" | awk '{print $3; exit}')
    # Configura interface correta
    {
        sed '/# Principal interface de rede/q' /etc/network/interfaces
        printf 'auto %s\niface %s inet dhcp\n# Esta e uma interface IPv6 autoconfigurada\niface %s inet6 auto\n' "$IFACE" "$IFACE" "$IFACE"
    } > /etc/network/interfaces.new
    mv /etc/network/interfaces.new /etc/network/interfaces
    service networking restart
    # shellcheck source=lib.sh
    CHECK_CURRENT_REPO=1 . <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)
    unset CHECK_CURRENT_REPO
fi

# Verifica se ha erros no code e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

# Verifica Conexao
if network_ok
then
    printf "${Green}Online!${Color_Off}\n"
else
    printf "\nNetwork nao esta ok. Voce deve ter uma conexao de rede em funcionamento para executar este script.\n"
    echo "Por favor, relate este problema aqui: $ISSUES"
    exit 1
fi

# Verifica se o dpkg ou apt estao funcionando
is_process_running dpkg
is_process_running apt

# Verifique onde estao os melhores repositorios e atualize
printf "\nTo Faca downloads o mais rapido possivel ao atualizar, voce deve ter repositorios tao perto quanto possivel.\n"
echo "Esta VM vem com repositorios com base em servidores em que, quando usado quando a VM foi lancada e empacotada."
echo "Recomendamos que voce mude os repositorios com base em onde esta instalado atualmente."
echo "Verificando Repositorios..."
printf "O seu repositorio de servidor atual e:  ${Cyan}$REPO${Color_Off}\n"

if [[ "no" == $(ask_yes_or_no "Voce quer tentar encontrar um repositorio melhor?") ]]
then
    echo "Guardando $REPO como repositorio..."
    sleep 1
else
    echo "Localizando melhores repositorios..."
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

echo
echo "Obtendo scripts do GitHub para poder executar a primeira configuracao..."
# Todos os scripts shell em estatico(.sh)
download_static_script temporary-fix
download_static_script security
download_static_script update
download_static_script trusted
download_static_script ip
download_static_script test_connection
download_static_script setup_secure_permissions_nextcloud
download_static_script change_mysql_pass
download_static_script nextcloud
download_static_script update-config
download_static_script index
download_le_script activate-ssl

mv $SCRIPTS/index.php $HTML/index.php && rm -f $HTML/html/index.html
chmod 750 $HTML/index.php && chown www-data:www-data $HTML/index.php

# Mude 000-default para$WEB_ROOT
sed -i "s|DocumentRoot /var/www/html|DocumentRoot $HTML|g" /etc/apache2/sites-available/000-default.conf

# Faca $SCRIPTS executaveis
chmod +x -R $SCRIPTS
chown root:root -R $SCRIPTS

# Todos $UNIXUSER Executar script figlet
chown "$UNIXUSER":"$UNIXUSER" "$SCRIPTS/nextcloud.sh"

clear
echo "+--------------------------------------------------------------------+"
echo "| Este script ira configurar o Nextcloud e ativar SSL.        |"
echo "| Tambem fara o seguinte:                                     |"
echo "|                                                                    |"
echo "| - Gera novas chaves SSH para o servidor                             |"
echo "| - Gera nova senha MARIADB                                    |"
echo "| - Instala o phpMyadmin e fique seguro                            |"
echo "| - Instala aplicativos selecionados e configure-os automaticamente.           |"
echo "| - Detecta e define o nome do host                                          |"
echo "| - Atualiza seu sistema e Nextcloud para a versao mais recente              |"
echo "| - Define permissoes seguras para Nextcloud                              |"
echo "| - Define novas senhas para Linux e Nextcloud                         |"
echo "| - Define novo layout de teclado                                          |"
echo "| - Altera fuso horario                                                  |"
echo "| - Define IP estatico para o sistema (voce deve configurar o mesmo IP em      |"
echo "|   Seu roteador) https://www.techandme.se/open-port-80-443/          |"
echo "|   Nao configuramos IP estatico se voce executar isso em um *Servidor* VPS.        |"
echo "|                                                                    |"
echo "|   O script demorara cerca de 10 minutos para terminar,                 |"
echo "|   Dependendo da sua conexao com a internet.                           |"
echo "|                                                                    |"
echo "| ####################### Pablo Almeida - 2017 ####################### |"
echo "+--------------------------------------------------------------------+"
any_key "Pressione qualquer tecla para iniciar o script..."
clear

# VPS?
if [[ "no" == $(ask_yes_or_no "Do you run this script on a *remote* VPS like DigitalOcean, HostGator or similar?") ]]
then
    # Change IP
    printf "\n${Color_Off}OK, Entendemos que voce esta executando isso localmente e agora configuraremos seu IP para ser estatico.${Color_Off}\n"
    echo "Seu IP interno e: $ADDRESS"
    printf "\n${Color_Off}Anote isso, voce precisara dele para configurar o IP estatico\n"
    echo "No seu roteador mais tarde. Esta incluido neste guia:"
    echo "https://www.techandme.se/open-port-80-443/ (step 1 - 5)"
    any_key "Pressione qualquer tecla para configurar o IP estatico..."
    ifdown "$IFACE"
    wait
    ifup "$IFACE"
    wait
    bash "$SCRIPTS/ip.sh"
    if [ -z "$IFACE" ]
    then
        echo "A interface esta vazia. Tentando definir a interface com outro metodo..."
        download_static_script ip2
        bash "$SCRIPTS/ip2.sh"
        rm -f "$SCRIPTS/ip2.sh"
    fi
    ifdown "$IFACE"
    wait
    ifup "$IFACE"
    wait
    echo
    echo "Verificando se a rede esta correta..."
    echo
    CONTEST=$(bash $SCRIPTS/test_connection.sh)
    if [ "$CONTEST" == "Connected!" ]
    then
        # Conectado!
        printf "${Green}Conectedo!${Color_Off}\n"
        printf "Usaremos DHCP: ${Green}$ADDRESS${Color_Off}. Se voce quiser altera-lo mais tarde, basta editar as interfaces file:\n"
        printf "sudo nano /etc/network/interfaces\n"
        echo "Se voce tiver algum erro, informe-o aqui:"
        echo "$ISSUES"
        any_key "Pressione qualquer tecla para continuar..."
    else
        # Nao conectado!
        printf "${Red}Sem Conexao${Color_Off}\nVoce deve alterar suas configuracoes manualmente na proxima etapa.\n"
        any_key "Pressione qualquer tecla para abrir /etc/network/interfaces..."
        nano /etc/network/interfaces
        service networking restart
        clear
        echo "Verificando se conexao esta ok..."
        ifdown "$IFACE"
        wait
        ifup "$IFACE"
        wait
        bash "$SCRIPTS/test_connection.sh"
        wait
    fi
else
    echo "OK, Entao nao vamos configurar um IP estatico, pois seu provedor VPS ja configurou a rede para voce..."
    sleep 5 & spinner_loading
fi
clear

# Define o layout do teclado
echo "O layout atual do teclado e $(localectl status | grep "Layout" | awk '{print $3}')"
if [[ "no" == $(ask_yes_or_no "Do you want to change keyboard layout?") ]]
then
    echo "Nao alterando o layout do teclado..."
    sleep 1
    clear
else
    dpkg-reconfigure keyboard-configuration
clear
fi

# URLs Bonitas
echo "Configurando RewriteBase para \"/\" in config.php..."
chown -R www-data:www-data $NCPATH
sudo -u www-data php $NCPATH/occ config:system:set htaccess.RewriteBase --value="/"
sudo -u www-data php $NCPATH/occ maintenance:update:htaccess
bash $SECURE & spinner_loading

# Gerando nova chave para SSH
printf "\nGerando nova chave SSH para o servidor...\n"
rm -v /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server

# Gerando nova senha para MARIADB
echo "Gerando nova senha para MARIADB..."
if bash "$SCRIPTS/change_mysql_pass.sh" && wait
then
    rm "$SCRIPTS/change_mysql_pass.sh"
fi

cat << LETSENC
+-----------------------------------------------+
|  The following script will install a trusted  |
|  SSL certificate through Let's Encrypt.       |
+-----------------------------------------------+
LETSENC

# Let's Encrypt
if [[ "yes" == $(ask_yes_or_no "Do you want to install SSL?") ]]
then
    bash $SCRIPTS/activate-ssl.sh
else
    echo
    echo "OK, mas se voce quiser executa-lo mais tarde, basta digitar: sudo bash $SCRIPTS/activate-ssl.sh"
    any_key "Pressione qualquer tecla para continuar..."
fi
clear

# Alterar fuso horario
echo "Fuso horario atual $(cat /etc/timezone)"
echo "Voce deve muda-lo para o seu fuso horario"
any_key "Pressione qualquer tecla para carregar novo fuso horario..."
dpkg-reconfigure tzdata
sleep 3
clear

whiptail --title "Quais aplicativos deseja instalar??" --checklist --separate-output "Configure e instale automaticamente as aplicacoes selecionadas \nSelecione pressionando a barra de espaco" "$WT_HEIGHT" "$WT_WIDTH" 4 \
"Fail2ban" "(Protecao Extra contra Forca Bruta)   " OFF \
"phpMyadmin" "(*SQL GUI)       " OFF \
"Collabora" "(Edicao Online 2GB RAM)   " OFF \
"OnlyOffice" "(Edicao Online 4GB RAM)   " OFF \
"Nextant" "(autocomplete)   " OFF \
"Passman" "(Armazenamento de senhas)   " OFF \
"Spreed.ME" "(Video chamadas)   " OFF 2>results

while read -r -u 9 choice
do
    case $choice in
        Fail2ban)
            run_app_script fail2ban
            
        ;;
        phpMyadmin)
            run_app_script phpmyadmin_install_ubuntu16
        ;;
        
        OnlyOffice)
            run_app_script onlyoffice
        ;;
        
        Collabora)
            run_app_script collabora
        ;;

        Nextant)
            run_app_script nextant
        ;;

        Passman)
            run_app_script passman
        ;;

        Spreed.ME)
            run_app_script spreedme
        ;;

        *)
        ;;
    esac
done 9< results
rm -f results
clear
clear

# Add Seguranca Extra
if [[ "yes" == $(ask_yes_or_no "Deseja adicionar seguranaa extra, com base nisso: http://goo.gl/gEJHi7 ?") ]]
then
    bash $SCRIPTS/security.sh
    rm "$SCRIPTS"/security.sh
else
    echo
    echo "OK, mas se voce quiser executa-lo mais tarde, basta digitar: sudo bash $SCRIPTS/security.sh"
    any_key "Pressione qualquer tecla para continuar..."
fi
clear

# Mudar senha
printf "${Color_Off}\n"
echo "Para melhor seguranca, altere a senha do usuario do sistema para [$UNIXUSER]"
any_key "Pressione qualquer tecla para mudar a senha do usuario do sistema..."
while true
do
    sudo passwd "$UNIXUSER" && break
done
echo
clear
NCADMIN=$(sudo -u www-data php $NCPATH/occ user:list | awk '{print $3}')
printf "${Color_Off}\n"
echo "Para uma melhor seguranca, altere a senha Nextcloud para [$NCADMIN]"
echo "A senha atual para $NCADMIN e [$NCPASS]"
any_key "Pressione qualquer tecla para alterar a senha do Nextcloud..."
while true
do
    sudo -u www-data php "$NCPATH/occ" user:resetpassword "$NCADMIN" && break
done
clear

# ISSUES https://raw.githubusercontent.com/almeida-pf/nextcloud
a2dismod status
service apache2 reload

# Aumenta o tamanho maximo do arquivo (espera que as alteracoes sejam feitas em /etc/php/7.0/apache2/php.ini)
# Manual aqui: https://www.techandme.se/increase-max-file-size/
VALUE="# php_value upload_max_filesize 513M"
if ! grep -Fxq "$VALUE" $NCPATH/.htaccess
then
    sed -i 's/  php_value upload_max_filesize 513M/# php_value upload_max_filesize 511M/g' "$NCPATH"/.htaccess
    sed -i 's/  php_value post_max_size 513M/# php_value post_max_size 511M/g' "$NCPATH"/.htaccess
    sed -i 's/  php_value memory_limit 512M/# php_value memory_limit 512M/g' "$NCPATH"/.htaccess
fi

# Adicione correcao temporaria, se necessario
bash $SCRIPTS/temporary-fix.sh
rm "$SCRIPTS"/temporary-fix.sh

# Limpeza 1
sudo -u www-data php "$NCPATH/occ" maintenance:repair
rm -f "$SCRIPTS/ip.sh"
rm -f "$SCRIPTS/test_connection.sh"
rm -f "$SCRIPTS/instruction.sh"
rm -f "$NCDATA/nextcloud.log"
rm -f "$SCRIPTS/nextcloud-startup-script.sh"
find /root "/home/$UNIXUSER" -type f \( -name '*.sh*' -o -name '*.html*' -o -name '*.tar*' -o -name '*.zip*' \) -delete
sed -i "s|instruction.sh|nextcloud.sh|g" "/home/$UNIXUSER/.bash_profile"

truncate -s 0 \
    /root/.bash_history \
    "/home/$UNIXUSER/.bash_history" \
    /var/spool/mail/root \
    "/var/spool/mail/$UNIXUSER" \
    /var/log/apache2/access.log \
    /var/log/apache2/error.log \
    /var/log/cronjobs_success.log

sed -i "s|sudo -i||g" "/home/$UNIXUSER/.bash_profile"
cat << RCLOCAL > "/etc/rc.local"
#!/bin/sh -e
#
# rc.local
#
# Este script e executado no final de cada nivel de execucao multiusuario.
# Certifique-se de que o script "saira 0" com sucesso ou qualquer outro
# Valor em erro.
#
# Para ativar ou desativar este script, basta alterar a execucao
# bits.
#
# Por padrao, este script nao faz nada.

exit 0

RCLOCAL
clear

# Atualiza Sistema
echo "System will now upgrade..."
bash $SCRIPTS/update.sh

# Limpeza 2
apt autoremove -y
apt autoclean
CLEARBOOT=$(dpkg -l linux-* | awk '/^ii/{ print $2}' | grep -v -e "$(uname -r | cut -f1,2 -d"-")" | grep -e "[0-9]" | xargs sudo apt -y purge)
echo "$CLEARBOOT"

ADDRESS2=$(grep "address" /etc/network/interfaces | awk '$1 == "address" { print $2 }')
# Successo!
clear
printf "%s\n""${Green}"
echo    "+--------------------------------------------------------------------+"
echo    "|      Parabens! Voce instalou o Nextcloud com sucesso!   |"
echo    "|                                                                    |"
printf "|         ${Color_Off}Entre no Nextcloud em seu navegador: ${Cyan}\"$ADDRESS2\"${Green}         |\n"
echo    "|                                                                    |"
printf "|         ${Color_Off}Publique seu servidor on-line! ${Cyan}https://goo.gl/iUGE2U${Green}          |\n"
echo    "|                                                                    |"
printf "|         ${Color_Off}Para entrar no MARIADB, basta digitar: ${Cyan}'mysql -u root'${Green}             |\n"
echo    "|                                                                    |"
printf "|   ${Color_Off}Para atualizar esta VM, basta digitar: ${Cyan}'sudo bash /var/scripts/update.sh'${Green}  |\n"
echo    "|                                                                    |"
printf "|    ${IRed}#################### Pablo Almeida - 2017 ####################${Green}    |\n"
echo    "+--------------------------------------------------------------------+"
printf "${Color_Off}\n"

# Defina o dominio confiavel em config.php
if [ -f "$SCRIPTS"/trusted.sh ] 
then
    bash "$SCRIPTS"/trusted.sh
    rm -f "$SCRIPTS"/trusted.sh
fi

# Prefere IPv6
sed -i "s|precedence ::ffff:0:0/96  100|#precedence ::ffff:0:0/96  100|g" /etc/gai.conf

# Reboot
any_key "Instalacao concluida, pressione qualquer tecla para reiniciar o sistema..."
rm -f "$SCRIPTS/nextcloud-startup-script.sh"
reboot
