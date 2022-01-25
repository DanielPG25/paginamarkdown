+++ 
draft = true
date = 2022-01-20T09:04:35+01:00
title = "Ejercicios con docker"
description = "Ejercicios con docker"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Aplicaciones Web"]
externalLink = ""
series = []
+++

# Ejercicios con docker

Vamos a realizar los ejercicios que aparecen en el siguiente [curso de docker](https://iesgn.github.io/curso_docker_2021/).

## Ejercicio 1: Introducción

Vamos a entregar el ejercicio 4 con algunas modificaciones. Crearemos un contenedor demonio a partir de la imagen nginx, el contenedor se debe llamar servidor_web y se debe acceder a él utilizando el puerto 8181 del ordenador donde tengas instalado docker.

Entrega lo siguiente:

* Pantallazo donde se vea la creación del contenedor y podamos comprobar que el contenedor está funcionando.
* Pantallazo donde se vea el acceso al servidor web utilizando un navegador web (recuerda que tienes que acceder a la ip del ordenador donde tengas instalado docker)
* Pantallazo donde se vean las imágenes que tienes en tu registro local.
* Pantallazo donde se vea como se elimina el contenedor (recuerda que antes debe estar parado el contenedor).

-----------------------------------------------------

Para crear el contenedor usamos el siguiente comando:

```
docker run -d --name servidor_web -p 8181:80 nginx
```

![img_1.png](/images/introduccion_docker/img_1.png)

Una vez creado podemos ver que está funcionando usando el siguiente comando:

```
docker ps
```

![img_2.png](/images/introduccion_docker/img_2.png)

Ahora probamos a entrar en el navegador y ver si se muestra la página de inicio de nginx al entrar en el puerto indicado (8181):

![img_3.png](/images/introduccion_docker/img_3.png)

Como vemos, podemos acceder a la página de inicio de nginx. Ahora veamos las imágenes de docker que tenemos descargadas:

```
docker images
```

![img_4.png](/images/introduccion_docker/img_4.png)

Probemos ahora a eliminar el contenedor que acabamos de crear:

```
docker stop servidor_web

docker rm servidor_web
```

![img_5.png](/images/introduccion_docker/img_5.png)

## Ejercicio 2: Trabajando con imágenes existentes

### Servidor Web

* Arranca un contenedor que ejecute una instancia de la imagen php:7.4-apache, que se llame web y que sea accesible desde tu equipo en el puerto 8000.
* Colocar en el directorio raíz del servicio web (/var/www/html) de dicho contenedor un fichero llamado index.html con el siguiente contenido:

```
<h1>HOLA SOY XXXXXXXXXXXXXXX</h1>
```

Deberás sustituir XXXXXXXXXXX por tu nombre y tus apellidos.

* Colocar en ese mismo directorio raíz un archivo llamado `index.php` con el siguiente contenido:
```
<?php echo phpinfo(); ?>
```

* Para crear los ficheros tienes tres alternativas:
    * Ejecutando bash de forma interactiva en el contenedor y creando los ficheros.
    * Ejecutando un comando echo en el contenedor con docker exec.
    * Usando docker cp como hemos visto en el ejercicio 5.

--------------------------------------------------------------------------------

Empecemos por crear el servidor con la imagen que nos han indicado:

```
docker run -d --name web -p 8000:80 php:7.4-apache
```

Ahora tenemos que introducir los ficheros `index.html` e `index.php` a la ruta `/var/www/hmtl`. Para ellos podemos hacerlo de las siguientes tres formas:

*  Ejecutando bash de forma interactiva en el contenedor y creando los ficheros:

```
dparrales@debian:~$ docker exec -ti web bash
root@9b07090ac10d:/var/www/html# echo "<?php echo phpinfo(); ?>" > /var/www/html/index.php
root@9b07090ac10d:/var/www/html# echo "<h1>HOLA SOY DANIEL PARRALES</h1>" > /var/www/html/index.html
root@9b07090ac10d:/var/www/html# cat /var/www/html/index.html 
<h1>HOLA SOY DANIEL PARRALES</h1>
root@9b07090ac10d:/var/www/html# cat /var/www/html/index.php  
<?php echo phpinfo(); ?>
root@9b07090ac10d:/var/www/html# 
```

* Ejecutando un comando echo en el contenedor con docker exec:

```
dparrales@debian:~$ docker exec web bash -c 'echo "<h1>HOLA SOY DANIEL PARRALES</h1>" > /var/www/html/index.html'
dparrales@debian:~$ docker exec web bash -c 'echo "<?php echo phpinfo(); ?>" > /var/www/html/index.php'
```

* Usando docker cp (tenemos que crear antes los fichero en nuestro anfitrión):

```
dparrales@debian:~$ docker cp Descargas/index.php web:/var/www/html/
dparrales@debian:~$ docker cp Descargas/index.html web:/var/www/html/
```

Con cualquiera de ellas, podemos ver ambos archivos si entramos en el puerto 8000 de nuestra máquina:

![img_6.png](/images/introduccion_docker/img_6.png)

![img_7.png](/images/introduccion_docker/img_7.png)

Con ambos ficheros añadidos, podemos ver que el contenedor ha aumentado un poco su tamaño:

![img_8.png](/images/introduccion_docker/img_8.png)

### Servidor de base de datos

* Arrancar un contenedor que se llame `bbdd` y que ejecute una instancia de la imagen mariadb para que sea accesible desde el puerto 3336.
* Antes de arrancarlo visitar la página del contenedor en [Docker Hub](https://hub.docker.com/_/mariadb) y establecer las variables de entorno necesarias para que:
    * La contraseña de root sea root.
    * Crear una base de datos automáticamente al arrancar que se llame prueba.
    * Crear el usuario invitado con las contraseña invitado.

------------------------------------------------------

Para crear el contenedor con esas características, usamos el comando `docker run` con las siguientes opciones:

```
docker run -d --name bbdd -p 3336:3306 -e MARIADB_ROOT_PASSWORD=root -e MARIADB_DATABASE=prueba -e MARIADB_USER=invitado -e MARIADB_PASSWORD=invitado mariadb
```

Para acceder a dicha base de datos desde nuestro anfitrión, debemos usar la opción "-P" para indicar el puerto al que nos queremos conectar (3336):

```
mysql -u invitado -p -h 192.168.1.118 -P 3336
```

![img_9.png](/images/introduccion_docker/img_9.png)

Hay que mencionar que docker no deja que borremos una imagen si está siendo usada por un contenedor:

![img_10.png](/images/introduccion_docker/img_10.png)

## Ejercicio 3: Almacenamiento

### Bind mount para compartir datos

* Crea una carpeta llamada saludo y dentro de ella crea un fichero llamado index.html con el siguiente contenido (Deberás sustituir ese XXXXXx por tu nombre.):

```
<h1>HOLA SOY XXXXXX</h1>
```

* Una vez hecho esto arrancar dos contenedores basados en la imagen php:7.4-apache que hagan un bind mount de la carpeta saludo en la carpeta /var/www/html del contenedor. Uno de ellos vamos a acceder con el puerto 8181 y el otro con el 8282. Y su nombres serán c1 y c2.
* Modifica el contenido del fichero `~/saludo/index.html`.
* Comprueba que puedes seguir accediendo a los contenedores, sin necesidad de reiniciarlos.

----------------------------------------------------------------

Empezamos creando la carpeta y el fichero `index.html`:

```
mkdir /opt/saludo && echo "<h1>HOLA SOY DANIEL PARRALES</h1>" > /opt/saludo/index.html
```

Ahora crearemos los dos contenedores con la directorio anexado:

```
docker run -d --name c1 -p 8181:80 -v /opt/saludo:/var/www/html php:7.4-apache

docker run -d --name c2 -p 8282:80 -v /opt/saludo:/var/www/html php:7.4-apache
```

![img_21.png](/images/introduccion_docker/img_21.png)

Si entramos en el navegador web y entramos en el puerto de ambos contenedores, podremos ver el contenido del fichero "index.html" que creamos antes:

![img_11.png](/images/introduccion_docker/img_11.png)

![img_12.png](/images/introduccion_docker/img_12.png)

Si ahora modificamos ese fichero y recargamos la página, en ambos contenedores cambia la información:

![img_13.png](/images/introduccion_docker/img_13.png)

![img_14.png](/images/introduccion_docker/img_14.png)

### Creación y uso de volúmenes

* Crear los siguientes volúmenes con la orden docker volume: `volumen_datos` y `volumen_web`.
* Una vez creados estos contenedores:
    * Arrancar un contenedor llamado `c1` sobre la imagen `php:7.4-apache` que monte el `volumen_web` en la ruta `/var/www/html` y que sea accesible en el puerto 8080.
    * Arrancar un contenedor llamado `c2` sobre la imagen `mariadb` que monte el `volumen_datos` en la ruta `/var/lib/mysql` y cuya contraseña de root sea admin.
* Intenta borrar el volumen `volumen_datos`, para ello tendrás que parar y borrar el contenedor `c2` y tras ello borrar el volumen.
* Copia o crea un fichero `index.html` al contenedor `c1`, accede al contenedor y comprueba que se está visualizando.
* Borra el contenedor `c1` y crea un contenedor `c3` con las mismas características que c1 pero sirviendo en el puerto 8081.

-----------------------------------------------------

Creamos los volúmenes:

```
docker volume create volumen_datos

docker volume create volumen_web
```

Podemos verlos de la siguiente forma:

![img_15.png](/images/introduccion_docker/img_15.png)

Ahora creamos los contenedores usando los volúmenes que acabamos de crear:

```
docker run -d --name c1 -p 8080:80 -v volumen_web:/var/www/html php:7.4-apache

docker run -d --name c2 -v volumen_datos:/var/lib/mysql -e MARIADB_ROOT_PASSWORD=admin mariadb
```

![img_16.png](/images/introduccion_docker/img_16.png)

Para borrar el volumen_datos, primero tendremos que parar y borrar el contenedor que está haciendo uso de él. Así pues, seguiremos los siguientes pasos:

```
docker stop c2

docker rm c2

docker volume rm volumen_datos
```

![img_17.png](/images/introduccion_docker/img_17.png)

Ahora crearemos un fichero `index.html` en el contenedor `c1`:

```
docker cp Descargas/index.html c1:/var/www/html/
```

Podemos ver el contenido del mismo en el navegador web:

![img_18.png](/images/introduccion_docker/img_18.png)

Ahora borraremos el contenedor y crearemos otro que hará uso del mismo volumen pero que será accesible a través del puerto 8081:

```
docker stop c1

docker rm c1

docker run -d --name c3 -p 8081:80 -v volumen_web:/var/www/html php:7.4-apache
```

![img_19.png](/images/introduccion_docker/img_19.png)

Ahora veamos si el `index.html` que muestra es el mismo que creamos en el otro contenedor:

![img_20.png](/images/introduccion_docker/img_20.png)

Como vemos, a pesar de haber borrado el contenedor, la información se ha guardado al haberla guardado en el volumen.


## Ejercicio 4: Redes

### Despliegue de Nextcloud + Mariadb/PostgreSQL

Vamos a desplegar la aplicación nextcloud con una base de datos (puedes elegir mariadb o PostgreSQL) (*NOTA: Para que no te de errores utiiliza la imagen `mariadb:10.5`*). Te puede servir el ejercicio que hemos realizado para desplegar [Wordpress](https://iesgn.github.io/curso_docker_2021/sesion4/wordpress.html). Para ello sigue los siguientes pasos:

* Crea una red de tipo bridge.
* Crea el contenedor de la base de datos conectado a la red que has creado. La base de datos se debe configurar para crear una base de dato y un usuario. Además el contenedor debe utilizar almacenamiento (volúmenes o bind mount) para guardar la información. Puedes seguir la documentación de [Mariadb](https://hub.docker.com/_/mariadb) o la de [PostgreSQL](https://hub.docker.com/_/postgres).
* A continuación, siguiendo la documentación de la imagen [nextcloud](https://hub.docker.com/_/nextcloud), crea un contenedor conectado a la misma red, e indica las variables adecuadas para que se configure de forma adecuada y realice la conexión a la base de datos. El contenedor también debe ser persistente usando almacenamiento.
* Accede a la aplicación usando un navegador web.

-----------------------------------------------------------

Empecemos creando la red:

```
docker network create red_nextcloud
```

Ahora crearemos el contenedor de la base de datos (usaremos mariadb y "bind mount" para guardar la información):

```
docker run -d --name bdmaria --network red_nextcloud -v /opt/mariadb_nextcloud:/var/lib/mysql -e MARIADB_ROOT_PASSWORD=root -e MARIADB_DATABASE=nextcloud -e MARIADB_USER=nextcloud -e MARIADB_PASSWORD=nextcloud mariadb:10.5
```

![img_22.png](/images/introduccion_docker/img_22.png)

A continuación crearemos el contenedor con la aplicación nextcloud, al cual le indicaremos mediante variables de entorno, que la base de datos que debe usar es la que hemos creado en el otro contenedor:

```
docker run -d --name nextcloud --network red_nextcloud -v /opt/nextcloud:/var/www/html -p 8081:80 -e MYSQL_DATABASE=nextcloud -e MYSQL_USER=nextcloud -e MYSQL_PASSWORD=nextcloud -e MYSQL_HOST=bdmaria nextcloud
```

![img_23.png](/images/introduccion_docker/img_23.png)

Con esto, si entramos en el navegador y nos vamos al puerto 8081 nos debería aparecer la página de inicio de nextcloud:

![img_24.png](/images/introduccion_docker/img_24.png)

## Ejercicio 5: Escenarios multicontenedor

### Despliegue de prestashop

Es esta tarea vamos a desplegar una tienda virtual construída con prestashop. Utilizaremos el fichero `docker-compose.yml` de Bitnami que podemos encontrar en la siguiente [URL](https://hub.docker.com/r/bitnami/prestashop).

Una vez hemos descargado el fichero docker-compose.yml asociado deberemos modificarlo de la siguiente manera:

Modificar los valores de las variables de entorno para conseguir lo siguiente:

* El usuario de prestashop para conectarse a la base de datos deberá ser pepe y su contraseña pepe. Investigar en la página de Dockerhub cuál es el nombre de las variables de entorno que debo modificar y/o añadir.
* Modificar el nombre de la base de datos de prestashop para que se llame mitienda. Debéis de modificar esos valores en los dos servicios. Investigar en la página de Dockerhub cuál es el nombre de las variables de entorno que debo modificar.
* Ten en cuenta que si tienes instalado docker en una máquina virtual y tienes que poner la IP de la máquina para acceder a los contenedores, debes modificar la variable de entorno `PRESTASHOP_HOST` para poner esa dirección ip.
* Por último, si tienes que repetir el ejercicio, borra el escenario con `docker-compose down -v`, para eliminar los volúmenes y que la modificación de la configuración se tenga en cuenta.

----------------------------------------------------------------------------

En primer lugar debemos instalarnos "docker-compose":

```
apt install docker-compose
```

A continuación nos descargamos el fichero `docker-compose.yml` tal y como se nos indica en la url proporcionada:

```
curl -sSL https://raw.githubusercontent.com/bitnami/bitnami-docker-prestashop/master/docker-compose.yml > docker-compose.yml
```

Modificamos los parámetros necesarios para que se adapte a lo que nos piden:

```
nano docker-compose.yml

# En el servicio de mariadb:

ALLOW_EMPTY_PASSWORD=no
MARIADB_ROOT_PASSWORD=root
MARIADB_USER=pepe
MARIADB_PASSWORD=pepe
MARIADB_DATABASE=mitienda

# En el servicio de prestashop

PRESTASHOP_HOST=localhost
PRESTASHOP_DATABASE_HOST=mariadb
PRESTASHOP_DATABASE_PORT_NUMBER=3306
PRESTASHOP_DATABASE_USER=pepe
PRESTASHOP_DATABASE_NAME=mitienda
ALLOW_EMPTY_PASSWORD=no
PRESTASHOP_DATABASE_PASSWORD=pepe
```

Tras estas modificaciones, el fichero queda de la siguiente forma:

![img_25.png](/images/introduccion_docker/img_25.png)

Ahora levantamos los contenedores con el siguiente comando:

```
docker-compose up -d
```

Tras descargar los ficheros necesarios, podemos comprobar que los contenedores están funcionando con el siguiente comando:

```
docker-compose ps
```

![img_26.png](/images/introduccion_docker/img_26.png)

Nos indica que están funcionando, por lo que podemos acceder a nuestro navegador y ver si realmente se muestra la página principal de prestashop:

![img_27.png](/images/introduccion_docker/img_27.png)

Como se nos muestra la página principal, podemos decir que el ejercicio ha sido un éxito.
