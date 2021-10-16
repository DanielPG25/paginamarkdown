+++ 
draft = true
date = 2021-10-16T17:04:04+02:00
title = "Instalación de phpmyadmin usando un virtualhost"
description = "Vamos a instalar phpmyadmin desde los repositorios y vamos a acceder a través de un virtualhost"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = []
externalLink = ""
series = []
+++

# Instalación de phpmyadmin

*phpmyadmin* es una aplicación web escrita en PHP que nos posibilita la gestión de una base de datos mysql/mariadb.

Normalmente vamos a instalar las aplicaciones web descargando directamente el código de la aplicación al servidor, pero en este ejercicio vamos a instalar la aplicación desde los repositorios de Debian (para este ejercicio previamente hemos instalado un servidor LAMP en nuestra máquina).

Realizaremos los siguientes pasos:

## Accede desde el terminal a la base de datos con el `root` (con contraseña) y crea una base de datos y un usuario que tenga permiso sobre ella.

Vamos a suponer que hemos instalado el paquete de mariadb y hemos securizado la base de datos ejecutando la base de datos ejecutando `mysql_secure_installation `.

Vamos a entrar como root:

```
mysql -u root -p

Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 31
Server version: 10.5.12-MariaDB-0+deb11u1 Debian 11

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]>
```

Y creamos una base de datos y un usuario con permisos sobre ella:

```
MariaDB [(none)]> create database prueba;
Query OK, 1 row affected (0.001 sec)

MariaDB [(none)]> grant all on prueba.* to 'dparrales'@'%' identified by '*******' with grant option;
Query OK, 0 rows affected (0.008 sec)

MariaDB [(none)]>
```


## Instala desde los repositorios la aplicación phpmyadmin. Accede al servidor, al directorio phpmyadmin y comprueba que tienes acceso.

Para instalar *phpmyadmin* desde los repositorios de debian usamos el siguiente comando:

`
apt install phpmyadmin
`

Cuando nos pregunte que servidor web queremos configurar, seleccionamos *apache2* (en nuestro caso). Como ya tenemos una base de datos creada, seleccionamos que no queremos que nos cree una.

Una vez haya terminado la instalación, accedemos a la url de nuestro servidor e intentamos entrar en la directorio *phpmyadmin*:


![acceso.png](/images/phpmyadmin/acceso.png)

Como podemos ver tenemos acceso al directorio *phpmyadmin*.


## ¿Se ha creado en el DocumentRoot un directorio que se llama phpmyadmin? Entonces, ¿cómo podemos acceder?

Veamos el DocumentRoot (*/var/www/html*):


![documentroot.png](/images/phpmyadmin/documentroot.png)


Como podemos ver, no se ha creado ningún directorio llamado *phpmyadmin*. La razón por la que podemos acceder es debido a que al instalar *phpmyadmin*, ha creado un fichero en el directorio */etc/apache2/conf-available* llamado *phpmyadmin.conf*. En este fichero encontramos lo siguiente:

![alias.png](/images/phpmyadmin/alias.png)

La línea donde pone "Alias" lo que hace es crear un enlace simbólico, por lo que realmente la aplicación se encuentra en el directorio */usr/share/phpmyadmin*.


## Quita la configuración de acceso a phpmyadmin y comprueba que ya no puedes acceder. A continuación crea un virtualhost, al que hay que acceder con el nombre basededatos.tunombre.org, y que nos muestre la aplicación.

**Nota**: En la configuración del virtualhost copia las 3 directivas directory que se encuentran en el fichero /etc/apache2/conf-available/myphpadmin.conf.


Para quitar la configuración de acceso a *phpmyadmin* basta con comentar la línea de alias y reiniciar el servicio *apache2*:

![comentar.png](/images/phpmyadmin/comentar.png)


Al hacer esto perdemos el acceso al directorio *phpmyadmin*:


![noacceso.png](/images/phpmyadmin/noacceso.png)


Ahora crearemos un virtualhost para tener acceso a través de él a *phpmyadmin*. Lo primero será ir al directorio */etc/apache2/sites-available* y copiar el contenido del fichero *000-default.conf* a otro fichero que he llamado *phpmyadmin-daniel.conf*:

`
cat 000-default.conf > phpmyadmin-daniel.conf
`

Ya podemos modificar el nuevo fichero para adaptarlo a nuestras necesidades. En mi caso he dejado el fichero así:

```
<VirtualHost *:80>

        ServerName basededatos.dparrales.org
        ServerAdmin webmaster@localhost
        DocumentRoot /usr/share/phpmyadmin


        ErrorLog ${APACHE_LOG_DIR}/dparrales_error.log
        CustomLog ${APACHE_LOG_DIR}/dparrales_access.log combined


# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

#Alias /phpmyadmin /usr/share/phpmyadmin

<Directory /usr/share/phpmyadmin>
    Options SymLinksIfOwnerMatch
    DirectoryIndex index.php

    <IfModule mod_php7.c>
        php_admin_value upload_tmp_dir /var/lib/phpmyadmin/tmp
        php_admin_value open_basedir /usr/share/phpmyadmin/:/usr/share/doc/phpmyadmin/:/etc/phpmyadmin/:/var/lib/phpmyadmin/:/usr/share/php/:/usr/share/javascript/
    </IfModule>

</Directory>
<Directory /usr/share/phpmyadmin/templates>
    Require all denied
</Directory>
<Directory /usr/share/phpmyadmin/libraries>
    Require all denied
</Directory>

</VirtualHost>
```


Ahora activamos el virtualhost:

```
a2ensite phpmyadmin-daniel.conf 

systemctl reload apache2
```

Ya solo queda añadir la siguiente línea al fichero */etc/hosts* de la máquina con la que vayamos a acceder a *phpmyadmin*:


`
192.168.122.201 basededatos.dparrales.org
`


## Accede a phpmyadmin y comprueba que puede acceder con el usuario que creaste en el punto 1 y que puede gestionar su base de datos.

Antes de acceder


Vamos a acceder ahora a *phpmyadmin* a través de la url que le hemos asignado antes al *virtualhost*:


![acceso2.png](/images/phpmyadmin/acceso2.png)


Solo queda comprobar si tenemos acceso a la base de datos con el usuario que creamos al principio del ejercicio:


![comprobacion.png](/images/phpmyadmin/comprobacion.png)


Y con esto hemos completado el ejercicio con éxito.
