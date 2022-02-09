+++ 
draft = true
date = 2022-02-09T11:52:11+01:00
title = "Práctica Cortafuegos Perimetral sobre el Escenario de Trabajo"
description = "Práctica Cortafuegos Perimetral sobre el Escenario de Trabajo"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Seguridad y Alta Disponibilidad"]
externalLink = ""
series = []
+++

# Práctica Cortafuegos Perimetral sobre el Escenario de Trabajo

Sobre el escenario creado en el módulo de servicios con las máquinas Zeus (Router), Hera (DMZ), Ares y Apolo (LAN) y empleando iptables o nftables, configura un cortafuegos perimetral en la máquina Zeus de forma que el escenario siga funcionando completamente teniendo en cuenta los siguientes puntos:

* Política por defecto DROP para las cadenas INPUT, FORWARD y OUTPUT.
* Se pueden usar las extensiones que creamos adecuadas, pero al menos debe implementarse seguimiento de la conexión.
* Debemos implementar que el cortafuegos funcione después de un reinicio de la máquina.
* Debes indicar pruebas de funcionamiento de todas las reglas.
* El cortafuego debe cumplir al menos estas reglas:
    * La máquina Zeus tiene un servidor ssh escuchando por el puerto 22, pero al acceder desde el exterior habrá que conectar al puerto 2222.
    * Desde Apolo y Hera se debe permitir la conexión ssh por el puerto 22 a la máquina Zeus.
    * La máquina Zeus debe tener permitido el tráfico para la interfaz loopback.
    * A la máquina Zeus se le puede hacer ping desde la DMZ, pero desde la LAN se le debe rechazar la conexión (REJECT) y desde el exterior se rechazará de manera silenciosa.
    * La máquina Zeus puede hacer ping a la LAN, la DMZ y al exterior.
    * Desde la máquina Hera se puede hacer ping y conexión ssh a las máquinas de la LAN.
    * Desde cualquier máquina de la LAN se puede conectar por ssh a la máquina Hera.
    * Configura la máquina Zeus para que las máquinas de LAN y DMZ puedan acceder al exterior.
    * Las máquinas de la LAN pueden hacer ping al exterior y navegar.
    * La máquina Hera puede navegar. Instala un servidor web, un servidor ftp y un servidor de correos si no los tienes aún.
    * Configura la máquina Zeus para que los servicios web y ftp sean accesibles desde el exterior.
    * El servidor web y el servidor ftp deben ser accesibles desde la LAN y desde el exterior.
    * El servidor de correos sólo debe ser accesible desde la LAN.
    * En la máquina Ares instala un servidor mysql si no lo tiene aún. A este servidor se puede acceder desde la DMZ, pero no desde el exterior.
    * Evita ataques DoS por ICMP Flood, limitando el número de peticiones por segundo desde una misma IP.
    * Evita ataques DoS por SYN Flood.
    * Evita que realicen escaneos de puertos a Zeus.

---------------------------------------------------

El escenario es el siguiente:

* Zeus: Es una máquina Debian Bullseye que se encarga de router, y tras finalizar la práctica, actuará de cortafuegos del escenario.
* Hera: Es una máquina Rocky 8 que actúa como servidor web.
* Apolo: Es una máquina Debian Bullseye que actúa de servidor DNS, servidor LDAP y servidor de correos. 
* Ares: Es una máquina Ubuntu Server 20 que actúa de servidor de base de datos (MariaDB), servidor LDAP de respaldo y director de las copias de seguridad Bácula.

Para empezar, tenemos que hacer que las reglas que hagamos sean permanentes, es decir, que se vuelvan a crear automáticamente después de un reinicio. Para ello, guardaremos todas las reglas en un script, y dicho script será ejecutado en cada reinicio gracias a una unidad systemd que crearemos. Así pues, la unidad systemd es la siguiente:

```
nano /etc/systemd/system/iptables.service

[Unit]
Description=Reglas de iptables
After=systemd-sysctl.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/iptables.sh

[Install]
WantedBy=multi-user.target
```

