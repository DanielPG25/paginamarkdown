+++ 
draft = true
date = 2021-10-21T18:27:53+02:00
title = "Mapear URL a ubicaciones de un sistema de ficheros con Apache2"
description = "Mapear URL a ubicaciones de un sistema de ficheros con Apache2"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Servicios de Red"]
externalLink = ""
series = []
+++

# Mapear URL a ubicaciones de un sistema de ficheros

**Base:** Crea un nuevo host virtual que es accedido con el nombre `www.mapeo.com`, cuyo DocumentRoot sea /srv/mapeo.

En este ejercicio cumpliremos los siguientes objetivos:

* Cuando se entre a la dirección `www.mapeo.com` se redireccionará automáticamente a `www.mapeo.com/principal`, donde se mostrará el mensaje de bienvenida.
* En el directorio principal no se permite ver la lista de los ficheros, no se permite que se siga los enlaces simbólicos y no se permite negociación de contenido. ¿Qué configuración tienes que poner?
* Si accedes a la página `www.mapeo.com/principal/documentos` se visualizarán los documentos que hay en /home/usuario/doc. Por lo tanto se permitirá el listado de fichero y el seguimiento de enlaces simbólicos siempre que el propietario del enlace y del fichero al que apunta sean el mismo usuario.
* En todo el host virtual se debe redefinir los mensajes de error de objeto no encontrado y no permitido. Para el ello se crearan dos ficheros html dentro del directorio error. Entrega las modificaciones necesarias en la configuración y una comprobación del buen funcionamiento.

---------------------------------------------------------------------------------------------------------------------------------------------------------------


## Cuando se entre a la dirección `www.mapeo.com` se redireccionará automáticamente a `www.mapeo.com/principal`, donde se mostrará el mensaje de bienvenida.

Lo primero será instalar el servidor Apache2 si no lo tenemos ya instalado:

`
apt install apache2
`

Una vez instalado entramos en el directorio `/etc/apache2/sites-available` y creamos allí un nuevo virtualhost. En mi caso he copiado el contenido del virtualhost por defecto para no tener que escribir toda la configuración a mano:

`
cat 000-default.conf >> mapeo.conf
`

Una vez creado el fichero, lo modificamos de la siguiente forma:

```
<VirtualHost *:80>

        ServerName www.mapeo.com
        ServerAdmin webmaster@localhost
        DocumentRoot /srv/mapeo
        ErrorLog ${APACHE_LOG_DIR}/mapeo_error.log
        CustomLog ${APACHE_LOG_DIR}/mapeo_access.log combined
        RedirectMatch "^/$" "/principal"

</VirtualHost>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
```

También debemos modificar el fichero `/etc/apache2/apache2.conf`, cambiando o añadiendo la siguiente información:

```
<Directory /srv/>
        Options FollowSymLinks
        AllowOverride None
        Require all granted
</Directory>
```


Ahora debemos habilitar el virtualhost que hemos creado y reiniciar el servicio:

```
a2ensite mapeo.conf

systemctl reload apache2
```

Ya solo tenemos que cambiar el fichero `/etc/hosts` en la máquina desde la que queremos acceder a la web (cambiaremos la ip según la ip de la máquina servidora). Añadimos entonces la siguiente línea:

`
192.168.121.156 www.mapeo.com
` 

Con esto, ya podemos acceder desde nuestro navegador a `www.mapeo.com`, lo que nos redirigirá a `www.mapeo.com/principal`. Si abrimos la herramienta del desarrollador web podemos ver como funciona la redirección:

![redireccion.png](/images/mapearurl/redireccion.png)


## En el directorio principal no se permite ver la lista de los ficheros, no se permite que se siga los enlaces simbólicos y no se permite negociación de contenido. ¿Qué configuración tienes que poner?

Para lograr este objetivo, vamos a tener que modificar el fichero del virtual para eliminar las opciones que se nos piden:

```
<VirtualHost *:80>

        ServerName www.mapeo.com
        ServerAdmin webmaster@localhost
        DocumentRoot /srv/mapeo
        ErrorLog ${APACHE_LOG_DIR}/mapeo_error.log
        CustomLog ${APACHE_LOG_DIR}/mapeo_access.log combined
        RedirectMatch "^/$" "/principal"

        <Directory /srv/mapeo/principal>
                Options -Indexes -FollowSymLinks -MultiViews
        </Directory>



</VirtualHost>
```

