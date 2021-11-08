+++ 
draft = true
date = 2021-11-08T20:31:22+01:00
title = "Instalación y configuración del servidor bind9 en nuestra red local"
description = "Instalación y configuración del servidor bind9 en nuestra red local"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Servicios de Red"]
externalLink = ""
series = []
+++

# Instalación y configuración del servidor bind9 en nuestra red local

## Escenario

* En nuestra red local tenemos un servidor Web que sirve dos páginas web: `www.iesgn.org`, `departamentos.iesgn.org`.
* Vamos a instalar en nuestra red local un servidor DNS (lo puedes instalar en el mismo equipo que tiene el servidor web)
* El nombre del servidor DNS va a ser tunombre.iesgn.org.

## Servidor bind9

Instala un servidor dns bind9. Las características del servidor DNS que queremos instalar son las siguientes:

* El servidor DNS se llama tunombre.iesgn.org y por supuesto, va a ser el servidor con autoridad para la zona iesgn.org.
* Vamos a suponer que tenemos un servidor para recibir los correos que se llame correo.iesgn.org y que está en la dirección x.x.x.200 (esto es ficticio).
* Vamos a suponer que tenemos un servidor ftp que se llame `ftp.iesgn.org` y que está en x.x.x.201 (esto es ficticio)
* Además queremos nombrar a los clientes.
* También hay que nombrar a los virtualhosts de apache: `www.iesgn.org` y `departamentos.iesgn.org`
* Se tiene que configurar la zona de resolución inversa.

---------------------------------------------------------------------------------------------------------------------------

## Procedimiento

Primero instalamos el servidor dns:

```
apt install bind9
```

A continuación cambiamos el nombre de nuestra máquina a `dparrales.iesgn.org`:

```
nano /etc/hostname

dparrales

nano /etc/hosts

127.0.0.2       dparrales.iesgn.org     dparrales
```

Para asegurarnos de que hemos cambiado el nombre, podemos ejecutar el siguiente comando:

```
hostname -f

dparrales.iesgn.org
```

Ahora vamos a modificar el fichero de configuración de `bind` para que se adapte a los requisitos que nos han pedido:

```
nano /etc/bind/named.conf.local

//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
include "/etc/bind/zones.rfc1918";
zone "iesgn.org" { 
        type master;
        file "db.iesgn.org"; 
};

zone "121.168.192.in-addr.arpa" {
        type master;
        file "db.121.168.192";
};
```

A continuación hemos de crear los ficheros que hemos incluido en la configuración (`db.iesgn.org` y `db.121.168.192`), en el directorio `/var/cache/bind/`:

```
nano /var/cache/bind/db.iesgn.org

$TTL    86400
@       IN      SOA     dparrales.iesgn.org. root.iesgn. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                          86400 )       ; Negative Cache TTL
;
@       IN      NS      dparrales.iesgn.org.
@       IN      MX      10 correo.iesgn.org.

$ORIGIN iesgn.org.

dparrales       IN      A       192.168.121.176
correo          IN      A       192.168.121.200
ftp             IN      A       192.168.121.201
cliente1        IN      A       192.168.121.35
www             IN      CNAME   dparrales      
departamentos   IN      CNAME   dparrales 
```

```
nano /var/cache/bind/db.121.168.192

$TTL    86400
@       IN      SOA     dparrales.iesgn.org. root.iesgn. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                          86400 )       ; Negative Cache TTL
;
@       IN      NS      dparrales.iesgn.org.

$ORIGIN 121.168.192.in-addr.arpa.

176     IN      PTR     dparrales.iesgn.org.
200     IN      PTR     correo.iesgn.org.
201     IN      PTR     ftp.iesgn.org.
```

Ahora debemos reiniciar el servicio:

```
systemctl status bind9
```

Por último, tenemos que hacer que el cliente use el servidor dns que acabamos de crear. Esto lo hacemos modificando el fichero `/etc/resolv.conf`:

```
nameserver 192.168.121.176
```

Con esto ya podemos hacer las pruebas necesarias para ver si funciona:

* `departamentos.iesgn.org`:

![departamentos_iesgn.png](/images/instalar_dns/departamentos_iesgn.png)

* `www.iesgn.org`:

![www_iesgn.png](/images/instalar_dns/www_iesgn.png)

* `ftp.iesgn.org`:

![ftp_iesgn.png](/images/instalar_dns/ftp_iesgn.png)

* DNS con autoridad en `iesgn.org`:

![ns_iesgn.png](/images/instalar_dns/ns_iesgn.png)

* Servidor de correo:

![correo_iesgn.png](/images/instalar_dns/correo_iesgn.png)

* `www.josedomingo.org`:

![josedom_iesgn.png](/images/instalar_dns/josedom_iesgn.png)

* Una resolución inversa:

![inversa_iesgn.png](/images/instalar_dns/inversa_iesgn.png)