Tras crear esta unidad, la habilitamos:

```
systemctl enable iptables.service
```

En dicha unidad, aparece referenciado el siguiente fichero, el cual contendrá todas las reglas. Además de dicho fichero, en esta práctica, crearé un apartado para cada bloque de reglas y demostrar su funcionamiento. Así pues, el fichero final sería el siguiente:

```
nano /usr/local/bin/iptables.sh

#! /bin/sh

### Limpieza de reglas antiguas
iptables -F
iptables -t nat -F
iptables -Z
iptables -t nat -Z

### Política por defecto
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

### Permitimos trafico para la interfaz loopback
iptables -A INPUT -i lo -p icmp -j ACCEPT
iptables -A OUTPUT -o lo -p icmp -j ACCEPT

### Permitimos conectarnos por ssh al cortafuegos, creando una regla DNAT para que acceda a traves del puerto 2222
iptables -t nat -A PREROUTING -p tcp --dport 2222 -i enp0s8 -j DNAT --to 172.22.9.170:22
iptables -A INPUT -i enp0s8 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o enp0s8 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

### Permitimos la conexion ssh desde Zeus a cualquier maquina de la LAN y la DMZ (para poder seguir usando el escenario)
iptables -A OUTPUT -d 10.0.1.0/24 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -s 10.0.1.0/24 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

iptables -A OUTPUT -d 172.16.0.0/16 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -s 172.16.0.0/16 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

### Desde Apolo y Hera se debe permitir la conexion ssh por el puerto 22 a la maquina Zeus
iptables -A OUTPUT -d 10.0.1.102/32 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -s 10.0.1.102/32 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT

iptables -A OUTPUT -d 172.16.0.200/32 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -s 172.16.0.200/32 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT

### A la maquina Zeus se le puede hacer ping desde la DMZ, pero desde la LAN se le debe rechazar la conexión (REJECT) y desde el exterior se rechazara de manera silenciosa
#iptables -A INPUT -s 172.16.0.200/16 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -d 172.16.0.200/16 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT

iptables -A INPUT -s 10.0.1.0/24 -p icmp -m icmp --icmp-type echo-request -j REJECT
iptables -A OUTPUT -d 10.0.1.0/24 -p icmp -m icmp --icmp-type echo-reply -j REJECT

### La maquina Zeus puede hacer ping a la LAN, la DMZ y al exterior
iptables -A OUTPUT -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p icmp -m icmp --icmp-type echo-reply -j ACCEPT

### Desde la maquina Hera se puede hacer ping y conexion ssh a las maquinas de la LAN
iptables -A FORWARD -s 172.16.0.200/32 -d 10.0.1.0/24 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A FORWARD -d 172.16.0.200/32 -s 10.0.1.0/24 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT

iptables -A FORWARD -s 172.16.0.200/32 -d 10.0.1.0/24 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -d 172.16.0.200/32 -s 10.0.1.0/24 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

### Desde cualquier maquina de la LAN se puede conectar por ssh a la maquina Hera.
iptables -A FORWARD -s 10.0.1.0/24 -d 172.16.0.200/32 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -s 172.16.0.200/32 -d 10.0.1.0/24 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

### Configura la maquina Zeus para que las maquinas de LAN y DMZ puedan acceder al exterior
iptables -t nat -A POSTROUTING -s 172.16.0.0/16 -o enp0s8 -j MASQUERADE
iptables -A FORWARD -i enp0s6 -o enp0s8 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s6 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT

iptables -t nat -A POSTROUTING -s 10.0.1.0/24 -o enp0s8 -j MASQUERADE
iptables -A FORWARD -i enp0s7 -o enp0s8 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s7 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT

### Las maquinas de la LAN pueden navegar
iptables -A FORWARD -i enp0s7 -o enp0s8 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s7 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

iptables -A FORWARD -i enp0s7 -o enp0s8 -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s7 -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT

### La maquina Hera puede navegar
iptables -A FORWARD -i enp0s6 -o enp0s8 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s6 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

iptables -A FORWARD -i enp0s6 -o enp0s8 -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s6 -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT

### Permitimos las consultas DNS en el escenario, incluyendo las consultas a apolo desde el exterior
iptables -A OUTPUT -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT

iptables -t nat -A PREROUTING -p udp -i enp0s8 --dport 53 -j DNAT --to 10.0.1.102
iptables -A FORWARD -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT

### Al servidor MariaDb en Ares se puede acceder desde la DMZ, pero no desde el exterior
iptables -A FORWARD -i enp0s6 -o enp0s7 -p tcp --dport 3306 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s7 -o enp0s6 -p tcp --sport 3306 -m state --state ESTABLISHED -j ACCEPT

### Configura la maquina Zeus para que los servicios web y ftp sean accesibles desde el exterior
iptables -t nat -A PREROUTING -p tcp -i enp0s8 --dport 80 -j DNAT --to 172.16.0.200
iptables -A FORWARD -i enp0s8 -o enp0s6 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s6 -o enp0s8 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

iptables -t nat -A PREROUTING -p tcp -i enp0s8 --dport 21 -j DNAT --to 172.16.0.200
iptables -A FORWARD -i enp0s8 -o enp0s6 -p tcp --dport 21 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s6 -o enp0s8 -p tcp --sport 21 -m state --state ESTABLISHED -j ACCEPT

### El servidor web y el servidor ftp deben ser accesibles desde la LAN
iptables -A FORWARD -i enp0s7 -o enp0s6 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s6 -o enp0s7 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

iptables -A FORWARD -i enp0s7 -o enp0s6 -p tcp --dport 21 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s6 -o enp0s7 -p tcp --sport 21 -m state --state ESTABLISHED -j ACCEPT

### El servidor de correos solo debe ser accesible desde la LAN
iptables -A FORWARD -i enp0s7 -o enp0s6 -p tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s6 -o enp0s7 -p tcp --sport 25 -m state --state ESTABLISHED -j ACCEPT

### Evita ataques DoS por ICMP Flood, limitando el numero de peticiones por segundo desde una misma IP
iptables -A INPUT -i enp0s6 -p icmp -m state --state NEW --icmp-type echo-request -m limit --limit 1/s --limit-burst 1 -j ACCEPT

### Evita ataques DoS por SYN Flood
iptables -N syn_flood
iptables -A INPUT -p tcp --syn -j syn_flood
iptables -A syn_flood -m limit --limit 1/s --limit-burst 3 -j RETURN
iptables -A syn_flood -j DROP

### Permitimos al servidor DNS de Apolo hacer peticiones DNS a otros servidores
iptables -A OUTPUT -p tcp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --sport 53 -m state --state ESTABLISHED -j ACCEPT

iptables -A FORWARD -p tcp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -p tcp --sport 53 -m state --state ESTABLISHED -j ACCEPT

### Permitimos a Zeus navegar
iptables -A OUTPUT -o enp0s8 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i enp0s8 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

iptables -A OUTPUT -o enp0s8 -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i enp0s8 -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT

### Permitimos que se hagan consultas al servidor LDAP desde cualquier maquina del escenario y desde el exterior
iptables -t nat -A PREROUTING -p tcp -i enp0s8 --dport 389 -j DNAT --to 10.0.1.102
iptables -t nat -A PREROUTING -p tcp -i enp0s8 --dport 636 -j DNAT --to 10.0.1.102

iptables -A OUTPUT -p tcp --dport 389 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --sport 389 -m state --state ESTABLISHED -j ACCEPT

iptables -A OUTPUT -p tcp --dport 636 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --sport 636 -m state --state ESTABLISHED -j ACCEPT

iptables -A FORWARD -p tcp --dport 389 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -p tcp --sport 389 -m state --state ESTABLISHED -j ACCEPT

iptables -A FORWARD -p tcp --dport 636 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -p tcp --sport 636 -m state --state ESTABLISHED -j ACCEPT

### Apolo debe ser capaz de mandar correos al exterior
iptables -t nat -A PREROUTING -p tcp -i enp0s8 --dport 25 -j DNAT --to 10.0.1.102
iptables -A FORWARD -s 10.0.1.102 -o enp0s8 -p tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s8 -d 10.0.1.102 -p tcp --sport 25 -m state --state ESTABLISHED -j ACCEPT

### El director Bacula en Ares debe ser capaz de conectarse a todas las máquinas del escenario
iptables -A OUTPUT -p tcp -m multiport --sport 9101,9102,9103 -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dport 9101,9102,9103 -m state --state NEW,ESTABLISHED -j ACCEPT

iptables -A FORWARD -p tcp -m multiport --dport 9101,9102,9103 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -p tcp -m multiport --sport 9101,9102,9103 -m state --state ESTABLISHED -j ACCEPT
```