Esta configuración estará activa solo para el directorio */srv/mapeo/principal* y sus hijos (a no ser que se indique lo contrario). Para probar si la configuración a funcionado vamos a crear un enlace simbólico y vamos a intentar acceder a él. Si la configuración a funcionado, debería salirnos un error 403 (acceso restringido).

Primero creamos un enlace simbólico a un archivo que he creado:

`
ln -s /home/vagrant/hola.txt enlacesim
`

Ahora probemos a entrar desde el navegador:


![enlacesimbolico_no.png](/images/mapearurl/enlacesimbolico_no.png)


Como vemos, tenemos el acceso restringido debido a la configuración que hemos añadido al virtualhost.


## Si accedes a la página `www.mapeo.com/principal/documentos` se visualizarán los documentos que hay en /home/usuario/doc. Por lo tanto se permitirá el listado de fichero y el seguimiento de enlaces simbólicos siempre que el propietario del enlace y del fichero al que apunta sean el mismo usuario.


Para lograr este objetivo, debemos modificar dos ficheros:

* Primero modificamos el fichero de nuestro virtualhost, y añadimos las siguientes línea para crear el alias:

```
Alias "/principal/documentos" "/home/usuario/doc/"
<Directory /home/usuario/>
        Options Indexes SymLinksIfOwnerMatch
        Require all granted
</Directory>
```

*Nota:* Antes de todo, hemos de crear el directorio */home/usuario/doc* y añadir algunos ficheros.

Ahora reiniciamos el servicio y ya podríamos acceder:

`
systemctl reload apache2
`

Antes de acceder, comprobemos lo que hay en el directorio */home/usuario/doc*:

```
ls -l /home/usuario/doc/
total 0
-rw-r--r-- 1 root root 0 Oct 20 17:00 1.txt
-rw-r--r-- 1 root root 0 Oct 20 17:00 2.txt
-rw-r--r-- 1 root root 0 Oct 20 17:00 3.txt
```

Vamos a ver lo que nos muestra la página:


![principal_documentos.png](/images/mapearurl/principal_documentos.png)


Como podemos ver, el alias ha funcionado correctamente.


## En todo el host virtual se debe redefinir los mensajes de error de objeto no encontrado y no permitido. Para el ello se crearan dos ficheros html dentro del directorio error. Entrega las modificaciones necesarias en la configuración y una comprobación del buen funcionamiento.


Lo primero es crear el directorio `error` dentro del DocumentRoot, en el cual almacenaremos los mensajes de error personalizados:

`
mkdir /srv/mapeo/error
`

A continuación, crearemos los ficheros *.html* que mostrarán los mensajes de error. Los he llamado *403.html* y *404.html*, y los he rellenado con la siguiente información:

```
cat 403.html 

<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Error 404</title>
  </head>
  <body>
    <h1>No tienes los permisos necesarios para ver lo que has buscado. No seas pillín</h1>
    <img src="/error/pillin.jpg" alt="403">
  </body>
</html>
```


```
cat 404.html 

<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Error 404</title>
  </head>
  <body>
    <h1>No hemos podido encontrar lo que estabas buscando. Sentimos las molestias </h1>
    <img src="/error/gomennasai.jpg" alt="404">
  </body>
</html>
```

Ahora solo tenemos que añadir las siguientes líneas al fichero del virtualhost:

```
ErrorDocument 404 /error/404.html
ErrorDocument 403 /error/403.html
```

Reiniciamos el servicio y listo:

`
systemctl reload apache2
`

Probemos ahora los mensajes a ver si funcionan:

* Error 403:

![nopermiso.png](/images/mapearurl/nopermiso.png)

* Error 404:

![noencontrado.png](/images/mapearurl/noencontrado.png)


Con esto hemos acabado el ejercicio. Como detalle final, vamos a ver como ha quedado configuración final del virtualhost:

```
cat mapeo.conf

<VirtualHost *:80>

        ServerName www.mapeo.com
        ServerAdmin webmaster@localhost
        DocumentRoot /srv/mapeo
        ErrorLog ${APACHE_LOG_DIR}/mapeo_error.log
        CustomLog ${APACHE_LOG_DIR}/mapeo_access.log combined

        ErrorDocument 404 /error/404.html
        ErrorDocument 403 /error/403.html

        Alias "/principal/documentos" "/home/usuario/doc/"
        <Directory /home/usuario/doc/>
                Options Indexes SymLinksIfOwnerMatch
                Require all granted
        </Directory>


        RedirectMatch "^/$" "/principal"
        <Directory /srv/mapeo/principal>
                Options -Indexes -FollowSymLinks -MultiViews
        </Directory>


</VirtualHost>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

```
