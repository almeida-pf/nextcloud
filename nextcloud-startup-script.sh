#! / Bin / bash
# Shellcheck disable = 2034,2059
verdade
# Shellcheck source = lib.sh
FIRST_IFACE = 1 && CHECK_CURRENT_REPO = 1 .  <( Curl -sL https://raw.githubusercontent.com/nextcloud/vm/master/lib.sh )
unset FIRST_IFACE
unset CHECK_CURRENT_REPO

# Tech and Me © - 2017, https://www.techandme.se/

# # Se desejar o modo de depuração, ative-o mais para baixo no código na linha ~ 60

Is_root () {
    Se [[ " $ EUID " -  um 0]]
    então
        Retornar 1
    outro
        Retornar 0
    Fi
}

Network_ok () {
    Echo  " Testando se a rede está correta ... "
    Reiniciar o serviço de rede
    Se wget -q -T 20 -t 2 http://github.com -O / dev / null
    então
        Retornar 0
    outro
        Retornar 1
    Fi
}

# Verifique se a raiz
Se  ! Is_root
então
    Printf  " \ n $ {Red} Desculpe, você não é root. \ N $ {Color_Off} Você deve digitar: $ {Cyan} sudo $ {Color_Off} bash $ SCRIPTS /nextcloud-startup-script.sh\n "
    Saída 1
Fi

# Verificar rede
Se network_ok
então
    Printf  " $ {Green} Online! $ {Color_Off} \ n "
outro
    Echo  " Configuração da interface correta ... "
    [ -z  " $ IFACE " ] && IFACE = $ ( lshw -c rede | grep " nome lógico "  | awk ' {print $ 3; exit} ' )
    # Definir interface correta
    {
        Sed ' / # A principal interface de rede / q ' / etc / network / interfaces
        Printf  ' auto% s \ niface% s inet dhcp \ n # Esta é uma interface IPv6 autoconfigurada \ niface% s inet6 auto \ n '  " $ IFACE "  " $ IFACE "  " $ IFACE "
    } > /etc/network/interfaces.new
    Mv /etc/network/interfaces.new / etc / network / interfaces
    Reiniciar o serviço de rede
    # Shellcheck source = lib.sh
    CHECK_CURRENT_REPO = 1 .  <( Curl -sL https://raw.githubusercontent.com/nextcloud/vm/master/lib.sh )
    unset CHECK_CURRENT_REPO
Fi

# Verifique se há erros + código de depuração e aborta se algo não estiver certo
# 1 = ON
# 0 = DESLIGADO
DEBUG = 0
modo de depuração

# Verificar rede
Se network_ok
então
    Printf  " $ {Green} Online! $ {Color_Off} \ n "
outro
    printf  " \ nNetwork NÃO OK. É necessário ter uma conexão de rede para executar este script. \ n "
    Echo  " Por favor relate este problema aqui: $ ISSUES "
    Saída 1
Fi

# Verifique se dpkg ou apt estão sendo executados
Is_process_running dpkg
Is_process_running apt

# Verifique onde estão os melhores espelhos e atualize
Printf  " \ nPara fazer downloads o mais rápido possível ao atualizar você deve ter espelhos o mais próximo possível de você. \ N "
Echo  " Esta VM vem com espelhos com base em servidores naquela onde usado quando a VM foi lançada e embalada " .
Echo  " Recomendamos que você mude os espelhos com base em onde este está instalado atualmente " .
Echo  " Verificando o espelho atual ... "
Printf  " Seu repositório de servidor atual é:   $ {Ciano} $ REPO $ {Color_Off} \ n "

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

eco
Echo  " Obtendo scripts do GitHub para poder executar a primeira configuração ... "
# Todos os scripts de shell em static (.sh)
Download_static_script provisionamento temporário
Download_static_script security
Atualização download_static_script
Download_static_script confiado
Download_static_script ip
Download_static_script test_connection
Download_static_script setup_secure_permissions_nextcloud
Download_static_script change_mysql_pass
Download_static_script nextcloud
Download_static_script update-config
Índice download_static_script
Download_le_script activate-ssl

Mv $ SCRIPTS /index.php $ HTML /index.php && rm -f $ HTML /html/index.html
Chmod 750 $ HTML /index.php && chown www-data: www-data $ HTML /index.php

# Alterar 000-default para $ WEB_ROOT
Sed -i " s | DocumentRoot / var / www / html | DocumentRoot $ HTML | g " /etc/apache2/sites-available/000-default.conf

# Faça $ SCRIPTS excutable
Chmod + x -R $ SCRIPTS
Raiz chown: root -R $ SCRIPTS

# Permitir $ UNIXUSER para executar o script figlet
chown " $ UNIXUSER " : " $ UNIXUSER "  " $ SCRIPTS /nextcloud.sh "

Claro
Eco  " + ----------------------------------------------- --------------------- + "
Echo  " | Este script irá configurar o Nextcloud e ativar o SSL. "
Echo  " | Ele também fará o seguinte: "
echo  " | | "
Echo  " | - Gerar novas chaves SSH para o servidor | "
Echo  " | - Gerar nova senha do MARIADB | "
Echo  " | - Instalar phpMyadmin e torná-lo seguro | "
Echo  " | - Instale aplicativos selecionados e configure-os automaticamente | "
Echo  " | - Detectar e definir o nome do host | "
Echo  " | - Atualize seu sistema e Nextcloud para a versão mais recente | "
Echo  " | - Defina permissões seguras para Nextcloud | "
echo  " | - Definir novas senhas para Linux e Nextcloud | "
Echo  " | - Definir novo layout de teclado | "
Echo  " | - Alterar fuso horário | "
Echo  " | - Estabeleça IP estático para o sistema (você deve configurar o mesmo IP em | "
Echo  " | seu roteador) https://www.techandme.se/open-port-80-443/ | "
Echo  " | Não estabelecemos IP estático se você executar isso em um * VPS remoto *. "
echo  " | | "
Echo  " | O script demorará cerca de 10 minutos para terminar, | "
Echo  " dependendo da sua conexão com a internet. "
echo  " | | "
Echo  " | ####################### Tech and Me - 2017 ################### #### | "
Eco  " + ----------------------------------------------- --------------------- + "
Any_key " Pressione qualquer tecla para iniciar o script ... "
Claro

# VPS?
Se [[ " não "  ==  $ ( ask_yes_or_no " Você executa este script em um * remoto * VPS como DigitalOcean, HostGator ou similar? " ) ]]
então
    # Alterar IP
    Printf  " \ n $ {Color_Off} OK, assumimos que você executou isso localmente e agora configuraremos seu IP para ser estático. $ {Color_Off} \ n "
    Echo  " Seu IP interno é: $ ADDRESS "
    Printf  " \ n $ {Color_Off} Escreva isso para baixo, você precisará dele para configurar o IP estático \ n "
    Echo  " no seu roteador mais tarde. Está incluído neste guia: "
    Echo  " https://www.techandme.se/open-port-80-443/ (passo 1 - 5) "
    Any_key " Pressione qualquer tecla para configurar IP estático ... "
    Ifdown " $ IFACE "
    esperar
    Se " $ IFACE "
    esperar
    festança " $ SCRIPTS /ip.sh "
    Se [ -z  " $ IFACE " ]
    então
        Echo  "O IFACE é um valor imenso. Tentando definir o IFACE com outro método ... "
        Download_static_script ip2
        festança " $ SCRIPTS /ip2.sh "
Rm         -f " $ SCRIPTS /ip2.sh "
    Fi
    Ifdown " $ IFACE "
    esperar
    Se " $ IFACE "
    esperar
    eco
    Echo  " Testando se a rede está correta ... "
    eco
    CONTEST = $ ( bash $ SCRIPTS /test_connection.sh )
    Se [ " $ CONTEST "  ==  " Conectado! " ]
    então
        # Conectado!
        Printf  " $ {Green} Conectado! $ {Color_Off} \ n "
        Printf  " Usaremos o DHCP IP: $ {Green} $ ADDRESS $ {Color_Off} . Se você quiser alterá-lo mais tarde, basta editar o arquivo de interfaces: \ n "
        Printf  " sudo nano / etc / network / interfaces \ n "
        Echo  " Se você tiver algum erro, informe-o aqui: "
        Echo  " $ ISSUES "
        Any_key " Pressione qualquer tecla para continuar ... "
    outro
        # Não conectado!
        Printf  " $ {Red} Não conectado $ {Color_Off} \ nVocê deve alterar suas configurações manualmente na próxima etapa. \ N "
        Any_key " Pressione qualquer tecla para abrir / etc / network / interfaces ... "
        Nano / etc / network / interfaces
        Reiniciar o serviço de rede
        Claro
        Echo  " Testando se a rede está correta ... "
        Ifdown " $ IFACE "
        esperar
        Se " $ IFACE "
        esperar
        festança " $ SCRIPTS /test_connection.sh "
        esperar
    Fi
outro
    Echo  " OK, então não vamos definir um IP estático, pois seu provedor VPS já configurou a rede para você ... "
    Durma 5 & spinner_loading
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

# URLs bonitos
Echo  " Definir RewriteBase para \" / \ " em config.php ... "
Chown -R www-data: www-data $ NCPATH
Sudo -u www-data php $ NCPATH / occ config: system: set htaccess.RewriteBase --value = " / "
Sudo -u www-data php $ NCPATH / occ manutenção: atualização: htaccess
festa $ SEGURO  & spinner_loading

# Gere novas chaves SSH
printf  " \ nGenerating novas chaves SSH para o servidor ... \ n "
Rm -v / etc / ssh / ssh_host_ *
Dpkg-reconfigure openssh-server

# Gerar nova senha MARIADB
Echo  " Gerando nova senha MARIADB ... "
Se bash " $ SCRIPTS /change_mysql_pass.sh "  &&  wait
então
    rm " $ SCRIPTS /change_mysql_pass.sh "
Fi

Gato << LETSENC
+ ----------------------------------------------- +
|   O script a seguir irá instalar uma lista confiável   |
|   Certificado SSL através de Let ' s Criptografar. |
+ ----------------------------------------------- +
LETSENC
# Let ' s Criptografar
Se [[ " sim "  ==  $ ( ask_yes_or_no " Você deseja instalar o SSL? " ) ]]
então
    festa $ SCRIPTS /activate-ssl.sh
outro
    eco
    Echo  " OK, mas se você quiser executá-lo mais tarde, basta digitar: sudo bash $ SCRIPTS /activate-ssl.sh "
    Any_key " Pressione qualquer tecla para continuar ... "
Fi
Claro

# Change Timezone
Echo  " O fuso horário atual é $ ( cat / etc / timezone ) "
Echo  " Você deve mudá-lo para sua zona horária "
Any_key " Pressione qualquer tecla para alterar o fuso horário ... "
Dpkg-reconfigure tzdata
Durma 3
Claro

Whiptail --title " Quais aplicativos você deseja instalar? " --checklist - separate-output " Configure e instale automaticamente aplicativos selecionados \ nSelecione pressionando a barra espaciadora "  " $ WT_HEIGHT "  " $ WT_WIDTH " 4 \
" Fail2ban "  " (proteção Extra Bruteforce)    " OFF \
" PhpMyadmin "  " (* SQL GUI)        " OFF \
" Collabora "  " (edição online de 2GB de RAM)    " OFF \
" OnlyOffice "  " (edição online 4GB RAM)    " OFF \
" Nextant "  " (pesquisa de texto completo)    " OFF \
" Passman "  " (armazenamento de senha)    " OFF \
" Spreed.ME "  " (chamadas de vídeo)    " OFF 2> resultados

Enquanto  lê -r -u 9 escolha
Faz
    Caso  $ escolha  em
        Fail2ban)
            Run_app_script fail2ban
            
        ;;
        PhpMyadmin)
            Run_app_script phpmyadmin_install_ubuntu16
        ;;
        
        OnlyOffice)
            Office_app_script onlyoffice
        ;;
        
        Collabora)
            Run_app_script collabora
        ;;

        Nextant)
            Run_app_script nextant
        ;;

        Passman)
            Run_app_script passman
        ;;

        Spreed.ME)
            Run_app_script spreedme
        ;;

        * )
        ;;
    Esac
