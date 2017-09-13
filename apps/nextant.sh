#!/bin/bash

# Pablo Almeida - 2017

# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
NEXTANT_INSTALL=1 . <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)
unset NEXTANT_INSTALL

# Verifica se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

# Instalacao do Solr Server & Nextant App

# Deve ser root
if ! is_root
then
    echo "Deve ser root para executar o script, no Ubuntu: sudo -i"
    exit 1
fi

# Verifica se ha uma instalacao Nextcloud
if ! [ "$(sudo -u www-data php $NCPATH/occ -V)" ]
then
    echo "Parece que nao existe nenhum servidor Nextcloud instalado, verifique sua instalacao."
    exit 1
fi

# Verifica se e uma instalacao limpa
if [ -d "$SOLR_HOME" ]
then
    echo
    echo "Parece que $SOLR_HOME ja existe. Voce ja executou este script??"
    echo "Se sim, reverta todas as configuracoes e tente novamente, deve ser uma instalacao limpa."
    exit 1
fi

echo "Comecando a configurar Solr & Nextant no Nextcloud..."

# Instalando requisitos
apt update -q4 & spinner_loading
apt install default-jre -y

# Obtendo e instalando Apache Solr
echo "Instalando Apache Solr"
echo "Pode levar algum tempo dependendo da sua internet, seja paciente..."
mkdir -p "$SOLR_HOME"
check_command cd "$SOLR_HOME" 
wget -q "$SOLR_DL" --show-progress
tar -zxf "$SOLR_RELEASE"
if "./solr-$SOLR_VERSION/bin/install_solr_service.sh" "$SOLR_RELEASE"
then
    rm -rf "${SOLR_HOME:?}/$SOLR_RELEASE"
    wget -q https://raw.githubusercontent.com/apache/lucene-solr/master/solr/bin/install_solr_service.sh -P $SCRIPTS/
else
    echo "Solr nao foi instalado, algo esta errado com a instalacao do Solr"
    exit 1
fi

sudo sed -i '35,37  s/"jetty.host" \//"jetty.host" default="127.0.0.1" \//' $SOLR_JETTY

iptables -A INPUT -p tcp -s localhost --dport 8983 -j ACCEPT
iptables -A INPUT -p tcp --dport 8983 -j DROP
# Nao testado
#sudo apt install iptables-persistent
#sudo service iptables-persistent start
#sudo iptables-save > /etc/iptables.conf

if service solr start
then
    sudo -u solr /opt/solr/bin/solr create -c nextant 
else
    echo "Solr falhou ao iniciar, algo esta errado com a instalacao do Solr"
    exit 1
fi

# Adiciona recurso de sugestoes de pesquisa
sed -i '2i <!DOCTYPE config [' "$SOLR_DSCONF"
sed -i "3i   <\!ENTITY nextant_component SYSTEM \"$NCPATH/apps/nextant/config/nextant_solrconfig.xml\"\>" "$SOLR_DSCONF"
sed -i '4i   ]>' "$SOLR_DSCONF"

sed -i '$d' "$SOLR_DSCONF" | sed -i '$d' "$SOLR_DSCONF"
echo "
&nextant_component;
</config>" | tee -a "$SOLR_DSCONF"

check_command "echo \"SOLR_OPTS=\\\"\\\$SOLR_OPTS -Dsolr.allow.unsafe.resourceloading=true\\\"\" | sudo tee -a /etc/default/solr.in.sh"

check_command service solr restart

# Obtem o proximo aplicativo para a proxima nuvem
check_command wget -q -P "$NC_APPS_PATH" "$NT_DL"
check_command cd "$NC_APPS_PATH"
check_command tar zxf "$NT_RELEASE"

# Habilita Nextant
rm -r "$NT_RELEASE"
check_command sudo -u www-data php $NCPATH/occ app:enable nextant
chown -R www-data:www-data $NCPATH/apps
check_command sudo -u www-data php $NCPATH/occ nextant:test http://127.0.0.1:8983/solr/ nextant --save
check_command sudo -u www-data php $NCPATH/occ nextant:index

