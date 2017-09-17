#!/bin/bash

# Pablo Almeida - 2017

# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
. <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)

# Verifique se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

# Baseado em: http://www.techrepublic.com/blog/smb-technologist/secure-your-apache-server-from-ddos-slowloris-and-dns-injection-attacks/

# Protege contra DDOS
apt update -q4 & spinner_loading
apt -y install libapache2-mod-evasive
mkdir -p /var/log/apache2/evasive
chown -R www-data:root /var/log/apache2/evasive
if [ ! -f $ENVASIVE ]
then
    touch $ENVASIVE
    cat << ENVASIVE > "$ENVASIVE"
DOSHashTableSize 2048
DOSPageCount 20  # numero maximo de solicitacoes para a mesma pagina
DOSSiteCount 300  # numero total de solicitacoes para qualquer objeto pelo mesmo IP do cliente no mesmo ouvinte
DOSPageInterval 1.0 # intervalo para o limite de contagem de paginas
DOSSiteInterval 1.0  # intervalo para o limite de contagem do site
DOSBlockingPeriod 10.0 # tempo em que um IP do cliente sera bloqueado para
DOSLogDir
ENVASIVE
fi

# Protegee contra Slowloris
#apt -y install libapache2-mod-qos
a2enmod reqtimeout # http://httpd.apache.org/docs/2.4/mod/mod_reqtimeout.html

# Protege contra DNS Injection
apt -y install libapache2-mod-spamhaus
if [ ! -f $SPAMHAUS ]
then
    touch $SPAMHAUS
    cat << SPAMHAUS >> "$APACHE2"

# Modulo Spamhaus
<IfModule mod_spamhaus.c>
  MS_METHODS POST,PUT,OPTIONS,CONNECT
  MS_WhiteList /etc/spamhaus.wl
  MS_CacheSize 256
</IfModule>
SPAMHAUS
fi

if [ -f $SPAMHAUS ]
then
    echo "Adicionando lista branca IP-ranges..."
    cat << SPAMHAUSconf >> "$SPAMHAUS"

# Lista branca IP-ranges
192.168.0.0/16
172.16.0.0/12
10.0.0.0/8
SPAMHAUSconf
else
    echo "Nao existe nenhum arquivo, portanto, nao adicione nada a lista branca"
fi

# Habilita $SPAMHAUS
sed -i "s|#MS_WhiteList /etc/spamhaus.wl|MS_WhiteList $SPAMHAUS|g" /etc/apache2/mods-enabled/spamhaus.conf

check_command service apache2 restart
echo "Segurança adicionada!"
sleep 3

