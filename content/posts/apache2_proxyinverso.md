+++ 
draft = true
date = 2021-10-30T16:05:17+02:00
title = "Apache2 como proxy inverso"
description = "Apache2 como proxy inverso"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Servicios de Red"]
externalLink = ""
series = []
+++

# Apache2 como proxy inverso

Descarga el siguiente [fichero](https://fp.josedomingo.org/sri2122/u03/doc/ejercicio_proxy/ejercicio_proxy.zip) donde encontrarás un escenario vagrant y una receta ansible para configurar el siguiente escenario:

* Una máquina “proxy” conectada al exterior y a una red interna.
* Una máquina “servidorweb” conectada a la red interna.

En la máquina “servidorweb” tenemos instalado un apache2 con dos virtualhost. Suponemos que no podemos acceder a ella por la red de mantenimiento, por lo tanto lo que tienes que hacer es lo siguiente:

* Crea el escenario vagrant y pasa el ansible para configurar la máquina “servidorweb”.
* Instala un servidor web apache2 en la máquina proxy.
* Configura el proxy para acceder a las páginas del “servidorweb”:
    * Opción 1: Para que se acceda a la primera página con la URL `www.app1.org` y a la segunda página con la URL `www.app2.org`.
    * Opción 2: Para que se acceda a la primera página con la URL `www.servidor.org\app1` y a la segunda página con la URL `www.servidor.org\app2`.


------------------------------------


Tras crear el escenario y pasar el ansible, accedemos a la máquina proxy e instalamos el servidor apache2:

`
apt install apache2
`

Ahora vamos a configurar el servidor para cada una de las dos opciones:

## Opción 1: Para que se acceda a la primera página con la URL `www.app1.org` y a la segunda página con la URL `www.app2.org`.

Para ello, en primer lugar debemos habilitar los módulos en apache2 para que funcione como proxy inverso:

```
a2enmod proxy proxy_http
```

Ahora vamos a crear dos nuevos virtualhosts en la máquina proxy, uno para cada página, con la siguiente configuración:

* Para `www.app1.org`:

```
<VirtualHost *:80>
    ServerName www.app1.org
    ProxyPass  / "http://interno.example1.org/"
    ProxyPassReverse / "http://interno.example1.org/"
</VirtualHost>
```

* Para `www.app2.org`:

```
<VirtualHost *:80>
    ServerName www.app2.org
    ProxyPass  "/" "http://interno.example2.org/"
    ProxyPassReverse "/" "http://interno.example2.org/"
</VirtualHost>
```

Habilitamos los dos vitualhosts que acabamos de crear y reiniciamos el servicio de apache2:

```
a2ensite www.app1.org.conf www.app2.org.conf 

systemctl reload apache2
```

Ya solo queda configurar la resolución estática de nombres en la máquina `proxy` y en el anfitrión:

* En la máquina `proxy`:

```
cat /etc/hosts

127.0.0.1   localhost
127.0.0.2   bullseye
::1     localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters

127.0.1.1 proxy proxy
10.0.0.6 interno.example1.org interno.example2.org
```

* En el anfitrión:

```
cat /etc/hosts
127.0.0.1   localhost
127.0.1.1   debian
192.168.121.62  www.app1.org www.app2.org
```

Con esto, ya podemos acceder a ambas páginas desde el anfitrión:

* `www.app1.org`:

![pag1.png](/images/apache2_proxyinverso/pag1.png)

* `www.app2.org`:

![pag2.png](/images/apache2_proxyinverso/pag2.png)


## Opción 2: Para que se acceda a la primera página con la URL `www.servidor.org\app1` y a la segunda página con la URL `www.servidor.org\app2`.


Primero, debemos habilitar si no lo están ya, los siguientes módulos de apache en la máquina `proxy`:

```
a2enmod proxy proxy_http
```


Ahora vamos a crear un virtualhost en el que configuraremos el proxy para las dos páginas. La configuración será la siguiente:

```
<VirtualHost *:80>
    ServerName www.servidor.org

    <Location "/app1">
        ProxyPass "http://interno.example1.org/"
        ProxyPassReverse "http://interno.example1.org/"
    </Location>

    <Location "/app2">
                ProxyPass "http://interno.example2.org/"
                ProxyPassReverse "http://interno.example2.org/"
    </Location>

</VirtualHost>
```

Habilitamos el virtualhost y reiniciamos el servicio de apache2:

```
a2ensite www.servidor.org.conf 

systemctl reload apache2
```

Ahora añadimos la resolución de nombres en el fichero `/etc/hosts`, tanto del anfitrión como de la máquina `proxy`:

* En la máquina `proxy`:

```
cat /etc/hosts

127.0.0.1   localhost
127.0.0.2   bullseye
::1     localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters

127.0.1.1 proxy proxy
10.0.0.6 interno.example1.org interno.example2.org
```

* En el anfitrión:

```
cat /etc/hosts
127.0.0.1   localhost
127.0.1.1   debian
192.168.121.62  www.servidor.org
```

Con esto, ya podemos acceder a las páginas a través de los nuevos enlaces:

* `www.servidor.org/app1`:

![app1.png](/images/apache2_proxyinverso/app1.png)

* `www.servidor.org/app2`:

![app2.png](/images/apache2_proxyinverso/app2.png)
