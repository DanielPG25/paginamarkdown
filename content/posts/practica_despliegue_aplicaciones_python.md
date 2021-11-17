+++ 
draft = true
date = 2021-11-17T19:48:03+01:00
title = "Despliegue de aplicaciones python"
description = "Despliegue de aplicaciones python"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Aplicaciones Web"]
externalLink = ""
series = []
+++

# Despliegue de aplicaciones python

## Tarea 1: Entorno de desarrollo

Vamos a desarrollar la aplicación del [tutorial de django 3.2](https://docs.djangoproject.com/en/3.2/intro/tutorial01/). Vamos a configurar tu equipo como entorno de desarrollo para trabajar con la aplicación, para ello:

* Realiza un fork del repositorio de GitHub: https://github.com/josedom24/django_tutorial.
* Crea un entorno virtual de python3 e instala las dependencias necesarias para que funcione el proyecto.
* Comprueba que vamos a trabajar con una base de datos sqlite. ¿Qué fichero tienes que consultar?. ¿Cómo se llama la base de datos que vamos a crear?
* Crea la base de datos. A partir del modelo de datos se crean las tablas de la base de datos.
* Crea un usuario administrador.
* Ejecuta el servidor web de desarrollo y entra en la zona de administración (/admin) para comprobar que los datos se han añadido correctamente.
* Crea dos preguntas, con posibles respuestas.
* Comprueba en el navegador que la aplicación está funcionando, accede a la url /polls.
---------------------------------------------------------------------------------------------------------------------------------------------------------

Tal y como se nos ha indicado, vamos a realizar en primer lugar un fork del repositorio:

![fork_repo.png](/images/practica_despliegue_aplicaciones_python/fork_repo.png)

A continuación, clonamos el repositorio, creamos un entorno virtual e instalamos las dependencias del proyecto:

```
git clone git@github.com:DanielPG25/django_tutorial.git

python3 -m venv django

source django/bin/activate

pip install -r requirements.txt
```

Para verificar la base de datos con la que vamos a trabajar, vemos el contenido del fichero `django_tutorial/settings.py`:

![basedatos_sqlite.png](/images/practica_despliegue_aplicaciones_python/basedatos_sqlite.png)

Como vemos, nos indica que vamos a trabajar con una base de datos de tipo sqlite llamada `db.sqlite3`. Ahora que comprobado esto, podemos crear la base de datos. Para ello debemos ejecutar la migración inicial que nos indica al iniciar la aplicación:

![basedatosinicial_sqlite.png](/images/practica_despliegue_aplicaciones_python/basedatosinicial_sqlite.png)

```
python3 manage.py migrate
```

Con esto hemos creado la base de datos inicial. Ahora vamos a proceder a crear un usuario administrador:

```
python3 manage.py createsuperuser
```

Antes de poder acceder a la aplicación, tenemos que añadir la ip desde la que vamos a acceder al fichero `django_tutorial/settings.py`, en la línea de allowed_hosts:

![allowed_host.png](/images/practica_despliegue_aplicaciones_python/allowed_host.png)

Ahora vamos a probar si funciona la aplicación. Para ello ejecutamos lo siguiente:

```
python3 manage.py runserver 0.0.0.0:8000
```

Ya podemos acceder desde nuestro navegador a la página principal:

![principal.png](/images/practica_despliegue_aplicaciones_python/principal.png)

Y en la zona de administración, en la cual tendremos que introducir el usuario y la contraseña que creamos antes:

![zona_administracion.png](/images/practica_despliegue_aplicaciones_python/zona_administracion.png)

Podemos crear las preguntas si damos al botón de `questions` y `add question`. Así pues, voy a crear dos preguntas con sus respuestas:

![preguntas_encuesta.png](/images/practica_despliegue_aplicaciones_python/preguntas_encuesta.png)

Ahora accedemos a la aplicación `polls` para ver si las preguntas y sus respuestas funcionan correctamente:

![polls_preguntas.png](/images/practica_despliegue_aplicaciones_python/polls_preguntas.png)

![pregunta1_encuesta.png](/images/practica_despliegue_aplicaciones_python/pregunta1_encuesta.png)

![pregunta2_encuesta.png](/images/practica_despliegue_aplicaciones_python/pregunta2_encuesta.png)

Como vemos, la aplicación funciona perfectamente. 

----------------------------------------------------
## Tarea 2: Entorno de producción

Vamos a realizar el despliegue de nuestra aplicación en un entorno de producción, para ello vamos a utilizar nuestro VPS, sigue los siguientes pasos:

* Clona el repositorio en el VPS.
* Crea un entorno virtual e instala las dependencias de tu aplicación.
* Instala el módulo que permite que python trabaje con mysql:
```
(env)$ pip install mysqlclient
```
* Crea una base de datos y un usuario en mysql.
* Configura la aplicación para trabajar con mysql, para ello modifica la configuración de la base de datos en el archivo settings.py:
```
      DATABASES = {
          'default': {
              'ENGINE': 'django.db.backends.mysql',
              'NAME': 'myproject',
              'USER': 'myprojectuser',
              'PASSWORD': 'password',
              'HOST': 'localhost',
              'PORT': '',
          }
      }
```
* Como en la tarea 1, realiza la migración de la base de datos que creará la estructura de datos necesarias. Comprueba que se han creado la base de datos y las tablas.
* Crea un usuario administrador.
* Elige un servidor de aplicaciones python y configura nginx como proxy inverso para servir la aplicación.
* Debes asegurarte que el contenido estático se está sirviendo: ¿Se muestra la imagen de fondo de la aplicación? ¿Se ve de forma adecuada la hoja de estilo de la zona de administración?.
* Desactiva en la configuración el modo debug a False. Para que los errores de ejecución no den información sensible de la aplicación.
* Muestra la página funcionando. En la zona de administración se debe ver de forma adecuada la hoja de estilo.
-------------------------------------------------------------------------------------------

Los primeros pasos en nuestra vps son los mismos que en el entorno de desarrollo:

```
git clone https://github.com/DanielPG25/django_tutorial.git

python3 -m venv django

source django/bin/activate

pip install -r requirements.txt
```

Tras esto instalamos el módulo de python que hace posible que pueda trabajar con mysql (antes debemos instalar las dependencias de dicho módulo):

```
apt install python3-dev default-libmysqlclient-dev build-essential

pip install mysqlclient
```

Ahora debemos crear un usuario y una base de datos en mariadb para poder almacenar las tablas y datos de la aplicación:

```
create database django_polls;

grant all on django_polls.* to 'django_polls'@'%' identified by '*****' with grant option;
```

A continuación, vamos a modificar el fichero `settings.py` para adaptarlo a la nueva base de datos:

![config_basedatos.png](/images/practica_despliegue_aplicaciones_python/config_basedatos.png)

Con esto, ya podemos ejecutar la migración y crear el usuario administrador como hicimos anteriormente:

```
python3 manage.py migrate

python3 manage.py createsuperuser
```

Ahora tenemos que usar un servidor de aplicaciones python y configurar nginx como proxy inverso para servir la aplicación. Así pues, he elegido el servidor de aplicaciones gunicorn. Por ello vamos a instalar gunicorn con pip en nuestro entorno virtual:

```
pip install gunicorn
```

Una vez hecho esto, podríamos ejecutar la aplicación simplemente con el siguiente comando (si nos encontramos en el directorio principal de la aplicación):

```
gunicorn django_tutorial.wsgi
```

Sin embargo, como queremos que la aplicación se este ejecutando continuamente para poder acceder a ella desde un virtualhost en nginx, vamos a crear una unidad systemd para poder controlar ese proceso de forma más sencilla:

```
nano /etc/systemd/system/gunicorn-djangopolls.service

[Unit]
Description=gunicorn-djangopolls
After=network.target

[Install]
WantedBy=multi-user.target

[Service]
User=www-data
Group=www-data
Restart=always

ExecStart=/home/dparrales/venv/django/bin/gunicorn django_tutorial.wsgi
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID

WorkingDirectory=/home/dparrales/django_tutorial
Environment=PYTHONPATH='/home/dparrales/django_tutorial:/home/dparrales/venv/django/lib/python3.9/site-packages'

PrivateTmp=true
```

Ahora habilitamos e iniciamos el servicio:

```
systemctl enable gunicorn-djangopolls.service

systemctl start gunicorn-djangopolls.service 
```

Si en algún momento cambiamos la configuración del fichero que acabamos de crear, debemos recargar el demonio:

```
systemctl daemon-reload
```

Ahora ya podemos crear el virtualhost en nginx para que sirva la aplicación:

```
nano /etc/nginx/sites-available/django_polls

server {
        listen 80;
        listen [::]:80;

        root /home/dparrales/django_tutorial;

        index index.html index.php index.htm index.nginx-debian.html;

        server_name djangopolls.sysadblog.com;

        location / {
                proxy_pass http://localhost:8000;
                include proxy_params;
        }

        location /static {
                alias /home/dparrales/venv/django/lib/python3.9/site-packages/django/contrib/admin/static;
        }
}
```

* **Nota:** Ese último alias es para que cargue el contenido estático de la zona de administración.

Creamos el enlace simbólico, reiniciamos el servicio de nginx e intentamos acceder a la aplicación:

```
ln -s /etc/nginx/sites-available/django_polls /etc/nginx/sites-enabled/django_polls

systemctl reload nginx
```

Debemos acordarnos de cambiar la línea de `allowed-hosts` en el fichero `settings.py`:

![allowed_host_produccion.png](/images/practica_despliegue_aplicaciones_python/allowed_host_produccion.png)

Ahora accedemos a la url que indicamos en el virtualhost (tras haber creado un nuevo registro CNAME en nuestro dns):

![pagina_principal.png](/images/practica_despliegue_aplicaciones_python/pagina_principal.png)

Si accedemos a la zona de administración, debería cargarnos el contenido estático gracias al alias que pusimos en el virtualhost:

![zona_admin.png](/images/practica_despliegue_aplicaciones_python/zona_admin.png)

Como vemos, ha cargado el contenido estático y hemos podido entrar con las credenciales que creamos anteriormente. Ahora solo tenemos que cambiar la línea de `DEBUG` a `FALSE` para finalizar con esta parte del ejercicio:

![debug.png](/images/practica_despliegue_aplicaciones_python/debug.png)

## Tarea 3: Modificación de nuestra aplicación

Vamos a realizar cambios en el entorno de desarrollo y posteriormente vamos a subirlas a producción. Vamos a realizar tres modificaciones, pero recuerda que primero lo haces en el entrono de desarrollo, y luego tendrás que llevar los cambios a producción:

* Modifica la página inicial donde se ven las encuestas para que aparezca tu nombre: Para ello modifica el archivo `django_tutorial/polls/templates/polls/index.html`.
* Modifica la imagen de fondo que se ve en la aplicación.

* Vamos a crear una nueva tabla en la base de datos, para ello sigue los siguientes pasos:

    * Añade un nuevo modelo al fichero polls/models.py:
```
          class Categoria(models.Model):	
          	Abr = models.CharField(max_length=4)
          	Nombre = models.CharField(max_length=50)

          	def __str__(self):
          		return self.Abr+" - "+self.Nombre 		
```
    * Crea una nueva migración.
    * Y realiza la migración.
    * Añade el nuevo modelo al sitio de administración de django:
      Para ello cambia la siguiente línea en el fichero polls/admin.py:
```
          from .models import Choice, Question
```
      Por esta otra:
```
          from .models import Choice, Question, Categoria
```
      Y añade al final la siguiente línea:
```
          admin.site.register(Categoria)
```
    *  Despliega el cambio producido al crear la nueva tabla en el entorno de producción.
----------------------------------------------------------

Los cambios se realizarán en desarrollo, para posteriormente subirlos a github y descargarlos en producción. Todo esto hay que hacerlo habiendo añadido al fichero `.gitignore` el fichero `settigs.py`, para no nos pise la configuración que hemos hecho cada vez que hagamos un `git pull`. Con esto dicho, vamos a empezar con lo que se nos ha pedido. Así pues, vamos a modificar el fichero `django_tutorial/polls/templates/polls/index.html` para que aparezca nuestro nombre:

```
nano django_tutorial/polls/templates/polls/index.html

{% load static %}

<link rel="stylesheet" type="text/css" href="{% static 'polls/style.css' %}">
Daniel Parrales Garcia
{% if latest_question_list %}
    <ul>
    {% for question in latest_question_list %}
    <li><a href="{% url 'polls:detail' question.id %}">{{ question.question_text }}</a></li>
    {% endfor %}
    </ul>
{% else %}
    <p>No polls are available.</p>
{% endif %}

```

Una vez hecho esto y probado que funciona, subimos el cambio a github y lo descargamos en el entorno de producción:

![minombre_polls.png](/images/practica_despliegue_aplicaciones_python/minombre_polls.png)

A continuación vamos a modificar la imagen de fondo de la página principal de la aplicación. Para ello hemos de modificar el siguiente fichero: `django_tutorial/polls/templates/index.html`. En este fichero modificamos la línea de la imagen:

![cambiarimagen.png](/images/practica_despliegue_aplicaciones_python/cambiarimagen.png)

Tras probar que funciona en el entorno de desarrollo, volvemos a subirlo a github y lo descargamos en producción:

![imagen_produccion.png](/images/practica_despliegue_aplicaciones_python/imagen_produccion.png)

Ya solo nos queda añadir una nueva tabla en la base de datos. Para ello, y siguiendo las instrucciones que se nos indican:

* Añadimos el modelo que nos han dado al fichero `polls/models.py`:

![cambiarmodelo.png](/images/practica_despliegue_aplicaciones_python/cambiarmodelo.png)

* Creamos una nueva migración:

![hacermigracion.png](/images/practica_despliegue_aplicaciones_python/hacermigracion.png)

* Realizamos la migración:

![migrado.png](/images/practica_despliegue_aplicaciones_python/migrado.png)

* Añadimos el nuevo modelo al sitio de administración de django (`polls/admin.py`) cambiando las líneas que se nos indica en las instrucciones:

![cambiaradmin.png](/images/practica_despliegue_aplicaciones_python/cambiaradmin.png)

* Tras comprobar que funciona en desarrollo, subimos el cambio a github y lo descargamos en producción (hay que recordar que en producción debemos volver a realizar la migración):

![nuevatabla.png](/images/practica_despliegue_aplicaciones_python/nuevatabla.png)

![categoria.png](/images/practica_despliegue_aplicaciones_python/categoria.png)

Con esto hemos finalizado con lo que se nos había pedido.
