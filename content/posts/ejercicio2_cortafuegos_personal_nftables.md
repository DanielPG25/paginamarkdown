+++ 
draft = true
date = 2022-01-31T09:09:39+01:00
title = "Ejercicio 2: Implementación de un cortafuegos personal (nftables)"
description = "Ejercicio 2: Implementación de un cortafuegos personal (nftables)"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Seguridad y Alta Disponibilidad"]
externalLink = ""
series = []
+++

Vamos a realizar los primeros pasos para implementar un cortafuegos en un nodo de una red, aquel que se ejecuta en el propio equipo que trata de proteger, lo que a veces se denomina un cortafuegos personal. He usado contenedores virtuales LXC.

Una de las diferencias de usar nftables es que las tablas y cadenas son totalmente configurables. En nftables lo primero que tenemos que hacer es crear las tablas (son las zonas en las que crearemos las distintas reglas del cortafuegos clasificadas en cadenas). A continuación crearemos las distintas cadenas en las tablas (que nos permite clasificar las reglas).

Vamos a crear una tabla para filtrar los paquetes que llamaremos filter:

```
nft add table inet filter
```

Hemos elegido la familia "inet" ya que de esta forma las reglas que añadamos afectarán tanto a IPv4 como a IPv6. Lo primero que vamos a hacer es crear las cadenas que usaremos durante este ejercicio. Por defecto, haremos que las cadenas acepten los paquetes, para la que no nos echen de la conexión ssh:

```
nft add chain inet filter input { type filter hook input priority 0 \; counter \; policy accept \; }
nft add chain inet filter output { type filter hook output priority 0 \; counter \; policy accept \; }
``` 

Ahora ya podemos añadir la regla que permita conexiones ssh a nuestra máquina:

```
nft add rule inet filter input iifname "eth0" tcp dport 22 ct state new,established counter accept
nft add rule inet filter output oifname "eth0" tcp sport 22 ct state established counter accept
```

Una vez añadida esta regla, ya podemos cambiar la política por defecto a DROP:

```
nft chain inet filter input { policy drop \; }
nft chain inet filter output { policy drop \; }
```

Así pues tenemos las siguientes cadenas en este momento:

```
nft list chains

table inet filter {
	chain input {
		type filter hook input priority filter; policy drop;
	}
	chain output {
		type filter hook output priority filter; policy drop;
	}
}
```

Podemos probar que nos deja entrar por ssh:

![img_1.png](/images/ejercicio2_cortafuegos_personal_nftables/img_1.png)

Ahora añadiremos las reglas que permita que hagamos ping a otras máquinas:

```
nft add rule inet filter output oifname "eth0" icmp type echo-request counter accept
nft add rule inet filter input iifname "eth0" icmp type echo-reply counter accept
```

Vemos que funciona:

![img_2.png](/images/ejercicio2_cortafuegos_personal_nftables/img_2.png)

A continuación añadimos las reglas que permita hacer peticiones dns:

```
nft add rule inet filter output oifname "eth0" udp dport 53 ct state new,established  counter accept
nft add rule inet filter input iifname "eth0" udp sport 53 ct state established  counter accept
```

Y comprobamos que funciona:

![img_3.png](/images/ejercicio2_cortafuegos_personal_nftables/img_3.png)

Después añadimos las reglas que permitan el tráfico HTTP/HTTPS desde nuestra máquina:

```
nft add rule inet filter output oifname "eth0" ip protocol tcp tcp dport { 80,443 } ct state new,established  counter accept
nft add rule inet filter input iifname "eth0" ip protocol tcp tcp sport { 80,443 } ct state established  counter accept
```

![img_4.png](/images/ejercicio2_cortafuegos_personal_nftables/img_4.png)

![img_5.png](/images/ejercicio2_cortafuegos_personal_nftables/img_5.png)

También debemos crear la regla que haga que se pueda acceder a nuestro servidor web mediante http:

```
nft add rule inet filter output oifname "eth0" tcp sport 80 ct state established counter accept
nft add rule inet filter input iifname "eth0" tcp dport 80 ct state new,established counter accept
```

![img_6.png](/images/ejercicio2_cortafuegos_personal_nftables/img_6.png)

Con esto hemos terminado con la reglas iniciales. Ahora crearemos las reglas que nos indican en los ejercicios (eliminando las reglas antiguas que causen conflicto):

## Permitir conexiones ssh al exterior

```
nft add rule inet filter output oifname "eth0" tcp dport 22 ct state new,established  counter accept
nft add rule inet filter input iifname "eth0" tcp sport 22 ct state established  counter accept
```

Veamos si funciona:

![img_7.png](/images/ejercicio2_cortafuegos_personal_nftables/img_7.png)

