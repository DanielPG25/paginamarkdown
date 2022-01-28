+++ 
draft = true
date = 2022-01-28T13:46:58+01:00
title = "Instalación y configuración de un Servidor de Correos en la VPS"
description = "Instalación y configuración de un Servidor de Correos en la VPS"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Servicios de Red"]
externalLink = ""
series = []
+++

# Práctica: Servidor de correos en la VPS

Instala y configura de manera adecuada el servidor de correos en tu VPS. El nombre del servidor de correo será `mail.tudominio.es` (Este es el nombre que deberá aparecer en el registro MX).

## Gestión de correos desde el servidor

El envío y recepción se hará desde el servidor usando la herramienta `mail`.

### Tarea 1

Documenta una prueba de funcionamiento, donde envíes desde tu servidor local al exterior. Muestra el log donde se vea el envío. Muestra el correo que has recibido. Muestra el registro SPF.

-----------------------------------------------

Para empezar he entrado en la zona DNS de mi hosting para crear el registro MX, que debe estar asociado a un registro de clase A. También he aprovechado para crear el registro SPF:

![img_1.png](/images/practica_servidor_correo/img_1.png)

A continuación hemos instalado postfix en la vps y en la instalación le hemos indicado el dominio (`sysadblog.com`). También aprovechamos e instalamos los paquetes los paquetes necesarios para poder mandar correos:

```
apt install postfix bsd-mailx
```

Como tenemos una ip pública en la VPS, no necesitamos añadir el relay a la configuración de postfix, por lo que podemos pasar directamente a mandar el correo a mi cuenta de gmail:

![img_2.png](/images/practica_servidor_correo/img_2.png)

Ahora veamos los logs para ver si se ha enviado:

![img_3.png](/images/practica_servidor_correo/img_3.png)

Como vemos, según el log se ha enviado correctamente. Veamos si ha recibido en mi cliente de correo:

![img_4.png](/images/practica_servidor_correo/img_4.png)

Como vemos, he recibido correctamente el correo, por lo que podemos decir que esta primera tarea ha sido un éxito.

### Tarea 2

Documenta una prueba de funcionamiento, donde envíes un correo desde el exterior (gmail, hotmail,…) a tu servidor local. Muestra el log donde se vea el envío. Muestra cómo has leído el correo. Muestra el registro MX de tu dominio.

-----------------------------------------------

Vamos a mandar un correo desde mi cliente de correos gmail hacia mi vps:

![img_5.png](/images/practica_servidor_correo/img_5.png)

Como mostramos en la tarea anterior, en el registro dns de mi vps tengo un registro de clase MX que apunta hacia mi máquina, por lo que tendría que poder recibir el correo sin ningún tipo de problema. Veamos los logs de la vps para ver si ha llegado el correo:

![img_6.png](/images/practica_servidor_correo/img_6.png)

En los logs aparece la recepción del correo. Para visualizarlo usaremos la herramienta `mail`:

![img_7.png](/images/practica_servidor_correo/img_7.png)

![img_8.png](/images/practica_servidor_correo/img_8.png)

Con esto hemos acabado la segunda tarea de forma satisfactoria.

## Uso de alias y redirecciones

### Tarea 3

Vamos a comprobar como los procesos del servidor pueden mandar correos para informar sobre su estado. Por ejemplo cada vez que se ejecuta una tarea cron podemos enviar un correo informando del resultado. Normalmente estos correos se mandan al usuario root del servidor, para ello:

```
$ crontab -e
```

E indico donde se envía el correo:

```
MAILTO = root
```

Puedes poner alguna tarea en el cron para ver como se mandan correo.

Posteriormente usando alias y redirecciones podemos hacer llegar esos correos a nuestro correo personal.

Configura el cron para enviar correo al usuario root. Comprueba que están llegando esos correos al root. Crea un nuevo alias para que se manden a un usuario sin privilegios. Comprueban que llegan a ese usuario. Por último crea una redirección para enviar esos correo a tu correo personal (gmail,hotmail,…).