Damos los permisos de ejecución al fichero:

```
chmod +x /usr/local/bin/iptables.sh
```

Probamos las siguientes reglas:

### Permitimos conectarnos por ssh a la maquina, creando una regla DNAT para que acceda a través del puerto 2222

```
iptables -t nat -A PREROUTING -p tcp --dport 2222 -i enp0s8 -j DNAT --to 172.22.9.170:22
iptables -A INPUT -i enp0s8 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o enp0s8 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
```

![img_1.png](/images/practica_cortafuegosperimetral_iptables/img_1.png)

### Permitimos la conexión ssh desde Zeus a cualquier máquina de la LAN y la DMZ (para poder seguir usando el escenario)

```
iptables -A OUTPUT -d 10.0.1.0/24 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -s 10.0.1.0/24 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

iptables -A OUTPUT -d 172.16.0.0/16 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -s 172.16.0.0/16 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
```

* Apolo:

![img_2.png](/images/practica_cortafuegosperimetral_iptables/img_2.png)

* Ares:

![img_3.png](/images/practica_cortafuegosperimetral_iptables/img_3.png)

* Hera:

![img_4.png](/images/practica_cortafuegosperimetral_iptables/img_4.png)

### Desde Apolo y Hera se debe permitir la conexión ssh por el puerto 22 a la maquina Zeus

