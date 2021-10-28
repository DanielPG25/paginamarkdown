+++ 
draft = true
date = 2021-10-28T20:11:20+02:00
title = "Ejecución de PHP con PHP-FPM"
description = "Ejecución de PHP con PHP-FPM"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = []
externalLink = ""
series = []
+++

# Ejecución de PHP con PHP-FPM

El ejercicio tendrá los siguientes pasos:

* Desinstala el módulo de apache2 que permite la ejecución de PHP.
* Instala PHP-FPM.
* Configura apache2 para que utilice PHP-FPM para ejecutar PHP, lo puedes hacer para todos los virtualhost o en cada uno de los virtualhost.
* Comprueba accediendo a un fichero info.php, que los script PHP se estan ejecutando con PHP-FPM. Comprueba que los CMS instalados siguen funcionando.
* Cambia la configuración de PHP-FPM para que escuche en el puerto tcp/9000. Cambia la configuración de apache2 para que se comunique con PHP-FPM utilizando ese puerto.
* Comprueba que las aplicaciones siguen funcionando.
* Cambia la memoria máxima de uso de un script PHP (parámetro memory_limit) a 256Mb.

----------------------------------------------------------------------------------------

## Desinstala el módulo de apache2 que permite la ejecución de PHP.

Para ello podemos utilizar el siguiente comando:

`
apt remove libapache2-mod-php
`

Sin embargo, yo he optado por deshabilitar el módulo en apache, de forma que si más adelante lo necesito, pueda volver a activarlo sin problemas:

```
a2dismod php7.4

systemctl reload apache2
```


## Instala PHP-FPM.

Para instalar php-fpm basta con ejecutar lo siguiente:

`
apt install php7.4-fpm php7.4
`

Podemos comprobar que tras instalarlo, está ya operativo examinando la lista de procesos activos:

![procesos_php_fpm.png](/images/php_fpm/procesos_php_fpm.png)


## Configura apache2 para que utilice PHP-FPM para ejecutar PHP, lo puedes hacer para todos los virtualhost o en cada uno de los virtualhost.

Lo primero es activar los módulos que harán que apache2 funcione como un proxy inverso, pasando todos los ficheros `php` a `php-fpm` para que los ejecute:

`
a2enmod proxy_fcgi setenvif
`

A continuación, modificamos los virtualhost de cada cms, añadiendo las siguientes líneas:

* En el virtualhost de mediawiki:

`
ProxyPassMatch ^/(.*\.php)$ unix:/run/php/php7.4-fpm.sock|fcgi://127.0.0.1/var/www/www.dparrales-mediawiki.com
`

* En el virtualhost de opencart:

`
ProxyPassMatch ^/(.*\.php)$ unix:/run/php/php7.4-fpm.sock|fcgi://127.0.0.1/var/www/opencart
`


Si queremos que la configuración afecte a todos los virtualhost que tenemos configurados, tenemos que asegurarnos de sustituir en el fichero `/etc/apache2/conf-available/php7.4-fpm.conf` la siguiente línea:

![conf_global.png](/images/php_fpm/conf_global.png)

* Si queremos usar un socket TCP, la cambiamos por la siguiente línea:

`
SetHandler "proxy:fcgi://127.0.0.1:9000"
`

* Si queremos usar un socket UNIX, la cambiamos por la siguiente línea:

`
SetHandler "proxy:unix:/run/php/php7.4-fpm.sock|fcgi://localhost"
`

A continuación debemos activar la configuración (solo si queremos que la configuración afecte a todos los virtualhost) y reniniar el servicio:

```
a2enconf php7.4-fpm

systemctl reload apache2
```


## Comprueba accediendo a un fichero info.php, que los script PHP se estan ejecutando con PHP-FPM. Comprueba que los CMS instalados siguen funcionando.

El fichero `info.php` contiene la siguiente información:

```
<?php
phpinfo();
?>
```

Vamos a colocar el fichero en los DocumentRoot de nuestros cms, para ver si se están ejecutando con `php-fpm`:


![info_php.png](/images/php_fpm/info_php.png)


Como vemos, se está ejecutando con `php-fpm`. Ahora comprobemos que los cms siguen funcionando:


* Mediawiki:

![mediawiki_funcionando.png](/images/php_fpm/mediawiki_funcionando.png)

* Opencart:

![opencart_funcionando.png](/images/php_fpm/opencart_funcionando.png)


## Cambia la configuración de PHP-FPM para que escuche en el puerto tcp/9000. Cambia la configuración de apache2 para que se comunique con PHP-FPM utilizando ese puerto.

Para ello, primero debemos cambiar el fichero de configuración de `php-fpm`, ubicado en `/etc/php/7.4/fpm/pool.d/www.conf`. Tenemos que comentar la línea que viene por defecto, y añadir la siguiente:

![conf_phpfpm.png](/images/php_fpm/conf_phpfpm.png)

Reiniciamos el servicio tras cambiar la línea:

`
systemctl restart php7.4-fpm
`

Ahora cambiamos las líneas que añadimos antes en la configuración de los virtuahost por las siguientes:

* En mediawiki:

`
ProxyPassMatch ^/(.*\.php)$ fcgi://127.0.0.1:9000/var/www/www.dparrales-mediawiki.com/$1
`

* En opencart:

`
ProxyPassMatch ^/(.*\.php)$ fcgi://127.0.0.1:9000/var/www/opencart/$1
`

Reiniciamos el servicio:

`
systemctl reload apache2
`


## Comprueba que las aplicaciones siguen funcionando.

Podemos comprobarlo accediendo a las respectivas urls:

* Opencart:

![final_opencart.png](/images/php_fpm/final_opencart.png)


* Mediawiki:

![paginaprincipal_mediawiki.png](/images/php_fpm/paginaprincipal_mediawiki.png)


## Cambia la memoria máxima de uso de un script PHP (parámetro memory_limit) a 256Mb.

Para ello nos dirigimos al fichero que configura los parámetros de php al ejecutarse con `php-fpm` ubicado en `/etc/php/7.4/fpm/php.ini`, y modificamos la línea de `memory_limit`:

![memory_php.png](/images/php_fpm/memory_php.png)

Reiniciamos el servicio:

`
systemctl restart php7.4-fpm
`


Para comprobar si ha funcionado, nos vamos al fichero `info.php` que creamos antes:


![comprobacion_memoria.png](/images/php_fpm/comprobacion_memoria.png)


Como vemos, la configuración ha sido modificada correctamente.
