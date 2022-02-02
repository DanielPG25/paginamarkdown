+++ 
draft = true
date = 2022-02-02T21:28:35+01:00
title = "Implantación de aplicaciones web PHP en Docker"
description = "Implantación de aplicaciones web PHP en Docker"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Aplicaciones Web"]
externalLink = ""
series = []
+++

# Práctica: Implantación de aplicaciones web PHP en Docker

Imaginemos que el equipo de desarrollo de nuestra empresa ha desarrollado una aplicación PHP que se llama [BookMedik](https://github.com/evilnapsis/bookmedik).

Queremos crear una imagen Docker para implantar dicha aplicación.

Tenemos que tener en cuenta los siguientes aspectos:

* Contenedor mariadb
    - Es necesario que nuestra aplicación guarde su información en un contenedor docker mariadb.
    - El script para generar la base de datos y los registros lo encuentras en el repositorio y se llama `schema.sql`. Debes crear un usuario con su contraseña en la base de datos. La base de datos se llama `bookmedik`.
    - El contenedor mariadb debe tener un volumen para guardar la base de datos.

* Contenedor bookmedik
    - Vamos a crear tres versiones de la imagen que nos permite implantar la aplicación PHP.
    - La imagen debe crear las variables de entorno necesarias con datos de conexión por defecto.
    - Al crear un contenedor a partir de estas imágenes se ejecutará un script bash que realizará las siguientes tareas:
        - Modifique el fichero `core\controller\Database.php` para que lea las variables de entorno. Para obtener las variables de entorno en PHP usar la función getenv. [Para más información](http://php.net/manual/es/function.getenv.php).
        - Inicialice la base de datos con el fichero `schema.sql`.
        - Ejecute el servidor web.
    - El contenedor que creas debe tener un volumen para guardar los logs del servidor web.
    - La imagen la tienes que crear en tu entorno de desarrollo con el comando `docker build`.

------------------------------------------------------------------------------------

## Creación del contenedor MariaDB

Primero creamos un contenedor con la imagen `mariadb` y que tenga las variables de entorno que nos han indicado. También crearemos una nueva red para la aplicación web.

```
docker network create red_bookmedik
```

```
docker run -d --name bd_mariadb -v bookmedik_vol:/var/lib/mysql --network red_bookmedik -e MARIADB_ROOT_PASSWORD=root -e MARIADB_DATABASE=bookmedik -e MARIADB_USER=bookmedik -e MARIADB_PASSWORD=bookmedik mariadb
```

Estto será para realizar las pruebas necesarias y comprobar que la imagen de la aplicación funcione como es debido.

## Tarea 1: Creación de una imagen docker con una aplicación web desde una imagen base

* Vamos a crear una imagen que se llame usuario/bookmedik:v1.
* Crea una imagen docker con la aplicación desde una imagen base de debian o ubuntu.

------------------------------------------

En primer lugar hemos hecho un fork del repositorio de bookmedik y lo hemos clonado en nuestro entorno de desarrollo. Una vez hecho esto, vamos a modificar el fichero `schema.sql` para que podamos ejecutarlo en un contenedor que ya tendrá una base de datos creada. Así pues, eliminamos las siguientes líneas de ese fichero:

```
create database bookmedik;
use bookmedik; 
```

A continuación modificamos el fichero `core/controller/Database.php` para que se configure a través de las variables de entorno que introduzcamos al crear el contenedor:

```
<?php
class Database {
        public static $db;
        public static $con;
        function Database(){
                $this->user=getenv('USUARIO_BOOKMEDIK');$this->pass=getenv('CONTRA_BOOKMEDIK');$this->host=getenv('DATABASE_HOST');$this->ddbb=getenv('NOMBRE_DB');
        }

        function connect(){
                $con = new mysqli($this->host,$this->user,$this->pass,$this->ddbb);
                $con->query("set sql_mode=''");
                return $con;
        }

        public static function getCon(){
                if(self::$con==null && self::$db==null){
                        self::$db = new Database();
                        self::$con = self::$db->connect();
                }
                return self::$con;
        }
}
?>
```

Con esto ya podemos crear el Dockerfile que usaremos para crear la imagen:

```
nano Dockerfile

FROM debian:bullseye
MAINTAINER Daniel Parrales García "daniparrales16@gmail.com"
RUN apt update && apt upgrade -y && apt install apache2 libapache2-mod-php php php-mysql mariadb-client -y && apt clean && rm -rf /var/lib/apt/lists/*
ADD bookmedik /var/www/html/
ADD script.sh /opt/
RUN chmod +x /opt/script.sh && rm /var/www/html/index.html
ENTRYPOINT ["/opt/script.sh"]
```

Como vemos, al final le indicamos que ejecute un script. Dicho script lo hemos creado nosotros, y en él hacemos que introduzca la información del fichero `schema.sql` en la base de datos y hacemos que ejecute apache en modo demonio. El contenido del script es el siguiente:

```
nano script.sh

#! /bin/sh

mysql -u $USUARIO_BOOKMEDIK --password=$CONTRA_BOOKMEDIK -h $DATABASE_HOST $NOMBRE_DB < /var/www/html/schema.sql

/usr/sbin/apache2ctl -D FOREGROUND
```

Este script lo hemos introducido en el directorio `bookmedik` (el que hemos obtenido de la clonación de github) para que se añada al contenedor junto con el contenido de dicho directorio. Con esto ya podemos crear la imagen con el siguiente comando:

```
docker build -t dparrales/bookmedik:v1 .
```

Una vez creada, ya la podemos ver en nuestro registro local:

![img_1.png](/images/practica_php_docker/img_1.png)

Los ficheros que han sido creados se encuentran en mi repositorio de [Github](https://github.com/DanielPG25/Practica_Docker).

## Tarea 2: Despliegue en el entorno de desarrollo

* Crea un script con docker-compose que levante el escenario con los dos contenedores.
* Recuerda que para acceder a la aplicación: Usuario: admin, contraseña: admin.

-----------------------------------------------------------

Así pues, crearemos un fichero `docker-compose.yaml` con la configuración necesaria para levantar los dos contenedores:

```
nano docker-compose.yaml

version: '3.1'
services:
  bookmedik:
    container_name: bookmedik-app
    image: dparrales/bookmedik:v1
    restart: always
    environment:
      USUARIO_BOOKMEDIK: bookmedik
      CONTRA_BOOKMEDIK: bookmedik
      DATABASE_HOST: bd_mariadb
      NOMBRE_DB: bookmedik
    ports:
      - 8081:80
    depends_on:
      - db
  db:
    container_name: bd_mariadb
    image: mariadb
    restart: always
    environment:
      MARIADB_ROOT_PASSWORD: root
      MARIADB_DATABASE: bookmedik
      MARIADB_USER: bookmedik
      MARIADB_PASSWORD: bookmedik
    volumes:
      - mariadb_data:/var/lib/mysql
volumes:
    mariadb_data:
```

Ahora levantamos los contenedores:

```
docker-compose up -d
```

Podemos verlos funcionando con el siguiente comando:

![img_2.png](/images/practica_php_docker/img_2.png)

Y si entramos desde el navegador web, debería funcionar correctamente:

![img_3.png](/images/practica_php_docker/img_3.png)

## Tarea 3: Creación de una imagen docker con una aplicación web desde una imagen PHP

* Vamos a crear una imagen que se llame `usuario/bookmedik:v2`.
* Realiza la imagen docker de la aplicación a partir de la imagen oficial PHP que encuentras en docker hub. Lee la documentación de la imagen para configurar una imagen con apache2 y php, además seguramente tengas que instalar alguna extensión de php.
* Modifica el fichero `docker-compose.yml` para probar esta imagen.

--------------------------------------

Primero creamos el Dockerfile:

```
nano Dockerfile

FROM php:7.4-apache-bullseye
MAINTAINER Daniel Parrales García "daniparrales16@gmail.com"
RUN apt update && apt upgrade -y && docker-php-ext-install mysqli pdo pdo_mysql && apt install mariadb-client -y && apt clean && rm -rf /var/lib/apt/lists/*
ADD bookmedik /var/www/html/
ADD script.sh /opt/
RUN chmod +x /opt/script.sh
ENTRYPOINT ["/opt/script.sh"]
```

Ahora creamos la nueva imagen:

```
docker build -t dparrales/bookmedik:v2 .
```

En el fichero `docker-compose.yaml` solo debemos cambiar la versión:

```
nano docker-compose.yaml

version: '3.1'
services:
  bookmedik:
    container_name: bookmedik-app
    image: dparrales/bookmedik:v2
    restart: always
    environment:
      USUARIO_BOOKMEDIK: bookmedik
      CONTRA_BOOKMEDIK: bookmedik
      DATABASE_HOST: bd_mariadb
      NOMBRE_DB: bookmedik
    ports:
      - 8081:80
    depends_on:
      - db
  db:
    container_name: bd_mariadb
    image: mariadb
    restart: always
    environment:
      MARIADB_ROOT_PASSWORD: root
      MARIADB_DATABASE: bookmedik
      MARIADB_USER: bookmedik
      MARIADB_PASSWORD: bookmedik
    volumes:
      - mariadb_data:/var/lib/mysql
volumes:
    mariadb_data:
```

Ahora levantamos los contenedores:

```
docker-compose up -d
```

Vemos como se están ejecutando los contenedores:

![img_4.png](/images/practica_php_docker/img_4.png)

Y vemos también la imagen que se ha creado:

![img_5.png](/images/practica_php_docker/img_5.png)

Por último, accedemos a la aplicación web desde el navegador:

![img_6.png](/images/practica_php_docker/img_6.png)

## Tarea 4: Ejecución de una aplicación PHP en docker con nginx

* Vamos a crear una imagen que se llame usuario/bookmedik:v3.
* En este caso queremos usar un contenedor que utilice nginx para servir la aplicación PHP. Puedes crear la imagen desde una imagen base debian o ubuntu o desde la imagen oficial de nginx.
* Vamos a crear otro contenedor que sirva php-fpm.
* Para que funcione de forma adecuada el php-fpm tiene que tener acceso al directorio donde se encuentra la aplicación.
* Y finalmente nuestro contenedor con la aplicación.
* Crea un script con docker compose que levante el escenario con los tres contenedores.

------------------------------------------------

Para empezar, tenemos que crear dos imágenes: una que va a tener la aplicación y la va a servir a través de nginx, y otra que a tener php-fpm con los módulos necesarios instalados. Así pues, creamos los dos Dockerfile:

* El Dockerfile con php-fpm y los módulos:

```
FROM php:7.3-fpm-bullseye
MAINTAINER Daniel Parrales García "daniparrales16@gmail.com"
RUN docker-php-ext-install mysqli pdo pdo_mysql
```

Y construimos la imagen:

```
docker build -t dparrales/php-fpm-mysql:v1 .
```

* El Dockerfile con la aplicación y nginx:

```
FROM nginx
MAINTAINER Daniel Parrales García "daniparrales16@gmail.com"
RUN apt update && apt upgrade -y && apt install mariadb-client -y && apt clean && rm -rf /var/lib/apt/lists/*
ADD default.conf /etc/nginx/conf.d/
ADD bookmedik /usr/share/nginx/html
ADD script.sh /opt/
RUN chmod +x /opt/script.sh && rm /usr/share/nginx/html/index.html
ENTRYPOINT ["/opt/script.sh"]
```

Y construimos la imagen:

```
docker build -t dparrales/bookmedik:v3 .
```

Como vemos, en el anterior fichero hacemos referencia al fichero `default.conf`. Este fichero lo hemos añadido y sustituirá al que hay por defecto, añadiendo la configuración de php-fpm al virtualhost:

```
nano default.conf

server {
    listen       80;
    listen  [::]:80;
    server_name  localhost;
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root   /usr/share/nginx/html;
    index  index.php index.html;

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass book_php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
```

El fichero `script.sh` ha sido modificado para adaptarse a nginx:

```
nano script.sh

#! /bin/sh

sleep 10

mysql -u $USUARIO_BOOKMEDIK --password=$CONTRA_BOOKMEDIK -h $DATABASE_HOST $NOMBRE_DB < /usr/share/nginx/html/schema.sql

nginx -g "daemon off;"
```

Una vez explicado esto, podemos pasar a crear el fichero `docker-compose.yaml`:

```
nano docker-compose.yaml

version: '3.1'
services:
  bookmedik:
    container_name: bookmedik-app
    image: dparrales/bookmedik:v3
    restart: always
    environment:
      USUARIO_BOOKMEDIK: bookmedik
      CONTRA_BOOKMEDIK: bookmedik
      DATABASE_HOST: bd_mariadb
      NOMBRE_DB: bookmedik
    ports:
      - 8082:80
    depends_on:
      - db
      - php
    volumes:
      - phpdocs:/usr/share/nginx/html/
  db:
    container_name: bd_mariadb
    image: mariadb
    restart: always
    environment:
      MARIADB_ROOT_PASSWORD: root
      MARIADB_DATABASE: bookmedik
      MARIADB_USER: bookmedik
      MARIADB_PASSWORD: bookmedik
    volumes:
      - mariadb_data:/var/lib/mysql
  php:
    container_name: book_php
    image: php:7.3-fpm-bullseye
    restart: always
    environment:
      USUARIO_BOOKMEDIK: bookmedik
      CONTRA_BOOKMEDIK: bookmedik
      DATABASE_HOST: bd_mariadb
      NOMBRE_DB: bookmedik
    volumes:
      - phpdocs:/usr/share/nginx/html/

volumes:
    mariadb_data:
    phpdocs:
```

En el fichero anterior hay que destacar dos cosas:

* El volumen que comparten el contenedor nginx y el contenedor php-fpm **deben** tener la misma ruta. No importa que dicha ruta no exista en el contenedor php-fpm.
* Las variables de entorno deben estar también en el contenedor php-fpm.

Dicho todo lo anterior, podemos comprobar que las imágenes se han creado correctamente:

![img_8.png](/images/practica_php_docker/img_8.png)

Ahora creamos los contenedores con el siguiente comando:

```
docker-compose up -d
```

Vemos que están funcionando:

![img_7.png](/images/practica_php_docker/img_7.png)

Ahora ya podemos acceder a través del navegador web:

![img_9.png](/images/practica_php_docker/img_9.png)

Con esto hemos terminado esta tarea.

## Tarea 5: Puesta en producción de nuestra aplicación

* Elige una de las tres imágenes y súbela a Docker Hub.
* En tu VPS instala Docker y utilizando el docker-compose.yml correspondiente, crea un contenedor en ella de la aplicación.
* Configura el nginx de tu VPS para que haga de proxy inverso y nos permita acceder a la aplicación con `https://bookmedik.tudominio.xxx`.

-------------------------------------------------

En primero lugar, tenemos que crear el registro CNAME correspondiente en nuestra zona DNS:

![img_10.png](/images/practica_php_docker/img_10.png)

A continuación, en la VPS, debemos obtener el certificado de "Let's Encrypt" para ese registro:

```
certbot certonly --standalone -d bookmedik.sysadblog.com
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator standalone, Installer None
Requesting a certificate for bookmedik.sysadblog.com
Performing the following challenges:
http-01 challenge for bookmedik.sysadblog.com
Cleaning up challenges
Problem binding to port 80: Could not bind to IPv4 or IPv6.
root@blackstar:~# systemctl stop nginx
root@blackstar:~# certbot certonly --standalone -d bookmedik.sysadblog.com
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator standalone, Installer None
Requesting a certificate for bookmedik.sysadblog.com
Performing the following challenges:
http-01 challenge for bookmedik.sysadblog.com
Waiting for verification...
Cleaning up challenges

IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/bookmedik.sysadblog.com/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/bookmedik.sysadblog.com/privkey.pem
   Your certificate will expire on 2022-05-03. To obtain a new or
   tweaked version of this certificate in the future, simply run
   certbot again. To non-interactively renew *all* of your
   certificates, run "certbot renew"
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le
```

Ahora debemos instalar `docker` y `docker-compose` si no lo está ya:

```
apt install docker.io docker-compose
```

Podemos comprobar que las imágenes de encuentran subidas a mi cuenta en "Docker Hub":

![img_11.png](/images/practica_php_docker/img_11.png)

Ahora hay que elegir una de las imágenes anteriores para desplegarla en la VPS. Tras pensarlo, me he decidido por la versión dos. Así pues, nos llevamos el fichero `docker-compose.yaml` con la versión dos a la VPS y levantamos los contenedores (he modificado el puerto, ya que ese estaba ocupado):

![img_12.png](/images/practica_php_docker/img_12.png)

Ya solo queda crear el virtualhost en nginx que actuará como proxy inverso:

```
nano /etc/nginx/sites-available/bookmedik

server {
        listen 80;
        listen [::]:80;

        server_name bookmedik.sysadblog.com;

        return 301 https://$host$request_uri;
}

server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;

        ssl    on;
        ssl_certificate /etc/letsencrypt/live/bookmedik.sysadblog.com/fullchain.pem;
        ssl_certificate_key     /etc/letsencrypt/live/bookmedik.sysadblog.com/privkey.pem;

        index index.html index.php index.htm index.nginx-debian.html;

        server_name bookmedik.sysadblog.com;

        location / {
                proxy_pass http://localhost:8083;
                include proxy_params;
        }

}
```

Ahora creamos el enlace simbólico:

```
ln -s /etc/nginx/sites-available/bookmedik /etc/nginx/sites-enabled/bookmedik
```

Y reiniciamos el servicio de nginx:

```
systemctl restart nginx
```

Ya podemos acceder desde el navegador web:

![img_13.png](/images/practica_php_docker/img_13.png)

Con esto hemos terminado esta tarea.

## Tarea 6: Modificación de la aplicación

* En el entorno de desarrollo vamos a hacer una modificación de la aplicación. Por ejemplo modifica el fichero `core/app/view/login-view.php` y pon tu nombre en la línea `<h4 class="title">Acceder a BookMedik</h4>`.
* Vamos a trabajar con la primera imagen que construimos. Vuelve a crear la imagen con la etiqueta `v1_2`.
* Cambia el docker-compose para probar el cambio.
* Modifica la aplicación en producción.

------------------------------------------------------

Como nos han indicado, modificaremos el fichero `core/app/view/login-view.php`:

```
<h4 class="title">Acceder a BookMedik Daniel Parrales</h4>
```

Y creamos la imagen nueva:

```
docker build -t dparrales/bookmedik:v1_2 .
```

Esta imagen la subimos también a "Docker Hub":

```
docker login

docker push dparrales/bookmedik:v1_2
```

Podemos verla en dicha página:

![img_14.png](/images/practica_php_docker/img_14.png)

Ahora, en la vps tenemos que eliminar los contenedores que hemos creado y volverlos a crear tras actualizar el fichero `docker-compose.yaml` a la nueva versión. Una vez hecho esto, podemos acceder a la web y ver si se han producido los cambios:

![img_15.png](/images/practica_php_docker/img_15.png)

![img_16.png](/images/practica_php_docker/img_16.png)

Como vemos, se han producido los cambios, por lo que podemos decir que la práctica ha sido un éxito.