--------------------------------------------------------------

Para empezar he creado una tarea cron que se ejecuta cada 3 minutos y he hecho que mande el mail al usuario "root":

![img_9.png](/images/practica_servidor_correo/img_9.png)

El script que ejecuta es el siguiente:

```
#! /bin/sh

echo "Hola amigo mio, que tengas un buen día"
```

Es un script muy simple que servirá para realizar las pruebas que necesitemos. Ahora crearemos un alias en el fichero `/etc/aliases` para que el correo que le llegue a root sea reenviado a mi usuario "dparrales":

```
nano /etc/aliases

postmaster:    root
root: dparrales
```

Para que se apliquen los cambios realizados en este fichero debemos ejecutar el siguiente comando:

```
newaliases
```

Ahora los correos que le lleguen al usuario "root", deberían llegarle también al usuario "dparrales":

![img_10.png](/images/practica_servidor_correo/img_10.png)

![img_11.png](/images/practica_servidor_correo/img_11.png)

Ahora para hacer que estos correos lleguen a nuestra cuenta principal de correo, debemos crear un fichero llamado `.forward` en el directorio `~` del usuario, en el que añadiremos las cuentas a las que queremos reenviar los mensajes:

```
nano ~/.forward

daniparrales16@gmail.com
```

Veamos si llegan a mi correo:

![img_12.png](/images/practica_servidor_correo/img_12.png)

Como vemos, se han reenviado los correos de forma correcta, por lo que podemos dar por finalizada esta tarea.

## Para asegurar el envío

### Tarea 4

Configura de manera adecuada DKIM es tu sistema de correos. Comprueba el registro DKIM en la página `https://mxtoolbox.com/dkim.aspx`. Configura postfix para que firme los correos que envía. Manda un correo y comprueba la verificación de las firmas en ellos.

----------------------------------------------------------------------

En esta tarea vamos a configurar en nuestra vps "DKIM" (DomainKeys Identified Mail) como método de autenticación del correo que enviamos. Sirve para asegurar que el mensaje no ha sido modificado desde que se envió y consiste básicamente en que publicamos en un registro TXT del DNS la clave pública del servidor de correos. De esta forma, el servidor firmará los mensajes con su clave pública y los clientes podrán usar la clave pública que está en el DNS para comprobar la firma.

Explicado esto, vamos a instalar los paquetes necesarios para configurar DKIM en nuestra vps:

```
apt install opendkim opendkim-tools
```

Ahora modificaremos el fichero de configuración de DKIM (`/etc/opendkim.conf`):

```
nano /etc/opendkim.conf

Syslog                  yes
SyslogSuccess           yes
Canonicalization        relaxed/simple
OversignHeaders         From
Domain                  sysadblog.com
Selector                dkim
KeyFile         		/etc/dkimkeys/dkim.private
UserID                  opendkim
UMask                   007
Socket                  inet:8891@localhost
PidFile                 /run/opendkim/opendkim.pid
TrustAnchorFile         /usr/share/dns/root.key
```

De los parámetros anteriores he dejado por defecto la mayoría. Los que he cambiado son los siguientes:

* **Domain:** Indicamos nuestro dominio.
* **Selector:** Nombre único, el cual utilizaremos más tarde para subir la clave pública al servidor dns y para que el destinatario pueda identificarla fácilmente.
* **KeyFile:** Localización de la clave privada, la cual usaremos para firmar los mensajes.
* **Socket:** Cambiamos el socker UNIX que viene por defecto por uno TCP/IP (comentamos el que venía por defecto y descomentamos este).

Como hemos cambiado el socket, debemos modificar el fichero `/etc/default/opendkim` para indicarlo:

```
nano /etc/default/opendkim

SOCKET=inet:8891@localhost
```

Ahora vamos a tener que modificar el fichero de configuración de Postfix (`/etc/postfix/main.cf`) para indicarle que use este mecanismo para firmar los mensajes:

```
nano /etc/postfix/main.cf

milter_default_action = accept
milter_protocol = 2
smtpd_milters = inet:localhost:8891
non_smtpd_milters = $smtpd_milters
```

