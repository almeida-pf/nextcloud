#!/bin/bash
# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
. <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)

# Pablo Almeida - 2017

# Verifica se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

# Verifica se e root
if ! is_root
then
    printf "\n${Red}Desculpe, voce nao e root.\n${Color_Off}Voce deve digitar: ${Cyan}sudo ${Color_Off}bash %s/activate-ssl.sh\n" "$SCRIPTS"
    exit 1
fi

clear

cat << STARTMSG
+---------------------------------------------------------------+
|       Importante! Por favor leia isto!                        |
|                                                               |
|       Este script ira instalar o SSL a partir do Letsencrypt. |
|       E gratuito e muito facil de usar.                       |
|                                                               |
|       Antes de comecar a instalacao, voce precisa ter         |
|       um dominio com qual os certificados SSL serao validos.  |
|       Se voce ainda nao possui um dominio, pegue um antes     |
|       que voce execute esse script!                           |
|                                                               |
|       Você tambem precisa abrir a porta 443 contra essas VMs  |
|       IP address: "$ADDRESS" - faca isso no seu roteador.     |
|       Aqui esta um guia: https://goo.gl/Uyuf65                |
|                                                               |
|       Este script esta localizado em "$SCRIPTS" e voce        |
|       pode executar este script depois de ter um dominio.     |
|                                                               |
|       Nao execute este script se voce nao tiver um dominio.   |
|       Voce pode obter um por um preco justo aqui:             |
|       https://www.citysites.eu/                               |
|                                                               |
+---------------------------------------------------------------+

STARTMSG

if [[ "no" == $(ask_yes_or_no "Voce tem certeza que quer continuar?") ]]
then
    echo
    echo "OK, mas se quiser executar este script mais tarde, basta digitar: sudo bash $SCRIPTS/activate-ssl.sh"
    any_key "Pressione qualquer tecla para continuar..."
exit
fi

if [[ "no" == $(ask_yes_or_no "Voce encaminhou a porta 443 no seu roteador?") ]]
then
    echo
    echo "OK, mas se quiser executar este script mais tarde, basta digitar: sudo bash /var/scripts/activate-ssl.sh"
    any_key "Pressione qualquer tecla para continuar..."
    exit
fi

if [[ "yes" == $(ask_yes_or_no "Voce tem um dominio que voce usara??") ]]
then
    sleep 1
else
    echo
    echo "OK, mas se quiser executar este script mais tarde, basta digitar: sudo bash /var/scripts/activate-ssl.sh"
    any_key "Pressione qualquer tecla para continuar..."
    exit
fi

echo
while true
do
# Pergunta o nome do dominio
cat << ENTERDOMAIN
+---------------------------------------------------------------+
|    Digite o nome de dominio que voce usara para Nextcloud:    |
|    Digite:  example.com, ou nextcloud.example.com             |
+---------------------------------------------------------------+
ENTERDOMAIN
echo
read -r domain
echo
if [[ "yes" == $(ask_yes_or_no "esta correto? $domain") ]]
then
    break
fi
done

# Verifica se a porta 443 esta aberta usando nmap, se nao notifica o usuario
apt update -q4 & spinner_loading
install_if_not nmap

if [ "$(nmap -sS -p 443 "$WANIP4" -PN | grep -c "open")" == "1" ]
then
    apt remove --purge nmap -y
else
    echo "Porta 443 nao esta aberta $WANIP4. Vamos fazer uma segunda tentativa em $domain ou."
    any_key "Pressione qualquer tecla para continuar $domain... "
    sed -i "s|127.0.1.1.*|127.0.1.1       $domain nextcloud|g" /etc/hosts
    service networking restart
    if [[ $(nmap -sS -PN -p 443 "$domain" | grep -m 1 "open" | awk '{print $2}') = open ]]
    then
        apt remove --purge nmap -y
    else
        echo "Porta 443 nao esta aberta $domain. Siga este guia para abrir portas em seu roteador: https://www.techandme.se/open-port-80-443/"
        any_key "Pressione qualquer tecla para sair..."
        apt remove --purge nmap -y
        exit 1
    fi
fi

# Obtenha a ultima versao do test-new-config.sh
check_command download_le_script test-new-config

# Verifica se $domain existe e esta acessivel
echo
echo "Verificando se o $domain existe e esta acessivel..."
if wget -q -T 10 -t 2 --spider "$domain"; then
    sleep 1
elif wget -q -T 10 -t 2 --spider --no-check-certificate "https://$domain"; then
    sleep 1
elif curl -s -k -m 10 "$domain"; then
    sleep 1
elif curl -s -k -m 10 "https://$domain" -o /dev/null ; then
    sleep 1
else
    echo "Nao, nao esta la.. Voce precisa criar $domain e apontar"
    echo "para este servidor antes que voce possa executar isso script."
    any_key "Pressione qualquer tecla para continuar..."
    exit 1
fi

# Instala certbot (Let's Encrypt)
install_certbot

