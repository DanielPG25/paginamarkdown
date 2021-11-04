+++ 
draft = true
date = 2021-11-04T10:29:00+01:00
title = "Desplegando aplicaciones flask con apache2 + mod_wsgi"
description = "Desplegando aplicaciones flask con apache2 + mod_wsgi"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Aplicaciones Web"]
externalLink = ""
series = []
+++

# Desplegando aplicaciones flask con apache2 + mod_wsgi

En este ejercicio tenemos que configurar la aplicación [guestbook](https://github.com/josedom24/guestbook) para que sea servida con apache2 y el módulo wsgi. Para ello vamos a tener que realizar los siguientes pasos:


## Crear el entorno virtual con el que vamos a trabajar

Para ello tenemos que instalar el paquete necesario para crear entornos virtuales con python3:

`
apt install python3-venv
`

A continuación podemos crear el entorno con el siguiente comando:

`
python3 -m venv flask
`

Ahora activamos el entorno virtual que hemos creado e instalamos flask y redis:

```
source flask/bin/activate

pip install flask redis

apt install redis
```

Ahora solo tenemos que clonar el repositorio, ejecutar el `app.py` y ver si funciona:

```
git clone https://github.com/josedom24/guestbook.git

python3 app.py
```


![guestbook.png](/images/apache2_flask/guestbook.png)

Como vemos, la aplicación funciona. Ahora tenemos que hacer que funcione usando apache2 para que ejecute flask.


## Configurar apache2 para que ejecute la aplicación

Si no lo está ya, instalamos apache2 y el módulo wsgi:

`
apt install apache2 libapache2-mod-wsgi-py3
`

Activamos el módulo wsgi si no lo está ya:

`
a2enmod wsgi
`

Creamos el fichero `wsgi.py` en el mismo directorio donde se encuentra la aplicación:

```
nano guestbook/app/wsgi.py 

from app import prog as application
```

Tenemos que tener en cuenta lo siguiente:

* El primer app corresponde con el nombre del módulo, es decir del fichero del programa, en nuestro caso se llama app.py.
* Prog se corresponde con la aplicación flask creada en app.py: `prog = Flask(__name__)`.
* Importamos la aplicación flask, pero la llamamos `application` necesario para que el servidor web pueda enviarle peticiones.


A continuación creamos un virtualhost para que ejecute la aplicación:

```
nano /etc/apache2/sites-available/guestbook.conf

<VirtualHost *:80>

        ServerName www.guestbook.com
        ServerAdmin webmaster@localhost
        DocumentRoot /home/vagrant/guestbook/app
        ErrorLog ${APACHE_LOG_DIR}/guestbook-error.log
        CustomLog ${APACHE_LOG_DIR}/guestbook-access.log combined

        WSGIDaemonProcess guestbook python-path=/home/vagrant/guestbook/app:/home/vagrant/flask/lib/python3.9/site-packages
        WSGIProcessGroup guestbook
        WSGIScriptAlias / /home/vagrant/guestbook/app/wsgi.py process-group=guestbook
        <Directory /home/vagrant/guestbook/app>
                Require all granted
        </Directory>

</VirtualHost>
```

Ahora activamos el virtualhost que acabamos de crear y reiniciamos el servicio:

```
a2ensite guestbook.conf

systemctl reload apache2
```

Con esto ya podemos acceder a la web siempre y cuando indiquemos la resolución estática de nombres en el fichero `/etc/hosts` de nuestra máquina:

`
192.168.121.161 www.guestbook.com
`

Entramos en la web y vemos si funciona:

![entrada_final_guestbook.png](/images/apache2_flask/entrada_final_guestbook.png)

Con esto ya habríamos terminado de configurar apache2 para que ejecute la aplicación flask.

 