Feito  9 resultados
Resultados rm -f
Claro
Claro

# Adicionar segurança adicional
Se [[ " sim "  ==  $ ( ask_yes_or_no " Você deseja adicionar segurança adicional, com base nisso: http://goo.gl/gEJHi7? " ) ]]
então
    festa $ SCRIPTS /security.sh
    rm " $ SCRIPTS " /security.sh
outro
    eco
    Echo  " OK, mas se você quiser executá-lo mais tarde, basta digitar: sudo bash $ SCRIPTS /security.sh "
    Any_key " Pressione qualquer tecla para continuar ... "
Fi
Claro

# Alterar senha
printf  " $ {Color_Off} \ n "
Echo  " Para uma melhor segurança, altere a senha do usuário do sistema para [ $ UNIXUSER ] "
Any_key " Pressione qualquer tecla para alterar a senha para o usuário do sistema ... "
Enquanto  verdadeiro
Faz
Sudo     passwd " $ UNIXUSER "  &&  break
feito
eco
Claro
NCADMIN = $ ( sudo -u www-data php $ NCPATH / occ user: list | awk ' {print $ 3} ' )
printf  " $ {Color_Off} \ n "
Echo  " Para uma melhor segurança, altere a senha do Nextcloud para [ $ NCADMIN ] "
Echo  " A senha atual para $ NCADMIN é [ $ NCPASS ] "
Any_key " Pressione qualquer tecla para alterar a senha do Nextcloud ... "
Enquanto  verdadeiro
Faz
    Sudo -u www-data php " $ NCPATH / occ " usuário: resetpassword " $ NCADMIN "  &&  break
