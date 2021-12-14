+++ 
draft = true
date = 2021-12-14T20:01:34+01:00
title = "Aumento de rendimiento en servidores web"
description = "Aumento de rendimiento en servidores web"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Servicios de Red"]
externalLink = ""
series = []
+++

# Aumento de rendimiento en servidores web

## HAProxy: Balanceador de carga

### Crea y configura el escenario usando el repositorio [vagrant_ansible_haproxy](https://github.com/josedom24/vagrant_ansible_haproxy).

Para ello simplemente clonamos el repositorio en nuestra máquina y levantamos el escenario con vagrant:

```
git clone https://github.com/josedom24/vagrant_ansible_haproxy.git

cd vagrant_ansible_haproxy

vagrant up
```

Una vez que hemos levantado el escenario, comprobamos las direcciones ip que se han asignado a nuestras máquinas y modificamos el ansible para añadir dichas direcciones:

```
cd ansible

nano hosts

[servidor_ha]
frontend ansible_ssh_host=192.168.121.241 ansible_ssh_user=vagrant ansible_ssh_private_key_file=../.vagrant/machines/frontend/libvirt/private_key ansible_python_interpreter=/usr/bin/python3

[servidores_web]
backend1 ansible_ssh_host=192.168.121.114 ansible_ssh_user=vagrant ansible_ssh_private_key_file=../.vagrant/machines/backend1/libvirt/private_key ansible_python_interpreter=/usr/bin/python3
backend2 ansible_ssh_host=192.168.121.19 ansible_ssh_user=vagrant ansible_ssh_private_key_file=../.vagrant/machines/backend2/libvirt/private_key ansible_python_interpreter=/usr/bin/python3
```

Una vez hecho esto ya podemos ejecutar el ansible:

```
ansible-playbook site.yaml 

PLAY [all] *************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************
ok: [frontend]
ok: [backend2]
ok: [backend1]

TASK [commons : Ensure system is updated] ******************************************************************************
changed: [frontend]
changed: [backend2]
changed: [backend1]

PLAY [servidor_ha] *****************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************
ok: [frontend]

TASK [haproxy : install haproxy] ***************************************************************************************
changed: [frontend]

PLAY [servidores_web] **************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************
ok: [backend1]
ok: [backend2]

TASK [nginx : install nginx, php-fpm] **********************************************************************************
changed: [backend1]
changed: [backend2]

TASK [nginx : Copy info.php] *******************************************************************************************
changed: [backend1]
changed: [backend2]

TASK [nginx : Copy virtualhost default] ********************************************************************************
changed: [backend1]
changed: [backend2]

RUNNING HANDLER [nginx : restart nginx] ********************************************************************************
changed: [backend2]
changed: [backend1]

PLAY [servidores_web] **************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************
ok: [backend1]
ok: [backend2]

TASK [mariadb : ensure mariadb is installed] ***************************************************************************
changed: [backend1]
changed: [backend2]

TASK [mariadb : ensure mariadb binds to internal interface] ************************************************************
changed: [backend1]
changed: [backend2]

RUNNING HANDLER [mariadb : restart mariadb] ****************************************************************************
changed: [backend1]
changed: [backend2]

PLAY [servidores_web] **************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************
ok: [backend1]
ok: [backend2]

TASK [wordpress : install unzip] ***************************************************************************************
changed: [backend1]
changed: [backend2]

TASK [wordpress : download wordpress] **********************************************************************************
changed: [backend1]
changed: [backend2]

TASK [wordpress : unzip wordpress] *************************************************************************************
changed: [backend1]
changed: [backend2]

TASK [wordpress : Copy wordpress.sql] **********************************************************************************
changed: [backend1]
changed: [backend2]

TASK [wordpress : create database wordpress] ***************************************************************************
changed: [backend1]
changed: [backend2]

TASK [wordpress : create user mysql wordpress] *************************************************************************
changed: [backend1] => (item=localhost)
changed: [backend2] => (item=localhost)

TASK [wordpress : copy wp-config.php] **********************************************************************************
changed: [backend1]
changed: [backend2]

RUNNING HANDLER [wordpress : restart nginx] ****************************************************************************
changed: [backend1]
changed: [backend2]

PLAY RECAP *************************************************************************************************************
backend1                   : ok=20   changed=16   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
backend2                   : ok=20   changed=16   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
frontend                   : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 
```

