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

rm "/home/$UNIXUSER/.profile"

cat <<-UNIXUSER-PROFILE > "$UNIXUSER_PROFILE"
# ~/.profile: executado pela linha de comando para login e shells.
# Este arquivo nao e lido por bash(1), e se ~/.bash_profile entao ~/.bash_login
# existe.
# veja /usr/share/doc/bash/examples/startup-files por exemplo.
# os arquivos estao localizados no pacote bash-doc.
# o umask padrao e configurado no /etc/profile; para ajustar o umask
# Para logs do ssh, instale e configure o pacote libpam-umask.
#umask 022
# Se esta rodando bash
if [ -n "$BASH_VERSION" ]
then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]
    then
        . "$HOME/.bashrc"
    fi
fi
# Define PATH para que ele inclua o compartimento privado do usuario se ele existir
if [ -d "$HOME/bin" ]
then
    PATH="$HOME/bin:$PATH"
fi
bash /var/scripts/instruction.sh
bash /var/scripts/history.sh
sudo -i

UNIXUSER-PROFILE

chown "$UNIXUSER:$UNIXUSER" "$UNIXUSER_PROFILE"
chown "$UNIXUSER:$UNIXUSER" "$SCRIPTS/history.sh"
chown "$UNIXUSER:$UNIXUSER" "$SCRIPTS/instruction.sh"

exit 0