Con esto hemos terminado con los ficheros de configuración, por lo que pasaremos a generar el par de claves a las que hemos hecho referencia en los mismos. Para ello nos situamos en el directorio que hemos indicado anteriormente (`/etc/dkimkeys`) y ejecutamos el siguiente comando:

```
opendkim-genkey -s dkim -d sysadblog.com -b 1024
```

Donde:

* "-s:" Indicamos el "Selector" al cual nombramos en la configuración de DKIM.
* "-d:" Indicamos el dominio.
* "-b:" Indicamos el tamaño de la clave.

Al par de claves que se han generado debemos cambiarle el propietario:

```
chown opendkim: dkim.private dkim.txt
```

Ahora ya solo tendríamos que añadir el registro TXT al dns en el cual indicaremos la clave pública. El registro debe comenzar por lo siguiente: `[selector]._domainkey`. Así pues, mi registro quedaría de la siguiente forma:

![img_13.png](/images/practica_servidor_correo/img_13.png)

Si usamos la herramienta que se menciona en el enunciado, podemos comprobar que el registro se ha añadido correctamente:

![img_14.png](/images/practica_servidor_correo/img_14.png)

Sin embargo, esto solo nos indica que el registro se ha añadido de forma correcta, no que nuestro servidor sea capaz de firmar los mensajes con nuestra clave privada. Para comprobar esto último, vamos a tener que mandar un correo y verificar si se ha firmado. Para ello, en primer lugar debemos reiniciar los servicios de postfix y opendkim:

```
systemctl restart opendkim postfix
```

Comprobemos si nuestra vps está escuchando en el puerto que le hemos indicado (8891):

```
netstat -tlnp | egrep opendkim
```

![img_15.png](/images/practica_servidor_correo/img_15.png)

Ahora mandaremos un mensaje a mi cuenta de gmail y veremos si nos indica que está verificado por dkim:

![img_16.png](/images/practica_servidor_correo/img_16.png)

Veamos el mensaje:

![img_17.png](/images/practica_servidor_correo/img_17.png)

Y el contenido original del mensaje:

![img_18.png](/images/practica_servidor_correo/img_18.png)

Como vemos, nos indica que está verificado con DKIM, por lo que podemos decir que esta tarea ha sido un éxito.


## Para luchar contra el SPAM

### Tarea 5

Configura de manera adecuada Postfix para que tenga en cuenta el registro SPF de los correos que recibe. Muestra el log del correo para comprobar que se está haciendo el testeo del registro SPF.

------------------------------------------------------

Para que postfix pueda comprobar los registros SPF de los correo que le llegan, debemos instalar otro paquete que le agregue esa funcionalidad, ya que no la tiene por defecto:

```
apt install postfix-policyd-spf-python
```

Ahora tendremos que modificar la configuración de postfix, de manera que haga uso de las nuevas funcionalidades instaladas para comprobar el correo entrante. Para ello vamos a cambiar la configuración que aparece en el fichero `/etc/postfix/master.cf`:

```
nano /etc/postfix/master.cf

policyd-spf  unix  -    n       n       -       0       spawn
  user=policyd-spf argv=/usr/bin/policyd-spf
```

Con esto hemos hecho que nuestro servidor ejecute un proceso en un socket UNIX que analizará el registro SPF de los mensajes que le lleguen. Sin embargo, aún tenemos que decirle a postfix que debe hacer con los mensajes que pasen dicho filtro. Para ello modificamos lo siguiente en la configuración de postfix (`/etc/postfix/main.cf`):

```
policyd-spf_time_limit = 3600
smtpd_recipient_restrictions = check_policy_service unix:private/policyd-spf
```

Gracias a esto que hemos añadido, cualquier correo que sea recibido pero no pase el filtro SPF será descartado. Para aplicar estos cambios, es necesario reiniciar el servicio de postfix:

```
systemctl restart postfix
```

