+++ 
draft = true
date = 2021-10-28T11:07:36+02:00
title = "Implantación de aplicaciones web PHP"
description = "Implantación de aplicaciones web PHP"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Aplicaciones Web"]
externalLink = ""
series = []
+++

# Práctica: Implantación de aplicaciones web PHP

Los requisitos previos son los siguientes:

* Crea una instancia de vagrant basado en un box debian o ubuntu
* Instala en esa máquina virtual toda la pila LAMP

## Tarea 1: Instalación de un CMS PHP en mi servidor local

Los objetivos de esta tarea son los siguientes:

* Configura el servidor web con virtual hosting para que el CMS sea accesible desde la dirección: `www.nombrealumno-nombrecms.org`.
* Crea un usuario en la base de datos para trabajar con la base de datos donde se van a guardar los datos del CMS.
* Descarga el CMS seleccionado y realiza la instalación.
* Realiza una configuración mínima de la aplicación (Cambia la plantilla, crea algún contenido, …)
* Instala un módulo para añadir alguna funcionalidad al CMS.

### Configura el servidor web con virtual hosting para que el CMS sea accesible desde la dirección: `www.nombrealumno-nombrecms.org`

Vamos a crear el fichero de configuración del virtualhost en el directorio `/etc/apache2/sites-available`, y lo vamos a llamar *dparrales-mediawiki.conf*. La configuración del virtualhost es la siguiente:

```
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName www.dparrales-mediawiki.com
    ServerAlias www.dparrales-mediawiki.com
    DocumentRoot /var/www/www.dparrales-mediawiki.com
    ErrorLog ${APACHE_LOG_DIR}/error-mediawiki.log
    CustomLog ${APACHE_LOG_DIR}/access-media-wiki.log combined

    <Directory /var/www/www.dparrales-mediawiki.com>
          Options -Indexes
    </Directory>

    <IfModule mod_dir.c>
        DirectoryIndex index.php index.html index.cgi index.pl  index.xhtml index.htm
    </IfModule>

</VirtualHost>
```

Ahora habilitamos el virtualhost con el siguiente comando:

`
a2ensite dparrales-mediawiki.conf
`

También hay que crear la carpeta y un archivo de prueba en el DocumentRoot:

```
tree /var/www/www.dparrales-mediawiki.com/
/var/www/www.dparrales-mediawiki.com/
└── info.php

0 directories, 1 file
```

Reiniciamos el servicio para aplicar los cambios que hemos hecho:

`
systemctl reload apache2
`

Ya solo tenemos que añadir la línea de resolución de nombres al fichero */etc/hosts* del anfitrión:

`
192.168.121.241 www.dparrales-mediawiki.com
`

Con esto, ya podemos acceder a través de nuestro navegador y ver si se nos muestra la pantalla de información sobre *php* que tenemos en el servidor:


![conexion_primera.png](/images/practicacms/conexion_primera.png)


### Crea un usuario en la base de datos para trabajar con la base de datos donde se van a guardar los datos del CMS.

Antes con continuar con la instalación, debemos crear una base de datos en mariadb y un usuario con permisos sobre esa base de datos:

```
mysql -u root -p
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 6
Server version: 10.5.12-MariaDB-0+deb11u1 Debian 11

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> create database mediawiki
    -> ;
Query OK, 1 row affected (0.007 sec)

MariaDB [(none)]> grant all on mediawiki.* to 'mediawiki'@'%' identified by '******' with grant option;
Query OK, 0 rows affected (0.010 sec)
```


### Descarga el CMS seleccionado y realiza la instalación.

Ahora podemos descargar los archivos de configuración y descomprimir el cms en el DocumentRoot:


```
wget https://releases.wikimedia.org/mediawiki/1.36/mediawiki-1.36.2.tar.gz

tar -vxf mediawiki-1.36.2.tar.gz
```


