+++ 
draft = true
date = 2021-11-10T20:12:40+01:00
title = "Instalación y configuración de un servidor DNS esclavo"
description = "Instalación y configuración de un servidor DNS esclavo con bind9"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Servicios de Red"]
externalLink = ""
series = []
+++

# Instalación y configuración de un servidor DNS esclavo

El servidor DNS actual funciona como DNS maestro. Vamos a instalar un nuevo servidor DNS que va a estar configurado como DNS esclavo del anterior, donde se van a ir copiando periódicamente las zonas del DNS maestro. Suponemos que el nombre del servidor DNS esclavo se va llamar `tusapellidos.iesgn.org`.

* Realiza la instalación del servidor DNS esclavo.
* Comprueba si las zonas definidas en el maestro tienen algún error con el comando adecuado.
* Comprueba si la configuración de named.conf tiene algún error con el comando adecuado.
* Reinicia los servidores y comprueba en los logs si hay algún error. No olvides incrementar el número de serie en el registro SOA si has modificado la zona en el maestro.
* Configura un cliente para que utilice los dos servidores como servidores DNS.

---------------------------------------------------------------------------

En primer lugar tenemos que cambiar el nombre a nuestro servidor dns esclavo. Para ello tenemos que modificar los ficheros `/etc/hosts` y `/etc/hostname`. Tras esto, si ejecutamos el comando `hostname -f`, debería mostrarnos lo siguiente:

![nombre_esclavo.png](/images/dns_maestro_esclavo/nombre_esclavo.png)

A continuación, instalamos el servidor dns con el siguiente comando:

```
apt install bind9
```

Una vez instalado vamos a tener que configurar los dos servidores, tanto el maestro como el esclavo, para que funcionen como tales:

* En el servidor maestro:

Vamos a modificar primero la configuración global para dotar de más seguridad a nuestro servidor dns:

```
nano /etc/bind/named.conf.options

options {
        directory "/var/cache/bind";
        allow-query { 192.168.121.0/24; };
        allow-transfer { none; };

        dnssec-validation auto;
        listen-on-v6 { any; };

};

acl slaves {
  192.168.121.35/24;           // parralesgarcia
};
```

Las directivas más importantes del fichero anterior son las siguientes:

* `allow-query { 192.168.121.0/24; };`: Red desde donde podemos realizar consultas al DNS.
* `allow-transfer { none; };`: Con este parámetro restringimos la transferencia de zonas a Servidores DNS esclavos que no estén autorizados. Esta es una buena medida de seguridad, ya que evitamos que personas ajenas se enteren de las direcciones IP que están dentro de la zona de DNS de un dominio.
* `acl slaves { 192.168.121.35; };`: Listado de acceso (access list) de los servidores de DNS esclavos.

Ahora modificamos la configuración del fichero `/etc/bind/named.conf.local`, para añadir el rol de maestro:

```
nano /etc/bind/named.conf.local

include "/etc/bind/zones.rfc1918";
zone "iesgn.org" {
        type master;
        file "db.iesgn.org";
        allow-transfer { slaves; };
        notify yes;
};

zone "121.168.192.in-addr.arpa" {
        type master;
        file "db.121.168.192";
        allow-transfer { slaves; };
        notify yes;
};
```

Después modificamos las zonas de resolución directa y de resolución inversa:

```
nano /var/cache/bind/db.iesgn.org

$TTL	86400
@	IN	SOA	dparrales.iesgn.org. root.iesgn. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			  86400 )	; Negative Cache TTL
;
@	IN	NS	dparrales.iesgn.org.
@       IN      NS      parralesgarcia.iesgn.org.
@	IN	MX	10 correo.iesgn.org.

$ORIGIN iesgn.org.

dparrales	IN	A	192.168.121.176
parralesgarcia	IN	A	192.168.121.35
correo		IN	A	192.168.121.200
ftp             IN      A       192.168.121.201
cliente1	IN	A	192.168.121.35
www		IN	CNAME	dparrales
departamentos	IN	CNAME	dparrales
```

