+++ 
draft = true
date = 2021-10-26T20:06:50+02:00
title = "Modificación de un virtualhost con el fichero .htaccess"
description = "Modificación de un virtualhost con el fichero .htaccess"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Servicios de Red"]
externalLink = ""
series = []
+++

# Configuración de apache mediante archivo .htaccess

Date de alta en un proveedor de hosting. ¿Si necesitamos configurar el servidor web que han configurado los administradores del proveedor?, ¿qué podemos hacer? ¿Para qué sirve la directiva AllowOverride de apache2?. Utilizando archivos .htaccess realiza las siguientes configuraciones:

* Habilita el listado de ficheros en la URL `http://host.dominio/nas`.
* Crea una redirección permanente: cuando entremos en `http://host.dominio/google` salte a `www.google.es`.
* Pedir autentificación para entrar en la URL `http://host.dominio/prohibido`. (No la hagas si has elegido como proveedor CDMON, en la plataforma de prueba, no funciona.)

-----------------------------------------------------


En primer lugar, vamos a hacer una pequeña introducción sobre el fichero `.htaccess`. Este fichero se usa para modificar la configuración de un virtualhost sin tener que acceder al fichero de configuración directamente. Esto es útil cuando no tienes acceso al fichero de configuración debido a que no tienes privilegios de administrador en la página (como ocurren con los hosting que hay por internet). 

Hay que elegir bien el hosting que queremos usar, debido a que no todos tienen activada esta opción, o solo es accesible si pagas. Si quieres utilizar estos ficheros para modificar la configuración de un apache2 del que si tengas privilegios de administrador, primero debemos activar esa opción en el virtualhost o en el fichero `apache2.conf` usando la directiva `AllowOverride`.


## Habilita el listado de ficheros en la URL `http://host.dominio/nas`.

En mi caso, he elegido el hosting [000webhost](https://es.000webhost.com), ya que tenía una cuenta ahí de otro ejercicio anterior, y además, permite un fácil uso del fichero `.htaccess`. Cuando nos creamos una cuenta, podemos crear y modificar ficheros directamente desde el navegador web, lo que hace muy cómodo la edición de los ficheros y la configuración del virtualhost (en las siguientes imágenes se pueden ver más archivos, pero estos no son relevantes para el ejercicio, ya que son los que ya tenía subidos al hosting de otro ejercicio).

Una vez dado de alta en el servicio, entramos en el gestor de contenido de la web. Allí encontramos un fichero `.htaccess` que se ha creado por defecto. Como *000webhost* trae activado por defecto la opción `Indexes`, la vamos a desactivar en la carpeta principal de la web, ya que no nos interesa mostrar el contenido de esta carpeta:

![inicio.png](/images/htaccess/inicio.png)

![deshabilitar_indexes.png](/images/htaccess/deshabilitar_indexes.png)


Ahora creamos la carpeta `nas` en el directorio principal, y dentro de esta carpeta creamos otro fichero `.htaccess` y habilitamos la opción `Indexes` en este fichero:

![habilitar_indexes.png](/images/htaccess/habilitar_indexes.png)

Si ahora intentamos entrar en el directorio `/nas` desde el navegador, nos mostrará la lista de archivos:

![nas.png](/images/htaccess/nas.png)


## Crea una redirección permanente: cuando entremos en `http://host.dominio/google` salte a `www.google.es`.


Para lograr esto, simplemente tenemos que añadir la directiva de redirección en el fichero `.htaccess` del directorio principal:

![redireccion_google.png](/images/htaccess/redireccion_google.png)

Podemos ver la redirección en funcionamiento si utilizamos la herramienta del desarrollador web y vemos los paquetes que recibimos del servidor:

![cabeceras_redireccion_google.png](/images/htaccess/cabeceras_redireccion_google.png)


## Pedir autentificación para entrar en la URL `http://host.dominio/prohibido`.

Primero crearemos la carpeta `prohibido` y añadiremos un fichero `index.html` simple para verificar el funcionamiento. Mi fichero contiene la siguiente información:

```
<!DOCTYPE html>

<html>
    <head>
        <meta charset="utf-8">
        <title>Lo lograste amigo</title>
    </head>
    <body>
        <h2>No todo el mundo tiene acceso a este lugar. Debes de ser importante</h2>
    </body>
</html>
```

A continuación, vamos a crear el fichero con los usuarios y contraseñas que van a tener acceso al directorio. Para ello usamos el siguiente comando:

```
htpasswd -n danielp
New password: 
Re-type new password: 
danielp:$apr1$orQTJvKo$0JMl4WuNYAIi9rMXrLfzd/
```

Este comando nos devuelve por pantalla el usuario y la contraseña encriptada. Ahora podemos copiarlos e insertarlos en el fichero donde vamos a guardar los usuarios y contraseñas. Como no queremos que el hosting sirva este fichero, vamos a ubicarlo en el directorio raíz, ya que ese directorio no es servido:

![pass.png](/images/htaccess/pass.png)

Ahora, dentro del directorio `prohibido`, creamos un fichero `.htaccess` en el que configuraremos la autentificación básica:

![configuracion_autentificacion_basica.png](/images/htaccess/configuracion_autentificacion_basica.png)

*Nota:* Para averiguar la dirección de tu directorio raíz en 000webhost, basta con ir a los detalles de la página web. En los detalles nos aparecerá lo siguiente:

![directorio_raiz.png](/images/htaccess/directorio_raiz.png)

Ya podemos intentar acceder al directorio `/prohibido`, lo que nos devolverá lo siguiente:

![basica_hosting.png](/images/htaccess/basica_hosting.png)

Si introducimos las credenciales que hemos creado antes, podremos acceder a la página:

![acceso_000webhost.png](/images/htaccess/acceso_000webhost.png.png)

Con esto hemos acabado el ejercicio propuesto.
