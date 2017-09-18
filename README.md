# nextcloud
Nextcloud VM Créditos Daniel Hanson @ Tech and Me

Apoiar o desenvolvimento

*Crie um PR e melhore o código
*Informe seu problema
*Ajude-nos com problemas existentes


Crie sua própria VM ou instale em um VPS

Exemplo do DigitalOcean: https://youtu.be/LlqY5Y6P9Oc

Requerimentos mínimos:

*Um Ubuntu Server 16.04.X limpo
*OpenSSH (preferido)
*HDD de 20 GB
*Pelo menos 1 vCPU e 2 GB de RAM (mínimo de 4 GB se você estiver executando OnlyOffice)
*Uma conexão de internet ativa (o script precisa de baixar arquivos e variáveis)

Recomendado:

*Grosso provisionado (melhor desempenho e facilidade de manutenção)
*DHCP disponível

Instalação:

1- Obtenha o roteiro de instalação mais recente do master:
wget https://raw.githubusercontent.com/nextcloud/vm/master/nextcloud_install_production.sh

2- Execute o script com:
sudo bash nextcloud_install_production.sh

3- Quando a VM estiver instalada, ela será reiniciada automaticamente. Lembre-se de fazer login com o usuário que você criou: 
ssh <user>@IP-ADDRESS
Se ele for executado automaticamente como root quando você reiniciar a máquina, você deve abortá-lo pressionando CTRL+Ce executando o script como o usuário que você acabou de criar:
sudo -u <user> sudo bash /var/scripts/nextcloud-startup-script.sh 

4- Observe que a instalação / configuração não está finalizada apenas executando o nextcloud_install_production.shQuando você efetua o login com o (novo) usuário sudo que você executou o script com na etapa 2 você será automaticamente apresentado com o script de instalação.