Ahora comprobemos que lo que hemos hecho funciona. Para ello mandaremos un correo a nuestra vps y veremos lo que aparece en el log:

![img_19.png](/images/practica_servidor_correo/img_19.png)

Como vemos, el correo ha pasado filtro SPF, por lo que hemos podido recibirlo de forma correcta.


### Tarea 6

Configura un sistema antispam. Realiza comprobaciones para comprobarlo.

---------------------------------------------

Para luchar contra el problema del spam, vamos a utilizar una herramienta llamada "SpamAssassin", la cual actuará como filtro en Postfix y nos avisará de cuales de los correos que recibimos son considerados spam. Dicho esto, vamos a proceder a instalar los paquetes necesarios para que funcione SpamAssassin.

```
apt install spamassassin spamc
```

Ahora iniciaremos y habilitaremos el servicio de SpamAssassin:

```
systemctl start spamassassin
systemctl enable spamassassin
```

Para determinar si un correo es spam o no, modificaremos la configuración de SpamAssassin, indicándole que actualice una vez al día la base de datos que usa. Para ello cambiaremos la línea "CRON" del fichero `/etc/default/spamassassin` y cambiaremos su valor a "1":

```
nano /etc/default/spamassassin

CRON=1
```

Ahora tendremos que modificar la configuración de Postfix para indicarle que use SpamAssassin para flitrar los correos. Para ello añadimos a su configuración lo siguiente:

```
nano /etc/postfix/master.cf

smtp      inet  n       -       y       -       -       smtpd
  -o content_filter=spamassassin
submission inet n       -       y       -       -       smtpd
  -o content_filter=spamassassin
spamassassin unix -     n       n       -       -       pipe
  user=debian-spamd argv=/usr/bin/spamc -f -e /usr/sbin/sendmail -oi -f ${sender} ${recipient}
```

Solo nos queda configurar como se identificarán los correos que sean considerados como spam. Para ello modificamos el fichero `/etc/spamassassin/local.cf` y descomentamos la siguiente línea:

```
nano /etc/spamassassin/local.cf

rewrite_header Subject *****SPAM*****
```

Para aplicar todos los cambios que hemos realizado en la configuración, hemos de reiniciar los servicios:

```
systemctl restart postfix spamassassin
```

Comprobemos si funciona el filtro anti-spam. Para ello nos mandaremos un correo de prueba que contendrá la siguiente línea:

```
XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X
```

Cualquier correo que contenga la anterior cadena es inmediatamente considerado como spam, por lo que es perfecta para realizar las pruebas que necesitamos. De esta forma, mandamos el siguiente correo:

![img_20.png](/images/practica_servidor_correo/img_20.png)

Ahora comprobemos si el mensaje aparece en los logs como si fuera spam:

![img_21.png](/images/practica_servidor_correo/img_21.png)

En los logs aparece como spam. Veamos si lo marca como spam en nuestro buzón:

![img_22.png](/images/practica_servidor_correo/img_22.png)

Como vemos, lo ha marcado como spam y ha añadido la cabecera que le indicamos, por lo que podemos identificar los correos spam de forma mucho más sencilla.


### Tarea 7

Configura un sistema antivirus. Realiza comprobaciones para comprobarlo.

------------------------------------------

Para ello, vamos a hacer uso de la herramienta "ClamAV", la cual añadirá un nuevo filtro al correo que recibamos a través de postfix, y nos avisará de que correos son considerados virus. Para poder trabajar con "ClamAV" debemos instalar los siguientes paquetes:

```
apt install clamsmtp clamav-daemon arc arj bzip2 cabextract lzop nomarch p7zip pax tnef unrar-free unzip
```

Al instalarlo, se ha creado un proceso que escucha en la interfaz de loopback:

```
netstat -tlnp | egrep clamsmtp
tcp        0      0 127.0.0.1:10026         0.0.0.0:*               LISTEN      135708/clamsmtpd 
```

A continuación debemos arrancar y habilitar el demonio de ClamAV:

```
systemctl start clamav-daemon
systemctl enable clamav-daemon
```

