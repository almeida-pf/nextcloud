#!/bin/bash
# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
. <(curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)

# Pablo Almeida - 2017

# Verifique se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

# Deve ser root
if ! is_root
then
    echo "Deve ser root para executar o script, no Ubuntu: sudo -i"
    exit 1
fi

# Verifica versao do UBUNTU
echo "Verificando o sistema operacional e a versao do servidor..."
if [ "$OS" != 1 ]
then
    echo "Ubuntu O servidor e necessario para executar este script."
    echo "Instale essa distro e tente novamente."
    exit 1
fi


if ! version 16.04 "$DISTRO" 16.04.4; then
    echo "Versao Ubuntu $DISTRO deve estar entre 16.04 - 16.04.4"
    exit
fi

# Verifica se o dir existe
if [ ! -d $SCRIPTS ]
then
    mkdir -p $SCRIPTS
fi

# Obtenha pacotes para poder instalar o Redis
apt update -q4 & spinner_loading
sudo apt install -q -y \
    build-essential \
    tcl8.5 \
    php7.0-dev \
    php-pear

# Instala PHPmodule
if ! pecl install -Z redis
then
    echo "PHP Falha na instalacao do modulo"
    sleep 3
    exit 1
else
    printf "${Green}\nInstalacao do modulo PHP esta OK!${Color_Off}\n"
fi
# Definir globalmente nao funciona por algum motivo
# Ajustar em /etc/php/7.0/mods-available/redis.ini
# echo 'extension=redis.so' > /etc/php/7.0/mods-available/redis.ini
# phpenmod redis
# Definir direto para apache2 funciona se 'libapache2-mod-php7.0' estiver instalado
echo 'extension=redis.so' >> /etc/php/7.0/apache2/php.ini
service apache2 restart


# Instala Redis
if ! apt -y install redis-server
then
    echo "Falha na instalacao."
    sleep 3
    exit 1
else
    printf "${Green}\nInstalacao Redis OK!${Color_Off}\n"
fi

# Prepara para adicionar a configuracao redis
sed -i "s|);||g" $NCPATH/config/config.php

# Adicione a configuracao necessaria a Nextclouds config.php
cat <<ADD_TO_CONFIG >> $NCPATH/config/config.php
  'memcache.local' => '\\OC\\Memcache\\Redis',
  'filelocking.enabled' => true,
  'memcache.distributed' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' =>
  array (
    'host' => '$REDIS_SOCK',
    'port' => 0,
    'timeout' => 0,
    'dbindex' => 0,
    'password' => '$REDIS_PASS',
  ),
);
ADD_TO_CONFIG

# Redis performance tweaks
if ! grep -Fxq "vm.overcommit_memory = 1" /etc/sysctl.conf
then
    echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf
fi
sed -i "s|# unixsocket /var/run/redis/redis.sock|unixsocket $REDIS_SOCK|g" $REDIS_CONF
sed -i "s|# unixsocketperm 700|unixsocketperm 777|g" $REDIS_CONF
sed -i "s|port 6379|port 0|g" $REDIS_CONF
sed -i "s|# requirepass foobared|requirepass $REDIS_PASS|g" $REDIS_CONF
redis-cli SHUTDOWN

# Seguranca Redis
chown redis:root /etc/redis/redis.conf
chmod 600 /etc/redis/redis.conf

# Limpeza
apt purge -y \
    git \
    build-essential*

apt update -q4 & spinner_loading
apt autoremove -y
apt autoclean

exit