Con esto ya está terminada la configuración inicial del escenario.

### Configura la resolución estática y accede a wordpress.

El escenario te instala el balanceador de carga HAProxy, pero lo hace sin configurar. Así pues, lo primero será configurarlo:

```
/etc/haproxy/haproxy.cfg

frontend servidores_web
	bind *:80 
	mode http
	stats enable
	stats uri /ha_stats
	stats auth  cda:cda
	default_backend servidores_web_backend

backend servidores_web_backend
	mode http
	balance roundrobin
	server backend1 10.0.0.10:80 check
	server backend2 10.0.0.11:80 check
```

Reiniciamos el servicio para aplicar los cambios:

```
systemctl restart haproxy
```

Y modificamos la resolución estática del anfitrión para que `www.example.org/wordpress/` coincida con la ip pública del frontend:

```
nano /etc/hosts

192.168.121.241 www.example.org
```

Ahora ya podemos acceder a wordpress:

![acceso_wordpress1.png](/images/practica_aumento_rendimiento_servidores_web/acceso_wordpress1.png)

### Vamos a calcular el rendimiento con el balanceo de carga a dos nodos. Para ello haz varias pruebas y quédate con la media de peticiones/segundo (`ab -t 10 -c 100 -k http://www.example.org/wordpress/`):

Para ello, tenemos que instalarnos si no lo está ya el paquete `apache2-utils`:

```
apt install apache2-utils
```

Ahora ejecutamos el comando que nos indican en el enunciado para ver las peticiones por segundo que es capaz de responder el servidor:

```
ab -t 10 -c 100 -k http://www.example.org/wordpress/
This is ApacheBench, Version 2.3 <$Revision: 1879490 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking www.example.org (be patient)
Finished 1319 requests


Server Software:        nginx/1.18.0
Server Hostname:        www.example.org
Server Port:            80

Document Path:          /wordpress/
Document Length:        11421 bytes

Concurrency Level:      100
Time taken for tests:   10.002 seconds
Complete requests:      1319
Failed requests:        0
Total transferred:      15365031 bytes
HTML transferred:       15064299 bytes
Requests per second:    131.87 [#/sec] (mean)
Time per request:       758.333 [ms] (mean)
Time per request:       7.583 [ms] (mean, across all concurrent requests)
Transfer rate:          1500.13 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.4      0       2
Processing:    38  726 116.5    751     851
Waiting:       35  723 116.1    748     846
Total:         40  726 116.2    751     851

Percentage of the requests served within a certain time (ms)
  50%    751
  66%    760
  75%    768
  80%    773
  90%    787
  95%    800
  98%    816
  99%    824
 100%    851 (longest request)
```

Como vemos, en esta primera prueba, fue capaz de responder 131 peticiones por segundo. Pero esto solo no es bastante para hacernos una idea de las peticiones que puede responder. Así pues, volveremos a ejecutar este comando un total de 5 veces y calcularemos la media con diferentes niveles de concurrencia:

* Con una concurrencia de 100: Hemos obtenido 131,132,133,132,132 peticiones por segundo, haciendo esto una media de 132 peticiones por segundo.
* Con una concurrencia de 500: Hemos obtenido 131,129,131,130,130 peticiones por segundo, haciendo esto una media de 130,2 peticiones por segundo.
* Con una concurrencia de 1000: Hemos obtenido 4161,4199,4240,4257,4329 peticiones por segundo, haciendo esto una media de 4237,2 peticiones por segundo (pero empieza a fallar muchas peticiones).

### Accede con hatop y deshabilita un nodo. Vuelve a hacer las pruebas de rendimiento. ¿Se nota la diferencia entre balancear y no balancear?. (Al terminar este ejercicio habilita de nuevo el nodo).

Lo primero es instalarnos la herramienta en el frontend:

```
apt install hatop
```

Después lo conectamos a un socket unix donde escucha HAProxy:

```
hatop -s /run/haproxy/admin.sock
```

Esto nos muestra la siguiente ventana:

![hatop_1.png](/images/practica_aumento_rendimiento_servidores_web/hatop_1.png)