Ya podemos configurar el cms si accedemos desde el navegador a la ruta donde se encuentra el fichero de configuración:


![configuracion_mediawiki1.png](/images/practicacms/configuracion_mediawiki1.png)


Como podemos ver, se nos pide que instalemos unos paquetes antes de realizar la configuración:


```
apt install php-mbstring php-xml php-intl

systemctl reload apache2
```


Ahora al acceder a la misma url nos sale el menú de configuración:

![configuracion_mediawiki2.png](/images/practicacms/configuracion_mediawiki2.png)


Ya podemos iniciar la configuración de mediawiki. Tras rellenar todos los campos en las páginas de configuración con los datos del usuario y de la base de datos que creamos antes, llegamos al final de la instalación:


![finalizarmediawiki.png](/images/practicacms/finalizarmediawiki.png)


Haciendo caso a lo que nos dice la página y copiamos el archivo que se ha descargado (*LocalSettings.php*) en el directorio donde se encontraba el *index.php* (*`www.dparrales-mediawiki.com/mediawiki-1.36.2`*):

```
ls -l

total 1636
-rw-rw-r--  1 www-data www-data     168 Sep 30 16:46 CODE_OF_CONDUCT.md
-rw-rw-r--  1 www-data www-data   19421 Nov  4  2019 COPYING
-rw-rw-r--  1 www-data www-data   13612 Sep 30 16:48 CREDITS
-rw-rw-r--  1 www-data www-data      95 Nov  4  2019 FAQ
-rw-rw-r--  1 www-data www-data 1247893 Sep 30 16:48 HISTORY
-rw-rw-r--  1 www-data www-data    3612 Sep 30 16:48 INSTALL
-rw-r--r--  1 www-data www-data    4634 Oct 21 07:13 LocalSettings.php
-rw-rw-r--  1 www-data www-data    1525 Sep 30 16:46 README.md
-rw-rw-r--  1 www-data www-data   48038 Sep 30 16:48 RELEASE-NOTES-1.36
-rw-rw-r--  1 www-data www-data     199 Nov  4  2019 SECURITY
-rw-rw-r--  1 www-data www-data    4544 Sep 30 16:48 UPGRADE
-rw-rw-r--  1 www-data www-data    4490 Sep 30 16:46 api.php
-rw-rw-r--  1 www-data www-data  156893 Sep 30 16:48 autoload.php
drwxr-xr-x  2 www-data www-data    4096 Oct 20 12:33 cache
-rw-rw-r--  1 www-data www-data    5073 Sep 30 16:48 composer.json
-rw-rw-r--  1 www-data www-data     102 Nov  4  2019 composer.local.json-sample
drwxr-xr-x  5 www-data www-data    4096 Oct 20 12:33 docs
drwxr-xr-x 30 www-data www-data    4096 Oct 20 12:33 extensions
drwxr-xr-x  2 www-data www-data    4096 Oct 21 06:59 images
-rw-rw-r--  1 www-data www-data    8245 Sep 30 16:46 img_auth.php
drwxr-xr-x 83 www-data www-data    4096 Oct 20 12:33 includes
-rw-rw-r--  1 www-data www-data    1977 Sep 30 16:46 index.php
-rw-rw-r--  1 www-data www-data    1430 Sep 30 16:48 jsduck.json
drwxr-xr-x  6 www-data www-data    4096 Oct 20 12:33 languages
-rw-rw-r--  1 www-data www-data    1951 Sep 30 16:46 load.php
drwxr-xr-x 15 www-data www-data   12288 Oct 20 12:33 maintenance
drwxr-xr-x  4 www-data www-data    4096 Oct 21 07:20 mw-config
-rw-rw-r--  1 www-data www-data    4610 Sep 30 16:46 opensearch_desc.php
drwxr-xr-x  5 www-data www-data    4096 Oct 20 12:33 resources
-rw-rw-r--  1 www-data www-data     998 Sep 30 16:46 rest.php
drwxr-xr-x  5 www-data www-data    4096 Oct 20 12:33 skins
drwxr-xr-x  9 www-data www-data    4096 Oct 20 12:33 tests
-rw-rw-r--  1 www-data www-data   23581 Sep 30 16:48 thumb.php
-rw-rw-r--  1 www-data www-data    1439 Sep 30 16:46 thumb_handler.php
drwxr-xr-x 17 www-data www-data    4096 Oct 20 12:33 vendor
```