## Denegar el acceso a mi servidor web desde una ip concreta

```
nft insert rule inet filter output position 10 oifname "eth0" ip daddr 10.0.3.157/32 tcp sport 80 ct state established counter drop
nft insert rule inet filter input position 11 ip saddr 10.0.3.157/32 tcp dport 80 ct state new,established counter drop
```

Esto inserta las reglas antes de la regla que creamos antes que permite el acceso a cualquier máquina a nuestro servidor web:

```
table inet filter { # handle 10
	chain input { # handle 1
		type filter hook input priority filter; policy drop;
		iifname "eth0" tcp dport 22 ct state established,new counter packets 0 bytes 0 accept # handle 5
		iifname "eth0" tcp sport 22 ct state established counter packets 55 bytes 9008 accept # handle 7
		ip saddr 10.0.3.157 tcp dport 80 ct state established,new counter packets 0 bytes 0 drop # handle 13
		iifname "eth0" tcp dport 80 ct state established,new counter packets 0 bytes 0 accept # handle 11
	}

	chain output { # handle 2
		type filter hook output priority filter; policy drop;
		oifname "eth0" tcp sport 22 ct state established counter packets 0 bytes 0 accept # handle 6
		oifname "eth0" tcp dport 22 ct state established,new counter packets 65 bytes 8284 accept # handle 8
		oifname "eth0" ip daddr 10.0.3.157 tcp sport 80 ct state established counter packets 0 bytes 0 drop # handle 12
		oifname "eth0" tcp sport 80 ct state established counter packets 0 bytes 0 accept # handle 10
	}
}
```

La probamos:

![img_8.png](/images/ejercicio2_cortafuegos_personal_nftables/img_8.png)

Como vemos no deja acceder a la ip que hemos bloqueado. Sin embargo, si lo intentamos desde otra máquina si nos deja:

![img_9.png](/images/ejercicio2_cortafuegos_personal_nftables/img_9.png)

## Permite hacer consultas DNS sólo al servidor `192.168.202.2`. Comprueba que no puedes hacer un `dig @1.1.1.1.`.

```
nft add rule inet filter output oifname "eth0" ip daddr 192.168.202.2/32 udp dport 53 ct state new,established  counter accept
nft add rule inet filter input iifname "eth0" ip saddr 192.168.202.2/32 udp sport 53 ct state established  counter accept
```

Probamos:

![img_14.png](/images/ejercicio2_cortafuegos_personal_nftables/img_14.png)

Sin embargo no nos deja hacer lo siguiente:

![img_15.png](/images/ejercicio2_cortafuegos_personal_nftables/img_15.png)

## No permitir el acceso al servidor web de `www.josedomingo.org`

Tal y como paso en la práctica anterior con `iptables`, al bloquear la ip de `www.josedomingo.org` también estaremos bloqueando todas los servicios web que estén asociados a esa ip, como `fp.josedomingo.org`.

```
nft insert rule inet filter output position 18 oifname "eth0" ip daddr 37.187.119.60/32 tcp dport 80 ct state new,established counter drop
nft insert rule inet filter input position 20 iifname "eth0" ip saddr 37.187.119.60/32 tcp sport 80 ct state established counter drop
```

Lo probamos:

![img_10.png](/images/ejercicio2_cortafuegos_personal_nftables/img_10.png)

Como vemos nos bloquea ambas webs. Probemos si podemos acceder a otra web diferente:

![img_11.png](/images/ejercicio2_cortafuegos_personal_nftables/img_11.png)

## Permite mandar un correo usando nuestro servidor de correo: `babuino-smtp`.

```
nft add rule inet filter output oifname "eth0" ip daddr 192.168.203.3/32 tcp dport 25 ct state new,established counter accept
nft add rule inet filter input iifname "eth0" ip saddr 192.168.203.3/32 tcp sport 25 ct state established counter accept
```

Probemos la regla con `telnet`:

![img_16.png](/images/ejercicio2_cortafuegos_personal_nftables/img_16.png)

## Permite el acceso al servidor MariaDB desde una ip en concreto.

```
nft add rule inet filter output oifname "eth0" ip daddr 10.0.3.157/32 tcp sport 3306 ct state established counter accept
nft add rule inet filter input iifname "eth0" ip saddr 10.0.3.157/32 tcp dport 3306 ct state new,established counter accept
```

Probamos si dicho cliente puede acceder:

![img_12.png](/images/ejercicio2_cortafuegos_personal_nftables/img_12.png)

Y vemos como si accedemos desde otro cliente nos lo impide:

![img_13.png](/images/ejercicio2_cortafuegos_personal_nftables/img_13.png)
