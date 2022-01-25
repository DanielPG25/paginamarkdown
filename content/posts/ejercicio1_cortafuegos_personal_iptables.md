+++ 
draft = true
date = 2022-01-25T18:25:31+01:00
title = "Ejercicio 1: Implementación de un cortafuegos personal (iptables)"
description = "Implementación de un cortafuegos personal (iptables)"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Seguridad y Alta Disponibilidad"]
externalLink = ""
series = []
+++

# Ejercicio 1: Implementación de un cortafuegos personal (iptables)

Vamos a realizar los primeros pasos para implementar un cortafuegos en un nodo de una red, aquel que se ejecuta en el propio equipo que trata de proteger, lo que a veces se denomina un cortafuegos personal. He usado contenedores virtuales LXC.

Para empezar vamos a tener que eliminar las reglas anteriores que hubiera en el cortafuegos:

```
iptables -F
iptables -t nat -F
iptables -Z
iptables -t nat -Z
```

Y añadimos las reglas necesarias para asegurar que podemos seguir trabajando mediante ssh:

```
iptables -A INPUT -s 10.0.3.0/24 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -d 10.0.3.0/24 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
```

Ahora podemos añadir la política por defecto (será de tipo DROP):

```
iptables -P INPUT DROP
iptables -P OUTPUT DROP
```

Comprobamos que podemos acceder mediante ssh a la máquina:

![img_12.png](/images/ejercicio1_cortafuegos_personal_iptables/img_12.png)

Ahora añadimos las reglas que permitirán que hagamos ping a otras máquinas:

```
iptables -A INPUT -i eth0 -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A OUTPUT -o eth0 -p icmp --icmp-type echo-request -j ACCEPT
```

Y comprobamos que podemos hacer ping a otra máquina de la red:

![img_13.png](/images/ejercicio1_cortafuegos_personal_iptables/img_13.png)

También creamos las reglas para permitir que se hagan consultas y se obtengan las respuestas del servidor dns:

```
iptables -A INPUT -i eth0 -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
```

Y lo comprobamos haciendo un `dig`:

![img_14.png](/images/ejercicio1_cortafuegos_personal_iptables/img_14.png)

Ahora añadimos las reglas que permitirán a la máquina hacer peticiones http/https:

```
iptables -A INPUT -i eth0 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT

iptables -A INPUT -i eth0 -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
```

Y lo comprobamos usando el comando curl:

![img_15.png](/images/ejercicio1_cortafuegos_personal_iptables/img_15.png)

![img_16.png](/images/ejercicio1_cortafuegos_personal_iptables/img_16.png)

Por último tenemos que crear la regla que permita que se puede acceder a nuestro servidor web (mediante http):

```
iptables -A INPUT -i eth0 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT
```

Y probamos si podemos acceder desde un cliente:

![img_17.png](/images/ejercicio1_cortafuegos_personal_iptables/img_17.png)

## Tarea 1
 
Permite poder hacer conexiones ssh al exterior.

-------------------------------------------

Vamos a añadir las reglas que permitan realizar conexiones ssh al exterior:

```
iptables -A INPUT -i eth0 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
```

Probemos si podemos conectarnos por ssh a otra máquina:

![img_1.png](/images/ejercicio1_cortafuegos_personal_iptables/img_1.png)

Efectivamente, podemos conectarnos, por lo que podemos decir que la regla funciona correctamente.

## Tarea 2

Deniega el acceso a tu servidor web desde una ip concreta.

------------------

Para ello vamos a usar otro contenedor LXC que se encuentra en la misma red, y desde él intentaremos usar "curl" para obtener nuestra web. Debido a que estamos usando una política por defecto de tipo DROP, si queremos bloquear una ip en concreto, estamos asumiendo que el resto de IPs si tienen acceso, por lo que se haría de la siguiente forma:

```
iptables -A INPUT ! -s 10.0.3.157/32 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT ! -d 10.0.3.157/32 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT
```

Como vemos, esta regla permitirá el acceso a nuestro servidor web a cualquier máquina que no tenga la ip indicada. Veamos si funciona:

* Desde otra ip que no es la bloqueada:

![img_2.png](/images/ejercicio1_cortafuegos_personal_iptables/img_2.png)

* Desde la ip bloqueda:

![img_3.png](/images/ejercicio1_cortafuegos_personal_iptables/img_3.png)

Como vemos, podemos acceder desde cualquier máquina que no sea la que tenga la ip que tenemos bloqueada.

## Tarea 3

Permite hacer consultas DNS sólo al servidor `192.168.202.2`. Comprueba que no puedes hacer un `dig @1.1.1.1.`.

----------------------------------------------------

Para ello añadimos las siguientes reglas:

```
iptables -A INPUT -s 192.168.202.2/32 -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -d 192.168.202.2/32 -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
```

Vemos que no podemos hacer un `dig @1.1.1.1`:

![img_4.png](/images/ejercicio1_cortafuegos_personal_iptables/img_4.png)

Pero si podemos usar el servidor dns que hay en "192.168.202.2":

![img_5.png](/images/ejercicio1_cortafuegos_personal_iptables/img_5.png)

## Tarea 4

No permitir el acceso al servidor web de `www.josedomingo.org` (Tienes que utilizar la ip). ¿Puedes acceder a `fp.josedomingo.org`?

------------------------------------------------

Para lograr esto debemos añadir las siguientes reglas a nuestro cortafuegos (previamente hemos averiguado que la ip de esa página es `37.187.119.60`):

```
iptables -A OUTPUT ! -d 37.187.119.60/32 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT ! -s 37.187.119.60/32 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT
```

Ahora no podemos acceder a esa url desde esta máquina debido a la regla del cortafuegos:

![img_6.png](/images/ejercicio1_cortafuegos_personal_iptables/img_6.png)

Tampoco podemos acceder a `fp.josedomingo.org`, ya que tiene la misma ip, y la tenemos bloqueada:

![img_7.png](/images/ejercicio1_cortafuegos_personal_iptables/img_7.png)

Sin embargo, si que podemos acceder a otros dominios que no tengan esa ip:

![img_8.png](/images/ejercicio1_cortafuegos_personal_iptables/img_8.png)

Como vemos, la regla funciona bien, pero debemos tener cuidado al bloquear ciertas ips, ya que podríamos estar bloqueando más servicios de los que queremos.


## Tarea 5

Permite mandar un correo usando nuestro servidor de correo: `babuino-smtp`. Para probarlo ejecuta un `telnet babuino-smtp.gonzalonazareno.org 25`.

-----------------------------------------------

Para ello vamos a crear las reglas necesarias que permitan el acceso de paquetes tcp a través del puerto 25. También hemos averiguado la ip del servidor de correos (192.168.202.3). Las reglas quedarían de la siguiente forma:

```
iptables -A OUTPUT -d 192.168.203.3/32 -p tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -s 192.168.203.3/32 -p tcp --sport 25 -m state --state ESTABLISHED -j ACCEPT
```

Ahora hagamos la prueba estableciendo una conexión telnet al puerto 25 de dicha máquina:

![img_9.png](/images/ejercicio1_cortafuegos_personal_iptables/img_9.png)

Como vemos, nos esta respondiendo, por lo que también podríamos mandar un correo a dicha máquina y funcionaría.

## Tarea 6

Instala un servidor mariadb, y permite los accesos desde la ip de tu cliente. Comprueba que desde otro cliente no se puede acceder.

------------------------------------------------------

Para probar esta regla antes hemos creado una base de datos en mariadb y un usuario con permisos sobre dicha base de datos. También hemos configurado mariadb para que sea accesible remotamente. Una vez hecho todo esto, podemos crear las reglas necesarias para permitir el acceso a una ip en concreto (he elegido la misma ip del cliente al que bloqueamos antes):

```
iptables -A INPUT -s 10.0.3.157/32 -p tcp --dport 3306 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -d 10.0.3.157/32 -p tcp --sport 3306 -m state --state ESTABLISHED -j ACCEPT
```

Si ahora intentamos acceder desde dicho cliente:

![img_10.png](/images/ejercicio1_cortafuegos_personal_iptables/img_10.png)

Como vemos, podemos conectarnos perfectamente desde el cliente que le hemos indicado. Sin embargo, si lo intentamos desde un cliente diferente obtenemos lo siguiente:

![img_11.png](/images/ejercicio1_cortafuegos_personal_iptables/img_11.png)

Con esto podemos afirmar que la regla funciona bien, por lo que podemos dar por concluido este ejercicio.