```
iptables -A OUTPUT -d 10.0.1.102/32 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -s 10.0.1.102/32 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT

iptables -A OUTPUT -d 172.16.0.200/32 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -s 172.16.0.200/32 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
```

* Desde Apolo:

![img_5.png](/images/practica_cortafuegosperimetral_iptables/img_5.png)

* Desde Hera:

![img_6.png](/images/practica_cortafuegosperimetral_iptables/img_6.png)

### Permitimos trafico para la interfaz loopback

```
iptables -A INPUT -i lo -p icmp -j ACCEPT
iptables -A OUTPUT -o lo -p icmp -j ACCEPT
```

![img_7.png](/images/practica_cortafuegosperimetral_iptables/img_7.png)

### A la maquina Zeus se le puede hacer ping desde la DMZ, pero desde la LAN se le debe rechazar la conexión (REJECT) y desde el exterior se rechazara de manera silenciosa

```
iptables -A INPUT -s 172.16.0.200/16 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -d 172.16.0.200/16 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT

iptables -A INPUT -s 10.0.1.0/24 -p icmp -m icmp --icmp-type echo-request -j REJECT
iptables -A OUTPUT -d 10.0.1.0/24 -p icmp -m icmp --icmp-type echo-reply -j REJECT
```

* Desde el exterior:

![img_45.png](/images/practica_cortafuegosperimetral_iptables/img_45.png)

* Desde la DMZ:

![img_8.png](/images/practica_cortafuegosperimetral_iptables/img_8.png)

* Desde la LAN:

![img_44.png](/images/practica_cortafuegosperimetral_iptables/img_44.png)

### La máquina Zeus puede hacer ping a la LAN, la DMZ y al exterior

```
iptables -A OUTPUT -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
```

* Al exterior:

![img_9.png](/images/practica_cortafuegosperimetral_iptables/img_9.png)

* A la DMZ:

![img_10.png](/images/practica_cortafuegosperimetral_iptables/img_10.png)

* A la LAN:

![img_11.png](/images/practica_cortafuegosperimetral_iptables/img_11.png)

### Desde la maquina Hera se puede hacer ping y conexión ssh a las maquinas de la LAN

```
iptables -A FORWARD -s 172.16.0.200/32 -d 10.0.1.0/24 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A FORWARD -d 172.16.0.200/32 -s 10.0.1.0/24 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT

iptables -A FORWARD -s 172.16.0.200/32 -d 10.0.1.0/24 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -d 172.16.0.200/32 -s 10.0.1.0/24 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
```

* Ping:

![img_12.png](/images/practica_cortafuegosperimetral_iptables/img_12.png)

* SSH:

![img_13.png](/images/practica_cortafuegosperimetral_iptables/img_13.png)

### Desde cualquier máquina de la LAN se puede conectar por ssh a la maquina Hera.

```
iptables -A FORWARD -s 10.0.1.0/24 -d 172.16.0.200/32 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -s 172.16.0.200/32 -d 10.0.1.0/24 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
```

* Desde Apolo:

![img_14.png](/images/practica_cortafuegosperimetral_iptables/img_14.png)

* Desde Ares:

![img_15.png](/images/practica_cortafuegosperimetral_iptables/img_15.png)

### Configura la máquina Zeus para que las máquinas de LAN y DMZ puedan acceder al exterior

```
iptables -t nat -A POSTROUTING -s 172.16.0.0/16 -o enp0s8 -j MASQUERADE
iptables -A FORWARD -i enp0s6 -o enp0s8 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s6 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT

iptables -t nat -A POSTROUTING -s 10.0.1.0/24 -o enp0s8 -j MASQUERADE
iptables -A FORWARD -i enp0s7 -o enp0s8 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s7 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
```

* Desde la DMZ:

![img_16.png](/images/practica_cortafuegosperimetral_iptables/img_16.png)

* Desde la LAN:

![img_17.png](/images/practica_cortafuegosperimetral_iptables/img_17.png)

### Las maquinas de la LAN pueden hacer ping al exterior y navegar

Como el "ping" ya se ha configurado en la regla anterior, solo haremos las reglas necesarias para la navegación.

```
iptables -A FORWARD -i enp0s7 -o enp0s8 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s7 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

iptables -A FORWARD -i enp0s7 -o enp0s8 -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s7 -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT
```

![img_18.png](/images/practica_cortafuegosperimetral_iptables/img_18.png)

### La máquina Hera puede navegar

Como en este escenario solo hay una máquina en la DMZ (Hera) podemos usar indistintamente la interfaz de red o la ip para identificarla:

```
iptables -A FORWARD -i enp0s6 -o enp0s8 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s6 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

iptables -A FORWARD -i enp0s6 -o enp0s8 -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s8 -o enp0s6 -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT
```

![img_19.png](/images/practica_cortafuegosperimetral_iptables/img_19.png)

### Permitimos las consultas DNS en el escenario, incluyendo las consultas a apolo desde el exterior

```
iptables -A OUTPUT -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT

iptables -t nat -A PREROUTING -p udp -i enp0s8 --dport 53 -j DNAT --to 10.0.1.102
iptables -A FORWARD -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT
```

* Desde la DMZ podemos hacer consultas al exterior y a apolo:

![img_20.png](/images/practica_cortafuegosperimetral_iptables/img_20.png)

![img_21.png](/images/practica_cortafuegosperimetral_iptables/img_21.png)

* Desde la LAN podemos hacer consultas al exterior y a apolo:

![img_22.png](/images/practica_cortafuegosperimetral_iptables/img_22.png)

![img_23.png](/images/practica_cortafuegosperimetral_iptables/img_23.png)

* Desde Zeus podemos hacer consultas al exterior y a apolo:

![img_24.png](/images/practica_cortafuegosperimetral_iptables/img_24.png)

![img_25.png](/images/practica_cortafuegosperimetral_iptables/img_25.png)

* Desde el exterior podemos hacer consultas DNS al escenario:

![img_26.png](/images/practica_cortafuegosperimetral_iptables/img_26.png)

