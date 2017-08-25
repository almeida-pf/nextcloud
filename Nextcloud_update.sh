#! / Bin / bash
# Shellcheck disable = 2034,2059
verdade
# Shellcheck source = lib.sh
NCDB = 1 && MYCNFPW = 1 && NC_UPDATE = 1 .  <( Curl -sL https://raw.githubusercontent.com/nextcloud/vm/master/lib.sh )
unset NC_UPDATE
unset MYCNFPW
Desligar NCDB

# Tech and Me © - 2017, https://www.techandme.se/

# Verifique se há erros + código de depuração e aborta se algo não estiver certo
# 1 = ON
# 0 = DESLIGADO
DEBUG = 0
modo de depuração

PATH = / usr / local / sbin: / usr / local / bin: / usr / sbin: / usr / bin: / sbin: / bin: / snap / bin

# Coloque o nome do seu tema aqui:
THEME_NAME = " "

# Deve ser root
Se  ! Is_root
então
    Echo  " Deve ser root para executar script, no tipo Ubuntu: sudo -i "
    Saída 1
Fi

# Verifique se dpkg ou apt estão sendo executados
Is_process_running dpkg
Is_process_running apt

# Upgrade do sistema
Atualização do apt -q4 & spinner_loading
Exportar DEBIAN_FRONTEND = não interativo ; Apt dist-upgrade -y -o Dpkg :: Options :: = " --force-confdef " -o Dpkg :: Options :: = " --force-confold "

# Atualização Redis PHP extensão
Se  tipo pecl > / dev / null 2> & 1
então
    Install_if_not php7.0-dev
    Echo  " Tentando atualizar a extensão Redis Pecl ... "
    Redes de atualização do pecl
    Service apache2 reiniciar
Fi

# Atualize as imagens do docker
# Isso atualiza todas as imagens do Docker:
Se [ " $ ( docker ps -a > / dev / null 2> & 1  &&  echo sim ||  echo no ) "  ==  " sim " ]
então
Imagens do docker | Grep -v REPOSITORIA | Awk ' {print $ 1} '  | Xargs -L1 docker pull
Fi

# # OLD WAY ##
# Se ["$ (imagem docker inspecionar onlyoffice / documentserver> / dev / null 2> & 1 && echo sim || echo no)" == "sim"]
# Então
#     Echo "Atualizando o recipiente do Docker para o OnlyOffice ..."
#     Docker pull onlyoffice / documentserver
# Fi
#
# Se ["$ (imagem docker inspecionar colabora / código> / dev / null 2> & 1 && echo sim || echo no)" == "sim"]
# Então
#     Echo "Atualizando o recipiente Docker para Collabora ..."
#     Docker pull colabora / code
# Fi

# Limpeza de pacotes não utilizados
Autor eletrodo -y
Apt autoclean

# Atualize o GRUB, apenas no caso
Update-grub

# Remover listas de atualização
Rm / var / lib / apt / lists / * -r

# Defina permissões seguras
Se [ !  -f  " $ SECURE " ]
então
    Mkdir -p " $ SCRIPTS "
    Download_static_script setup_secure_permissions_nextcloud
    Chmod + x " $ SECURE "
Fi

# Versões principais não suportadas
Se [ " $ {CURRENTVERSION %% . * } "  ==  " $ NCBAD " ]
então
    eco
    Echo  " Por favor, note que as atualizações entre múltiplas versões principais não são suportadas! Sua situação é: "
    Echo  " Versão atual: $ CURRENTVERSION "
    Echo  " Última versão: $ NCVERSION "
    eco
    Echo  " É melhor manter seu servidor Nextcloud atualizado regularmente e instalar todos os lançamentos "
    Echo  " e grandes lançamentos sem ignorar nenhum deles, como saltar lançamentos aumenta o risco de "
    Echo  " . Os lançamentos principais são 9, 10, 11 e 12. As versões de pontos são lançamentos intermediários para cada "
    Echo  " . Por exemplo, 9.0.52 e 10.0.2 são lançamentos pontuais " .
    eco
    Echo  " Entre em contato com a Tech and Me para ajudá-lo na atualização entre as principais versões " .
    Echo  " https://shop.techandme.se/index.php/product-category/support/ "
    eco
    Saída 1
Fi

# Verifique se a nova versão é maior do que a versão atual instalada.
Se version_gt " $ NCVERSION "  " $ CURRENTVERSION "
então
    Echo  "O último lançamento é: $ NCVERSION . A versão atual é: $ CURRENTVERSION . "
    Printf  " $ {Green} Nova versão disponível! Upgrade continua ... $ {Color_Off} \ n "
outro
    Echo  "A versão mais recente é: $ NCVERSION . A versão atual é: $ CURRENTVERSION . "
    Echo  " Não é necessário atualizar, este script irá sair ... "
    Saia 0
Fi

# Certifique-se de que as instaces antigas também possam atualizar
Se [ !  -f  " $ MYCNF " ] && [ -f /var/mysql_password.txt]
então
Regressionpw     = $ ( cat /var/mysql_password.txt )
Gato << LOGIN >  " $ MYCNF "
[cliente]
Senha = ' $ regressionpw '
ENTRAR
    Chmod 0600 $ MYCNF
    Raiz chown: root $ MYCNF
    Echo  " Reinicie o processo de atualização, corrigimos o arquivo de senha $ MYCNF " .
    Saída 1    
Elif [ -z  " $ MARIADBMYCNFPASS " ] && [ -f /var/mysql_password.txt]
então
Regressionpw     = $ ( cat /var/mysql_password.txt )
    {
    Echo  " [cliente] "
    Echo  " password = ' $ regressionpw ' "
    } >>  " $ MYCNF "
    Echo  " Reinicie o processo de atualização, corrigimos o arquivo de senha $ MYCNF " .
    Saída 1    
Fi

Se [ -z  " $ MARIADBMYCNFPASS " ]
então
    Echo  " Algo deu errado ao copiar sua senha mysql para $ MYCNF " .
    Echo  " Nós escrevemos um guia sobre como corrigir isso. Você pode encontrar o guia aqui: "
    Echo  " https://www.techandme.se/reset-mysql-5-7-root-password/ "
    Saída 1
outro
    Rm -f /var/mysql_password.txt
Fi

# Upgrade Nextcloud
Echo  " Verificar a versão mais recente no servidor de download do Nextcloud e se for possível fazer o download ... "
Se  ! Wget -q - show-progress -T 10 -t 2 " $ NCREPO / $ STABLEVERSION .tar.bz2 "
então
    eco
    printf  " $ {iRed} Nextcloud% s não existe. $ {Color_Off} \ n "  " $ NCVERSION "
    Echo  " Verifique as versões disponíveis aqui: $ NCREPO "
    eco
    Saída 1
outro
Rm     -f " $ STABLEVERSION .tar.bz2 "
Fi

Echo  " Fazendo backup de arquivos e atualizando para Nextcloud $ NCVERSION em 10 segundos ... "
Echo  " Pressione CTRL + C para abortar. "
Durma 10

# Verifique se o backup existe e mude para o antigo
Echo  " Fazendo backup de dados ... "
DATA = $ ( data +% Y-% m-% d-% H% M% S )
Se [ -d  $ BACKUP ]
então
    Mkdir -p " / var / NCBACKUP_OLD / $ DATE "
    Mv $ BACKUP / *  " / var / NCBACKUP_OLD / $ DATE "
    Rm -R $ BACKUP
    Mkdir -p $ BACKUP
Fi

# Dados de backup
Para  pastas  em aplicativos de configuração de temas
Faz
    Se [[ " $ ( rsync -Aax $ NCPATH / $ folders  $ BACKUP ) "  -eq 0]]
    então
        BACKUP_OK = 1
    outro
        unset BACKUP_OK
    Fi
feito

Se [ -z  $ BACKUP_OK ]
então
    Echo  "O backup não estava OK. Verifique $ BACKUP e veja se as pastas são copiadas de forma adequada "
    Saída 1
outro
    Printf  " $ {Green} \ nBackup OK! $ {Color_Off} \ n "
Fi

# Backup MARIADB
Se mysql -u raiz -p " $ MARIADBMYCNFPASS " -e " MOSTRAR bases de dados como ' $ NCCONFIGDB ' "  > / dev / null
então
    Echo  " Fazendo mysqldump de $ NCCONFIGDB ... "
    Check_command mysqldump -u root -p " $ MARIADBMYCNFPASS " -d " $ NCCONFIGDB "  >  " $ BACKUP " /nextclouddb.sql
outro
    Echo  " Fazendo mysqldump de todos os bancos de dados ... "
    Check_command mysqldump -u root -p " $ MARIADBMYCNFPASS " -d - todas-bases de dados >  " $ BACKUP " /alldatabases.sql
Fi

# Faça o download e valide o pacote Nextcloud
Check_command download_verify_nextcloud_stable

Se [ -f  " $ HTML / $ STABLEVERSION .tar.bz2 " ]
então
    Echo  " $ HTML / $ STABLEVERSION .tar.bz2 existe "
outro
    Echo  " Abortando, algo deu errado com o download "
    Saída 1
Fi

Se [ -d  $ BACKUP / config /]
então
    Echo  " $ BACKUP / config / exists "
outro
    Echo  " Algo deu errado ao fazer backup de sua antiga instância do nextcloud, por favor verifique $ BACKUP se a configuração / pasta existir. "
    Saída 1
Fi

Se [ -d  $ BACKUP / apps /]
então
    Echo  " $ BACKUP / apps / exists "
outro
    Echo  " Algo deu errado ao fazer backup de sua antiga instância próxima à próxima, verifique $ BACKUP se existem apps / pasta " .
    Saída 1
Fi

Se [ -d  $ BACKUP / themes /]
então
    Echo  " $ BACKUP / themes / exists "
    eco 
    Printf  " $ {Green} Todos os arquivos são copiados. $ {Color_Off} \ n "
    Sudo -u www-data php " $ NCPATH " / occ manutenção: modo - em
    Echo  " Removendo a instância antiga Nextcloud em 5 segundos ... "  && sleep 5
Rm     -rf $ NCPATH
    Tar -xjf " $ HTML / $ STABLEVERSION .tar.bz2 " -C " $ HTML "
    rm " $ HTML / $ STABLEVERSION .tar.bz2 "
    Cp -R $ BACKUP / themes " $ NCPATH " /
    Cp -R $ BACKUP / config " $ NCPATH " /
    festa $ SEGURO  & spinner_loading
    Sudo -u www-data php " $ NCPATH " / occ manutenção: modo - off
    Sudo -u www-data php " $ NCPATH " / occ upgrade --no-app-disable
outro
    Echo  " Algo deu errado ao fazer backup de sua antiga instância próxima à próxima, verifique $ BACKUP se as pastas existem. "
    Saída 1
Fi

# Recuperar aplicativos que existem na pasta de aplicativos de backup
# Run_static_script recover_apps

# Habilitar aplicativos
Se [ -d  " $ SNAPDIR " ]
então
    Run_app_script spreedme
Fi

# Alterar o proprietário da pasta $ BACKUP para a raiz
Chown -R raiz: root " $ BACKUP "

# Defina o carregamento máximo em Nextcloud .htaccess
Configure_max_upload

# Define $ THEME_NAME
VALUE2 = " $ THEME_NAME "
Se  ! Grep -Fxq " $ VALUE2 "  " $ NCPATH /config/config.php "
então
    Sed -i " s | 'theme' => '', | 'tema' => ' $ THEME_NAME ', | g "  " $ NCPATH " /config/config.php
    Echo  " Conjunto de temas "
Fi

# URLs bonitos
Echo  " Definir RewriteBase para \" / \ " em config.php ... "
Chown -R www-data: www-data " $ NCPATH "
Sudo -u www-data php " $ NCPATH " / occ config: system: configure htaccess.RewriteBase --value = " / "
Sudo -u www-data php " $ NCPATH " / occ manutenção: atualização: htaccess
Bash " $ SECURE "

# Reparação
Sudo -u www-data php " $ NCPATH " / occ manutenção: reparo

CURRENTVERSION_after = $ ( sudo -u www-data php " $ NCPATH " / occ status | grep " versionstring "  | awk ' {print $ 3} ' )
Se [[ " $ NCVERSION "  ==  " $ CURRENTVERSION_after " ]]
então
    eco
    Echo  "A versão mais recente é: $ NCVERSION . A versão atual é: $ CURRENTVERSION_after . "
    Echo  " ACTUALIZAÇÃO SUCESSO! "
    Echo  " NEXTCLOUD UPDATE sucesso- $ ( data + " % Y% m% d " ) "  >> /var/log/cronjobs_success.log
    Sudo -u www-data php " $ NCPATH " / status occ
    Sudo -u www-data php " $ NCPATH " / occ manutenção: modo - off
    eco
    Eco  " Se você notar que alguns aplicativos estão desativados, é devido a que eles não são compatíveis com a nova versão Nextcloud. "
    Echo  " Para recuperar seus aplicativos antigos, verifique $ BACKUP / apps e copie-os para $ NCPATH / apps manualmente. "
    eco
    Eco  " Obrigado por usar o atualizador da Tech and Me! "
    # # Un-hash this se você quiser que o sistema seja reiniciado
    # Reinicialização
    Saia 0
outro
    eco
    Echo  "A versão mais recente é: $ NCVERSION . A versão atual é: $ CURRENTVERSION_after . "
    Sudo -u www-data php " $ NCPATH " / status occ
    Echo  " UPGRADE FAILED! "
    Echo  " Seus arquivos ainda estão com backup em $ BACKUP . Não há preocupações! "
    Echo  " Informe esta questão para $ QUESTÕES "
    Saída 1
Fi