#Resolve o problema #28
ssl_conf="/etc/apache2/sites-available/"$domain.conf""

# DHPARAM
DHPARAMS="$CERTFILES/$domain/dhparam.pem"

# Verifica se "$ssl.conf" existe, e entao, exclui
if [ -f "$ssl_conf" ]
then
    rm -f "$ssl_conf"
fi

# Gera nextcloud_ssl_domain.conf
if [ ! -f "$ssl_conf" ]
then
    touch "$ssl_conf"
    echo "$ssl_conf foi criado com sucesso"
    sleep 2
    cat << SSL_CREATE > "$ssl_conf"
<VirtualHost *:80>
    ServerName $domain
    Redirect / https://$domain
</VirtualHost>

<VirtualHost *:443>

    Header add Strict-Transport-Security: "max-age=15768000;includeSubdomains"
    SSLEngine on
    SSLCompression off
    SSLProtocol all -SSLv2 -SSLv3
    SSLCipherSuite ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA
    SSLHonorCipherOrder on
    
### ENDERECO DO SEU SERVIDOR ###

    ServerAdmin admin@$domain
    ServerName $domain

### CONFIGURACOES ###

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

    SetEnv HOME $NCPATH
    SetEnv HTTP_HOME $NCPATH


### LOCALIZACAO DOS ARQUIVOS CERT ###

    SSLCertificateChainFile $CERTFILES/$domain/chain.pem
    SSLCertificateFile $CERTFILES/$domain/cert.pem
    SSLCertificateKeyFile $CERTFILES/$domain/privkey.pem
    SSLOpenSSLConfCmd DHParameters $DHPARAMS

</VirtualHost>
SSL_CREATE
fi

# Metodos
default_le="--rsa-key-size 4096 --renew-by-default --agree-tos -d $domain"

standalone() {
# Gera certs
if eval "certbot certonly --standalone --pre-hook 'service apache2 stop' --post-hook 'service apache2 start' $default_le"
then
    echo "sucesso" > /tmp/le_test
else
    echo "falha" > /tmp/le_test
fi
}
webroot() {
if eval "certbot certonly --webroot --webroot-path $NCPATH $default_le"
then
    echo "sucesso" > /tmp/le_test
else
    echo "falha" > /tmp/le_test
fi
}
certonly() {
if eval "certbot certonly $default_le"
then
    echo "sucesso" > /tmp/le_test
else
    echo "falha" > /tmp/le_test
fi
}

methods=(standalone webroot certonly)

create_config() {
# $1 = method
local method="$1"
# Verifica se $CERTFILES existe
if [ -d "$CERTFILES" ]
 then
    # Gera DHparams chifer
    if [ ! -f "$DHPARAMS" ]
    then
        openssl dhparam -dsaparam -out "$DHPARAMS" 8192
    fi
    # Ativa nova config
    check_command bash "$SCRIPTS/test-new-config.sh" "$domain.conf"
    exit
fi
}

attempts_left() {
local method="$1"
if [ "$method" == "standalone" ]
then
    printf "${ICyan}Parece que nenhum certificado foi gerado, faremos mais 2 tentativas.${Color_Off}\n"
    any_key "Pressione qualquer tecla para continuar..."
elif [ "$method" == "webroot" ]
then
    printf "${ICyan}Parece que nenhum certificado foi gerado, faremos mais 1 tentativas.${Color_Off}\n"
    any_key "Pressione qualquer tecla para continuar..."
elif [ "$method" == "certonly" ]
then
    printf "${ICyan}Parece que nenhum certificado foi gerado, faremos mais 0 tentativas.${Color_Off}\n"
    any_key "Pressione qualquer tecla para continuar..."
fi
}

# Gera cert
for f in "${methods[@]}"; do "$f"
if [ "$(grep 'success' /tmp/le_test)" == 'success' ]; then
    rm -f /tmp/le_test
    create_config "$f"
else
    rm -f /tmp/le_test
    attempts_left "$f"
fi
done

printf "${ICyan}Desculpe, a ultima tentativa falhou tambem. :/${Color_Off}\n\n"
cat << ENDMSG
+------------------------------------------------------------------------+
| O script esta localizado em $SCRIPTS/activate-ssl.sh                   |
| Tente executar novamente outra vez com outras configuracoes.           |
|                                                                        |
| Existem configuracoes diferentes nas quais voce pode tentar            |
|  Let's Encrypt's user guide:                                           |
| https://letsencrypt.readthedocs.org/en/latest/index.html               |
| Verifique o guia para obter mais informacoes sobre como habilitar SSL. |
|                                                                        |
| Este script e desenvolvido no GitHub, sinta-se livre para contribuir:  |
| https://github.com/almeida-pf/nextcloud                                |
|                                                                        |
| O script agora fara alguma limpeza e revertera as configuracoes.       |
+------------------------------------------------------------------------+
ENDMSG
any_key "Pressione qualquer tecla para reverter as configuracoes e sair... "

# Limpeza
apt remove letsencrypt -y
apt autoremove -y
clear
