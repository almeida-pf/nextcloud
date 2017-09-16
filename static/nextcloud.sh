#!/bin/bash

# Pablo Almeida - 2017

# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
LOAD_IP6=1 . <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)
unset LOAD_IP6

# Verifique se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

clear
figlet -f small Nextcloud
echo "     https://www.nextcloud.com"
echo
echo
echo "Hostname: $(hostname -s)"
echo "WAN IPv4: $WANIP4"
echo "WAN IPv6: $WANIP6"
echo "LAN IPv4: $ADDRESS"
echo
exit 0