Si nos situamos sobre un nodo del backend y pulsamos F10 lo desactivamos. Ahora volveremos a realizar las pruebas de antes:

* Con una concurrencia de 100: Hemos obtenido 76,77,77,76,77 peticiones por segundo, haciendo esto una media de 76,6 peticiones por segundo.
* Con una concurrencia de 500: Hemos obtenido 4657,4700,4708,4767,4539 peticiones por segundo, haciendo esto una media de 4674,2 peticiones por segundo (empieza a fallar más del 90% de peticiones).
* Con una concurrencia de 1000: Hemos obtenido 4934,4952,4895,4705,4860 peticiones por segundo, haciendo esto una media de 4237,2 peticiones por segundo (empieza a fallar más del 90% de peticiones).

Para volver activar el nodo entramos en la interfaz de antes y pulsamos F9 sobre el nodo.

### Modifica el vagrant y el ansible e introduce un nuevo nodo backend3 donde se instalale wordpress. Modifica la configuración de HAProxy para que balancee entre los tres nodos. Vuelve a hacer las pruebas de rendimiento. ¿Se nota la diferencia entre balancear a dos nodos o a tres?

En primer lugar añadimos lo siguiente al Vagrantfile:

```
config.vm.define :backend2 do |backend2|
      backend2.vm.box = "debian/bullseye64"
      backend2.vm.hostname = "backend2"
      backend2.vm.synced_folder ".", "/vagrant", disabled: true
      backend2.vm.network :private_network,
        :libvirt__network_name => "red1",
        :libvirt__dhcp_enabled => false,
        :ip => "10.0.0.11",
        :libvirt__forward_mode => "veryisolated"
    end
```

Para modificar el ansible, añadimos al fichero `hosts` lo siguiente:

```
backend3 ansible_ssh_host=192.168.121.4 ansible_ssh_user=vagrant ansible_ssh_private_key_file=../.vagrant/machines/backend3/libvirt/private_key ansible_python_interpreter=/usr/bin/python3
```

Y volvemos a pasar el ansible:

```
ansible-playbook site.yaml
```

Ahora entramos en la configuración de HAProxy en el frontend y añadimos el nuevo nodo:

```
frontend servidores_web
        bind *:80
        mode http
        stats enable
        stats uri /ha_stats
        stats auth  cda:cda
        default_backend servidores_web_backend

backend servidores_web_backend
        mode http
        balance roundrobin
        server backend1 192.168.121.114:80 check
        server backend2 192.168.121.19:80 check
        server backend3 192.168.121.4:80 check
```

Y reiniciamos el servicio para aplicar los cambios:

```
systemctl restart haproxy
```

Ahora volvemos a realizar las pruebas anteriores:

* Con una concurrencia de 100: Hemos obtenido 171,177,177,176,176 peticiones por segundo, haciendo esto una media de 175,4 peticiones por segundo.
* Con una concurrencia de 500: Hemos obtenido 175,176,176,176,175 peticiones por segundo, haciendo esto una media de 175,6 peticiones por segundo.
* Con una concurrencia de 1000: Hemos obtenido 176,177,177,177,177 peticiones por segundo, haciendo esto una media de 176,8 peticiones por segundo. (Hemos observado un aumento del uso de la CPU al 100%, así que esta puede ser la razón del cuello de botella).

Como hemos podido ver, la diferencia entre balancear dos nodos y tres son una media de 40 peticiones por segundos, pero nos aseguramos de que todas las peticiones que llegan son respondidas. Si dispusiéramos de máquinas con más recursos, podríamos alcanzar valores más altos.

## Memcached

