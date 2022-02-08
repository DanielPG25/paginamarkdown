+++ 
draft = true
date = 2022-02-04T17:24:54+01:00
title = "Recolección centralizada de logs de sistema mediante journald"
description = "Recolección centralizada de logs de sistema mediante journald"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Administración de Sistemas Operativos"]
externalLink = ""
series = []
+++

# Recolección centralizada de logs de sistema mediante journald

Implementa en tu escenario de trabajo, un sistema de recolección de log mediante journald. Para ello, implementa el sistema de recolección mediante el paquete systemd-journal-remote, o similares.

---------------------------------------------------------------------------

Vamos a centralizar la recogida de logs de nuestro escenario de trabajo. En dicho escenario hay 4 máquinas: "Zeus", una máquina Debian 11, que funciona como cortafuegos y router del escenario, razón por la cual será la máquina en la que centralizaremos la recogida de logs; "Hera", una máquina Rocky 8, que funciona como servidor web; "Apolo", una máquina Debian 11, que funciona como servidor LDAP, de correos y DNS; y "Ares", una máquina Ubuntu Server 20, que funciona como servidor de base de datos, servidor de respaldo de LDAP y director de Bacula.

Con el escenario descrito, vamos a empezar por instalar en todas las máquinas el paquete que se encargará de centralizar la recogida de logs: `systemd-journal-remote`

```
apt install systemd-journal-remote

dnf install systemd-journal-remote
```

Ahora debemos iniciar en Zeus los dos componentes que usará para recibir los mensajes:

```
systemctl enable --now systemd-journal-remote.socket

systemctl enable systemd-journal-remote.service
``` 

En el lado de los clientes, habilitaremos el servicio que permita enviar los logs al servidor:

```
systemctl enable systemd-journal-upload.service
```

Debido a que mi escenario se encuentra aislado, no es posible obtener los certificados necesarios a través de "Let's Encrypt" por lo que tendremos que usar http en lugar de https para centralizar los logs. Igualmente, explicaremos como se haría en caso de que sí pudiésemos obtener dichos certificados. En primer, tendríamos que obtener los certificados de "Let's Encrypt" con "certbot" en cada máquina:

```
apt/dnf install certbot

certbot certonly --standalone --agree-tos --email daniparrales16@gmail.com -d dparrales.gonzalonazareno.org
``` 

Ahora tendremos que descargar los certificados CA de Let's Encrypt y de nivel intermedio en el mismo archivo. `jounald` usará este archivo para verificar la autenticidad de los certificados entre servidor y clientes:

```
curl -s https://letsencrypt.org/certs/{isrgrootx1.pem.txt,letsencryptauthorityx3.pem.txt} > ~/letsencrypt-combined-certs.pem
```

Ahora tendríamos que mover dicho fichero al directorio en el que certbot ha introducido los certificados que conseguimos anteriormente:

```
cp ~/letsencrypt-combined-certs.pem /etc/letsencrypt/live/dparrales.gonzalonazareno.org/
```

Una vez hecho esto, ya podemos configurar el servidor. Para ello ello modificaremos el fichero `/etc/systemd/journal-remote.conf` en Zeus:

Si tuviéramos los certificados, lo dejaríamos de la siguiente forma:

```
[Remote]
Seal=false
SplitMode=host
ServerKeyFile=/etc/letsencrypt/live/dparrales.gonzalonazareno.org/privkey.pem
ServerCertificateFile=/etc/letsencrypt/live/dparrales.gonzalonazareno.org/fullchain.pem
TrustedCertificateFile=/etc/letsencrypt/live/dparrales.gonzalonazareno.org/letsencrypt-combined-certs.pem
```

Y tendríamos que cambiar los permisos de dichos certificados y el grupo de la clave privada para que `systemd-journal-remote` los pudiera usar:

```
chmod 0755 /etc/letsencrypt/{live,archive}
chmod 0640 /etc/letsencrypt/live/dparrales.gonzalonazareno.org/privkey.pem
chgrp systemd-journal-remote /etc/letsencrypt/live/dparrales.gonzalonazareno.org/privkey.pem
```

