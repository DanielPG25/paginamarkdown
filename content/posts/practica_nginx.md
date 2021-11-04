+++ 
draft = true
date = 2021-11-04T11:08:45+01:00
title = "Instalación de un servidor LEMP en nuestra VPS"
description = "Instalación de un servidor LEMP en nuestra VPS"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Servicios de Red"]
externalLink = ""
series = []
+++

# Instalación de un servidor LEMP en nuestra VPS

## Instalación

Vamos a tener los siguientes pasos:

* Instala un servidor web nginx
* Instala un servidor de base de datos MariaDB. Ejecuta el programa necesario para asegurar el servicio, ya que lo vamos a tener corriendo en el entorno de producción.
* Instala un servidor de aplicaciones PHP-FPM.

------------------------------------------------------------------------------------

Vamos entonces a instalar nginx:

```
apt update && apt install nginx
```

Ahora instalamos mariadb y lo securizamos con su script:

```
apt install mariadb-server

mysql_secure_installation
```

Por último, instalamos un servidor de aplicaciones PHP-FPM:

```
apt install php7.4-fpm php7.4
```

## VirtualHosting

Los pasos de este punto son los siguientes:

* Crea un virtualhost al que vamos acceder con el nombre `www.tudominio.algo` Recuerda que tendrás que crear un registro CNAME en la zona DNS.
* Cuando se acceda al virtualhost por defecto default nos tiene que redirigir al virtualhost que hemos creado en el punto anterior.

------------------------------------------------------------------------------------------------------

Así pues, vamos a crear el registro cname en nuestra zona dns:

![dns_cname.png](/images/practica_nginx/dns_cname.png)

Ahora tenemos que crear el virtualhost al que accederemos con nuestro dominio. Para ello nos vamos al directorio `/etc/nginx/sites-available` y creamos allí un virtualhost, al que he llamado `sysadblog`. Este virtualhost tendrá la siguiente configuración:

```
server {
        listen 80;
        listen [::]:80;

        root /var/www/sysadblog;

        index index.html index.htm index.nginx-debian.html;

        server_name www.sysadblog.com;

        location / {
                try_files $uri $uri/ =404;
        }

}
```

Ahora debemos cambiar el virtualhost por defecto para que redireccione al nuevo que hemos creado. Para ello, añadimos la siguiente línea al bloque de `server` del virtualhost `default`:

```
rewrite ^/$ http://www.sysadblog.com permanent;
```

Ya simplemente tenemos que crear el enlace simbólico al nuevo virtualhost que hemos creado y reiniciar el servicio:

```
ln -s /etc/nginx/sites-available/sysadblog /etc/nginx/sites-enabled/

systemctl reload nginx
```

Con esto, si accedemos a la url `www.sysadblog.com` nos saldrá el mensaje de entrada que hemos puesto en el DocumentRoot:


![primer_acceso.png](/images/practica_nginx/primer_acceso.png)


También podemos comprobar que funciona la redirección si intentamos entrar en la web usando la ip de mi máquina:


![redireccion_inicial.png](/images/practica_nginx/redireccion_inicial.png)


## Mapeo de URL

Los objetivos de este apartado serán los siguientes:


* Cuando se acceda a `www.tudominio.algo` se nos redigirá a la página `www.tudominio.algo/principal`. En el directorio principal no se permite ver la lista de los ficheros y no se permite que se siga los enlaces simbólicos.
* En la página `www.tudominio.algo/principal` se debe mostrar una página web estática (utiliza alguna plantilla para que tenga hoja de estilo o la página estática que has generado en IAW). En esta página debe aparecer tu nombre, y una lista de enlaces a las aplicaciones que vamos a ir desplegando posteriormente.
* Si accedes a la página `www.tudominio.algo/principal/documentos` se visualizarán los documentos que hay en /srv/doc. Por lo tanto se permitirá el listado de fichero y el seguimiento de enlaces simbólicos.
* En todo el host virtual se debe redefinir los mensajes de error de objeto no encontrado y no permitido. Para el ello se crearan dos ficheros html dentro del directorio error.

--------------------------------------------------------------------------------------

En primer lugar, vamos a crear la redirección. Para ello vamos a añadir la siguiente línea al fichero de configuración de nuestro virtualhost:

`
rewrite ^/$ http://www.sysadblog.com/principal permanent;
`

Ahora vamos a añadir las opciones necesarias para que no se vea la lista de contenidos ni se sigan los enlaces simbólicos:

```
location /principal {
    autoindex off;
    disable_symlinks on;
}
```

Tenemos que recordar reiniciar el servicio cada vez que hagamos algún cambio en la configuración:

`
systemctl restart nginx
`


Con esto ya podemos acceder a la página a través de la url anterior y nos redirigirá al nuevo enlace:


![redireccion_principal.png](/images/practica_nginx/redireccion_principal.png)


Podemos comprobar que si quitamos el fichero index.html, no se nos muestra la lista de archivos:


![prohibicion_principal.png](/images/practica_nginx/prohibicion_principal.png)



Ahora vamos a poner bonita nuestra página web. Para ello buscamos una plantilla gratuita (hay muchas en Internet). Una vez que hayamos elegido una, la ponemos en nuestro DocumentRoot y la modificamos a nuestro gusto:


![pagina_estatica.png](/images/practica_nginx/pagina_estatica.png)