Vamos a utilizar el repositorio [vagrant_ansible_wordpress](https://github.com/josedom24/vagrant_ansible_wordpress) que te crea un servidor servidorweb con wordpress instalado. Para acceder a la zona de adminsitarción (admin/admin). Para acceder al Wordpress usamos la url `http://www.example.org/wordpress/`.

Para realizar este ejercicio puedes basarte en el artículo [Optimizar WordPress con Memcached](https://www.rjcardenas.com/optimizar-wordpress-con-memcached/).

### Instala memcached en el servidor. Comprueba con un info.php que está instalado.

Lo primero es montar el escenario. Para empezar, clonamos el repositorio:

```
git clone https://github.com/josedom24/vagrant_ansible_wordpress.git
```

Ahora usamos levantamos las máquinas con vagrant:

```
cd vagrant_ansible_wordpress

vagrant up
```

Modificamos la configuración de ansible para que se adapte a la nueva ip:

```
cd ansible

nano hosts

servidor_web ansible_ssh_host=192.168.121.149 ansible_ssh_user=vagrant ansible_ssh_private_key_file=../.vagrant/machines/default/libvirt/private_key ansible_python_interpreter=/usr/bin/python3
```

Ahora ya podemos configurar el escenario usando ansible:

```
ansible-playbook site.yaml 

PLAY [all] *************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************
ok: [servidor_web]

TASK [commons : Ensure system is updated] ******************************************************************************
changed: [servidor_web]

PLAY [servidores_web] **************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************
ok: [servidor_web]

TASK [nginx : install nginx, php-fpm] **********************************************************************************
changed: [servidor_web]

TASK [nginx : Copy info.php] *******************************************************************************************
changed: [servidor_web]

TASK [nginx : Copy virtualhost default] ********************************************************************************
changed: [servidor_web]

RUNNING HANDLER [nginx : restart nginx] ********************************************************************************
changed: [servidor_web]

PLAY [servidores_web] **************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************
ok: [servidor_web]

TASK [mariadb : ensure mariadb is installed] ***************************************************************************
changed: [servidor_web]

TASK [mariadb : ensure mariadb binds to internal interface] ************************************************************
changed: [servidor_web]

RUNNING HANDLER [mariadb : restart mariadb] ****************************************************************************
changed: [servidor_web]

PLAY [servidores_web] **************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************
ok: [servidor_web]

TASK [wordpress : install unzip] ***************************************************************************************
changed: [servidor_web]

TASK [wordpress : download wordpress] **********************************************************************************
changed: [servidor_web]

TASK [wordpress : unzip wordpress] *************************************************************************************
changed: [servidor_web]

TASK [wordpress : Copy wordpress.sql] **********************************************************************************
changed: [servidor_web]

TASK [wordpress : create database wordpress] ***************************************************************************
changed: [servidor_web]

TASK [wordpress : create user mysql wordpress] *************************************************************************
changed: [servidor_web] => (item=localhost)

TASK [wordpress : copy wp-config.php] **********************************************************************************
changed: [servidor_web]

RUNNING HANDLER [wordpress : restart nginx] ****************************************************************************
changed: [servidor_web]

PLAY RECAP *************************************************************************************************************
servidor_web               : ok=20   changed=16   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 
```

Ahora, con el escenario montado, podemos instalar memcached:

```
apt install php-memcached memcached
```

Comprobemos que se ha instalado observando el fichero `info.php` a través del navegador:

![info_php.png](/images/practica_aumento_rendimiento_servidores_web/info_php.png)

Como vemos, se ha instalado y habilitado correctamente.

### Configura en wordpress un plugin que le permita trabajar con memcached.

El plugin que vamos a instalar en wordpress es WP-FFPC. Para ello nos tenemos que ir a la zona de administración de wordpress (`http://www.example.org/wordpress/wp-admin`) y entramos con las credenciales admin/admin. Aquí nos vamos a la sección de plugins e instalamos WP-FFPC:

![wp_plugin.png](/images/practica_aumento_rendimiento_servidores_web/wp_plugin.png)

Cuando lo activemos (desde la misma página), nos aparecerán los siguientes mensajes:

![wp_plugin2.png](/images/practica_aumento_rendimiento_servidores_web/wp_plugin2.png)

Para solucionarlos tendremos que realizar las siguientes configuraciones:

* En primer lugar añadimos lo siguiente a `/var/www/html/wordpress/wp-config.php`:

```
nano /var/www/html/wordpress/wp-config.php

define('WP_CACHE', true);
```

* Modificamos las opciones de memcached a nuestro gusto en los ajustes que aparecen en la web y guardamos los cambios (guardar los cambios es necesario aunque no cambiemos nada, ya que memcached no está configurado desde el principio):

![wp_plugin3.png](/images/practica_aumento_rendimiento_servidores_web/wp_plugin3.png)

Con esto ya hemos terminado de configurar el plugin y estamos listo para realizar las pruebas.

### Realiza el calculo de rendimiento. Para ello haz varias pruebas y quédate con la media de peticiones/segundo (`ab -t 10 -c 100 -k http://www.example.org/wordpress/`) ¿Se ha aumentado el rendimiento de forma significativa?

Al igual que el con el apartado anterior, haremos cinco pruebas cada vez con mayor concurrencia y calcularemos la media:

* Con una concurrencia de 100: Hemos obtenido 1224,1215,1233,1233,1212 peticiones por segundo, haciendo esto una media de 1223,4 peticiones por segundo.
* Con una concurrencia de 300: Hemos obtenido 1225,1169,1214,1228,1241 peticiones por segundo, haciendo esto una media de 1215,4 peticiones por segundo.

Como vemos se ha estabilizado la media en torno a las 1220 peticiones por segundo. Aunque aumentemos más la concurrencia, el número no aumentará, ya que hemos llegado al límite de hardware que ofrece la máquina (se satura la cpu). Nos damos cuenta de que el número de peticiones que es capaz de responder por segundo ha aumentado considerablemente con respecto a HAProxy (unas diez veces más), además de responder todas las peticiones que le llegan.

## Varnish

Utiliza el mismo repositorio para crear un servidor con wordpress. Siguiendo la [introducción a varnish](https://fp.josedomingo.org/sri2122/u06/varnish.html) realiza los siguientes pasos:

### Configura un proxy inverso - caché Varnish escuchando en el puerto 80 y que se comunica con el servidor web por el puerto 8080. Entrega y muestra una comprobación de que varnish está funcionando con la nueva configuración.

Usaremos el mismo repositorio que usamos en el apartado anterior, así que he eliminado la máquina que tenía y la he vuelto a levantar para poder empezar desde cero. Al igual que antes, usaremos vagrant y ansible para levantar el escenario, así que no me voy a parar a explicar todos los pasos.

Una vez que tenemos el escenario montado, podemos instalar varnish:

```
apt install varnish
```

Como vamos a configurar varnish en el puerto 80, tenemos que modificar el virtualhost de nginx para que deje de escuchar por ese puerto:

```
/etc/nginx/sites-available/default

listen 8080 default_server;
listen [::]:8080 default_server;
```

Reiniciamos el servicio para aplicar los cambios:

```
systemctl reload nginx
```

Ahora configuremos varnish para que escuche en el puerto 80:

```
nano /etc/default/varnish

DAEMON_OPTS="-a :80 \
             -T localhost:6082 \
             -f /etc/varnish/default.vcl \
             -S /etc/varnish/secret \
             -s malloc,256m"
```

Podemos comprobar que redirige las peticiones al puerto 8080 (en el cual está escuchando nginx):

```
cat /etc/varnish/default.vcl

backend default {
    .host = "127.0.0.1";
    .port = "8080";
}
```

Cambiaremos también la unidad systemd para que arranque varnish en el puerto 80:

```
nano /lib/systemd/system/varnish.service

ExecStart=/usr/sbin/varnishd \
          -j unix,user=vcache \
          -F \
          -a :80 \
          -T localhost:6082 \
          -f /etc/varnish/default.vcl \
          -S /etc/varnish/secret \
          -s malloc,256m
```

Como hemos modificado una unidad systemd, tenemos que reiniciar el demonio:

```
systemctl daemon-reload

systemctl restart varnish
```

Ahora podemos comprobar que se encuentra escuchando peticiones en el puerto 80:

```
netstat -tlnp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:3306            0.0.0.0:*               LISTEN      11734/mariadbd      
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      16804/varnishd      
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN      12220/nginx: master 
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      520/sshd: /usr/sbin 
tcp        0      0 127.0.0.1:6082          0.0.0.0:*               LISTEN      16804/varnishd      
tcp6       0      0 :::80                   :::*                    LISTEN      16804/varnishd      
tcp6       0      0 :::8080                 :::*                    LISTEN      12220/nginx: master 
tcp6       0      0 :::22                   :::*                    LISTEN      520/sshd: /usr/sbin 
tcp6       0      0 ::1:6082                :::*                    LISTEN      16804/varnishd  
```

También podemos ver el servicio de varnish ejecutándose con la nueva configuración:

```
systemctl status varnish

● varnish.service - Varnish Cache, a high-performance HTTP accelerator
     Loaded: loaded (/lib/systemd/system/varnish.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2021-12-14 18:37:55 UTC; 3min 2s ago
       Docs: https://www.varnish-cache.org/docs/
             man:varnishd
   Main PID: 16804 (varnishd)
      Tasks: 217 (limit: 528)
     Memory: 98.4M
        CPU: 305ms
     CGroup: /system.slice/varnish.service
             ├─16804 /usr/sbin/varnishd -j unix,user=vcache -F -a :80 -T localhost:6082 -f /etc/varnish/default.vcl -S /etc/varnish/secret -s malloc,256m
             └─16816 /usr/sbin/varnishd -j unix,user=vcache -F -a :80 -T localhost:6082 -f /etc/varnish/default.vcl -S /etc/varnish/secret -s malloc,256m

Dec 14 18:37:55 servidorweb varnishd[16804]: Warnings:
Dec 14 18:37:55 servidorweb varnishd[16804]: VCL compiled.
Dec 14 18:37:55 servidorweb varnishd[16804]: Debug: Version: varnish-6.5.1 revision 1dae23376bb5ea7a6b8e9e4b9ed95cdc9469fb64
Dec 14 18:37:55 servidorweb varnishd[16804]: Debug: Platform: Linux,5.10.0-9-amd64,x86_64,-junix,-smalloc,-sdefault,-hcritbit
Dec 14 18:37:55 servidorweb varnishd[16804]: Version: varnish-6.5.1 revision 1dae23376bb5ea7a6b8e9e4b9ed95cdc9469fb64
Dec 14 18:37:55 servidorweb varnishd[16804]: Platform: Linux,5.10.0-9-amd64,x86_64,-junix,-smalloc,-sdefault,-hcritbit
Dec 14 18:37:55 servidorweb varnishd[16804]: Debug: Child (16816) Started
Dec 14 18:37:55 servidorweb varnishd[16804]: Child (16816) Started
Dec 14 18:37:55 servidorweb varnishd[16804]: Info: Child (16816) said Child starts
Dec 14 18:37:55 servidorweb varnishd[16804]: Child (16816) said Child starts
```

### Realiza pruebas de rendimiento (quédate con el resultado del parámetro `Requests per second`) y comprueba si hemos aumentado el rendimiento.

Al igual que el con el apartado anterior, haremos cinco pruebas cada vez con mayor concurrencia y calcularemos la media:

* Con una concurrencia de 100: Hemos obtenido 5490,9233,8871,8727,8601 peticiones por segundo, haciendo esto una media de 8184,4 peticiones por segundo.
* Con una concurrencia de 300: Hemos obtenido 5562,8422,8552,8249,8286 peticiones por segundo, haciendo esto una media de 7814,2 peticiones por segundo.

Como vemos ha aumentado muchísimo el rendimiento del servidor, en orden de 7 veces más que con memcached y entre 70 y 80 veces más que con HAProxy, por lo que podemos decir que este es el mejor método que hemos probado. Nuevamente hemos llegado al límite de hardware que tenemos, pero aún así es bastante impresionante para lo limitado de recursos que estamos.

### Si hacemos varias peticiones a la misma URL, ¿cuantas peticiones llegan al servidor web? (comprueba el fichero access.log para averiguarlo).

Si observamos el fichero `/var/log/nginx/access.log` podemos ver lo siguiente:

```
cat /var/log/nginx/access.log

127.0.0.1 - - [14/Dec/2021:18:43:53 +0000] "GET /wordpress/ HTTP/1.1" 200 4229 "-" "ApacheBench/2.3"
127.0.0.1 - - [14/Dec/2021:18:46:23 +0000] "GET /wordpress/ HTTP/1.1" 200 4229 "-" "ApacheBench/2.3"
127.0.0.1 - - [14/Dec/2021:18:51:33 +0000] "GET /wordpress/ HTTP/1.1" 200 4229 "-" "ApacheBench/2.3"
```

Como vemos, aunque hemos estado haciendo bastantes pruebas, solo aparecen tres registros en el log, uno cada cinco minutos, que es el tiempo que mantiene en caché la respuesta. Con ello, podemos afirmar que solo hace una petición al servidor web cada cinco minutos, lo que hace que varnish sea tan eficiente.