Sin embargo, debido a que no tenemos los certificados necesarios, tendremos que configurar el servicio para que use http en lugar de https. Para ello, tendremos que copiar y modificar el siguiente fichero:

```
cp /lib/systemd/system/systemd-journal-remote.service /etc/systemd/system/
```

```
nano /etc/systemd/system/systemd-journal-remote.service

[Unit]
Description=Journal Remote Sink Service
Documentation=man:systemd-journal-remote(8) man:journal-remote.conf(5)
Requires=systemd-journal-remote.socket

[Service]
ExecStart=/lib/systemd/systemd-journal-remote --listen-http=-3 --output=/var/log/journal/remote/
User=systemd-journal-remote
Group=systemd-journal-remote
PrivateTmp=yes
PrivateDevices=yes
PrivateNetwork=yes
WatchdogSec=3min

[Install]
Also=systemd-journal-remote.socket
```

Si el directorio que le hemos indicado no existiese, tendríamos que crearlo y cambiar el dueño:

```
mkdir /var/log/journal/remote
chown systemd-journal-remote /var/log/journal/remote
```

Recargamos la configuración del demonio:

```
systemctl daemon-reload
```

Ahora podemos reiniciar el servicio en el servidor:

```
systemctl start systemd-journal-remote.service
```

Una vez terminado con el servidor, procedamos con los clientes. Así pues, en los clientes, tendremos que crear un usuario llamado `systemd-journal-upload`:

```
#En Debian/Ubuntu
adduser --system --home /run/systemd --no-create-home --disabled-login --group systemd-journal-upload 

#En Rocky
adduser --system --home /run/systemd --no-create-home --user-group systemd-journal-upload
```

Una vez hecho esto, si tuviéramos los certificados, deberíamos hacer lo mismo que en el servidor (cambiar los permisos y grupos a dichos certificados):

```
chmod 0755 /etc/letsencrypt/{live,archive}
chmod 0640 /etc/letsencrypt/live/dparrales.gonzalonazareno.org/privkey.pem
chgrp systemd-journal-remote /etc/letsencrypt/live/dparrales.gonzalonazareno.org/privkey.pem
``` 

Y modificaríamos la configuración del `journal-upload` de la siguiente forma:

```
nano /etc/systemd/journal-upload.conf

[Upload]
URL=https://zeus.dparrales.gonzalonazareno.org:19532
ServerKeyFile=/etc/letsencrypt/live/dparrales.gonzalonazareno.org/privkey.pem
ServerCertificateFile=/etc/letsencrypt/live/dparrales.gonzalonazareno.org/fullchain.pem
TrustedCertificateFile=/etc/letsencrypt/live/dparrales.gonzalonazareno.org/letsencrypt-combined-certs.pem
```

Sin embargo, y debido a vamos a usar http, el fichero queda de la siguiente forma:

```
nano /etc/systemd/journal-upload.conf

[Upload]
URL=http://zeus.dparrales.gonzalonazareno.org:19532
```

Ahora reiniciamos el servicio y ya estaría funcionando:

```
systemctl restart systemd-journal-upload.service
```

Si miramos en el directorio `/var/log/journal/remote/` del servidor, podemos ver lo siguiente:

![img_1.png](/images/centralizar_logs_journald/img_1.png)

Como vemos, se han creado tres ficheros con las ip de los clientes. Para visualizar dichos logs, tendremos que usar el siguiente comando:

```
journalctl --file=ruta/al/fichero
```

De esta forma, si queremos ver el log de Ares, ejecutamos lo siguiente:

```
journalctl --file=/var/log/journal/remote/remote-10.0.1.101.journal
```

![img_2.png](/images/centralizar_logs_journald/img_2.png)

Como vemos, Zeus es capaz de recolectar los logs de todos lo miembros del escenario, por lo que podemos concluir que la práctica ha sido un éxito.
