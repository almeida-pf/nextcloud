#!/bin/bash

# Tech and Me © - 2017, https://www.techandme.se/

# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
FIRST_IFACE=1 . <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)
unset FIRST_IFACE

# Verifique se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

cat <<-IPCONFIG > "$INTERFACES"
source /etc/network/interfaces.d/*

# Interface de rede de loopback
auto lo $IFACE
iface lo inet loopback

# Principal interface de rede
iface $IFACE inet static
pre-up /sbin/ethtool -K $IFACE tso off
pre-up /sbin/ethtool -K $IFACE gso off
# Ajuste https://github.com/nextcloud/vm/issues/92:
pre-up ip link set dev $IFACE mtu 1430

# A melhor opcao e mudar o endereco para estatico
# para algo fora do seu alcance DHCP.
address $ADDRESS
netmask $NETMASK
gateway $GATEWAY

# Esta e uma interface IPv6 autoconfigurada
# iface $IFACE inet6 auto

# Sair e salvar:	[CTRL+X] + [Y] + [ENTER]
# Sair sem salvar:	[CTRL+X]

IPCONFIG

exit 0
