#! / Bin / bash
# Shellcheck disable = 2034,2059
verdade
# Veja https://github.com/koalaman/shellcheck/wiki/Directive

# # Variáveis

# Dirs
SCRIPTS = / var / scripts
NCPATH = / var / www / nextcloud
HTML = / var / www
NCDATA = / var / ncdata
SNAPDIR = / var / snap / spreedme
GPGDIR = / tmp / gpg
BACKUP = / var / NCBACKUP
# Ubuntu OS
DISTRO = $ ( lsb_release -sd | cut -d '  ' -f 2 )
OS = $ ( grep -ic " Ubuntu " /etc/issue.net )
# Rede
[ !  -z  " $ FIRST_IFACE " ] && IFACE = $ ( lshw -c rede | grep " nome lógico "  | awk ' {print $ 3; exit} ' )
IFACE2 = $ ( ip -o link show | awk ' {print $ 2, $ 9} '  | grep ' UP '  | cut -d ' : ' -f 1 )
[ !  -z  " $ CHECK_CURRENT_REPO " ] && REPO = $ ( apt-get update | grep -m 1 Hit | awk ' {print $ 2} ' )
ADDRESS = $ ( nome do host -I | cut -d '  ' -f 1 )
WGET = " / usr / bin / wget "
# WANIP4 = $ (dig + short myip.opendns.com @ resolver1.opendns.com) # como alternativa
WANIP4 = $ ( curl -s -m 5 ipinfo.io/ip )
[ !  -z  " $ LOAD_IP6 " ] && WANIP6 = $ ( curl -s -k -m 7 https://6.ifcfg.me )
IFCONFIG = " / sbin / ifconfig "
INTERFACES = " / etc / network / interfaces "
NETMASK = $ ( $ IFCONFIG  | grep -w inet | grep -v 127.0.0.1 | awk ' {print $ 4} '  | cut -d " : " -f 2 )
GATEWAY = $ ( rota -n | grep " UG " | grep -v " UGH " | cut -f 10 -d "  " )
# Repo
GITHUB_REPO = " https://raw.githubusercontent.com/nextcloud/vm/master "
STATIC = " $ GITHUB_REPO / static "
LETS_ENC = " $ GITHUB_REPO / lets-encrypt "
APP = " $ GITHUB_REPO / apps "
NCREPO = " https://download.nextcloud.com/server/releases "
ISSUES = " https://github.com/nextcloud/vm/issues "
# Informações do usuário
NCPASS = nextcloud
NCUSER = ncadmin
UNIXUSER = $ SUDO_USER
UNIXUSER_PROFILE = " / home / $ UNIXUSER /.bash_profile "
ROOT_PROFILE = " /root/.bash_profile "
# MARIADB
SHUF = $ ( shuf -i 25-29 -n 1 )
MARIADB_PASS = $ ( tr -dc " a-zA-Z0-9 @ # * = "  < / dev / urandom | fold -w " $ SHUF "  | head -n 1 )
NEWMARIADBPASS = $ ( tr -dc " a-zA-Z0-9 @ # * = "  < / dev / urandom | fold -w " $ SHUF "  | head -n 1 )
[ !  -z  " $ NCDB " ] && NCCONFIGDB = $ ( grep " dbname "  $ NCPATH /config/config.php | awk ' {print $ 3} '  | sed ' s / [',] // g " )
ETCMYCNF = / etc / mysql / my.cnf
MYCNF = / root / .my.cnf
[ !  -z  " $ MYCNFPW " ] && MARIADBMYCNFPASS = $ ( grep " senha "  $ MYCNF  | sed -n " /password/s/^password='\(.*\)'$/\1/p " )
[ !  -z  " $ NCDB " ] && NCCONFIGDB = $ ( grep " dbname "  $ NCPATH /config/config.php | awk ' {print $ 3} '  | sed ' s / [',] // g " )
[ !  -z  " $ NCDBPASS " ] && NCCONFIGDBPASS = $ ( grep " dbpassword "  $ NCPATH /config/config.php | awk ' {print $ 3} '  | sed ' s / [',] // g " )
# Caminho para arquivos específicos
PHPMYADMIN_CONF = " /etc/apache2/conf-available/phpmyadmin.conf "
SECURE = " $ SCRIPTS /setup_secure_permissions_nextcloud.sh "
SSL_CONF = " /etc/apache2/sites-available/nextcloud_ssl_domain_self_signed.conf "
HTTP_CONF = " /etc/apache2/sites-available/nextcloud_http_domain_self_signed.conf "
# Próxima versão em segundo plano
[ !  -z  " $ NC_UPDATE " ] && CURRENTVERSION = $ ( sudo -u www-data php $ NCPATH / estado occ | grep " versionstring "  | awk ' {print $ 3} ' )
NCVERSION = $ ( curl -s -m 900 $ NCREPO / | sed --silent ' s /.* href = "nextcloud - \ ([^"] \ + \). Zip.asc ". * / \ 1 / p '  | Sort --version-sort | tail -1 )
STABLEVERSION = " nextcloud- $ NCVERSION "
NCMAJOR = " $ {NCVERSION %% . * } "
NCBAD = $ (( NCMAJOR - 2 ))
# Chaves
OpenPGP_fingerprint = ' 28806A878AE423A28372792ED75899B9A724937A '
# URL do OnlyOffice
[ !  -z  " $ OO_INSTALL " ] && SUBDOMAIN = $ ( whiptail --title " Techandme.se OnlyOffice " --inputbox " Apenas  subdominio de escritório, por exemplo: office.yourdomain.com " " $ WT_HEIGHT "  " $ WT_WIDTH "  3> & 1  1> & 2  2> & 3 )
# Nextcloud Domínio principal
[ !  -z  " $ OO_INSTALL " ] && NCDOMAIN = $ ( whiptail --title " Techandme.se OnlyOffice " --inputbox " Nextcloud url, verifique se ele está assim: nuvem \\. Seu domínio \\ .com "  " $ WT_HEIGHT "  " $ WT_WIDTH " nuvem \\. Seu domínio \\ .com 3> & 1  1> & 2  2> & 3 )
# Collabora Docker URL
[ !  -z  " $ COLLABORA_INSTALL " ] && SUBDOMAIN = $ ( whiptail --title " Techandme.se Collabora " --inputbox " Subdomínio Collabora, por exemplo: office.yourdomain.com "  " $ WT_HEIGHT "  " $ WT_WIDTH "  3> & 1  1> & 2  2> & 3 )
# Nextcloud Domínio principal
[ !  -z  " $ COLLABORA_INSTALL " ] && NCDOMAIN = $ ( whiptail --title " Techandme.se Collabora " --inputbox " Nextcloud url, verifique se ele está assim: nuvem \\. Seu domínio \\ .com "  " $ WT_HEIGHT "  " $ WT_WIDTH " nuvem \\. Seu domínio \\ .com 3> & 1  1> & 2  2> & 3 )
# Letsencrypt
LETSENCRYPTPATH ​​= " / etc / letsencrypt "
CERTFILES = " $ LETSENCRYPTPATH / live "
DHPARAMS = " $ CERTFILES / $ SUBDOMAIN /dhparam.pem "
# Collabora App
[ !  -z  " $ COLLABORA_INSTALL " ] && COLLVER = $ ( curl -s https://api.github.com/repos/nextcloud/richdocuments/releases/latest | grep " tag_name "  | cut -d \ " -f4 )
COLLVER_FILE = richdocuments.tar.gz
COLLVER_REPO = https: //github.com/nextcloud/richdocuments/releases/download
HTTPS_CONF = " / etc / apache2 / sites-available / $ SUBDOMAIN .conf "
# Nextant
SOLR_VERSION = $ ( curl -s https://github.com/apache/lucene-solr/tags | grep -o " . * </ Span> $ "  | grep -o ' [0-9]. [0- 9]. [0-9] '  | class -t. -k1,1n -k2,2n -k3,3n | tail -n1 )
[ !  -z  " $ NEXTANT_INSTALL " ] && NEXTANT_VERSION = $ ( curl -s https://api.github.com/repos/nextcloud/nextant/releases/latest | grep ' tag_name '  | cut -d \ " -f4 | sed - E " s | v || g " )
NT_RELEASE = nextant- $ NEXTANT_VERSION .tar.gz
NT_DL = https: //github.com/nextcloud/nextant/releases/download/v $ NEXTANT_VERSION / $ NT_RELEASE
SOLR_RELEASE = solr- $ SOLR_VERSION .tgz
SOLR_DL = http: //www-eu.apache.org/dist/lucene/solr/ $ SOLR_VERSION / $ SOLR_RELEASE
NC_APPS_PATH = $ NCPATH / apps /
SOLR_HOME = / home / $ SUDO_USER / solr_install /
SOLR_JETTY = / opt / solr / server / etc / jetty-http.xml
SOLR_DSCONF = / opt / solr- $ SOLR_VERSION /server/solr/configsets/data_driven_schema_configs/conf/solrconfig.xml
# Passman
[ !  -z  " $ PASSMAN_INSTALL " ] && PASSVER = $ ( curl -s https://api.github.com/repos/nextcloud/passman/releases/latest | grep " tag_name "  | cut -d \ " -f4 )
PASSVER_FILE = passman_ $ PASSVER .tar.gz
PASSVER_REPO = https: //releases.passman.cc
SHA256 = / tmp / sha256
# Preview Generator
[ !  -z  " $ PREVIEW_INSTALL " ] && PREVER = $ ( curl -s https://api.github.com/repos/rullzer/previewgenerator/releases/latest | grep " tag_name "  | cut -d \ " -f4 | sed - E " s | v || g " )
PREVER_FILE = previewgenerator.tar.gz
PREVER_REPO = https: //github.com/rullzer/previewgenerator/releases/download
# Calendário
[ !  -z  " $ CALENDAR_INSTALL " ] && CALVER = $ ( curl -s https://api.github.com/repos/nextcloud/calendar/releases/latest | grep " tag_name "  | cut -d \ " -f4 | sed - E " s | v || g " )
CALVER_FILE = calendar.tar.gz
CALVER_REPO = https: //github.com/nextcloud/calendar/releases/download
# Contatos
[ !  -z  " $ CONTACTS_INSTALL " ] && CONVER = $ ( curl -s https://api.github.com/repos/nextcloud/contacts/releases/latest | grep " tag_name "  | cut -d \ " -f4 | sed - E " s | v || g " )
CONVER_FILE = contatos.tar.gz
CONVER_REPO = https: //github.com/nextcloud/contacts/releases/download
# Spreed.ME
SPREEDME_VER = $ ( wget -q https://raw.githubusercontent.com/strukturag/nextcloud-spreedme/master/appinfo/info.xml && grep -Po " (? <= <Versão>) [^ <] * (? = </ Version>) " info.xml && rm info.xml )
SPREEDME_FILE = " v $ SPREEDME_VER .tar.gz "
SPREEDME_REPO = https: //github.com/strukturag/nextcloud-spreedme/archive
# PhpMyadmin
PHPMYADMINDIR = / usr / share / phpmyadmin
PHPMYADMIN_CONF = " /etc/apache2/conf-available/phpmyadmin.conf "
UPLOADPATH = " "
SAVEPATH = " "
# Redis
REDIS_CONF = / etc / redis / redis.conf
REDIS_SOCK = / var / run / redis / redis.sock
RSHUF = $ ( shuf -i 30-35 -n 1 )
REDIS_PASS = $ ( tr -dc " a-zA-Z0-9 @ # * = "  < / dev / urandom | fold -w " $ RSHUF "  | head -n 1 )
# Segurança extra
SPAMHAUS = / etc / spamhaus.wl
ENVASIVE = / etc / apache2 / mods-available / mod-evasive.load
APACHE2 = / etc / apache2 / apache2.conf

# # Funções

# Se o script está sendo executado como root?
#
# Exemplo:
# Se is_root
# Então
#      # Faça coisas
# Else
#      Echo "Você não é root ..."
#      Saída 1
# Fi
#
Is_root () {
    Se [[ " $ EUID " -  um 0]]
    então
        Retornar 1
    outro
        Retornar 0
    Fi
}

Debug_mode () {
Se [ " $ DEBUG "  -eq 1]
então
    Set -ex
Fi
}

Ask_yes_or_no () {
    Leia -r -p " $ 1 ([y] es ou [N] o): "
    Case  $ {REPLY ,,}  em
        Y | sim)
            Echo  " sim "
        ;;
        * )
            Ecoa  " não "
        ;;
    Esac
}

# Verifique se o processo é executado: is_process_running dpkg
Is_process_running () {
PROCESS = " $ 1 "

Enquanto  :
Faz
    RESULT = $ ( pgrep " $ {PROCESS} " )

    Se [ " $ {RESULT : - null} "  = null] ;  então
            pausa
    outro
            Echo  " $ {PROCESS} está em execução. Esperando que ele pare ... "
            Durma 10
    Fi
feito
}

# Instale certbot (vamos criptografar)
Install_certbot () {
Certbot --version 2> / dev / null
LE_IS_AVAILABLE = $?
Se [ $ LE_IS_AVAILABLE  -eq 0]
então
    Certbot --versão
outro
    Echo  " Instalando certbot (Vamos criptografar) ... "
    Atualização do apt -q4 & spinner_loading
    Instalar software-propriedades-comum
    Add-apt-repository ppa: certbot / certbot -y
    Atualização do apt -q4 & spinner_loading
    Instale certbot -y -q
    Atualização do apt -q4 & spinner_loading
    Apt dist-upgrade -y
Fi
}

Configure_max_upload () {
# Aumentar o tamanho máximo do arquivo (espera que as alterações sejam feitas em /etc/php/7.0/apache2/php.ini)
# Aqui está um guia: https://www.techandme.se/increase-max-file-size/
Sed -i ' s / php_value upload_max_filesize. * / # Php_value upload_max_filesize 511M / g '  " $ NCPATH " /.htaccess
Sed -i ' s / php_value post_max_size. * / # Php_value post_max_size 511M / g '  " $ NCPATH " /.htaccess
Sed -i ' s / php_value memory_limit. * / # Php_value memory_limit 512M / g '  " $ NCPATH " /.htaccess
}

# Verifique se o programa está instalado (is_this_installed apache2)
Is_this_installed () {
Se [ " $ ( dpkg-query -W -f = ' $ {Status} '  " $ {1} "  2> / dev / null | grep -c " ok instalado " ) "  ==  " 1 " ]
então
    Echo  " $ {1} está instalado, ele deve ser um servidor limpo. "
    Saída 1
Fi
}

# Install_if_not program
Install_if_not () {
Se [[ " $ ( is_this_installed " $ {1} " ) "  ! =  " $ {1} estiver instalado, ele deve ser um servidor limpo. " ]]
então
    Apt update -q4 & spinner_loading && apt install " $ {1} " -y
Fi
}

# Teste tamanho da RAM
# Ligue assim: ram_check [quantidade de RAM mínima em GB] [para qual programa]
# Exemplo: ram_check 2 Nextcloud
Ram_check () {
Mem_available = " $ ( awk ' / MemTotal / {print $ 2} ' / proc / meminfo ) "
se [ " $ {mem_available} "  -É  " $ (( $ {1} * 1002400 )) " ]
então
    Printf  " $ {Red} Erro: $ {1} GB RAM necessária para instalar $ {2} ! $ {Color_Off} \ n "  > e 2
    Printf  " $ {Red} A RAM atual é: ( " $ (( mem_available / 1002400 )) " GB) $ {Color_Off} \ n "  > e 2
    Durma 3
    Saída 1
outro
    Printf  " $ {Verde} RAM por $ {2} OK! ( " $ (( Mem_available / 1002400 )) " GB) $ {Color_Off} \ n "
Fi
}

# Número de teste da CPU
# Ligue assim: cpu_check [quantidade de min CPU] [para qual programa]
# Exemplo: cpu_check 2 Nextcloud
Cpu_check () {
Nr_cpu = " $ ( nproc ) "
se [ " $ {nr_cpu} "  -É  " $ {1} " ]
então
    Printf  " $ {Red} Erro: $ {1} CPU necessária para instalar $ {2} ! $ {Color_Off} \ n "  > e 2
    printf  " $ {Red} CPU atual: ( " $ (( nr_cpu )) " ) $ {Color_Off} \ n "  > & 2
    Durma 3
    Saída 1
outro
    printf  " $ {verde} CPU para $ {2} OK! ( " $ (( nr_cpu )) " ) $ {Color_Off} \ n "
Fi
}

Check_command () {
  Se  !  Eval  " $ * "
  então
     printf  " $ {iRed} Desculpe, mas algo deu errado. Por favor, reporte este problema para $ QUESTÕES e incluir a saída da mensagem de erro. Obrigado! $ {Color_Off} \ n "
     Eco  " $ * falhou "
    Saída 1
  Fi
}

Network_ok () {
    Echo  " Testando se a rede está correta ... "
    Reiniciar o serviço de rede
    Se wget -q -T 20 -t 2 http://github.com -O / dev / null & spinner_loading
    então
        Retornar 0
    outro
        Retornar 1
    Fi
}

# Whiptail auto-size
Calc_wt_size () {
    WT_HEIGHT = 17
    WT_WIDTH = $ ( tput cols )

    Se [ -z  " $ WT_WIDTH " ] || [ " $ WT_WIDTH "  -É 60] ;  então
        WT_WIDTH = 80
    Fi
    Se [ " $ WT_WIDTH "  -gt 178] ;  então
        WT_WIDTH = 120
    Fi
    WT_MENU_HEIGHT = $ (( WT_HEIGHT - 7 ))
    Exportar WT_MENU_HEIGHT
}

Download_verify_nextcloud_stable () {
Rm -f " $ HTML / $ STABLEVERSION .tar.bz2 "
Wget -q -T 10 -t 2 " $ NCREPO / $ STABLEVERSION .tar.bz2 " -P " $ HTML "
Mkdir -p " $ GPGDIR "
Wget -q " $ NCREPO / $ STABLEVERSION .tar.bz2.asc " -P " $ GPGDIR "
Chmod -R 600 " $ GPGDIR "
Gpg --keyserver hkp: //p80.pool.sks-keyservers.net: 80 --recv-keys " $ OpenPGP_fingerprint "
Gpg --verify " $ GPGDIR / $ STABLEVERSION .tar.bz2.asc "  " $ HTML / $ STABLEVERSION .tar.bz2 "
Rm -r " $ GPGDIR "
}

# Primeiro download do script em ../static
# Chamada como: download_static_script name_of_script
Download_static_script () {
    # Obter $ {1} script
    Rm -f " $ {SCRIPTS} / $ {1} .sh "  " $ {SCRIPTS} / $ {1} .php "  " $ {SCRIPTS} / $ {1} .py "
    Se  ! {Wget -q " $ {ESTÁTICO} / $ {1} .sh " -P " $ SCRIPTS "  || Wget -q " $ {ESTÁTICO} / $ {1} .php " -P " $ SCRIPTS "  || Wget -q " $ {STATIC} / $ {1} .py " -P " $ SCRIPTS " ; }
    então
        Echo  " { $ 1 } falhou ao fazer o download. Execute: 'sudo wget $ {STATIC} / $ {1} .sh | .php | .py' novamente. "
        Echo  " Se você receber esse erro ao executar o script nextcloud-startup, basta re-executar com: "
        Echo  " 'sudo bash $ SCRIPTS /nextcloud-startup-script.sh' e todos os scripts serão baixados novamente "
        Saída 1
    Fi
}

# Download inicial do script em ../lets-encrypt
# Chamada como: download_le_script name_of_script
Download_le_script () {
    # Obter $ {1} script
    Rm -f " $ {SCRIPTS} / $ {1} .sh "  " $ {SCRIPTS} / $ {1} .php "  " $ {SCRIPTS} / $ {1} .py "
    Se  ! {Wget -q " $ {LETS_ENC} / $ {1} .sh " -P " $ SCRIPTS "  || Wget -q " $ {LETS_ENC} / $ {1} .php " -P " $ SCRIPTS "  || Wget -q " $ {LETS_ENC} / $ {1} .py " -P " $ SCRIPTS " ; }
    então
        Echo  " { $ 1 } falhou ao fazer o download. Execute: 'sudo wget $ {STATIC} / $ {1} .sh | .php | .py' novamente. "
        Echo  " Se você receber esse erro ao executar o script nextcloud-startup, basta re-executar com: "
        Echo  " 'sudo bash $ SCRIPTS /nextcloud-startup-script.sh' e todos os scripts serão baixados novamente "
        Saída 1
    Fi
}

# Execute qualquer script em ../master
# Chamada como: run_main_script name_of_script
Run_main_script () {
    Rm -f " $ {SCRIPTS} / $ {1} .sh "  " $ {SCRIPTS} / $ {1} .php "  " $ {SCRIPTS} / $ {1} .py "
    Se wget -q " $ {GITHUB_REPO} / $ {1} .sh " -P " $ SCRIPTS "
    então
        Bash " $ {SCRIPTS} / $ {1} .sh "
        Rm -f " $ {SCRIPTS} / $ {1} .sh "
    Elif wget -q " $ {GITHUB_REPO} / $ {1} .php " -P " $ SCRIPTS "
    então
        Php " $ {SCRIPTS} / $ {1} .php "
        Rm -f " $ {SCRIPTS} / $ {1} .php "
    Elif wget -q " $ {GITHUB_REPO} / $ {1} .py " -P " $ SCRIPTS "
    então
        Python " $ {SCRIPTS} / $ {1} .py "
        Rm -f " $ {SCRIPTS} / $ {1} .py "
    outro
        Echo  " Download de $ {1} falhou "
        Echo  "O script falhou ao fazer o download. Execute: 'sudo wget $ {GITHUB_REPO} / $ {1} .sh | php | py' novamente. "
        Durma 3
    Fi
}

# Execute qualquer script em ../static
# Chamada como: run_static_script name_of_script
Run_static_script () {
    # Obter $ {1} script
    Rm -f " $ {SCRIPTS} / $ {1} .sh "  " $ {SCRIPTS} / $ {1} .php "  " $ {SCRIPTS} / $ {1} .py "
    Se wget -q " $ {STATIC} / $ {1} .sh " -P " $ SCRIPTS "
    então
        Bash " $ {SCRIPTS} / $ {1} .sh "
        Rm -f " $ {SCRIPTS} / $ {1} .sh "
    Elif wget -q " $ {STATIC} / $ {1} .php " -P " $ SCRIPTS "
    então
        Php " $ {SCRIPTS} / $ {1} .php "
        Rm -f " $ {SCRIPTS} / $ {1} .php "
    Elif wget -q " $ {STATIC} / $ {1} .py " -P " $ SCRIPTS "
    então
        Python " $ {SCRIPTS} / $ {1} .py "
        Rm -f " $ {SCRIPTS} / $ {1} .py "
    outro
        Echo  " Download de $ {1} falhou "
        Echo  "O script não foi feito para download. Por favor, execute: 'sudo wget $ {STATIC} / $ {1} .sh | php | py' novamente. "
        Durma 3
    Fi
}

# Execute qualquer script em ../apps
# Chamada como: run_app_script collabora | nextant | passman | spreedme | contatos | calendário | webmin | previewgenerator
Run_app_script () {
    Rm -f " $ {SCRIPTS} / $ {1} .sh "  " $ {SCRIPTS} / $ {1} .php "  " $ {SCRIPTS} / $ {1} .py "
    Se wget -q " $ {APP} / $ {1} .sh " -P " $ SCRIPTS "
    então
        Bash " $ {SCRIPTS} / $ {1} .sh "
        Rm -f " $ {SCRIPTS} / $ {1} .sh "
    Elif wget -q " $ {APP} / $ {1} .php " -P " $ SCRIPTS "
    então
        Php " $ {SCRIPTS} / $ {1} .php "
        Rm -f " $ {SCRIPTS} / $ {1} .php "
    Elif wget -q " $ {APP} / $ {1} .py " -P " $ SCRIPTS "
    então
        Python " $ {SCRIPTS} / $ {1} .py "
        Rm -f " $ {SCRIPTS} / $ {1} .py "
    outro
        Echo  " Download de $ {1} falhou "
        Echo  "O script não foi baixado. Execute: 'sudo wget $ {APP} / $ {1} .sh | php | py' novamente. "
        Durma 3
    Fi
}

Versão () {
    Htv local

    [[ $ 2  =  " $ 1 "  ||  $ 2  =  " $ 3 " ]] &&  return 0

    V = $ ( printf ' % s \ n '  " $ @ "  | classificar -V )
    H = $ ( head -n1 <<< " $ v " )
    T = $ ( tail -n1 <<< " $ v " )

    [[ $ 2  ! =  " $ H "  &&  $ 2  ! =  " $ T " ]]
}

Version_gt () {
    Local v1 v2 IFS =.
    Ler -ra v1 <<<  " $ 1 "
    Ler -ra v2 <<<  " $ 2 "
    printf -v v1% 03d " $ {v1 [@]} "
    printf -v v2% 03d " $ {v2 [@]} "
    [[ $ V1  >  $ v2 ]]
}

Spinner_loading () {
    Pid = $!
    Spin = ' - \ | / '
    I = 0
    Enquanto  mata -0 $ pid  2> / dev / null
    Faz
        I = $ (( (i + 1 ) % 4  ))
        Printf  " \ r [ $ {spin : $ i : 1} ] "  # Adicione texto aqui, algo como "Por favor, seja paente ..." talvez?
        Durma .1
    feito
}

Any_key () {
    Local PROMPT = " $ 1 "
    Leia -r -p " $ ( printf " $ {Green} $ {PROMPT} $ {Color_Off} " ) " -n1 -s
    eco
}

# # Bash colors
# Redefinir
Color_Off = ' \ e [0m '        # Redefinir Texto

# Cores regulares
Preto = ' \ e [0; 30m '         # Preto
Vermelho = ' \ e [0; 31m '           # Vermelho
Verde = ' \ e [0; 32m '         # Verde
Amarelo = ' \ e [0; 33m '        # Amarelo
Azul = ' \ e [0; 34m '          # Azul
Purple = ' \ e [0; 35m '        # Roxo
Cyan = ' \ e [0; 36m '          # Ciano
Branco = ' \ e [0; 37m '         # Branco

# Negrito
BBlack = ' \ e [1; 30m '        # Black
BRed = ' \ e [1; 31m '          # Vermelho
BGreen = ' \ e [1; 32m '        # Verde
BYellow = ' \ e [1; 33m '       # Amarelo
BBlue = ' \ e [1; 34m '         # Azul
BPurple = ' \ e [1; 35m '       # Purple
BCyan = ' \ e [1; 36m '         # Ciano
BWhite = ' \ e [1; 37m '        # Branco

# Sublinhado
UBlack = ' \ e [4; 30m '        # Black
URed = ' \ e [4; 31m '          # Vermelho
UGreen = ' \ e [4; 32m '        # Verde
UYellow = ' \ e [4; 33m '       # Amarelo
UBlue = ' \ e [4; 34m '         # Azul
UPurple = ' \ e [4; 35m '       # Roxo
UCyan = ' \ e [4; 36m '         # Ciano
UWhite = ' \ e [4; 37m '        # Branco

# Antecedentes
On_Black = ' \ e [40m '        # Black
On_Red = ' \ e [41m '          # Vermelho
On_Green = ' \ e [42m '        # Verde
On_Yellow = ' \ e [43m '       # Amarelo
On_Blue = ' \ e [44m '         # Blue
On_Purple = ' \ e [45m '       # Roxo
On_Cyan = ' \ e [46m '         # Ciano
On_White = ' \ e [47m '        # Branco

# Intensidade elevada
IBlack = ' \ e [0; 90m '        # Black
IRed = ' \ e [0; 91m '          # Vermelho
IGreen = ' \ e [0; 92m '        # Verde
IYellow = ' \ e [0; 93m '       # Amarelo
IBlue = ' \ e [0; 94m '         # Azul
IPurple = ' \ e [0; 95m '       # Roxo
ICyan = ' \ e [0; 96m '         # Ciano
IWhite = ' \ e [0; 97m '        # Branco

# Bold High Intensity
BIBLack = ' \ e [1; 90m '       # Black
BIRED = ' \ e [1; 91m '         # Vermelho
BIGreen = ' \ e [1; 92m '       # Verde
BIYellow = ' \ e [1; 93m '      # Amarelo
BIBlue = ' \ e [1; 94m '        # Azul
BIPurple = ' \ e [1; 95m '      # Purple
BICyan = ' \ e [1; 96m '        # Ciano
BIWhite = ' \ e [1; 97m '       # Branco

# Backgrounds de alta intensidade
On_IBlack = ' \ e [0; 100m '    # Black
On_IRed = ' \ e [0; 101m '      # Vermelho
On_IGreen = ' \ e [0; 102m '    # Verde
On_IYellow = ' \ e [0; 103m '   # Amarelo
On_IBlue = ' \ e [0; 104m '     # Azul
On_IPurple = ' \ e [0; 105m '   # Roxo
On_ICyan = ' \ e [0; 106m '     # Ciano
On_IWhite = ' \ e [0; 107m '    # Branco