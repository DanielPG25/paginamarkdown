+++ 
draft = true
date = 2021-11-09T21:15:20+01:00
title = "Desplegando aplicaciones flask con apache2 + uwsgi"
description = "Desplegando aplicaciones flask con apache2 + uwsgi"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Aplicaciones Web"]
externalLink = ""
series = []
+++

# Desplegando aplicaciones flask con apache2 + uwsgi

Vamos a explicar paso por paso como configurar apache y ngnix para que usen uwsgi para servir aplicaciones web python, en concreto, la aplicación `guestbook`.

En primer lugar tenemos que instalar los paquetes que usaremos para el ejercicio, incluyendo los paquetes necesarios para crear el entorno virtual y las dependencias de `guesbook`:

```
apt install python3-venv libapache2-mod-wsgi-py3 git redis build-essential libpython3.9-dev
```

Ahora creamos el entorno virtual en el que instalaremos flask:

```
python3 -m venv flask
```

Activamos el entorno virtual e instalamos flask y uwsgi con pip:

```
source flask/bin/activate

pip install flask uwsgi
```
 
Ya podemos clonar el repositorio de github con la aplicación guestbook:

```
git clone https://github.com/josedom24/guestbook.git
```

No se nos puede olvidar crear el fichero `wsgi.py` en el mismo directorio donde se encuentra la aplicación `app.py`, añadiendo la siguiente línea al fichero `wsgi.py`:

```
nano wsgi.py

from app import prog as application
```

Con esto ya podríamos ejecutar la aplicación y acceder a ella si usamos el comando específico de uwsgi:

```
uwsgi --http :8080 --chdir /home/vagrant/guestbook/app --wsgi-file    wsgi.py --process 4 --threads 2 --master
```

Ahora podemos acceder a la ip de nuestra máquina al puerto 8080 y ver la aplicación:

![guestbook_uwsgi_app.png](/images/flask_apache2_uwsgi/guestbook_uwsgi_app.png)

En lugar de usar el comando con sus parámetros, podemos ejecutarlo a través de un fichero `.ini` con la siguiente información:

```
nano guestbook.ini

[uwsgi]
http = :8080
chdir = /home/vagrant/guestbook/app               
wsgi-file = wsgi.py
processes = 4
threads = 2
```

El comando es el siguiente:

```
uwsgi guestbook.ini
```

Ahora procedamos a crear unidad systemd para poder controlar el proceso de uwsgi de forma más sencilla. Para ello creamos el fichero `uwsgi-guestbook.service` en el directorio `/etc/systemd/system/`:

```
nano /etc/systemd/system/uwsgi-guestbook.service

[Unit]
Description=uwsgi-guestbook
After=network.target

[Install]
WantedBy=multi-user.target

[Service]
User=www-data
Group=www-data
Restart=always

ExecStart=/home/vagrant/flask/bin/uwsgi /home/vagrant/guestbook/app/guestbook.ini
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID

WorkingDirectory=/home/vagrant/guestbook/app
Environment=PYTHONPATH='/home/vagrant/guestbook/app:/home/vagrant/flask/lib/python3.9/site-packages'

PrivateTmp=true
```

Activamos la unidad de systemd, y la iniciamos:

```
systemctl enable uwsgi-guestbook.service

systemctl start uwsgi-guestbook.service
```

Si cambiamos el contenido de la unidad tendremos que recargar el demonio:

```
systemctl daemon-reload
```

Con esta configuración ya podemos controlar uwsgi con systemctl, como si fuera un servicio más. Ahora podemos configurar apache o nginx como un proxy inverso que haga uso del servicio que hemos creado para servir las aplicaciones python.

* En apache2:

Creamos un virtualhost con la siguiente configuración:

```
nano guestbook.conf

<VirtualHost *:80>

	ServerName www.guestbook.com
	ServerAdmin webmaster@localhost
	DocumentRoot /home/vagrant/guesbook/app
	ProxyPass / http://127.0.0.1:8080/
	ProxyPassReverse / http://127.0.0.1:8080/
	<Directory /home/vagrant/guesbook/app>
		Require all granted
	</Directory>

	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined

</VirtualHost>
```

Una vez creado el virtualhost lo habilitamos:

```
a2ensite guestbook.conf
```

También debemos habilitar los módulos del proxy:

```
a2enmod proxy proxy_http
```

Reiniciamos el servicio y probamos la conexión (hay que recordar añadir la dirección estática al fichero `/etc/hosts` del anfitrión):

```
systemctl reload apache2
```

![guestbook_apache2_uwsgi.png](/images/flask_apache2_uwsgi/guestbook_apache2_uwsgi.png)

Podemos acceder a la página, por lo que podemos decir que funciona.


* En nginx:

Creamos un virtualhost con la siguiente configuración:

```
nano guestbook

server {
        listen 80;
        listen [::]:80;

        root /home/vagrant/guestbook/app;

        index index.html index.php index.htm index.nginx-debian.html;

        server_name www.guestbook.com;

        location / {
                proxy_pass http://192.168.121.190:8080;
                include proxy_params;
        }

}
```

Creamos el enlace simbólico del virtualhost y reiniciamos el servicio:

```
ln -s /etc/nginx/sites-available/guestbook /etc/nginx/sites-enabled/

systemctl reload nginx
```

Ahora probamos a acceder a guestbook desde el navegador:

![guestbook_nginx_uwsgi.png](/images/flask_apache2_uwsgi/guestbook_nginx_uwsgi.png)

También funciona al acceder a `www.guestbook.com` cuando lo sirve nginx.
