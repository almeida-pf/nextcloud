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

# Ativa nova config
printf "${Color_Off}Vamos agora testar se tudo esta OK\n"
any_key "Pressione qualquer tecla para continuar... "
a2ensite "$1"
a2dissite nextcloud_ssl_domain_self_signed.conf
a2dissite nextcloud_http_domain_self_signed.conf
a2dissite 000-default.conf
if service apache2 restart
then
    printf "${On_Green}Novas configuracoes estao funcionando! SSL agora esta ativado e esta OK!${Color_Off}\n\n"
    echo "Este cert expirara em 90 dias, entao voce deve renova-lo."
    echo "Existem varias maneiras de faze-lo, aqui estao algumas dicas e truques: https://goo.gl/c1JHR0"
    echo "Este script ira adicionar um novo cronjob para voce comecar, edite-o digitando:"
    echo "'crontab -u root -e'"
    echo "Sinta-se livre para contribuir com este projeto: https://goo.gl/3fQD65"
    any_key "Pressione qualquer tecla para continuar..."
    crontab -u root -l | { cat; echo "@daily $SCRIPTS/letsencryptrenew.sh"; } | crontab -u root -

FQDOMAIN=$(grep -m 1 "ServerName" "/etc/apache2/sites-enabled/$1" | awk '{print $2}')
if [ "$(hostname)" != "$FQDOMAIN" ]
then
    echo "Configurando o nome do host para $FQDOMAIN..."
    sudo sh -c "echo 'ServerName $FQDOMAIN' >> /etc/apache2/apache2.conf"
    sudo hostnamectl set-hostname "$FQDOMAIN"
    # Muda tambem /etc/hosts
    sed -i "s|127.0.1.1.*|127.0.1.1       $FQDOMAIN $(hostname -s)|g" /etc/hosts
fi

# Defina dominios confiaveis
run_static_script trusted

add_crontab_le() {
# Desabilita=SC2016 shellcheck
DATE='$(date +%Y-%m-%d_%H:%M)'
cat << CRONTAB > "$SCRIPTS/letsencryptrenew.sh"
#!/bin/sh
if ! certbot renew --quiet --no-self-upgrade > /var/log/letsencrypt/renew.log 2>&1 ; then
        echo "Let's Encrypt Falhou!"--$DATE >> /var/log/letsencrypt/cronjob.log
else
        echo "Let's Encrypt SUCESSO!"--$DATE >> /var/log/letsencrypt/cronjob.log
fi

# Verifica se o servico esta em execucao
if ! pgrep apache2 > /dev/null
then
    service apache2 start
fi
CRONTAB
}
add_crontab_le

# Monta script executavel Makeletsencryptrenew.sh
chmod +x $SCRIPTS/letsencryptrenew.sh

# Limpa
rm $SCRIPTS/test-new-config.sh ## Remove ??
rm $SCRIPTS/activate-ssl.sh ## Remove ??

else
# Se ele falhar, reverte as mudancas de volta ao normal
    a2dissite "$1"
    a2ensite nextcloud_ssl_domain_self_signed.conf
    a2ensite nextcloud_http_domain_self_signed.conf
    a2ensite 000-default.conf
    service apache2 restart
    printf "${ICyan}Nao foi possivel carregar nova configuracao, revertido para configuracoes antigas. Certificado Auto-assinado SSL esta OK!${Color_Off}\n"
    any_key "Pressione qualquer tecla para continuar... "
    exit 1
fi