Ahora ya podemos acceder a la página principal al entrar en la ruta donde hemos guardado el fichero *LocalSettings.php*:

![paginaprincipal_mediawiki.png](/images/practicacms/paginaprincipal_mediawiki.png)


### Realiza una configuración mínima de la aplicación (Cambia la plantilla, crea algún contenido, …)

Para este paso he creado un nuevo post en la página de mediawiki sobre mi usuario: *mediawiki*:

![primerpost.png](/images/practicacms/primerpost.png)


### Instala un módulo para añadir alguna funcionalidad al CMS.

En mi caso, voy a instalar una extensión que nos permitirá tener un calendario en la página de la wiki. Para ello descargamos primero la extensión:

`
wget https://extdist.wmflabs.org/dist/extensions/SimpleCalendar-master-dc0b4a4.tar.gz
`

A continuación, descomprimimos el archivo en la carpeta `/extensions` de mediawiki:

`
tar -xzf SimpleCalendar-master-dc0b4a4.tar.gz -C /var/www/www.dparrales-mediawiki.com/mediawiki-1.36.2/extensions/
`

Ya solo tenemos que añadir la siguiente línea al final del fichero *LocalSettings.php* y reiniciar el servicio:

```
wfLoadExtension( 'SimpleCalendar' );

systemctl reload apache2
```

Con esto ya debería aparecernos la nueva extensión en la lista de extensiones instaladas:

![extensioninstalada.png](/images/practicacms/extensioninstalada.png)



## Tarea 2: Configuración multinodo


Los objetivos de esta tarea son los siguientes:

* Realiza un copia de seguridad de la base de datos
* Crea otra máquina con vagrant, conectada con una red interna a la anterior y configura un servidor de base de datos.
* Crea un usuario en la base de datos para trabajar con la nueva base de datos.
* Restaura la copia de seguridad en el nuevo servidor de base datos.
* Desinstala el servidor de base de datos en el servidor principal.
* Realiza los cambios de configuración necesario en el CMS para que la página funcione.


------------------------


## Realiza un copia de seguridad de la base de datos


Para realizar la copia de seguridad basta con utilizar el siguiente comando, lo que nos generará un fichero sql con la información de la base de datos que le indiquemos:

```
mysqldump -v --opt --events --routines --triggers --default-character-set=utf8 -u mediawiki -p mediawiki > db_backup_mediawiki_`date +%Y%m%d_%H%M%S`.sql
```

Este fichero `.sql` podemos comprimirlo después para que sea más manejable, pero como esta base de datos es nueva y apenas tiene contenido, no he visto necesario comprimirlo:

```
ls -lh

-rw-r--r-- 1 vagrant vagrant 2.4M Oct 26 06:36 db_backup_mediawiki_20211026_063630.sql
```


## Crea otra máquina con vagrant, conectada con una red interna a la anterior y configura un servidor de base de datos.


Para ello vamos a utilizar la misma configuración de vagrant que con el anterior, por lo que su creación será bastante rápida. A continuación el `Vagrantfile` que he usado:

