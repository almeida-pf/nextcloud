<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
    <head>
        <title>Nextcloud VM</title>
        <META NAME="ROBOTS" CONTENT="NOINDEX, NOFOLLOW">
        <style type="text/css">
            body {
                background-color: #0082c9;
                font-weight: 300;
                font-size: 1em;
                line-height: 1.6em;
                font-family: 'Open Sans', Frutiger, Calibri, 'Myriad Pro', Myriad, sans-serif;
                color: white;
                height: auto;
                margin-left: auto;
                margin-right: auto;
                align: center;
                text-align: center;
                background: #0082c9; /* Browsers antigos */
                background-image: url('https://raw.githubusercontent.com/nextcloud/server/master/core/img/background.jpg');
                background-size: cover;
            }
            div.logotext   {
                width: 50%;
                margin: 0 auto;
            }
            div.logo   {
                background-image: url('/nextcloud/core/img/logo-icon.svg');
                background-repeat: no-repeat; top center;
                width: 50%;
                height: 25%;
                margin: 0 auto;
                background-size: 40%;
                margin-left: 40%;
                margin-right: 20%;
            }
            pre  {
                padding:10pt;
                width: 50%
                text-align: center;
                margin-left: 20%;
                margin-right: 20%;
            }
            div.information {
                align: center;
                width: 50%;
                margin: 10px auto;
                display: block;
                padding: 10px;
                background-color: rgba(0,0,0,.3);
                color: #fff;
                text-align: left;
                border-radius: 3px;
                cursor: default;
            }
            /* Link nao visitado */
            a:link {
                color: #FFFFFF;
            }
            /* Link visitado */
            a:visited {
                color: #FFFFFF;
            }
            /* Link passe o mouse por cima */
            a:hover {
                color: #E0E0E0;
            }
            /* Selecione o link */
            a:active {
                color: #E0E0E0;
            }
        </style>
    </head>
    <body>
        <br>
        <div class="logo"></div>
        <div class="logotext">
            <h2><a href="https://github.com/almeida-pf/nextcloud" target="_blank">Nextcloud VM</a> - by <a href="https://nextcloud.com" target="_blank">Nextcloud Community</a></h2>
        </div>
        <br>
        <div class="information">
            <p>Obrigado por fazer o download da VM Nextcloud pré-configurada! Se você ver esta página, você montou com sucesso o Nextcloud VM no computador que atuará como host para Nextcloud.</p>
            <p>Nós Configuramos tudo para você e a única coisa que você precisa fazer agora é fazer o login. Você pode encontrar detalhes de login em no meio desta página.</p>
            <p>Não hesite em perguntar se você tem alguma dúvida. Você pode pedir ajuda em nossa comunidade <a href="https://help.nextcloud.com/c/support/appliances-docker-snappy-vm" target="_blank">support</a> channels. Você também pode verificar o link <a href="https://www.techandme.se/complete-install-instructions-nextcloud/" target="_blank">completo instruções de instalação</a>.</p>
        </div>

        <h2><a href="https://www.techandme.se/user-and-password-nextcloud/" target="_blank">Login</a> to Nextcloud</h2>

        <div class="information">
            <p>Usuário padrão:</p>
            <h3>ncadmin</h3>
            <p>Senha padrão:</p>
            <h3>nextcloud</h3>
            <p>Nota: O script de configuração pedirá que você altere a senha padrão para o seu próprio bem. Também é recomendado mudar o usuário padrão. Faça isso adicionando outro usuário administrador, desconecte-se do ncadmin e faça o login com seu novo usuário e, em seguida, exclua ncadmin.</p>
            <br>
            <center>
                <h3> Como montar a VM e fazer login:</h3>
            </center>
            <p>Antes de poder usar o Nextcloud, você deve executar o script de instalação para concluir a instalação. Isso é facilmente feito apenas digitando 'nextcloud' quando inicia sessão no terminal pela primeira vez.</p>
            <p>O caminho completo para o script de instalação é: /var/scripts/nextcloud-startup-script.sh. Quando o script for finalizado, ele pode ser excluído, pois é usado apenas a primeira vez que você inicializa a máquina.</p>
            <center>
                <iframe width="560" height="315" src="https://www.youtube.com/embed/-3fKEu2HhJo" frameborder="0" allowfullscreen></iframe>
            </center>
        </div>

        <h2>Access Nextcloud</h2>

        <div class="information">
            <p>Use um dos seguintes endereços, HTTPS é preferido:
            <h3>
                <ul>
                    <li><a href="http://<?=$_SERVER['SERVER_NAME'];?>/nextcloud">http://<?=$_SERVER['SERVER_NAME'];?></a> (HTTP)
                    <li><a href="https://<?=$_SERVER['SERVER_NAME'];?>/nextcloud">https://<?=$_SERVER['SERVER_NAME'];?></a> (HTTPS)
                </ul>
            </h3>
            <p>Nota: Aceite o aviso no navegador se você se conectar via HTTPS. É recomendado<br>
            para <a href="https://www.techandme.se/publish-your-server-online" target="_blank">comprar seu próprio certificado e substitua o certificado auto-assinado pelo o seu próprio.</a></p>
            <p>Nota: Antes de iniciar sessão, você deve executar o script de instalação, conforme descrito no vídeo acima.</p>
        </div>

        <h2>Acesso ao Webmin</h2>

        <div class="information">
            <p>Use um dos seguintes endereços, HTTPS é preferido:
            <h3>
                <ul>
                    <li><a href="http://<?=$_SERVER['SERVER_NAME'];?>:10000">http://<?=$_SERVER['SERVER_NAME'];?></a> (HTTP)</li>
                    <li><a href="https://<?=$_SERVER['SERVER_NAME'];?>:10000">https://<?=$_SERVER['SERVER_NAME'];?></a> (HTTPS)</li>
                </ul>
            </h3>
            <p>Nota: Aceite o aviso no navegador se você se conectar via HTTPS.</p>
            <h3>
                <a href="https://www.techandme.se/user-and-password-nextcloud/" target="_blank">Login details</a>
            </h3>
            <p>Nota: O Webmin está instalado. Para acessar o Webmin externamente, você precisa abrir a porta 10000 no seu roteador.</p>
        </div>

        <h2>Acesso phpMyadmin</h2>

        <div class="information">
            <p>Use um dos seguintes endereços, HTTPS é recomendado:
            <h3>
                <ul>
                    <li><a href="http://<?=$_SERVER['SERVER_NAME'];?>/phpmyadmin">http://<?=$_SERVER['SERVER_NAME'];?></a> (HTTP)</li>
                    <li><a href="https://<?=$_SERVER['SERVER_NAME'];?>/phpmyadmin">https://<?=$_SERVER['SERVER_NAME'];?></a> (HTTPS)</li>
                </ul>
            </h3>
            <p>Nota: Aceite o aviso no navegador se você se conectar via HTTPS.</p>
            <h3>
                <a href="https://www.techandme.se/user-and-password-nextcloud/" target="_blank">Login details</a>
            </h3>
            <p>Nota: O seu IP externo está configurado como aprovado em /etc/apache2/conf-available/phpemadmin.conf, todos os outros acessos são proibidos.</p>
        </div>
    </body>
</html>