Ahora modificaremos la configuración de postfix para añadir las directivas necesarias para que se escaneen los correos en busca de virus:

```
nano /etc/postfix/master.cf

scan unix -       -       n       -       16       smtp
  -o smtp_data_done_timeout=1200
  -o smtp_send_xforward_command=yes
  -o disable_dns_lookups=yes
127.0.0.1:10025 inet n       -       n       -       16       smtpd
  -o content_filter=
  -o local_recipient_maps=
  -o relay_recipient_maps=
  -o smtpd_restriction_classes=
  -o smtpd_client_restrictions=
  -o smtpd_helo_restrictions=
  -o smtpd_sender_restrictions=
  -o smtpd_recipient_restrictions=permit_mynetworks,reject
  -o mynetworks_style=host
  -o smtpd_authorized_xforward_hosts=127.0.0.0/8
```

También debemos añadir al fichero de configuración principal de postfix el socket por el que debe comunicarse con ClamAV:

```
nano /etc/postfix/main.cf

content_filter = scan:127.0.0.1:10026
```

Con esto ya estaría listo. Solo tendríamos que reiniciar el servicio de postfix para aplicar los cambios que hemos hecho:

```
systemctl restart postfix
```

Para probar el antivirus, nos mandaremos un correo desde nuestro cliente que contenga la siguiente cadena:

```
X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*
```

La cadena anterior está hecha para pruebas, y debería hacer que el mensaje sea identificado como un virus de forma inmediata. Veámoslo:

![img_23.png](/images/practica_servidor_correo/img_23.png)

Como vemos en el log, ha identificado correctamente el mensaje como un virus, por lo que se ha desecho de él. Con esto podemos dar por finalizada esta tarea.


## Gestión de correos desde un cliente

### Tarea 8

Configura el buzón de los usuarios de tipo `Maildir`. Envía un correo a tu usuario y comprueba que el correo se ha guardado en el buzón `Maildir` del usuario del sistema correspondiente. Recuerda que ese tipo de buzón no se puede leer con la utilidad `mail`.

-----------------------------------------------

Para ello, debemos modificar la configuración principal de postfix, indicándole que en lugar de `mbox`, utilice un buzón de tipo `Maildir`:

```
nano /etc/postfix/main.cf

home_mailbox = Maildir/
```

Ahora debemos reiniciar el servicio de postfix para aplicar los cambios:

```
systemctl restart postfix
```

Sin embargo, una vez que hemos hecho esto, ya no podemos utilizar la herramienta `mail` para visualizar los correos que nos lleguen. Por ello, en su lugar usaremos otra herramienta que sí nos permite esto último: `mutt`.

```
apt install mutt
```

Para que esta herramienta funcione, debemos crear el siguiente fichero con esta configuración:

```
nano ~/.muttrc

set mbox_type=Maildir
set folder="~/Maildir"
set mask="!^\\.[^.]"
set mbox="~/Maildir"
set record="+.Sent"
set postponed="+.Drafts"
set spoolfile="~/Maildir"
```

Con esto ya podríamos hacer uso de dicha herramienta para visualizar los correos. Así pues, vamos a ver si efectivamente, los correos se almacenan en el directorio `Maildir`:

![img_24.png](/images/practica_servidor_correo/img_24.png)

![img_25.png](/images/practica_servidor_correo/img_25.png)

Como vemos lo ha guardado en el directorio Maildir. Para visualizarlo, usaremos la herramienta `mutt`:

![img_26.png](/images/practica_servidor_correo/img_26.png)

![img_27.png](/images/practica_servidor_correo/img_27.png)

De esta forma hemos comprobado que los correos se están guardando en el directorio `Maildir` y también hemos comprobado que podemos visualizarlos con la herramienta `mutt`.


### Tarea 9

Instala configura dovecot para ofrecer el protocolo IMAP. Configura dovecot de manera adecuada para ofrecer autentificación y cifrado.