```
Vagrant.configure("2") do |config|
      config.vm.provider :libvirt do |v|
      v.memory = 1024
      end
    config.vm.define :nodo1 do |nodo1|
      nodo1.vm.box = "debian/bullseye64"
      nodo1.vm.hostname = "CMS1"
      nodo1.vm.synced_folder ".", "/vagrant", disabled: true
      nodo1.vm.network :private_network,
         :libvirt__network_name => "muyaislada",
         :libvirt__dhcp_enabled => false,
         :ip => "10.0.0.2",
         :libvirt__forward_mode => "veryisolated"
     end
    config.vm.define :nodo2 do |nodo2|
      nodo2.vm.synced_folder ".", "/vagrant", disabled: true
      nodo2.vm.box = "debian/bullseye64"
      nodo2.vm.hostname = "CMS2"
      nodo2.vm.network :private_network,
         :libvirt__network_name => "muyaislada",
         :libvirt__dhcp_enabled => false,
         :ip => "10.0.0.3",
         :libvirt__forward_mode => "veryisolated"
     end
end
```


A continuación instalamos, securizamos la base de datos mariadb y la configuramos para que pueda ser accedida desde el exterior:


```
apt-get install mariadb-server

mysql_secure_installation
```

```
nano /etc/mysql/mariadb.conf.d/50-server.cnf

bind-address            = 0.0.0.0
```

Reiniciamos el servicio para que cargue la nueva configuración:

`
systemctl restart mariadb
`

## Crea un usuario en la base de datos para trabajar con la nueva base de datos.

Entramos como root y creamos el nuevo usuario. Para facilitarnos el trabajo, hemos creado el mismo usuario que en la anterior base de datos:

`
create user 'mediawiki'@'%' identified by '******';
`


## Restaura la copia de seguridad en el nuevo servidor de base datos.

Para ello hemos de llevar el fichero `.sql` de la forma que queramos desde una máquina a otra, y una vez allí usamos el siguiente comando para restaurar la copia de seguridad:


`
mysql -u mediawiki -p mediawiki < db_backup_mediawiki_20211026_063630.sql
`

*Nota*: Antes hemos de haber creado la base de datos a la que hacemos referencia en el comando (mediawiki) y haber otorgado permisos al usuario sobre esa base de datos.



## Desinstala el servidor de base de datos en el servidor principal.

Para ello simplemente usamos el siguiente comando:

`
apt remove mariadb-server
`


## Realiza los cambios de configuración necesario en el CMS para que la página funcione.

Cambiar la configuración de mediawiki para que utilice otro servidor es bastante sencilla. Para ello tenemos que modificar el fichero *LocalSettings.php*. Las líneas que debemos cambiar son las siguientes:


![configuracion_mediawiki_dbexterna.png](/images/practicacms/configuracion_mediawiki_dbexterna.png)


## Tarea 3: Instalación de otro CMS PHP

Los objetivos de esta tarea son los siguientes:

* Elige otro CMS realizado en PHP y realiza la instalación en tu infraestructura.
* Configura otro virtualhost para acceder con otro nombre: `www.nombrealumno-nombrecms.org`.

----------------------------------------------------------------------------------


## Elige otro CMS realizado en PHP y realiza la instalación en tu infraestructura (con otro virtualhost).

He elegido el cms OpenCart, un sistema de administración online, que utiliza PHP y una base de datos Mysql. Los primeros pasos serán similares a los anteriores:

* Creamos un nuevo virtualhost para OpenCart:

```
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName www.dparrales-opencart.org
    ServerAlias www.dparrales-opencart.org
    DocumentRoot /var/www/opencart
    ErrorLog ${APACHE_LOG_DIR}/error-opencart.log
    CustomLog ${APACHE_LOG_DIR}/access-opencart.log combined

    <Directory /var/www/opencart>
          Options -Indexes
    </Directory>

    <IfModule mod_dir.c>
        DirectoryIndex index.php index.html index.cgi index.pl  index.xhtml index.htm
    </IfModule>

</VirtualHost>
```

* Habilitamos el virtualhost y reiniciamos el servicio:

```
a2ensite dparrales-opencart.conf 

systemctl reload apache2
```


* Descargamos y extraemos el archivo de instalación de opencart en el DocumentRoot:

```
ls -l /var/www/opencart/
total 17296
-rw-r--r-- 1 root    root       33574 Aug 27 07:28 CHANGELOG.md
-rw-r--r-- 1 root    root      327817 Aug 27 07:28 CHANGELOG_AUTO.md
-rw-r--r-- 1 root    root        5021 Aug 27 07:28 README.md
-rw-r--r-- 1 root    root        2106 Aug 27 07:28 build.xml
-rw-r--r-- 1 root    root         622 Aug 27 07:28 composer.json
-rw-r--r-- 1 root    root       36033 Aug 27 07:28 composer.lock
-rw-r--r-- 1 root    root        3709 Aug 27 07:28 install.txt
-rw-r--r-- 1 root    root       34529 Aug 27 07:28 license.txt
-rw-r--r-- 1 vagrant vagrant 17233835 Oct 27 12:20 opencart-3.0.3.8.zip
-rw-r--r-- 1 root    root        5995 Aug 27 07:28 upgrade.txt
drwxr-xr-x 7 root    root        4096 Aug 27 07:28 upload
```

* Antes de seguir con la instalación, creamos la base de datos y un nuevo usuario para administrar dicha base de datos:

```
mysql -u root -p
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 6
Server version: 10.5.12-MariaDB-0+deb11u1 Debian 11

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> create database opencart;
Query OK, 1 row affected (0.007 sec)

MariaDB [(none)]> grant all on opencart.* to 'opencart'@'%' identified by '******' with gra
nt option;
Query OK, 0 rows affected (0.015 sec)
```

* Leemos las instrucciones para instalar *opencart*:

```
- Linux Install -

1. Upload all of the files and folders to your server from the "Upload" folder, place them in your web root. The web root is different on some servers, cPanel it should be public_html/ and on Plesk it should be httpdocs/.

2. Rename config-dist.php to config.php and admin/config-dist.php to admin/config.php

3. For Linux/Unix make sure the following folders and files are writable.

        chmod 0755 system/storage/cache/
        chmod 0755 system/storage/download/
        chmod 0755 system/storage/logs/
        chmod 0755 system/storage/modification/
        chmod 0755 system/storage/session/
        chmod 0755 system/storage/upload/
        chmod 0755 system/storage/vendor/
        chmod 0755 image/
        chmod 0755 image/cache/
        chmod 0755 image/catalog/
        chmod 0755 config.php
        chmod 0755 admin/config.php

        If 0755 does not work try 0777.

4. Make sure you have installed a MySQL Database which has a user assigned to it
    DO NOT USE YOUR ROOT USERNAME AND ROOT PASSWORD

5. Visit the store homepage e.g. http://www.example.com or http://www.example.com/store/

6. You should be taken to the installer page. Follow the on screen instructions.

7. After successful install, delete the /install/ directory from ftp.

8. If you have downloaded the compiled version with a folder called "vendor" - this should be uploaded above the webroot (so the same folder where the public_html or httpdocs is)
```

* Seguimos lo que se nos indica:

```
mv config-dist.php config.php
mv admin/config-dist.php admin/config.php
chmod 0755 system/storage/cache/
chmod 0755 system/storage/download/
chmod 0755 system/storage/logs/
chmod 0755 system/storage/modification/
chmod 0755 system/storage/session/
chmod 0755 system/storage/upload/
chmod 0755 system/storage/vendor/
chmod 0755 image/
chmod 0755 image/cache/
chmod 0755 image/catalog/
chmod 0755 config.php
chmod 0755 admin/config.php
mv upload/* .
```

* Nos quedan los siguientes ficheros y directorios en el DocumentRoot:

```
ls -l /var/www/opencart/
total 32
drwxr-xr-x 6 www-data www-data 4096 Oct 27 15:32 admin
drwxr-xr-x 6 www-data www-data 4096 Aug 27 07:28 catalog
-rwxr-xr-x 1 www-data www-data    0 Aug 27 07:28 config.php
drwxr-xr-x 5 www-data www-data 4096 Aug 27 07:28 image
-rw-r--r-- 1 www-data www-data  293 Aug 27 07:28 index.php
drwxr-xr-x 6 www-data www-data 4096 Aug 27 07:28 install
-rw-r--r-- 1 www-data www-data  418 Aug 27 07:28 php.ini
-rw-r--r-- 1 www-data www-data  345 Aug 27 07:28 robots.txt
drwxr-xr-x 7 www-data www-data 4096 Aug 27 07:28 system
```

* Ahora accedemos a nuestro virtualhost a través del navegador para continuar con la instalación (previamente añadiendo la resolución de nombres al fichero `/etc/hosts`):


![instalar_opencart.png](/images/practicacms/instalar_opencart.png)


* Nos aseguramos de tener instaladas todas las dependencias y de que los directorios que nos indica tienen los permisos correctos:


![requisitos_opencart.png](/images/practicacms/requisitos_opencart.png)


![requisitos_opencart2.png](/images/practicacms/requisitos_opencart2.png)


* Rellenamos con la información de nuestra base de datos:

![basedatos_opencart.png](/images/practicacms/basedatos_opencart.png)


* Con esto hemos terminado de instalar opencart:

![finalizar_opencart.png](/images/practicacms/finalizar_opencart.png)


Ya podemos acceder a nuestra página:

![opencart.png](/images/practicacms/opencart.png)


## Tarea 4: Migración del CMS PHP en el hosting compartido.

Vamos a migrar la última aplicación que has instalado a un hosting externo, para ello sigue los siguientes pasos:

* Elige un servicio de hosting compartido con las características necesarias para instalar un CMS PHP (soporte PHP, base de datos,…)
* Date de alta en el servicio.
* Realiza la migración: Sube los ficheros al hosting externo, cambia las credenciales de acceso a la base de datos,…

-------------------------------------------------------------------

En mi caso, he elegido el hosting *awardspacenet*, ya que tenía una cuenta creada en este hosting por otro ejercicio anterior, y tras informarme, cumplía los requisitos que pedía el ejercicio.


Una vez creada la cuenta, elegimos el nombre para nuestro subdominio gratuito. En mi caso he elegdo `http://dparrales-opencart.atwebpages.com`. Una vez creado el subdominio, vemos que nos ha creado una carpeta en nuestro directorio raíz con el mismo nombre, que es donde subiremos nuestros archivos:


![opencart_hosting.png](/images/practicacms/opencart_hosting.png)


Ahora toca subir nuestros archivos al hosting. Yo he utilizado filezilla y he seguido los pasos que me indicaba la página para subir todos los ficheros al hosting:


![filezilla.png](/images/practicacms/filezilla.png)


Cuando se hayan subido los archivos (tarda su tiempo), es hora de subir la información de nuestra base de datos al hosting. Para ello seguiremos los pasos del ejercicio 2 para sacar una copia de la información de la base de datos, y la subiremos con el cliente de `phpmyadmin` que nos ofrece nuestro hosting:

![phpmyadmin.png](/images/practicacms/phpmyadmin.png)

Acabado este paso, ya solo tenemos que cambiar el fichero de configuración de nuestro cms (en mi caso llamado `config.php`) y cambiar la rutas de los directorios que nos indica y las credenciales de acceso a la base de datos:


![configuracion_opencart_hosting.png](/images/practicacms/configuracion_opencart_hosting.png)


Guardamos el archivo e intentamos acceder a la nueva ruta desde el navegador:


![opencart_hosting_acceso.png](/images/practicacms/opencart_hosting_acceso.png)


Accedemos con las credenciales que usamos en la instalación de opencart, y si funciona la conexión con la base de datos, debería dejarnos entrar:


![final_opencart.png](/images/practicacms/final_opencart.png)

Con esto hemos finalizado el ejercicio con éxito.