feito
Claro

# Fixes https://github.com/nextcloud/vm/issues/58
A2dismod status
Serviço apache2 recarregar

# Aumentar o tamanho máximo do arquivo (espera que as alterações sejam feitas em /etc/php/7.0/apache2/php.ini)
# Aqui está um guia: https://www.techandme.se/increase-max-file-size/
VALUE = " # php_value upload_max_filesize 513M "
Se  ! Grep -Fxq " $ VALUE "  $ NCPATH /.htaccess
então
    Sed -i ' s / php_value upload_max_filesize 513M / # php_value upload_max_filesize 511M / g '  " $ NCPATH " /.htaccess
    sed -i ' s / php_value post_max_size 513m / # php_value post_max_size 511M / g '  " $ NCPATH " /.htaccess
    Sed -i ' s / php_value memory_limit 512M / # php_value memory_limit 512M / g '  " $ NCPATH " /.htaccess
Fi

# Adicione correção temporária, se necessário
festa $ SCRIPTS /temporary-fix.sh
rm " $ SCRIPTS " /temporary-fix.sh

# Limpeza 1
Sudo -u www-data php " $ NCPATH / occ " manutenção: reparo
Rm -f " $ SCRIPTS /ip.sh "
Rm -f " $ SCRIPTS /test_connection.sh "
Rm -f " $ SCRIPTS /instruction.sh "
Rm -f " $ NCDATA /nextcloud.log "
Rm -f " $ SCRIPTS /nextcloud-startup-script.sh "
Encontrar / root " / home / $ UNIXUSER " - tipo f \ ( -name ' * .sh * ' -o -name ' * .html * ' -o -name ' * .tar * ' -o -name ' *. Zip * '  \) -delete
Sed -i " s | instruction.sh | nextcloud.sh | g "  " / home / $ UNIXUSER /.bash_profile "

