#!/usr/bin/php

# Creditos para: https://github.com/jnweiger

<?php

#
# Atualiza ou exclua uma entrada em config.php.
# Called by kiwi's config.sh
#
if ($argc < 3)
  {
    print "Exemplo de Uso:\n\t". __FILE__." path/to/config.php overwritewebroot /nextcloud\n";
    print "\t".__FILE__." path/to/config.php trusted_domains[] 17.0.2.15 localhost\n";
    # nada para fazer
    return;
  }


if (!is_file($argv[1]))
  {
    # nao crie o arquivo, se estiver faltando.
    # As permissoes erradas sao fatais para o proximo acesso.
        print($argv[1] . ": \$CONFIG nao pode ser carregado?\n");
    return;
  }

include "$argv[1]";

if ($argc > 3)
  {
    # anexar [] ao nome da chave, se voce precisar passar por um objeto de matriz.
    if (substr($argv[2], -2) === '[]')
      {
        $CONFIG[substr($argv[2],0,-2)] = array_slice($argv,3);
      }
    else
      {
        $CONFIG[$argv[2]] = $argv[3];
      }
  }
else
  {
    # exatamente dois parametros dados - significa excluir.
    unset($CONFIG[$argv[2]]);
  }

$text = var_export($CONFIG, true);
## Um aviso e impresso, se argv [1] nao e agravavel.
## O PHP nao emite errno ou strerror apropriado () faz isso?
file_put_contents($argv[1], "<?php\n\$CONFIG = $text;\n");
?>