### Al servidor MariaDb en Ares se puede acceder desde la DMZ, pero no desde el exterior

```
iptables -A FORWARD -i enp0s6 -o enp0s7 -p tcp --dport 3306 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s7 -o enp0s6 -p tcp --sport 3306 -m state --state ESTABLISHED -j ACCEPT
```

La prueba de funcionamiento en el siguiente apartado, ya que la página web "mezzanine" necesita de un servidor de base de datos para funcionar, por lo que si se puede acceder a la página, se demuestra que hay conexión con la base de datos.

### Configura la maquina Zeus para que los servicios web y ftp sean accesibles desde el exterior

```
iptables -t nat -A PREROUTING -p tcp -i enp0s8 --dport 80 -j DNAT --to 172.16.0.200
iptables -A FORWARD -i enp0s8 -o enp0s6 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s6 -o enp0s8 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

iptables -t nat -A PREROUTING -p tcp -i enp0s8 --dport 21 -j DNAT --to 172.16.0.200
iptables -A FORWARD -i enp0s8 -o enp0s6 -p tcp --dport 21 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s6 -o enp0s8 -p tcp --sport 21 -m state --state ESTABLISHED -j ACCEPT
```

* FTP:

![img_27.png](/images/practica_cortafuegosperimetral_iptables/img_27.png)

* Servidor Web:

![img_28.png](/images/practica_cortafuegosperimetral_iptables/img_28.png)

### El servidor web y el servidor ftp deben ser accesibles desde la LAN

```
iptables -A FORWARD -i enp0s7 -o enp0s6 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s6 -o enp0s7 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

iptables -A FORWARD -i enp0s7 -o enp0s6 -p tcp --dport 21 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s6 -o enp0s7 -p tcp --sport 21 -m state --state ESTABLISHED -j ACCEPT
```

* Servidor Web:

![img_29.png](/images/practica_cortafuegosperimetral_iptables/img_29.png)

* FTP:

![img_30.png](/images/practica_cortafuegosperimetral_iptables/img_30.png)

### El servidor de correos sólo debe ser accesible desde la LAN

```
iptables -A FORWARD -i enp0s7 -o enp0s6 -p tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s6 -o enp0s7 -p tcp --sport 25 -m state --state ESTABLISHED -j ACCEPT
```

Para que funcione he tenido que configurar postfix para que escuche en todas las interfaces, ya que en Rocky por defecto, está configurado para que escuche solo en localhost.

![img_31.png](/images/practica_cortafuegosperimetral_iptables/img_31.png)

### Evita ataques DoS por ICMP Flood, limitando el número de peticiones por segundo desde una misma IP

Ya que el ping se encuentra bloqueado tanto desde el exterior como desde la LAN, solo tendríamos que bloquear el ICMP Flood desde la DMZ a Zeus (tenemos que comentar o quitar la regla antigua que permitía a Hera hacer ping a Zeus).

```
iptables -A INPUT -i enp0s6 -p icmp -m state --state NEW --icmp-type echo-request -m limit --limit 1/s --limit-burst 1 -j ACCEPT
```

Probamos a hacer un ICMP Flood desde Hera:

![img_32.png](/images/practica_cortafuegosperimetral_iptables/img_32.png)

### Evita ataques DoS por SYN Flood

```
iptables -N syn_flood
iptables -A INPUT -p tcp --syn -j syn_flood
iptables -A syn_flood -m limit --limit 1/s --limit-burst 3 -j RETURN
iptables -A syn_flood -j DROP
```

Hacemos el ataque:

![img_33.png](/images/practica_cortafuegosperimetral_iptables/img_33.png)

Vemos en los contadores que solo hemos respondido a 6 paquetes, descartando unos 278 mil paquetes:

![img_34.png](/images/practica_cortafuegosperimetral_iptables/img_34.png)

### Evita que realicen escaneos de tipo NULL a Zeus

