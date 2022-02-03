+++ 
draft = true
date = 2022-02-03T12:53:12+01:00
title = "Ejercicio 3: Implementación de un cortafuegos perimetral (iptables)"
description = "Implementación de un cortafuegos perimetral (iptables)"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Seguridad y Alta Disponibilidad"]
externalLink = ""
series = []
+++

# Ejercicio 3: Implementación de un cortafuegos perimetral (iptables)

Configura un cortafuegos perimetral en una máquina con dos interfaces de red (externa e interna). Debes controlar el tráfico a la máquina cortafuego y el trafico a los equipos de la LAN.

Realiza la configuración necesaria para que el cortafuegos sea consistente.

Antes de implementar dicho cortafuegos, vamos a partir de la posición inicial de que las máquinas de la LAN pueden navegar libremente por Internet, por lo que la máquina que actúa como cortafuegos y como router tiene activado el bit de forwarding y la regla de SNAT necesaria:

```
iptables -t nat -A POSTROUTING -s 10.1.0.0/24 -o eth0 -j MASQUERADE
```

Ahora añadimos las reglas que permitan conectarnos por ssh a la máquina, para que no nos eche de la misma cuando añadamos la política por defecto:

```
iptables -A INPUT -s 10.0.3.0/24 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -d 10.0.3.0/24 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
```

Ya podemos añadir la política por defecto:

```
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
```

Con esto ya tenemos creada la situación inicial.

## Permitimos tráfico para la interfaz loopback

```
iptables -A INPUT -i lo -p icmp -j ACCEPT
iptables -A OUTPUT -o lo -p icmp -j ACCEPT
```

Probamos:

![img_16.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_16.png)

## Permite el ping al cortafuegos desde el exterior

```
iptables -A OUTPUT -o eth0 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
iptables -A INPUT -i eth0 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
```

Probamos:

![img_17.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_17.png)

## Permite el ping desde el cortafuegos a la LAN

```
iptables -A OUTPUT -o eth1 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -i eth1 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
```

Probamos:

![img_18.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_18.png)

## Permitimos el acceso a nuestro servidor web de la LAN desde el exterior

```
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to 10.1.0.2
iptables -A FORWARD -i eth0 -o eth1 -d 10.1.0.2/32 -p tcp --dport 80 -m state --state NEW,ESTABLISHED  -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -s 10.1.0.2/32 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT
```

Probamos:

![img_19.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_19.png)

## Permite poder hacer conexiones ssh al exterior desde la máquina cortafuegos

```
iptables -A INPUT -i eth0 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
```

Probamos:

![img_1.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_1.png)

## Permite hacer consultas DNS desde la máquina cortafuegos sólo al servidor `192.168.202.2`

```
iptables -A INPUT -s 192.168.202.2/32 -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -d 192.168.202.2/32 -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
```

Probamos a hacer una consulta DNS a ese servidor:

![img_2.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_2.png)

Pero no podemos hacer consultas a otro servidor DNS:

![img_3.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_3.png)

## Permite que la máquina cortafuegos pueda navegar por internet

```
iptables -A INPUT -i eth0 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
```

## Los equipos de la red local deben poder tener conexión al exterior

```
iptables -A FORWARD -i eth1 -o eth0 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
```

Probamos:

![img_15.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_15.png)

## Permitimos el ssh desde el cortafuego a la LAN

```
iptables -A INPUT -i eth1 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth1 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
```

Probamos:

![img_4.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_4.png)

## Permitimos hacer ping desde la LAN a la máquina cortafuegos.

```
iptables -A OUTPUT -o eth1 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
iptables -A INPUT -i eth1 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
```

Probamos:

![img_5.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_5.png)

## Permite realizar conexiones ssh desde los equipos de la LAN

```
iptables -A INPUT -i eth1 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth1 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
```

Probamos a hacer ssh al cortafuegos:

![img_6.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_6.png)

Y al exterior:

![img_7.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_7.png)

## Instala un servidor de correos en la máquina de la LAN. Permite el acceso desde el exterior y desde el cortafuego al servidor de correos

```
iptables -A INPUT -i eth1 -p tcp --sport 25 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth1 -p tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
```

Para acceder desde fuera debemos crear antes una regla DNAT:

```
iptables -t nat -A PREROUTING -p tcp --dport 25 -i eth0 -j DNAT --to 10.1.0.2
iptables -A FORWARD -i eth0 -o eth1 -p tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -p tcp --sport 25 -m state --state ESTABLISHED -j ACCEPT
```

Probamos a hacerlo desde la propia máquina cortafuegos:

![img_11.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_11.png)

Y probamos desde el exterior:

![img_12.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_12.png)

## Permite poder hacer conexiones ssh desde exterior a la LAN

Al igual que antes, debemos crear también una regla DNAT:

```
iptables -t nat -A PREROUTING -p tcp --dport 22 -i eth0 -j DNAT --to 10.1.0.2
iptables -A FORWARD -i eth0 -o eth1 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
```

Lo probamos:

![img_13.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_13.png)

## Modifica la regla anterior, para que al acceder desde el exterior por ssh tengamos que conectar al puerto 2222, aunque el servidor ssh este configurado para acceder por el puerto 22.

```
iptables -t nat -A PREROUTING -p tcp --dport 2222 -i eth0 -j DNAT --to 10.1.0.2:22
```

![img_14.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_14.png)

## Permite hacer consultas DNS desde la LAN sólo al servidor 192.168.202.2

```
iptables -A FORWARD -i eth1 -o eth0 -d 192.168.202.2 -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -s 192.168.202.2 -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT
```

Probamos a hacer una consulta a ese servidor:

![img_8.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_8.png)

Sin embargo, al hacer una consulta a otro servidor:

![img_9.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_9.png)

## Permite que los equipos de la LAN puedan navegar por internet

```
iptables -A FORWARD -i eth1 -o eth0 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT
```

Probamos:

![img_10.png](/images/ejercicio3_cortafuegosperimetral_iptables/img_10.png)

## Hacer la configuración permanente

Para ello, añadiremos todas las reglas que mencionemos en este ejercicio en un script ubicado en `/usr/local/bin/`:

```
nano /usr/local/bin/iptables.sh

#! /bin/sh

## Limpieza de reglas antiguas
iptables -F
iptables -t nat -F
iptables -Z
iptables -t nat -Z

## Política por defecto
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

## Reglas NAT
iptables -t nat -A POSTROUTING -s 10.1.0.0/24 -o eth0 -j MASQUERADE

## Permitimos tráfico para la interfaz loopback
iptables -A INPUT -i lo -p icmp -j ACCEPT
iptables -A OUTPUT -o lo -p icmp -j ACCEPT

## Permite el ping al cortafuegos desde el exterior
iptables -A OUTPUT -o eth0 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
iptables -A INPUT -i eth0 -p icmp -m icmp --icmp-type echo-request -j ACCEPT

## Permite el ping desde el cortafuegos a la LAN
iptables -A OUTPUT -o eth1 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -i eth1 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT

## Permitimos el acceso a nuestro servidor web de la LAN desde el exterior
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to 10.1.0.2
iptables -A FORWARD -i eth0 -o eth1 -d 10.1.0.2/32 -p tcp --dport 80 -m state --state NEW,ESTABLISHED  -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -s 10.1.0.2/32 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

## Conexión por SSH al cortafuegos
iptables -A INPUT -s 10.1.0.0/24 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -d 10.1.0.0/24 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

## Conexiones SSH desde el cortafuegos
iptables -A INPUT -i eth0 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT

## Permite hacer consultas DNS desde la máquina cortafuegos sólo al servidor `192.168.202.2`
iptables -A INPUT -s 192.168.202.2/32 -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -d 192.168.202.2/32 -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT

## Permite que la máquina cortafuegos pueda navegar por internet.
iptables -A INPUT -i eth0 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT

## Permitimos el ssh desde el cortafuegos a la LAN
iptables -A INPUT -i eth1 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth1 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT

## Permitimos hacer ping desde la LAN a la máquina cortafuegos.
iptables -A OUTPUT -o eth1 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
iptables -A INPUT -i eth1 -p icmp -m icmp --icmp-type echo-request -j ACCEPT

## Los equipos de la red local deben poder tener conexión al exterior
iptables -A FORWARD -i eth1 -o eth0 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT

## Permite realizar conexiones ssh desde los equipos de la LAN
iptables -A INPUT -i eth1 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth1 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

## Permite el acceso desde el exterior y desde el cortafuego al servidor de correos de la LAN
iptables -A INPUT -i eth1 -p tcp --sport 25 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth1 -p tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t nat -A PREROUTING -p tcp --dport 25 -i eth0 -j DNAT --to 10.1.0.2
iptables -A FORWARD -i eth0 -o eth1 -p tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -p tcp --sport 25 -m state --state ESTABLISHED -j ACCEPT

## Permite poder hacer conexiones ssh desde exterior a la LAN (con la modificación del puerto 2222)
#iptables -t nat -A PREROUTING -p tcp --dport 22 -i eth0 -j DNAT --to 10.1.0.2
iptables -A FORWARD -i eth0 -o eth1 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -t nat -A PREROUTING -p tcp --dport 2222 -i eth0 -j DNAT --to 10.1.0.2:22

## Permite hacer consultas DNS desde la LAN sólo al servidor 192.168.202.2
iptables -A FORWARD -i eth1 -o eth0 -d 192.168.202.2 -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -s 192.168.202.2 -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT

## Permite que los equipos de la LAN puedan navegar por internet
iptables -A FORWARD -i eth1 -o eth0 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT
```

Y le daremos permisos de ejecución:

```
chmod +x /usr/local/bin/iptables.sh
```

Ahora crearemos una unidad de systemd que ejecute ese script en cada arranque de la máquina:

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

Ahora iniciamos el servicio y lo habilitamos:

```
systemctl enable iptables.service
systemctl start iptables.service
```