Truncar -s 0 \
    /root/.bash_history \
    " / Home / $ UNIXUSER /.bash_history " \
    / Var / spool / mail / root \
    " / Var / spool / mail / $ UNIXUSER " \
    /var/log/apache2/access.log \
    /var/log/apache2/error.log \
    /var/log/cronjobs_success.log

Sed -i " s | sudo -i || g "  " / home / $ UNIXUSER /.bash_profile "
Gato << RCLOCAL >  " /etc/rc.local "
#! / Bin / sh -e
#
# Rc.local
#
# Esse script é executado no final de cada nível de execução multiusuário.
# Certifique-se de que o script "sairá 0" com sucesso ou qualquer outro
# Valor em erro.
#
# Para ativar ou desativar este script, basta alterar a execução
# Bits.
#
# Por padrão, este script não faz nada.

Saia 0

RCLOCAL
Claro

# Sistema de atualização
Echo  "O sistema agora atualizará ... "
festa $ SCRIPTS /update.sh

# Limpeza 2
Autor eletrodo -y
Apt autoclean
CLEARBOOT = $ ( dpkg -l linux- *  | awk ' / ^ ii / {print $ 2} '  | grep -v -e " $ ( uname -r | cut -f1,2 -d " - " ) "  | grep - E " [0-9] "  | xargs sudo apt -y purge )
Echo  " $ CLEARBOOT "

ADDRESS2 = $ ( grep " endereço " / etc / network / interfaces | awk ' $ 1 == "endereço" {print $ 2} ' )
# Sucesso!
Claro
Printf  " % s \ n " " $ {Green} "
Eco     " + ----------------------------------------------- --------------------- + "
Echo     " | Parabéns! Você instalou o Nextcloud com sucesso! "
echo     " | | "
Printf  " |          $ {Color_Off} Entre no Nextcloud em seu navegador: $ {Cyan} \" $ ADDRESS2 \ " $ {Green}          | \ n "
echo     " | | "
Printf  " |          $ {Color_Off} Publique seu servidor online! $ {Cyan} https://goo.gl/iUGE2U $ {Green}           | \ n "
echo     " | | "
Printf  " |          $ {Color_Off} Para entrar no MARIADB, basta digitar: $ {Cyan} 'mysql -u root' $ {Green}              | \ n "
echo     " | | "
Printf  " |    $ {Color_Off} Para atualizar esta VM, basta digitar: $ {Cyan} 'sudo bash /var/scripts/update.sh' $ {Green}   | \ n "
echo     " | | "
Printf  " |     $ {IRed} #################### Tech and Me - 2017 ################## ## $ {Green}     | \ n "
Eco     " + ----------------------------------------------- --------------------- + "
printf  " $ {Color_Off} \ n "

# Defina o domínio confiável no config.php
Se [ -f  " $ SCRIPTS " /trusted.sh]
então
    festa " $ SCRIPTS " /trusted.sh
Rm     -f " $ SCRIPTS " /trusted.sh
Fi

# Prefira o IPv6
Sed -i " s | precedence :: ffff: 0: 0/96 100 | #precedence :: ffff: 0: 0/96 100 | g " /etc/gai.conf

# Reiniciar
Any_key " Instalação concluída, pressione qualquer tecla para reiniciar o sistema ... "
Rm -f " $ SCRIPTS /nextcloud-startup-script.sh "
Reiniciar