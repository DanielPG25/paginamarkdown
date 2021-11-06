+++ 
draft = true
date = 2021-11-06T20:39:03+01:00
title = "Migración de Centos 8 a Rocky Linux"
description = "Migración de Centos 8 a Rocky Linux"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Administración de Sistemas Operativos"]
externalLink = ""
series = []
+++

# Migración de Centos 8 a Rocky Linux

Debido a las últimas noticias sobre Centos 8, nos vemos obligados a tener que tomar un decisión con respecto al futuro de las máquinas que ahora mismo estén funcionando con Centos 8. Esta decisión será a que sistema operativo debemos migrar dichas máquinas. En este momento hay varias opciones de entre las que elegir: Rocky Linux, Alma Linux, Red Hat Enterprise Linux, Oracle Linux, etc. Es por ello que tenemos que sopesar los pros y los contras de las diferentes distribuciones, sabiendo siempre que, como ha pasado con Centos 8, es posible que la distribución que elijamos pierda su soporte en algún punto y tengamos que volver a cambiar más adelante.

Dicho todo lo anterior, he optado por hacer la migración de una máquina con el sistema Centos 8 a Rocky Linux. He optado por elegir este sistema debido a los siguientes motivos:

* Es una distribución basada en un fork de Centos, por lo que habrá muy pocas cosas que cambien entre Centos y Rocky, lo que facilitará la labor en las migraciones.
* Lo mantiene la misma comunidad que mantenía Centos, por lo que podemos esperar un nivel de apoyo similar del público.
* Cuenta con los repositorios oficiales de Centos, por lo que hay una baja probabilidad de que perdamos paquetes durante la migración.
* Rocky Linux se encuentra dirigido por Gregory Kurtzer, el fundador del proyecto Centos.
* Proporciona un script de migración, de forma que contamos con menos riesgo de error humano durante la migración.
* Está respalda por empresas y orgacinaciones importantes del sector, como pueden ser Amazon Web Service, Google Cloud, Microsoft Azure, Montavista, entre otros, por lo que podemos deducir que la vida de este sistema no será corta.

Con todo esto dicho, vamos a pasar a explicar el escenario del que disponemos:

Tenemos una máquina con Centos 8 instalado. En dicha máquina están instalados y funcionando los siguientes programas/paquetes:

* Servidor de ssh (openssh-server)
* Servidor web (nginx)
* Php-fpm
* Servidor de base de datos (mariadb-server) con tablas y usuarios creados
* Servidor de base de datos (postgresql)

También he creado tres usuruarios llamados prueba1, prueba2 y prueba3.

Con este escenario creado vamos a iniciar la migración de Centos 8 a Rocky Linux:

En primer lugar vamos a actualizar el sistema a la última versión:

```
dnf update -y

dnf upgrade -y
```

Una vez hecho esto reiniciamos el sistema:

```
reboot
```

Cuando hayamos reiniciado, descargamos el script de migración a Rocky Linux, llamado `migrate2rocky.sh`:

```
wget https://raw.githubusercontent.com/rocky-linux/rocky-tools/main/migrate2rocky/migrate2rocky.sh
```

Añadimos los permisos de ejecución a dicho script:

```
chmod +x migrate2rocky.sh
```

Empezamos la migración ejecutando el script:

```
./migrate2rocky.sh -r
```

![empezar_migracion.png](/images/migracion_centos8/empezar_migracion.png)

Usamos la opción `-r` en el script para indicarle que queremos que la migración tiene que ser a Rocky Linux. Tras esto el script analizará los repositorios y paquetes instalados, y los actualizará/modificará o instalará otros que sean necesarios para adaptarlos a Rocky Linux. Una vez que todos los paquetes necesarios hayan sido instalados/actualizados, el script nos pedirá que reiniciemos el sistema:

![script_completado.png](/images/migracion_centos8/script_completado.png)

Ahora cuando reiniciemos, ya vemos que podemos acceder a rocky:

![rocky.png](/images/migracion_centos8/rocky.png)

![comprobacion.png](/images/migracion_centos8/comprobacion.png)

Ahora miremos si los servicio mencionados anteriormente siguen funcionando:

* Servidor de ssh (openssh-server): Funciona perfectamente (de hecho estoy comprobando los servicios conectado por ssh).

![ssh_rocky.png](/images/migracion_centos8/ssh_rocky.png)

* Servidor web (nginx): Funciona perfectamente, mostrando la web de inicio.

![nginx_rocky.png](/images/migracion_centos8/nginx_rocky.png)

![pagina_nginx.png](/images/migracion_centos8/pagina_nginx.png)

* Php-fpm: También funciona perfectamente, mostrando el fichero `info.php` de forma adecuada:

![phpfpm_rocky.png](/images/migracion_centos8/phpfpm_rocky.png)

* Servidor de base de datos (mariadb-server) con tablas y usuarios creados: También funciona, conservando los datos de las tablas y usuarios que creamos anteriormente.

![mariadb_rocky.png](/images/migracion_centos8/mariadb_rocky.png)

![tablas_rocky.png](/images/migracion_centos8/tablas_rocky.png)

* Servidor de base de datos (postgresql): Sigue funcionando el servicio como es debido.

![postgresql_rocky.png](/images/migracion_centos8/postgresql_rocky.png)

Y los usuarios que creamos antes siguen ahí:

![usuarios_rocky.png](/images/migracion_centos8/usuarios_rocky.png)

Una vez que hemos comprobado que todos los servicios funcionan, podemos afirmar que la migración ha sido un éxito. Como hemos podido ver, la migración no ha sido difícil debido al script que nos proporciona Rocky, lo cual atraerá a mucha parte de la comunidad de servidores que en este momento está funcionando con Centos 8.

Como hemos mencionado antes, Rocky es una solución bastante plausible para realizar la migración desde Centos 8, pero solo el tiempo dirá si ha sido una buena o una mala decisión el haber realizado la migración a Rocky. En el peor de los casos, tendremos que volver a realizar la migración a otro sistema operativo, pero esperemos que a Rocky aún le quede bastante tiempo por delante.