A continuación vamos a crear un alias en nuestro virtualhost para que cada vez que se acceda a `www.sysadblog.com/principal/documentos`, se nos muestre lo que haya en el directorio `/srv/doc`. En este directorio se permitirá el listado de ficheros y el seguimiento de enlaces simbólicos. Para ello, añadimos a nuestro virtualhost lo siguiente:

```
location /principal/documentos {
        alias /srv/doc;
        autoindex on;
        disable_symlinks off;           
}
```

Reiniciamos el servicio y probamos si funciona:

`
systemctl reload nginx
`

![enlace_simbolico.png](/images/practica_nginx/enlace_simbolico.png)


![comprobar_alias.png](/images/practica_nginx/comprobar_alias.png)


![texto_tres.png](/images/practica_nginx/texto_tres.png)


Como vemos, la configuración que hemos añadido funciona perfectamente. Ya solo queda cambiar los mensajes de error en el virtualhost. Para ello, vamos a añadir las siguientes líneas a la configuración del virtualhost:


```
error_page 404 /error/404.html;
error_page 403 /error/403.html;
```

Probemos ahora los nuevos mensajes de error:


![404.png](/images/practica_nginx/404.png)


![403.png](/images/practica_nginx/403.png)


Los mensajes funcionan perfectamente, por lo que hemos terminado con este apartado.


## Autentificación

El objetivo de este apartado será el siguiente:

* Autentificación básica. Limita el acceso a la URL `www.tudominio.algo/secreto`.

---------------------------------------------------

Para poder usar la autentificación básica con nginx, debemos descargar primero el siguiente paquete:

`
apt install apache2-utils
`

Una vez instalado, pasamos a crear `htpasswd` con el usuario que usaremos para la autentificación:

`
htpasswd -c /etc/apache2/.htpasswd usuario1
`

Ahora modificamos la configuración del virtualhost para que utilice la autentificación básica:

```
location /secreto {
        auth_basic           “Área secreta”;
        auth_basic_user_file /etc/apache2/.htpasswd;
}
```

Reiniamos el servicio y probamos si funciona:

`
systemctl restart nginx
`


![area_secreta.png](/images/practica_nginx/area_secreta.png)

![secreto.png](/images/practica_nginx/secreto.png)


Como vemos, la configuración de la autentificación básica ha funcionado. Pasemos entonces al siguiente punto:


## PHP

Este apartado tendrá los siguientes objetivos:

* Configura el nuevo virtualhost, para que pueda ejecutar PHP. Determina que configuración tiene por defecto php-fpm (socket unix o socket TCP) para configurar nginx de forma adecuada.
* Crea un fichero info.php que demuestre que está funcionando el servidor LEMP.

-----------------------------------------------------------------------------

Podemos ver la configuración que tiene por defecto php-fpm si vemos el fichero `/etc/php/7.4/fpm/pool.d/www.conf`. En ese fichero nos encontramos la siguiente línea:

![php-fpm.png](/images/practica_nginx/php-fpm.png)

Esa línea nos indica que está configurado para usar socket unix, por lo que configuraremos el virtualhost para que use ese mismo socket:

```
location ~ \.php$ {
       include snippets/fastcgi-php.conf;
       fastcgi_pass unix:/run/php/php7.4-fpm.sock;
}
```

Reiniciamos el servicio y lo probamos creando un fichero `info.php`:

`
systemctl restart nginx
`

![info-php.png](/images/practica_nginx/info-php.png)


Como podemos ver, ha cargado el fichero `info.php`, por lo que hemos comprobado que puede ejecutar php usando php-fpm.


## Ansible

En este apartado vamos a relizar lo siguiente:

* Realiza la configuración básica de nginx creando una receta ansible. Utilizando como base la receta ansible que utilizaste para el [ejercicio 6](https://fp.josedomingo.org/sri2122/u03/doc/ejercicio_proxy/ejercicio_proxy.zip), modifícala para añadir las siguientes funcionalidades:

    * Instalación de los servicios. (Cada servicio se instalará y configurará en un rol diferenciado)
    * Como hace la receta original, creará virtualhost que tengas definido en una lista. Estos virtual host estarán configurados para ejecutar PHP.
    * La receta debe poder desactivar los virtualhost que tengas definido en una lista.
    * Como la receta tiene que ser lo más general posible, si quieres hacer algo más de la práctica, añade las tareas a un rol llamado practica.

----------------------------------------------------------------------

La receta de ansible se encuentra en mi [github](https://github.com/DanielPG25/Ansible_nginx)


----------------------------------------------------------------------

Como dato final, pongo la configuración de mi virtualhost de nginx después de todos los cambios realizados en la práctica:


```
server {
        listen 80;
        listen [::]:80;

        root /var/www/sysadblog;

        index index.html index.htm index.nginx-debian.html;

        server_name www.sysadblog.com;

        rewrite ^/$ http://www.sysadblog.com/principal permanent;
        location /principal {
                autoindex off;
                disable_symlinks on;
        }

        location /principal/documentos {
                alias /srv/doc;
                autoindex on;
                disable_symlinks off;           
        }
        
        location /secreto {
                auth_basic "Area secreta";
                auth_basic_user_file /etc/apache2/.htpasswd;
        }

        location ~ \.php$ {
               include snippets/fastcgi-php.conf;
               fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        }


        error_page 404 /error/404.html;
        error_page 403 /error/403.html;


        location / {
                try_files $uri $uri/ =404;
        }
}
```
