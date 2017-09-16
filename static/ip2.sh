#!/bin/bash

# Pablo Almeida - 2017

# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
. <(curl -sL curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)

# Verifique se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

# Este arquivo so e usado se o IFACE falhar no script de inicializacao

cat <<-IPCONFIG > "$INTERFACES"
source /etc/network/interfaces.d/*

# Interface de rede de loopback
auto lo $IFACE2
iface lo inet loopback

# Principal interface de rede
iface $IFACE inet static
pre-up /sbin/ethtool -K $IFACE2 tso off
pre-up /sbin/ethtool -K $IFACE2 gso off
# Fixes https://github.com/nextcloud/vm/issues/92:
pre-up ip link set dev $IFACE2 mtu 1430

# A melhor opcao e mudar o endereco para estatico
# para algo fora do seu alcance DHCP.
address $ADDRESS
netmask $NETMASK
gateway $GATEWAY

# Esta e uma interface IPv6 autoconfigurada
# iface $IFACE2 inet6 auto

# Sair e salvar:	[CTRL+X] + [Y] + [ENTER]
# Sair sem salvar:	[CTRL+X]

IPCONFIG

exit 0
