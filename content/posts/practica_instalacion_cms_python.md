+++ 
draft = true
date = 2021-11-26T19:12:33+01:00
title = "Instalación de un CMS python (Mezzanine)"
description = "Instalación de un CMS python (Mezzanine)"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Aplicaciones Web"]
externalLink = ""
series = []
+++

# Instalación de un CMS python

En esta tarea vamos a desplegar un CMS python. Tienes que realizar la instalación de un CMS python basado en django (puedes encontrar varios en el siguiente [enlace](https://djangopackages.org/grids/g/cms/).

## Instala el CMS en el entorno de desarrollo. Debes utilizar un entorno virtual.

En mi caso, he elegido instalar "Mezzanine". Así pues, lo primer es crear y activar el entorno virtual en el que trabajaremos en desarrollo:

```
python3 -m venv mezzanine_venv

source mezzanine_venv/bin/activate
```

Una vez activado, procedamos a instalar "Mezzanine" y sus dependencias:

```
pip install mezzanine
```

Ahora que está instalado, vamos a crear el proyecto de la aplicación:

```
mezzanine-project mezzaparr
```

Una vez que hemos creado el proyecto, procedemos a crear la base de datos:

```
python manage.py createdb
```

Con la base de datos creada, antes de poder acceder a la web, tenemos que modificar el fichero 'local_settings.py', para introducir la lista de hosts que van a tener permitido el acceso. Así pues, en mi caso, añadí lo siguiente:

```
ALLOWED_HOSTS = ["192.168.121.161"]
```

Una vez hecho esto, vamos a intentar acceder a través de un navegador a la paǵina web. Para ello antes tenemos que activar el servidor con el siguiente comando:

```
python manage.py runserver 0.0.0.0:8000
```

![paginainicial_mezzanine.png](/images/practica_instalacion_cms_python/paginainicial_mezzanine.png)

Con esto hemos finalizado la instalación en el entorno de desarrollo.

## Personaliza la página (cambia el nombre al blog y pon tu nombre) y añade contenido (algún artículo).

Para realizar esta parte de la tarea, primero debemos crearnos un usuario administrador de la aplicación:

```
python3 manage.py createsuperuser
```

Una vez que lo hemos creado, podemos acceder a la zona de administración de nuestra aplicación:

![administracion_mezzanine.png](/images/practica_instalacion_cms_python/administracion_mezzanine.png)

En esta página entramos con las credenciales que acabamos de crear:

![admin_mezzanine.png](/images/practica_instalacion_cms_python/admin_mezzanine.png)

Una vez en la zona de administración, ya podemos cambiar la página a nuestro gusto. En mi caso, he creado la siguiente entrada de blog:

![blog_mezzanine.png](/images/practica_instalacion_cms_python/blog_mezzanine.png)

Y he cambiado el título a la página:

![nombre_mezzanine.png](/images/practica_instalacion_cms_python/nombre_mezzanine.png)

Con esto ya hemos personalizado lo suficiente la página en este apartado.

## Guarda los ficheros generados durante la instalación en un repositorio github. Guarda también en ese repositorio la copia de seguridad de la bese de datos. Ten en cuenta que en el entorno de desarrolla vas a tener una base de datos sqlite, y en el entorno de producción una mariadb, por lo tanto es recomendable para hacer la copia de seguridad y recuperarla los comandos: `python manage.py dumpdata` y `python manage.py loaddata`, para [más información](https://coderwall.com/p/mvsoyg/django-dumpdata-and-loaddata).

En primer lugar tenemos que hacer una copia de seguridad de la información de la base de datos. Como la base de datos es diferente en producción, tenemos que hacer uso del siguiente comando para sacar la información:

```
python manage.py dumpdata > copia241121.json
```

En el servidor de base de datos mariadb que tenemos en producción, tenemos que crear un nueva base de datos y un usuario con privilegios sobre la misma:

```
create database mezzanine;

grant all on mezzanine.* to 'mezzanine'@'%' identified by '******' with grant option;
```

Una vez hecha la copia, ya podemos subir nuestro proyecto a github para descargarlo en nuestro servidor en producción.

```
git clone https://github.com/DanielPG25/mezzaparr.git
```

Ahora tenemos que modificar el fichero `settings.py` para adaptarlo al nuevo entorno:

![settings_mezzanine.png](/images/practica_instalacion_cms_python/settings_mezzanine.png)

Una vez modificado el fichero, vamos a instalar todos los paquetes que vamos a necesitar en el entorno de producción:

```
pip install --upgrade pip
pip install wheel 
pip install uwsgi mysql-connector-python mezzanine pymysql
```

Una vez que hemos instalado los paquetes, probamos a hacer la migración:

```
python3 manage.py migrate

..............
django.core.exceptions.ImproperlyConfigured: Error loading MySQLdb module: No module named 'MySQLdb'.
Did you install mysqlclient or MySQL-python?
```

El error nos indica que no encuentra el módulo de mysql. Para solucionarlo, simplemente tenemos que añadir al fichero `__init__.py ` la siguiente información:

```
import pymysql
pymysql.install_as_MySQLdb()
```

Con este error corregido, ya podemos hacer la migración:

```
python3 manage.py migrate
```

Tras haber realizado la migración, ya podemos cargar la copia que sacamos de nuestra base de datos en desarrollo:

```
python3 manage.py loaddata copia241121.json
```

## Realiza el despliegue de la aplicación en tu entorno de producción (servidor web y servidor de base de datos en KVM/openstack). Utiliza un entorno virtual. Utiliza el servidor de aplicaciones python que no hayas usado en la práctica anterior. El contenido estático debe servirlo el servidor web. La aplicación será accesible en la url `python.tunombre.gonzalonazareno.org`.

Ahora vamos a empezar a servir la aplicación haciendo uso de 'uwsgi'. Para ello, primero creamos un fichero `.ini` en el directorio donde se encuentra el fichero `settings.py` y añadimos la siguiente información:

```
nano mezzaparr/mezzanine.ini

[uwsgi]
http = :8080
chdir = /home/hera/mezzaparr
module = mezzaparr.wsgi:application
processes = 4
threads = 2
```

En este momento podríamos acceder a la aplicación ejecutando el siguiente comando:

```
uwsgi --ini mezzaparr/mezzanine.ini
```

Sin embargo, para tener un mayor control sobre la aplicación (hay que recordar abrir el puerto 8080 en la máquina si no lo está ya), vamos a crear una unidad systemd. Así pues:

```
/etc/systemd/system/uwsgi-mezza.service

[Unit]
Description=uwsgi-mezza
After=network.target

[Install]
WantedBy=multi-user.target

[Service]
User=hera
Group=hera
Restart=always

ExecStart=/home/hera/mezzanine/bin/uwsgi /home/hera/mezzaparr/mezzaparr/mezzanine.ini
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID

WorkingDirectory=/home/hera/mezzaparr
Environment=PYTHONPATH='/home/hera/mezzaparr:/home/hera/mezzanine/lib/python3.6/site-packages'

PrivateTmp=true
```

Ahora habilitamos el servicio y lo activamos (antes he desactivado SElinux porque me daba errores y no es necesario tenerlo activado para esta actividad):

```
sudo systemctl enable uwsgi-mezza.service

sudo systemctl start uwsgi-mezza.service
```

Antes de crear el virtualhost debemos recordar usar el siguiente comando para crear una carpeta que contendrá todo el contenido estático referente a las aplicaciones que están añadidas en "Installed Apps" en el `settings.py`:

```
python3 manage.py collectstatic
```

Ahora creamos el virtualhost para la nueva aplicación:

```
/etc/httpd/sites-available/mezzanine.conf


<VirtualHost *:80>

        ServerName python.dparrales.gonzalonazareno.org
        ServerAdmin webmaster@localhost
        Alias /static /home/hera/mezzaparr/static
        <Directory /home/hera/mezzaparr/static>
                Require all granted
                Options FollowSymlinks
        </Directory>

        ProxyPass /static !
        ProxyPass / http://localhost:8080/

        <Proxy "unix:/run/php-fpm/www.sock|fcgi://php-fpm">
                ProxySet disablereuse=off
        </Proxy>

        <FilesMatch \.php$>
                SetHandler proxy:fcgi://php-fpm
        </FilesMatch>


</VirtualHost>
```

Como vemos, hemos creado un alias para el contenido estático. Esto se debe a que django no muestra el contenido estático en producción, es decir, si Debug es igual a False. Es por ello que para conseguir mostrar el contenido estático debemos crear un alias, y al proxy que indica el contenido estático, le añadimos el símbolo "!", que simboliza que no debe buscar ese contenido a través del proxy, sino en local.

**Nota:**Si aún habiendo creado el proxy y la carpeta de forma correcta, el contenido estático sigue sin servirse, aseguraos de que el usuario que sirve la aplicación (por defecto el usuario apache en Rocky), tenga permisos para acceder a la carpeta de la aplicación y del contenido estático. 

Como estamos en Rocky, debemos crear el enlace simbólico a mano:

```
ln -s /etc/httpd/sites-available/mezzanine.conf /etc/httpd/sites-enabled/mezzanine.conf
```


Una vez explicado lo anterior pasamos a reiniciar el servicio httpd:

```
systemctl reload httpd
```

Ahora ya podemos acceder a nuestra página a través del navegador (tras añadir el correspondiente registro CNAME en nuestro servidor dns):

![acceso_hera.png](/images/practica_instalacion_cms_python/acceso_hera.png)

Como vemos se nos sirve el contenido estático. Veamos ahora si el artículo que creamos anteriormente sigue ahí (lo que querría decir que la migración de los datos de la base datos fue correcta):

![contenido_blog.png](/images/practica_instalacion_cms_python/contenido_blog.png)

Con esto podemos decir que la migración ha sido un éxito.
