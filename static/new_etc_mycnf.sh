#!/bin/bash
# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
MYCNFPW=1 . <(curl -sL curl -sL https://raw.githubusercontent.com/almeida-pf/nextcloud/master/Lib.sh)
unset MYCNFPW

# Verifique se ha erros no codigo e aborta se algo nao estiver correto
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

# Verifica se e root
if ! is_root
then
    printf "\n${Red}Desculpe, voce nao e root.\n${Color_Off}Voce deve digitar: ${Cyan}sudo ${Color_Off}bash %s/nextcloud_install_production.sh\n" "$SCRIPTS"
    exit 1
fi

/bin/cat <<WRITENEW >"$ETCMYCNF"
# Arquivo de configuracao do servidor de banco de dados MariaDB.
#
# Voce pode copiar este arquivo para um dos:
# - "/etc/mysql/my.cnf" para definir opcoes globais,
# - "~/.my.cnf" para definir opcoes especificas do usuario.
# 
# Pode-se usar todas as opcoes que o programa oferece.
# Execute o programa com --help para obter uma lista de opcoes disponiveis e com
# --print-defaults para ver qual seria realmente a sua compreensao e uso.
#
# Para explicacoes, veja
# http://dev.mysql.com/doc/mysql/en/server-system-variables.html

# Isso sera passado para todos os clientes mysql
# Foi relatado que as senhas deveriam ser incluidas ticks/quotes
# especialmente se contiverem "#" como caracteres...
# Lembre-se de editar /etc/mysql/debian.cnf ao mudar a localizacao do soquete.
[client]
port		= 3306
socket		= /var/run/mysqld/mysqld.sock

# Aqui estao as entradas para alguns programas especificos
# Os seguintes valores assumem que voce tem pelo menos 32M de ram

# Isso foi formalmente conhecido como [safe_mysqld]. Ambas as versoes estao atualmente analisadas.
[mysqld_safe]
socket		= /var/run/mysqld/mysqld.sock
nice		= 0

[mysqld]
#
# * Configuracoes basicas
#
user  = mysql
pid-file  = /var/run/mysqld/mysqld.pid
socket  = /var/run/mysqld/mysqld.sock
port  = 3306
basedir = /usr
datadir = /var/lib/mysql
tmpdir  = /tmp
lc_messages_dir = /usr/share/mysql
lc_messages = en_US
skip-external-locking
#
# Em vez de ignorar a rede, o padrao agora e apenas para ouvir.
# localhost que e mais compativel e nao menos seguro.
bind-address		= 127.0.0.1
#
# *Afinacao
#
max_connections		= 100
connect_timeout		= 5
wait_timeout		= 600
max_allowed_packet	= 16M
thread_cache_size       = 128
sort_buffer_size	= 4M
bulk_insert_buffer_size	= 16M
tmp_table_size		= 32M
max_heap_table_size	= 32M
#
# * MyISAM
#
# Isso substitui o script de inicializacao e verifica as tabelas do MyISAM se necessario
# a primeira vez que sao acessadas. Por erro, faca copia e tente um reparo.
myisam_recover_options = BACKUP
key_buffer_size		= 128M
#open-files-limit	= 2000
table_open_cache	= 400
myisam_sort_buffer_size	= 512M
concurrent_insert	= 2
read_buffer_size	= 2M
read_rnd_buffer_size	= 1M
#
# * Configuracao do cache de consulta
#
# Cache apenas pequenos conjuntos de resultados, para que possamos caber mais no cache da consulta.
query_cache_limit		= 128K
query_cache_size		= 64M
# para configuracoes de gravacao mais intensas, configurado para DEMAND ou OFF
#query_cache_type		= DEMAND
#
# * Logging e Replicacao
#
# Ambos os locais sao roteados pelo cronjob.
# Esteja ciente de que este tipo de registro e um assassino de desempenho.
# A partir da 5.1 voce pode habilitar o log em tempo de execucao!
#general_log_file        = /var/log/mysql/mysql.log
#general_log             = 1
#
# O registro de erros vai para o syslog /etc/mysql/conf.d/mysqld_safe_syslog.cnf.
#
# desejamos saber sobre erros de rede e tal
log_warnings		= 2
#
# Habilita o log de consulta lenta para ver consultas com duracao especialmente longa
#slow_query_log[={0|1}]
slow_query_log_file	= /var/log/mysql/mariadb-slow.log
long_query_time = 10
#log_slow_rate_limit	= 1000
log_slow_verbosity	= query_plan

#log-queries-not-using-indexes
#log_slow_admin_statements
#
# O seguinte pode ser usado para reproduzir registros de backup ou para replicacao.
# nota: se voce estiver configurando um escravo de replicacao, veja README.Debian sobre
#       outras configuracoes que você precisara mudar.
#server-id		= 1
#report_host		= master1
#auto_increment_increment = 2
#auto_increment_offset	= 1
log_bin			= /var/log/mysql/mariadb-bin
log_bin_index		= /var/log/mysql/mariadb-bin.index
# nao recomendado para desempenho, mas mais seguro
#sync_binlog		= 1
expire_logs_days	= 10
max_binlog_size         = 100M
# slaves
#relay_log		= /var/log/mysql/relay-bin
#relay_log_index	= /var/log/mysql/relay-bin.index
#relay_log_info_file	= /var/log/mysql/relay-bin.info
#log_slave_updates
#read_only
#
# Se os aplicativos o suportarem, isso e mais seguro sql_mode e evita alguns
# erros como insercao invalida dados e etc.
#sql_mode		= NO_ENGINE_SUBSTITUTION,TRADITIONAL
#
# * InnoDB
#
# InnoDB e habilitado por padrao com um arquivo de dados de 10 MB em /var/lib/mysql/.
# Leia o manual para obter mais opcoes relacionadas ao InnoDB.
default_storage_engine	= InnoDB
#voce nao pode simplesmente alterar o tamanho do arquivo de log, requer um procedimento especial
#innodb_log_file_size	= 50M
innodb_buffer_pool_size	= 256M
innodb_log_buffer_size	= 8M
innodb_file_per_table	= 1
innodb_open_files	= 400
innodb_io_capacity	= 400
innodb_flush_method	= O_DIRECT
innodb_flush_neighbors = 0
innodb_adaptive_flushing = 1
# innodb_max_dirty_pages_pct = 0
innodb_fast_shutdown = 0
innodb_large_prefix=on
innodb_file_format = barracuda
innodb_doublewrite = 0
init-connect='SET NAMES utf8mb4'
collation_server=utf8mb4_unicode_ci
character_set_server = utf8mb4
skip-character-set-client-handshake
innodb_use_native_aio = 1

#
# * Recursos de seguranca
#
# Leia o manual, tambem, se voce quiser do chroot!
# chroot = /var/lib/mysql/
#
# Para gerar certificados SSL, recomendo o OpenSSL GUI "tinyca".
#
# ssl-ca=/etc/mysql/cacert.pem
# ssl-cert=/etc/mysql/server-cert.pem
# ssl-key=/etc/mysql/server-key.pem

#
# * Configuracoes relacionadas com Galera
#
[galera]
# Mandatory settings
#wsrep_on=ON
#wsrep_provider=
#wsrep_cluster_address=
#binlog_format=row
#default_storage_engine=InnoDB
#innodb_autoinc_lock_mode=2
#
# Permitir que o servidor aceite conexoes em todas as interfaces.
#
#bind-address=0.0.0.0
#
# Optional setting
#wsrep_slave_threads=1
innodb_flush_log_at_trx_commit=1

[mysqldump]
quick
quote-names
max_allowed_packet	= 16M

[mysql]
default-character-set = utf8mb4
#no-auto-rehash # inicio mais rapido do mysql mas sem conclusao da guia

[mariadb]
innodb_use_fallocate = 1
innodb_use_atomic_writes = 1
innodb_use_trim = 1

[isamchk]
key_buffer		= 16M

#
# * IMPORTANTE: configuracoes adicionais que podem substituir essas do arquivo!
#   Os arquivos devem terminar com '.cnf', caso contrario, eles serao ignorados.
#
!includedir /etc/mysql/conf.d/
WRITENEW

# Reinicia MariaDB
mysqladmin -u root -p"$MARIADBMYCNFPASS" shutdown --force & spinner_loading
wait
check_command systemctl restart mariadb & spinner_loading

exit