```
iptables -A INPUT -p tcp --tcp-flags ALL NONE -m limit --limit 3/m --limit-burst 5 -j LOG --log-prefix "Firewall> Null scan "
iptables -A INPUT -p tcp --tcp-flags ALL NONE  -m recent --name blacklist_60 --set -m comment --comment "Drop/Blacklist Null scan" -j DROP
```

Con la primera regla registramos en el log el ataque, y con la segunda descartamos los paquetes del escaneo y bloqueamos la ip durante 60 segundos.

Al realizar un ataque nos aparece en los logs:

```
nmap -sN 172.22.9.170
```

![img_35.png](/images/practica_cortafuegosperimetral_iptables/img_35.png)

------------------------------------------------

Con esto hemos terminado con las reglas que nos han exigido para el escenario. A continuación crearemos las reglas necesarias para que el escenario siga funcionando como hasta ahora:

### Permitimos al servidor DNS de Apolo hacer peticiones DNS a otros servidores

```
iptables -A OUTPUT -p tcp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --sport 53 -m state --state ESTABLISHED -j ACCEPT

iptables -A FORWARD -p tcp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -p tcp --sport 53 -m state --state ESTABLISHED -j ACCEPT
```

![img_36.png](/images/practica_cortafuegosperimetral_iptables/img_36.png)

### Permitimos a Zeus navegar

```
iptables -A OUTPUT -o enp0s8 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i enp0s8 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

iptables -A OUTPUT -o enp0s8 -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i enp0s8 -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT
```

![img_37.png](/images/practica_cortafuegosperimetral_iptables/img_37.png)

### Permitimos que se hagan consultas al servidor LDAP desde cualquier máquina del escenario y desde el exterior

```
iptables -t nat -A PREROUTING -p tcp -i enp0s8 --dport 389 -j DNAT --to 10.0.1.102
iptables -t nat -A PREROUTING -p tcp -i enp0s8 --dport 636 -j DNAT --to 10.0.1.102

iptables -A OUTPUT -p tcp --dport 389 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --sport 389 -m state --state ESTABLISHED -j ACCEPT

iptables -A OUTPUT -p tcp --dport 636 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --sport 636 -m state --state ESTABLISHED -j ACCEPT

iptables -A FORWARD -p tcp --dport 389 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -p tcp --sport 389 -m state --state ESTABLISHED -j ACCEPT

iptables -A FORWARD -p tcp --dport 636 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -p tcp --sport 636 -m state --state ESTABLISHED -j ACCEPT
```

![img_38.png](/images/practica_cortafuegosperimetral_iptables/img_38.png)

### Apolo debe ser capaz de mandar correos al exterior y recibirlos

```
iptables -t nat -A PREROUTING -p tcp -i enp0s8 --dport 25 -j DNAT --to 10.0.1.102
iptables -A FORWARD -s 10.0.1.102 -o enp0s8 -p tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s8 -d 10.0.1.102 -p tcp --sport 25 -m state --state ESTABLISHED -j ACCEPT

iptables -A FORWARD -i enp0s8 -d 10.0.1.102 -p tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -s 10.0.1.102 -o enp0s8 -p tcp --sport 25 -m state --state ESTABLISHED -j ACCEPT
```

![img_39.png](/images/practica_cortafuegosperimetral_iptables/img_39.png)

![img_40.png](/images/practica_cortafuegosperimetral_iptables/img_40.png)

![img_41.png](/images/practica_cortafuegosperimetral_iptables/img_41.png)

### El director Bacula en Ares debe ser capaz de conectarse a todas las máquinas del escenario

```
iptables -A INPUT -p tcp -m multiport --dport 9101,9102,9103 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp -m multiport --sport 9101,9102,9103 -m state --state ESTABLISHED -j ACCEPT

iptables -A FORWARD -p tcp -m multiport --dport 9101,9102,9103 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -p tcp -m multiport --sport 9101,9102,9103 -m state --state ESTABLISHED -j ACCEPT
```

![img_42.png](/images/practica_cortafuegosperimetral_iptables/img_42.png)

![img_43.png](/images/practica_cortafuegosperimetral_iptables/img_43.png)

Con esto hemos terminado de configurar el cortafuegos para el escenario.
