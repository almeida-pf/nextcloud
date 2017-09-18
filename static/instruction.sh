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

clear
cat << INST1
+-----------------------------------------------------------------------+
| Obrigado por fazer o download desta vm Nextcloud!                     |
|                                                                       |
INST1
echo -e "|"  "${Green}Para executar o script de inicializacao, digite a senha sudo. ${Color_Off}  |"
echo -e "|"  "${Green} ou padrao ('nextcloud') ou o escolhido durante a instalacao.${Color_Off}   |"
cat << INST2
|                                                                       |
| Se voce nunca fez isso antes, pode seguir as                          |
| instrucoes de instalacao aqui: https://goo.gl/JVxuPh                  |
|                                                                       |
| Voce pode agendar o processo de atualizacao Nextcloud                 |
|  usando um cron job.                                                  |
| Isso e feito usando um script incorporado nesta VM que automaticamente|
| atualiza Nextcloud, define permissoes seguras e registra o sucesso    |
| atualiza para /var/log/cronjobs_success.log                           |
| Instrucoes detalhadas para configurar isso podem ser encontradas aqui:|
| https://www.techandme.se/nextcloud-update-is-now-fully-automated/     |
|                                                                       |
|  ####################### Pablo Almeida - 2017 ########################|
+-----------------------------------------------------------------------+
INST2

exit 0