```
nano /var/cache/bind/db.121.168.192

$TTL	86400
@	IN	SOA	dparrales.iesgn.org. root.iesgn. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			  86400 )	; Negative Cache TTL
;
@	IN	NS	dparrales.iesgn.org.
@	IN	NS	parralesgarcia.iesgn.org.

$ORIGIN 121.168.192.in-addr.arpa.

176	IN	PTR	dparrales.iesgn.org.
35	IN	PTR	parralesgarcia.iesgn.org.
200	IN	PTR	correo.iesgn.org.
201	IN	PTR	ftp.iesgn.org.
```


* En el servidor esclavo:

En el servidor esclavo solo debemos modificar el fichero `/etc/bind/named.conf.local`:

```
nano /etc/bind/named.conf.local

include "/etc/bind/zones.rfc1918";
zone "iesgn.org" {
        type slave;
        file "db.iesgn.org";
        masters { 192.168.121.176; };
};

zone "121.168.192.in-addr.arpa" {
        type slave;
        file "db.121.168.192";
        masters { 192.168.121.176; };
};
```

En último lugar, debemos reiniciar el servicio de `bind9` primero en el servidor maestro y después en el esclavo:

```
systemctl restart bind9
```

Si todo ha ido bien podemos comprobar que la transferencia de ha realizado si examinamos el fichero `/var/log/syslog`:

![transferencia_log.png](/images/dns_maestro_esclavo/transferencia_log.png)

Como podemos ver, la transferencia se ha realizado correctamente.

Ahora vamos a mostrar diferentes comandos y comprobaciones para demostrar que el servidor dns funciona correctamente:

![comandos_bind.png](/images/dns_maestro_esclavo/comandos_bind.png)

Los dos comandos son los siguientes:

* named-checkconf: Revisa la configuración de bind y nos informa si hay algún error.
* named-checkzone: Revisa la configuración para la zona que has indicado en el fichero de su zona, y nos indica si hay algún error.

Como vemos, en la parte de los servidores no parece haber ningún problema. Revisemos ahora en los clientes:

En los clientes debemos cambiar el fichero `/etc/resolv.conf` para añadir los servidores dns que acabamos de configurar:

![resolv_conf.png](/images/dns_maestro_esclavo/resolv_conf.png)

Una vez terminado eso, podemos empezar a hacer consultas a los servidores.

En primer lugar vamos a consultar tanto a maestro como esclavo si tienen autoridad para la zona `iesgn.org`:

* Al maestro:

![consulta_maestro_autoridad.png](/images/dns_maestro_esclavo/consulta_maestro_autoridad.png)

* Al esclavo:

![consulta_esclavo_autoridad.png](/images/dns_maestro_esclavo/consulta_esclavo_autoridad.png)

Ahora procederemos a pedir una copia completa de la zona desde el cliente y desde el servidor esclavo:

* Desde el cliente:

![copia_cliente.png](/images/dns_maestro_esclavo/copia_cliente.png)

* Desde el servidor esclavo:

![copia_esclavo.png](/images/dns_maestro_esclavo/copia_esclavo.png)

Como podemos ver, ya que no estamos autorizados a ello, no podemos conseguir la copia que hemos pedido desde el cliente, pero sí desde el servidor esclavo, ya que en la configuración hemos dado permiso al servidor a ello.

Por último vamos a comprobar que el servidor maestro y esclavo funcionan bien, haciendo primero una consulta al maestro, y después apagándolo para ver si el esclavo es capaz de responder con la misma información:

* Consulta al maestro:

![consulta_normal_maestro.png](/images/dns_maestro_esclavo/consulta_normal_maestro.png)

* Consulta al esclavo (con el maestro apagado):

![consulta_normal_esclavo.png](/images/dns_maestro_esclavo/consulta_normal_esclavo.png)

Como vemos, el cuando hemos apagado el servidor maestro, el esclavo ha sido capaz de responder nuestra petición, por lo que podemos considerar la configuración realizada como un éxito.
