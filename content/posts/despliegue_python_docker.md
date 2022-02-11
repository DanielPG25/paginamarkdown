+++ 
draft = true
date = 2022-02-11T18:37:27+01:00
title = "Implantación de aplicaciones web Python en Docker"
description = "Implantación de aplicaciones web Python en Docker"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Aplicaciones Web"]
externalLink = ""
series = []
+++

# Implantación de aplicaciones web Python en Docker

Queremos desplegar en docker la aplicación escrita en python: tutorial de django 3.2, que desplegamos en la tarea [Despliegue de aplicaciones python](https://fp.josedomingo.org/iaw2122/u03/practica.html).

Tienes que tener en cuenta los siguientes aspectos:

* La aplicación debe guardar los datos en una base de datos mariadb.
* La aplicación se podrá configurar para indicar los parámetros de conexión a la base de datos: usuario, contraseña, host y base de datos.
* La aplicación deberá tener creado un usuario administrador para el acceso.

----------------------------------------------------------------

En el entorno de desarrollo, para hacer las pruebas necesarias, vamos a crear los dos contenedores a mano conectados a la misma red. Cuando comprobemos que la aplicación funciona, crearemos el docker-compose y lo pasaremos al entorno de producción. Así pues, primero creamos la red a la que conectaremos ambos contenedores:

```
docker network create django-net
```

Creamos el contenedor de mariadb con las siguientes variables

```
docker run -d --name mariadb -v vol_polls:/var/lib/mysql --network django-net -e MARIADB_ROOT_PASSWORD=root -e MARIADB_USER=django -e MARIADB_PASSWORD=django -e MARIADB_DATABASE=django mariadb
```

Modificamos el fichero `settings.py` y lo modificamos para que sea capaz de leer las variables de entorno, añadiendo o modificando la siguiente información:

```
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
```

```
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': os.environ.get("BASE_DATOS"),
        'USER': os.environ.get('USUARIO'),
        'PASSWORD': os.environ.get("CONTRA"),
        'HOST': os.environ.get('HOST'),
        'PORT': '3306',
    }
}
```

```
ALLOWED_HOSTS = [os.environ.get("ALLOWED_HOSTS")]
```

```
STATIC_ROOT = os.path.join(BASE_DIR, 'static')
STATIC_URL = '/static/'
CSRF_TRUSTED_ORIGINS = ['http://*.sysadblog.com','http://*.127.0.0.1','https://*.sysadblog.com','https://*.127.0.0.1']
```

Creamos el Dockerfile a partir de la imagen de python:

```
nano Dockerfile

FROM python:3
WORKDIR /usr/src/app
MAINTAINER Daniel Parrales García "daniparrales16@gmail.com"
RUN pip install django mysqlclient && git clone https://github.com/DanielPG25/django_tutorial.git /usr/src/app && mkdir static && chmod + /usr/src/app/django_polls.sh
ENV ALLOWED_HOSTS=*
ENV HOST=mariadb
ENV USUARIO=django
ENV CONTRA=django
ENV BASE_DATOS=django
ENV DJANGO_SUPERUSER_PASSWORD=admin
ENV DJANGO_SUPERUSER_USERNAME=admin
ENV DJANGO_SUPERUSER_EMAIL=admin@example.org
CMD ["/usr/src/app/django_polls.sh"]
```

Al final del Dockerfile hacemos referencia a un script. Dicho script es el siguiente:

```
nano django_polls.sh

#! /bin/sh

python3 manage.py makemigrations
python3 manage.py migrate
python3 manage.py createsuperuser --noinput
python3 manage.py collectstatic --no-input
python3 manage.py runserver 0.0.0.0:8006
```

Ahora creamos la imagen:

```
docker build -t dparrales/django_tutorial .
```

Para probar dicha imagen, antes de hacer el docker-compose, creamos un contenedor en la misma red que el contenedor de mariadb:

```
docker run -d --name polls --network django-net -p 8080:8006 dparrales/django_tutorial
```

Y entramos a través del navegador al puerto que le hemos indicado:

![img_1.png](/images/despliegue_python_docker/img_1.png)

Como vemos, podemos acceder a la página web sin problemas, por lo que podemos decir que imagen funciona. Ahora crearemos el fichero `docker-compose.yaml` que levantará todo el escenario:

```
nano docker-compose.yaml

version: '3.1'
services:
  django-tutorial:
    container_name: django-tutorial
    image: dparrales/django_tutorial
    restart: always
    environment:
      ALLOWED_HOSTS: "*"
      HOST: bd_mariadb_django
      USUARIO: django
      CONTRA: django
      BASE_DATOS: django
      DJANGO_SUPERUSER_PASSWORD: admin
      DJANGO_SUPERUSER_USERNAME: admin
      DJANGO_SUPERUSER_EMAIL: admin@example.org
    ports:
      - 8084:8006
    depends_on:
      - db_django
  db_django:
    container_name: bd_mariadb_django
    image: mariadb
    restart: always
    environment:
      MARIADB_ROOT_PASSWORD: root
      MARIADB_DATABASE: django
      MARIADB_USER: django
      MARIADB_PASSWORD: django
    volumes:
      - mariadb_data_django:/var/lib/mysql
volumes:
    mariadb_data_django:
```

Probemos a levantar el escenario en desarrollo a partir del docker-compose:

```
docker-compose up -d
```

Volvemos a acceder:

![img_2.png](/images/despliegue_python_docker/img_2.png)

Intentamos entrar en la zona de administración con las credenciales que pusimos en el docker-compose:

![img_3.png](/images/despliegue_python_docker/img_3.png)

Como vemos, todo parece funcionar bien. Ahora nos iremos al entorno de producción y levantaremos allí el docker-compose:

```
docker-compose up -d
```

Vemos que se han creado ambos contenedores:

![img_4.png](/images/despliegue_python_docker/img_4.png)

Ahora debemos crear un nuevo registro CNAME en nuestro servidor DNS:

![img_5.png](/images/despliegue_python_docker/img_5.png)

Hecho esto, ya podemos solicitar los certificados de "Let's Encrypt" para el nuevo dominio:

```
certbot certonly --standalone -d tutorial.sysadblog.com

Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator standalone, Installer None
Requesting a certificate for tutorial.sysadblog.com
Performing the following challenges:
http-01 challenge for tutorial.sysadblog.com
Waiting for verification...
Cleaning up challenges

IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/tutorial.sysadblog.com/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/tutorial.sysadblog.com/privkey.pem
   Your certificate will expire on 2022-05-11. To obtain a new or
   tweaked version of this certificate in the future, simply run
   certbot again. To non-interactively renew *all* of your
   certificates, run "certbot renew"
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le
```


Una vez generados, solo tenemos que crear el proxy en nginx para que nos permita acceder al contenedor:

```
nano /etc/nginx/sites-available/polls

server {
        listen 80;
        listen [::]:80;

        server_name tutorial.sysadblog.com;

        return 301 https://$host$request_uri;
}

server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;

        ssl    on;
        ssl_certificate /etc/letsencrypt/live/tutorial.sysadblog.com/fullchain.pem;
        ssl_certificate_key     /etc/letsencrypt/live/tutorial.sysadblog.com/privkey.pem;

        index index.html index.php index.htm index.nginx-debian.html;

        server_name tutorial.sysadblog.com;

        location / {
                proxy_pass http://localhost:8084;
                include proxy_params;
        }
}
```

Ahora creamos el enlace simbólico:

```
ln -s /etc/nginx/sites-available/polls /etc/nginx/sites-enabled/polls
```

Y reiniciamos nginx:

```
systemctl restart nginx
```

Ahora deberíamos poder acceder sin problemas desde el navegador:

![img_6.png](/images/despliegue_python_docker/img_6.png)

![img_7.png](/images/despliegue_python_docker/img_7.png)

Como vemos, podemos entrar sin problemas en la zona de administración, por lo que podemos dar por finalizada esta práctica.