Para realizar el cifrado de la comunicación crea un certificado en LetsEncrypt para el dominio `mail.dominio.com`. Recuerda que para el ofrecer el cifrado tiene varias soluciones:

* IMAP con STARTTLS: STARTTLS transforma una conexión insegura en una segura mediante el uso de SSL/TLS. Por lo tanto usando el mismo puerto 143/tcp tenemos cifrada la comunicación.
* IMAPS: Versión segura del protocolo IMAP que usa el puerto 993/tcp.
* Ofrecer las dos posibilidades.

Elige una de las opciones anterior para realizar el cifrado. Y muestra la configuración de un cliente de correo (evolution, thunderbird, …) y muestra como puedes leer los correos enviado a tu usuario.

----------------------------------------

Para empezar vamos a instalar dovecot en la VPS:

```
apt install dovecot-imapd
```

Al instalarlo, habrá creado un proceso que estará escuchando en dos sockets TCP/IP diferentes: en el puerto 143 y en el puerto 993:

```
netstat -tlnp | egrep dovecot
tcp        0      0 0.0.0.0:993             0.0.0.0:*               LISTEN      167312/dovecot      
tcp        0      0 0.0.0.0:143             0.0.0.0:*               LISTEN      167312/dovecot      
tcp6       0      0 :::993                  :::*                    LISTEN      167312/dovecot      
tcp6       0      0 :::143                  :::*                    LISTEN      167312/dovecot    
```

A continuación, vamos a generar un certificado en LetsEncrypt para el dominio `mail.sysadblog.com`, el cual usaremos para cifrar la comunicación:

```
certbot certonly --standalone -d mail.sysadblog.com

Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator standalone, Installer None
Requesting a certificate for mail.sysadblog.com
Performing the following challenges:
http-01 challenge for mail.sysadblog.com
Waiting for verification...
Cleaning up challenges

IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/mail.sysadblog.com/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/mail.sysadblog.com/privkey.pem
   Your certificate will expire on 2022-04-27. To obtain a new or
   tweaked version of this certificate in the future, simply run
   certbot again. To non-interactively renew *all* of your
   certificates, run "certbot renew"
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le
```

Con el certificado generado, tendremos que modificar la configuración de dovecot para que haga uso de los mismos para cifrar la configuración:

```
nano /etc/dovecot/conf.d/10-ssl.conf

ssl_cert = </etc/letsencrypt/live/mail.sysadblog.com/fullchain.pem
ssl_key = </etc/letsencrypt/live/mail.sysadblog.com/privkey.pem
```

Ahora tenemos que indicar a dovecot donde se encuentran los correos que debe cifrar y sincronizar con el cliente. Actualmente, dichos correos se encuentran en el directorio `~/Maildir`:

```
nano /etc/dovecot/conf.d/10-mail.conf

mail_location = maildir:~/Maildir
```

Ahora reiniciaremos el servicio de dovecot para aplicar los cambios:

```
systemctl restart dovecot
```

Las comprobaciones de la recepción del correo desde el cliente las haremos en el siguiente apartado, junto al envío de correos desde el cliente, ya que al configurar Evolution nos pide que configuremos también el envío.

## Tarea 11

Configura de manera adecuada postfix para que podamos mandar un correo desde un cliente remoto. La conexión entre cliente y servidor debe estar autentificada con SASL usando dovecot y además debe estar cifrada. Para cifrar esta comunicación puedes usar dos opciones:

* ESMTP + STARTTLS: Usando el puerto 567/tcp enviamos de forma segura el correo al servidor.
* SMTPS: Utiliza un puerto no estándar (465) para SMTPS (Simple Mail Transfer Protocol Secure). No es una extensión de smtp. Es muy parecido a HTTPS.

Elige una de las opciones anterior para realizar el cifrado. Y muestra la configuración de un cliente de correo (evolution, thunderbird, …) y muestra como puedes enviar los correos.

--------------------------------

Siguiendo con el apartado anterior, vamos a utilizar los mismos certificados para cifrar el envío de correos. Así pues, modificaremos la configuración de postfix para que use dichos certificados y para usar autentificación por parte de dovecot:

```
nano /etc/postfix/main.cf

smtpd_tls_cert_file=/etc/letsencrypt/live/mail.sysadblog.com/fullchain.pem
smtpd_tls_key_file=/etc/letsencrypt/live/mail.sysadblog.com/privkey.pem

smtpd_sasl_auth_enable = yes
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_authenticated_header = yes
broken_sasl_auth_clients = yes
```

Ahora tendremos que indicarle a postfix que use los puertos 587/TCP y 465/TCP. Para ello modificamos el siguiente fichero de configuración de postfix y descomentamos estas directivas:

```
nano /etc/postfix/master.cf

submission inet n       -       y       -       -       smtpd
  -o content_filter=spamassassin
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_tls_auth_only=yes
  -o smtpd_reject_unlisted_recipient=no
  -o smtpd_client_restrictions=$mua_client_restrictions
  -o smtpd_helo_restrictions=$mua_helo_restrictions
  -o smtpd_sender_restrictions=$mua_sender_restrictions
  -o smtpd_recipient_restrictions=
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING
smtps     inet  n       -       y       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_reject_unlisted_recipient=no
  -o smtpd_client_restrictions=$mua_client_restrictions
  -o smtpd_helo_restrictions=$mua_helo_restrictions
  -o smtpd_sender_restrictions=$mua_sender_restrictions
  -o smtpd_recipient_restrictions=
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING
```

A continuación debemos indicar a dovecot como tiene que realizar la autentificación. Para ello modificamos el siguiente fichero:

```
nano /etc/dovecot/conf.d/10-master.conf

unix_listener /var/spool/postfix/private/auth {
  mode = 0666
}
```

Con esto ya podemos reiniciar los servicios de postfix y dovecot para aplicar los cambios:

```
systemctl restart postfix dovecot
```

Ahora ya podemos configurar el cliente de correos en nuestro anfitrión. En mi caso he elegido el cliente de correos "Evolution"

![img_28.png](/images/practica_servidor_correo/img_28.png)

![img_29.png](/images/practica_servidor_correo/img_29.png)

![img_30.png](/images/practica_servidor_correo/img_30.png)

![img_31.png](/images/practica_servidor_correo/img_31.png)

![img_32.png](/images/practica_servidor_correo/img_32.png)

Una vez que hemos terminado, podemos ver que se han sincronizado las carpetas `~/Maildir` de nuestra VPS con el cliente de correos Evolution (nos pedirá la contraseña de nuestro usuario en la VPS):

![img_33.png](/images/practica_servidor_correo/img_33.png)

Vamos a probar si al mandar un correo desde gmail hasta nuestra vps se sincronizan las carpetas:

![img_34.png](/images/practica_servidor_correo/img_34.png)

![img_35.png](/images/practica_servidor_correo/img_35.png)

Como vemos, lo hemos recibido en el cliente Evolution, por lo que podemos decir que ambos directorios se sincronizan perfectamente.

Ahora comprobemos si somos capaces de enviar correos desde Evolution usando nuestra cuenta de la VPS a nuestro gmail:

![img_36.png](/images/practica_servidor_correo/img_36.png)

![img_37.png](/images/practica_servidor_correo/img_37.png)

Como podemos ver, el mensaje ha llegado correctamente, por lo que podemos confirmar que tanto el apartado anterior como este ha sido un éxito.

## Tarea 10

Instala un webmail (roundcube, horde, rainloop) para gestionar el correo del equipo mediante una interfaz web. Muestra la configuración necesaria y cómo eres capaz de leer los correos que recibe tu usuario.

----------------------------------------

He elegido como webmail "roundcube". Para la instalación de "roundcube" en la VPS, he decidido hacerlo con contenedores Docker, ya que dispone de una imagen oficial en Docker Hub. Así pues, lo primero será instalarnos Docker en la VPS:

```
apt install docker.io
```

También crearemos un nuevo registro CNAME en el DNS para el nuevo servicio web:

![img_38.png](/images/practica_servidor_correo/img_38.png)

Con esto ya podemos crear el contenedor con la imagen de "roundcube":

```
docker run -e ROUNDCUBEMAIL_DEFAULT_HOST=ssl://mail.sysadblog.com -e ROUNDCUBEMAIL_SMTP_SERVER=ssl://mail.sysadblog.com -e ROUNDCUBEMAIL_SMTP_PORT=465 -e ROUNDCUBEMAIL_DEFAULT_PORT=993 -p 8001:80 -d roundcube/roundcubemail
```

Una vez que se haya descargado y se haya creado el contenedor, debemos obtener un certificado de "Let's Encrypt" para configurar el HTTPS:

```
certbot certonly --standalone -d roundcube.sysadblog.com
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator standalone, Installer None
Requesting a certificate for roundcube.sysadblog.com
Performing the following challenges:
http-01 challenge for roundcube.sysadblog.com
Waiting for verification...
Cleaning up challenges

IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/roundcube.sysadblog.com/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/roundcube.sysadblog.com/privkey.pem
   Your certificate will expire on 2022-04-28. To obtain a new or
   tweaked version of this certificate in the future, simply run
   certbot again. To non-interactively renew *all* of your
   certificates, run "certbot renew"
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le
```

Obtenido el fichero, ya podemos crear el VirtualHost que actuará como ProxyInverso para acceder a Round Cube:

```
nano /etc/nginx/sites-available/roundcube

server {
        listen 80;
        listen [::]:80;

        server_name roundcube.sysadblog.com;

        return 301 https://$host$request_uri;
}

server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;

        ssl    on;
        ssl_certificate /etc/letsencrypt/live/roundcube.sysadblog.com/fullchain.pem;
        ssl_certificate_key     /etc/letsencrypt/live/roundcube.sysadblog.com/privkey.pem;

        index index.html index.php index.htm index.nginx-debian.html;

        server_name roundcube.sysadblog.com;

        location / {
                proxy_pass http://localhost:8001;
                include proxy_params;
        }
}
```

A continuación creamos el enlace simbólico y reiniciamos nginx:

```
ln -s /etc/nginx/sites-available/roundcube /etc/nginx/sites-enabled/roundcube

systemctl restart nginx
```

Una vez que hemos terminado, ya podemos acceder a Round Cube desde nuestro navegador web:

![img_39.png](/images/practica_servidor_correo/img_39.png)

Ingresamos con nuestras credenciales:

![img_40.png](/images/practica_servidor_correo/img_40.png)

Como vemos, nos aparece el buzón de correos, por lo que podríamos decir que la recepción de correos desde nuestro webmail funciona, pero para asegurarnos mandaremos otro correo desde gmail, y veremos si aparece en nuestro buzón:

![img_41.png](/images/practica_servidor_correo/img_41.png)

![img_42.png](/images/practica_servidor_correo/img_42.png)

Con esto hemos comprobado que la recepción de correos funciona. Probemos ahora el envío:

![img_43.png](/images/practica_servidor_correo/img_43.png)

![img_44.png](/images/practica_servidor_correo/img_44.png)

Como vemos, he recibido el correo en mi cuenta de gmail, por lo que podemos decir que tanto la recepción de correos como el envío de los mismos en el webmail ha sido un éxito.

## Tarea 13

Prueba de envío de correo. En esta [página](https://www.mail-tester.com/) tenemos una herramienta completa y fácil de usar a la que podemos enviar un correo para que verifique y puntúe el correo que enviamos. Captura la pantalla y muestra la puntuación que has sacado.

--------------------

Así pues, vamos a mandar el correo a la página que nos han dicho y vamos a ver la puntuación que obtenemos:

![img_45.png](/images/practica_servidor_correo/img_45.png)

Obtenemos lo siguiente:

![img_46.png](/images/practica_servidor_correo/img_46.png)

Aunque la puntuación parece algo baja, realmente es por motivos que no estaban contemplados en la práctica, por lo que podemos dar por finalizada la práctica. 
