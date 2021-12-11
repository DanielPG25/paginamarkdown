+++ 
draft = true
date = 2021-12-11T16:40:54+01:00
title = "Despliegue de CMS Java (Guacamole)"
description = "Despliegue de CMS Java (Guacamole)"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Aplicaciones Web"]
externalLink = ""
series = []
+++

# Despliegue de CMS Java

En esta práctica vamos a desplegar un CMS escrito en java. ¿Qué debemos tener en cuenta?

* Debes desplegar la aplicación desde un fichero war.
* No usar instalaciones “bundler”. Estas instalaciones instalan la aplicación y tomcat al mismo tiempo. La aplicación se debe desplegar en el tomcat que tienes instalado.
* Utiliza una máquina virtual que tenga suficiente memoria, al menos 2Gb, algunos CMS requieren mucha memoria RAM.
* La aplicación debe guardar los datos en una base de datos

-------------------------------------------------------------------------

En esta práctica vamos a instalar un CMS escrito en Java, Apache Guacamole, que facilitará la administración remota de sistemas, unificando en una sola interfaz web los protocolos más usados en la administración remota (SSH, VNC, RDP). De esta forma podremos hacer uso de todos estos servicios simplemente accediendo a la interfaz web que nos ofrece.

Así pues, en primer lugar hay que instalar las dependencias de guacamole. Hay pocas obligatorias, pero yo he optado por instalar una gran cantidad de las opcionales (cada persona deberá decidir cuales quiere instalar y cuales no, dependiendo de sus necesidades). Podemos encontrar las dependencias en la página oficial de [guacamole](https://guacamole.apache.org/doc/gug/installing-guacamole.html):

```
apt install build-essential libcairo2-dev libjpeg62-turbo-dev libpng-dev libtool-bin libossp-uuid-dev libavcodec-dev libavformat-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libwebsockets-dev libpulse-dev libvorbis-dev libwebp-dev
```

Ahora debemos descargarnos las fuentes de guacamole-server, para compilar el programa nosotros (es un requisito que nos indica en la página, aunque posteriormente descarguemos el fichero `.war` para instalar el cliente). Así pues, descargaremos la última versión que hay en la página oficial:

```
wget https://apache.org/dyn/closer.lua/guacamole/1.3.0/source/guacamole-server-1.3.0.tar.gz
```

Y lo extraemos:

```
tar -zxf guacamole-server-1.3.0.tar.gz
```

Si accedemos al directorio que acabamos de extraer, nos encontramos lo siguiente:

```
ls -l guacamole-server-1.3.0
total 744
-rw-r--r--  1 1001 users  55738 dic 29  2020 aclocal.m4
drwxr-xr-x  2 1001 users   4096 dic 29  2020 bin
drwxr-xr-x  2 1001 users   4096 dic 29  2020 build-aux
-rw-r--r--  1 1001 users   6341 dic 29  2020 config.h.in
-rwxr-xr-x  1 1001 users 555917 dic 29  2020 configure
-rw-r--r--  1 1001 users  37030 dic 29  2020 configure.ac
-rw-r--r--  1 1001 users   1984 jun 30  2020 CONTRIBUTING
drwxr-xr-x  2 1001 users   4096 dic 29  2020 doc
-rw-r--r--  1 1001 users   6084 dic 29  2020 Dockerfile
-rw-r--r--  1 1001 users  11358 ene 26  2020 LICENSE
drwxr-xr-x  2 1001 users   4096 dic 29  2020 m4
-rw-r--r--  1 1001 users   2612 dic 22  2020 Makefile.am
-rw-r--r--  1 1001 users  30946 dic 29  2020 Makefile.in
-rw-r--r--  1 1001 users    165 dic 11  2020 NOTICE
-rw-r--r--  1 1001 users   6108 jul 10  2020 README
drwxr-xr-x 12 1001 users   4096 dic 29  2020 src
drwxr-xr-x  2 1001 users   4096 dic 29  2020 util
```

Aquí nos encontramos con un fichero `configure`, que es típico de las compilaciones (se usa normalmente para verificar que las dependencias de la compilación están cubiertas, antes de empezar con la misma). Así pues, ejecutamos de la siguiente forma ese fichero (usamos `--with-init-dir=/etc/init.d` para que genere un script de inicio en `/etc/init.d` para que más tarde podamos configurar el inicio automático de forma más sencilla):

```
./configure --with-init-dir=/etc/init.d


------------------------------------------------
guacamole-server version 1.3.0
------------------------------------------------

   Library status:

     freerdp2 ............ yes
     pango ............... yes
     libavcodec .......... yes
     libavformat.......... yes
     libavutil ........... yes
     libssh2 ............. yes
     libssl .............. yes
     libswscale .......... yes
     libtelnet ........... yes
     libVNCServer ........ yes
     libvorbis ........... yes
     libpulse ............ yes
     libwebsockets ....... yes
     libwebp ............. yes
     wsock32 ............. no

   Protocol support:

      Kubernetes .... yes
      RDP ........... yes
      SSH ........... yes
      Telnet ........ yes
      VNC ........... yes

   Services / tools:

      guacd ...... yes
      guacenc .... yes
      guaclog .... yes

   FreeRDP plugins: /usr/lib/x86_64-linux-gnu/freerdp2
   Init scripts: /etc/init.d
   Systemd units: no

Type "make" to compile guacamole-server.
```

Había más salida en ese comando, pero he dejado lo más importante. Como vemos, tenemos cubiertas las dependencias. Así pues, hacemos lo que nos indica la salida del comando:

```
make

make install
```

Ahora tendremos que actualizar la caché de librerías instaladas del sistema y volver a cargar todas las unidades de systemd para hacer uso del nuevo servicio instalado:

```
ldconfig

systemctl daemon-reload
```

Ahora ya podemos habilitar el nuevo servicio creado usando `systemctl`:

```
systemctl enable guacd.service

systemctl start guacd.service
```

Podemos ver el estado del servicio que acabamos de activar:

```
systemctl status guacd.service

● guacd.service - LSB: Guacamole proxy daemon
     Loaded: loaded (/etc/init.d/guacd; generated)
     Active: active (running) since Fri 2021-12-10 19:11:38 CET; 4s ago
       Docs: man:systemd-sysv-generator(8)
    Process: 22443 ExecStart=/etc/init.d/guacd start (code=exited, status=0/SUCCESS)
      Tasks: 1 (limit: 2340)
     Memory: 9.9M
        CPU: 12ms
     CGroup: /system.slice/guacd.service
             └─22446 /usr/local/sbin/guacd -p /var/run/guacd.pid

dic 10 19:11:38 guaca systemd[1]: Starting LSB: Guacamole proxy daemon...
dic 10 19:11:38 guaca guacd[22444]: Guacamole proxy daemon (guacd) version 1.3.0 started
dic 10 19:11:38 guaca guacd[22443]: Starting guacd:
dic 10 19:11:38 guaca guacd[22444]: guacd[22444]: INFO:        Guacamole proxy daemon (guacd) version 1.3.0 started
dic 10 19:11:38 guaca guacd[22443]: SUCCESS
dic 10 19:11:38 guaca systemd[1]: Started LSB: Guacamole proxy daemon.
dic 10 19:11:38 guaca guacd[22446]: Listening on host 127.0.0.1, port 4822
```

Con esto hemos terminado de instalar la parte del servidor de guacamole. Ahora seguiremos con el servidor de aplicaciones java: Tomcat

En primer lugar, debemos instalar tomcat. Para ello ejecutamos lo siguiente:

```
apt install tomcat9
```

Una vez que ha finalizado la instalación, comprobamos que se puede acceder desde el navegador:

![tomcat_inicial.png](/images/practica_despliegueCMS_Java/tomcat_inicial.png)

Ahora descargaremos el fichero `.war` de la página oficial y lo movemos al directorio `/var/lib/tomcat9/webapps/`, en el cual se extraerá automáticamente: 

```
wget -O 'guacamole.war' 'http://archive.apache.org/dist/guacamole/1.2.0/binary/guacamole-1.2.0.war'

mv guacamole.war /var/lib/tomcat9/webapps/
```

Con esto habríamos terminado de instalar el cliente de guacamole, y podríamos acceder a él a través del puerto 8080, pero en lugar de esto, instalaremos un servidor web (Apache en este caso), el cual configuraremos como proxy para acceder al servicio de guacamole:

```
apt install apache2
```

Una vez instalado, configuramos el virtualhost de forma que actúe como proxy:

```
nano /etc/apache2/sites-available/000-default.conf

<VirtualHost *:80>

        ServerName www.dparrales.guacamole.org
        ServerAdmin webmaster@localhost
        DocumentRoot /var/lib/tomcat9/webapps/guacamole
        Redirect 301 / /guacamole/

        <Location /guacamole/>
            Order allow,deny
            Allow from all
            ProxyPass http://localhost:8080/guacamole/ flushpackets=on
            ProxyPassReverse http://localhost:8080/guacamole/
        </Location>


        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

</VirtualHost>
```

Ahora habilitamos en módulo proxy y reniciamos el servicio de apache para que tengan lugar los cambios:

```
a2enmod proxy_http

systemctl restart apache2
```

Una vez que hemos terminado de configurar el servidor web, pasemos a configurar guacamole en sí, ya que hasta ahora, lo único que hemos hecho ha sido instalarlo. Para empezar hemos de crear el "GUACAMOLE_HOME", que es el nombre del directorio donde guardaremos toda la configuración de guacamole y está ubicado en `/etc/guacamole`:

```
mkdir /etc/guacamole
```

Dentro de este directorio tendremos que crear varios ficheros y directorios:

-`guacamole.properties`: En él definiremos como se va a comunicar con el demonio que habilitamos anteriormente (guacd), además de como vamos a autentificar a los usuarios (primero usaremos la autentificación básica, y más adelante crearemos una base de datos y restringiremos el acceso a solo aquellos usuario que estén en esa base datos):

```
nano guacamole.properties

guacd-hostname: localhost
guacd-port:     4822

auth-provider: net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider
basic-user-mapping: /etc/guacamole/user-mapping.xml
```

-`user-mapping.xml`: En él definiremos la lista de usuarios que tendrán acceso al servicio y la lista de conexiones que podrá realizar dicho usuario:

```
nano user-mapping.xml

<user-mapping>
    <authorize
         username="admin"
         password="admin">

       <connection name="Prueba1">
         <protocol>ssh</protocol>
         <param name="hostname">192.168.122.179</param>
         <param name="port">22</param>
         <param name="username">debian</param>
         <param name="password">debian</param>
       </connection>

       <connection name="Servidor">
         <protocol>ssh</protocol>
         <param name="hostname">192.168.122.63</param>
         <param name="port">22</param>
         <param name="username">debian</param>
         <param name="password">debian</param>
       </connection>
    </authorize>
</user-mapping>
```

Podemos encriptar las contraseñas, pero no lo he visto necesario para esta instalación. Ahora debemos reiniciar los servicios de tomcat y guacamole:

```
systemctl restart tomcat9 guacd
```

Ahora podemos probar el funcionamiento de guacamole de dos formas:

* Accediendo desde Tomcat:

![desde_tomcat.png](/images/practica_despliegueCMS_Java/desde_tomcat.png)

* Desde el proxy que hemos configurado:

![desde_proxy.png](/images/practica_despliegueCMS_Java/desde_proxy.png)

Con esto guacamole ya estaría funcionando correctamente, pero vamos a ir un paso más alla, y vamos a hacer que solo puedan acceder los usuario que registremos en nuestra base de datos. Así pues, lo primero es instalar un servidor de base de datos, en mi caso he elegido mariadb, pero guacamole también admite PostgreSQL y SQL Server.

```
apt install mariadb-server

mysql_secure_installation
```

Ahora crearemos la base de datos y un usuario con permisos sobre dicha base de datos:

```
mysql -u root -p

CREATE DATABASE guacamole_db;

CREATE USER 'guacamole_user'@'%' IDENTIFIED BY 'guacamole_user';

GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'%';

FLUSH PRIVILEGES;
```

Ahora debemos descargarnos la extensión de guacamole para permitir la autentificación mediante una base de datos:

```
wget https://archive.apache.org/dist/guacamole/1.2.0/binary/guacamole-auth-jdbc-1.2.0.tar.gz

tar -zxf guacamole-auth-jdbc-1.2.0.tar.gz
```

Dentro de ese nuevo directorio nos encontramos lo siguiente para mariadb:

```
ls -l guacamole-auth-jdbc-1.2.0/mysql/

total 5588
-rw-r--r-- 1 1001 users 5716097 jun 26  2020 guacamole-auth-jdbc-mysql-1.2.0.jar
drwxr-xr-x 3 1001 users    4096 feb  1  2020 schema
```

Tenemos que descargarnos también el conector para nuestra base de datos y situarlo en el directorio `/etc/guacamole/lib` (hay que crearlo si no lo está ya):

```
mkdir /etc/guacamole/lib

wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.27.tar.gz

tar -zxf mysql-connector-java-8.0.27.tar.gz

cp mysql-connector-java-8.0.27/mysql-connector-java-8.0.27.jar /etc/guacamole/lib/
```

Ahora debemos mover el fichero `guacamole-auth-jdbc-mysql-1.2.0.jar` que venía con la extensión al directorio `/etc/guacamole/extensions` (hay que crearlo si no lo está ya):

```
mkdir /etc/guacamole/extensions

cp guacamole-auth-jdbc-1.2.0/mysql/guacamole-auth-jdbc-mysql-1.2.0.jar /etc/guacamole/extensions/
```

Ahora debemos introducir los esquemas que venían con la extensión en la base de datos:

```
cat *.sql | mysql -u root -p guacamole_db
```

Con esto se nos ha creado un esquema básico dentro de nuestra base de datos. Ahora tenemos que añadir al fichero `guacamole.properties` las líneas adecuadas para que use el servidor de base datos que acabamos de crear:

```
# MySQL properties
mysql-hostname: localhost
mysql-port: 3306
mysql-database: guacamole_db
mysql-username: guacamole_user
mysql-password: guacamole_user
```

Si además añadimos la siguiente línea, indicaremos que no queremos permitir el acceso a ningún usuario que no se encuentre registrado en la base de datos:

```
mysql-user-required: true
```

Como hemos añadido esa directiva, ya no podemos acceder con el usuario que indicamos antes en `user-mapping.xml`:

![acceso_denegado.png](/images/practica_despliegueCMS_Java/acceso_denegado.png)

Para acceder, tenemos que usar el usuario que se crea por defecto en el esquema: "guacadmin" con contraseña "guacadmin":

![acceso_guacadmin.png](/images/practica_despliegueCMS_Java/acceso_guacadmin.png)

Desde dentro del perfil ya podríamos hacer lo que quisiéramos: crear conexiones, cambiar la contraseña, modificar los parátros de las conexiones existentes, etc. También, al ser administradores, podríamos crear usuarios, grupos, etc.

Para finalizar con la instalación y configuración de guacamole, intentaremos acceder a una de las máquinas que hemos definido en las conexiones:

![acceso_conexion.png](/images/practica_despliegueCMS_Java/acceso_conexion.png)

![acceso_conexion2.png](/images/practica_despliegueCMS_Java/acceso_conexion2.png)

Podemos ejecutar comandos de forma normal:

![acceso_conexion3.png](/images/practica_despliegueCMS_Java/acceso_conexion3.png)

Con esto hemos terminado de instalar y configurar Apache Guacamole.
