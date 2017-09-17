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

# Must be root
if ! is_root
then
    echo "Deve ser root para executar o script, no Ubuntu: sudo -i"
    exit 1
fi

mkdir -p "$SCRIPTS"

# Exclui, baixa, executa
run_main_script nextcloud_update

exit
