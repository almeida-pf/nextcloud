#!/bin/bash

# Pablo Almeida - 2017

# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
. <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)

# Verifica se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

# Verifica se e root
if ! is_root
then
    printf "\n${Red}Desculpe, Voce nao e ROOT.\n${Color_Off}Voce deve digitar: ${Cyan}sudo ${Color_Off}bash %s/fail2ban.sh\n" "$SCRIPTS"
    sleep 3
    exit 1
fi

### Variaveis locais ###
# Localizacao dos logs Nextcloud
NCLOG="$(find / -name nextcloud.log)"
# Tempo para proibir um IP que excedeu as tentativas
BANTIME_=600000
# Tempo de cooldown para senhas incorretas
FINDTIME_=1800
# Tentativas falhadas antes de proibir um IP
MAXRETRY_=10

echo "Instalando Fail2ban..."

apt update -q4 & spinner_loading
check_command apt install fail2ban -y
check_command update-rc.d fail2ban disable

if [ -z "$NCLOG" ]
then
    echo "nextcloud.log nao encontrado"
    echo "Adicione seu logpath para $NCPATH/config/config.php e reinicie este script."
    exit 1
else
    chown www-data:www-data "$NCLOG"
fi

# Defini valores em config.php
sudo -u www-data php "$NCPATH/occ" config:system:set loglevel --value=2
sudo -u www-data php "$NCPATH/occ" config:system:set log_type --value=file
sudo -u www-data php "$NCPATH/occ" config:system:set logfile  --value="$NCLOG"
sudo -u www-data php "$NCPATH/occ" config:system:set logtimezone  --value="$(cat /etc/timezone)"

# Criar arquivo nextcloud.conf
cat << NCONF > /etc/fail2ban/filter.d/nextcloud.conf
[Definition]
failregex = ^.*Login failed: '.*' \(Remote IP: '<HOST>'.*$
ignoreregex =
NCONF

# Criar arquivo jail.local
cat << FCONF > /etc/fail2ban/jail.local
# O DEFAULT permite uma definicao global das opcoes. Eles podem ser substituidos
# em cada um depois.
[DEFAULT]

# "ignoreip "pode ser um endereço IP, uma mascara CIDR ou um host DNS. Fail2ban nao
# Proibir um host que corresponda a um endereço nesta lista. Varios enderecos podem ser
# definidos usando separador de espaço.
ignoreip = 127.0.0.1/8 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8

# "bantime" e o numero de segundos que um host esta proibido.
bantime  = $BANTIME_

# Um host e banido se gerou "maxretry" durante o ultimo "findtime"
# seconds.
findtime = $FINDTIME_
maxretry = $MAXRETRY_

#
# Acoes
#
banaction = iptables-multiport
protocol = tcp
chain = INPUT
action_ = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
action_mw = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
action_mwl = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
action = %(action_)s

#
# SSH
#

[ssh]

enabled  = true
port     = ssh
filter   = sshd
logpath  = /var/log/auth.log
maxretry = $MAXRETRY_

#
# HTTP servers
#

[nextcloud]

enabled  = true
port     = http,https
filter   = nextcloud
logpath  = $NCLOG
maxretry = $MAXRETRY_
FCONF

# Atualiza Configuraçoes
check_command update-rc.d fail2ban defaults
check_command update-rc.d fail2ban enable
check_command service fail2ban restart

# E fim
echo
echo "Fail2ban agora esta instalado com sucesso."
echo "Por favor, use 'fail2ban-client set nextcloud unbanip <Banned IP>' para cancelar determinados IPs"
echo "Voce tambem pode usar 'iptables -L -n' para verificar quais IPs sao proibidos"
any_key "pressione qualquer tecla para continuar..."
clear
