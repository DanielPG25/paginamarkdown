+++ 
draft = true
date = 2022-02-04T08:37:32+01:00
title = "Ejercicio 4: Implementación de un cortafuegos perimetral (nftables)"
description = "Ejercicio 4: Implementación de un cortafuegos perimetral (nftables)"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Seguridad y Alta Disponibilidad"]
externalLink = ""
series = []
+++

Configura un cortafuegos perimetral en una máquina con dos interfaces de red (externa e interna). Debes controlar el tráfico a la máquina cortafuego y el trafico a los equipos de la LAN.

Realiza la configuración necesaria para que el cortafuegos sea consistente.

Todas las configuraciones se harán sobre la familia inet, por lo que serán aplicables también a IPv6.

Así pues, creamos las tablas y cadenas necesarias:

```
nft add table inet filter
nft add table inet nat
nft add chain inet filter input { type filter hook input priority 0 \; counter \; policy drop \; }
nft add chain inet filter output { type filter hook output priority 0 \; counter \; policy drop \; }
nft add chain inet filter forward { type filter hook forward priority 0 \; counter \; policy drop \; }
nft add chain inet nat prerouting { type nat hook prerouting priority 0 \; }
nft add chain inet nat postrouting { type nat hook postrouting priority 100 \; }
```

Antes de implementar dicho cortafuegos, vamos a partir de la posición inicial de que las máquinas de la LAN pueden navegar libremente por Internet, por lo que la máquina que actúa como cortafuegos y como router tiene activado el bit de forwarding y la regla de SNAT necesaria:

```
nft add rule inet nat postrouting oifname "eth0" ip saddr 10.1.0.0/24 counter masquerade
```

Ahora añadimos las reglas que permitan conectarnos por ssh a la máquina:

```
nft add rule inet filter input ip saddr 10.0.3.0/24 tcp dport 22 ct state new,established counter accept
nft add rule inet filter output ip daddr 10.0.3.0/24 tcp sport 22 ct state established counter accept
```

Probamos:

![img_1.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_1.png)

Con esto ya tenemos creada la situación inicial.

## Permitimos tráfico para la interfaz loopback

```
nft add rule inet filter input iifname "lo" counter accept    
nft add rule inet filter output oifname "lo" counter accept
```

Probamos:

![img_14.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_14.png)

## Permite el ping al cortafuegos desde el exterior

```
nft add rule inet filter input iifname "eth0" icmp type echo-request counter accept
nft add rule inet filter output oifname "eth0" icmp type echo-reply counter accept
```

Probamos:

![img_15.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_15.png)

## Permite el ping desde el cortafuegos a la LAN

```
nft add rule inet filter input iifname "eth1" icmp type echo-reply counter accept
nft add rule inet filter output oifname "eth1" icmp type echo-request counter accept
```

Probamos:

![img_16.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_16.png)

## Permitimos el acceso a nuestro servidor web de la LAN desde el exterior

```
nft add rule inet nat prerouting iifname "eth0" tcp dport 80 counter dnat ip to 10.1.0.2
nft add rule inet filter forward iifname "eth0" oifname "eth1" ip daddr 10.1.0.0/24 tcp dport 80 ct state new,established counter accept
nft add rule inet filter forward iifname "eth1" oifname "eth0" ip saddr 10.1.0.0/24 tcp sport 80 ct state established counter accept
```

Probamos:

![img_17.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_17.png)

## Permite poder hacer conexiones ssh al exterior desde la máquina cortafuegos

```
nft add rule inet filter output oifname "eth0" tcp dport 22 ct state new,established counter accept
nft add rule inet filter input iifname "eth0" tcp sport 22 ct state established counter accept
```

Probamos:

![img_2.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_2.png)

## Permite hacer consultas DNS desde la máquina cortafuegos sólo al servidor `192.168.202.2`

```
nft add rule inet filter output oifname "eth0" ip daddr 192.168.202.2/32 udp dport 53 ct state new,established counter accept
nft add rule inet filter input iifname "eth0" ip saddr 192.168.202.2/32 udp sport 53 ct state established counter accept
```

Probamos a hacer una consulta DNS a ese servidor:

![img_18.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_18.png)

Pero no podemos hacer consultas a otro servidor DNS:

![img_19.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_19.png)

## Permite que la máquina cortafuegos pueda navegar por internet

```
nft add rule inet filter output oifname "eth0" tcp dport 80 ct state new,established counter accept
nft add rule inet filter input iifname "eth0" tcp sport 80 ct state established counter accept
nft add rule inet filter output oifname "eth0" tcp dport 443 ct state new,established counter accept
nft add rule inet filter input iifname "eth0" tcp sport 443 ct state established counter accept
```

Probamos:

![img_3.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_3.png)

## Los equipos de la red local deben poder tener conexión al exterior

```
nft add rule inet filter forward iifname "eth1" oifname "eth0" ip saddr 10.1.0.0/24 icmp type echo-request counter accept
nft add rule inet filter forward iifname "eth0" oifname "eth1" ip daddr 10.1.0.0/24 icmp type echo-reply counter accept
```

Probamos:

![img_5.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_5.png)

## Permitimos el ssh desde el cortafuegos a la LAN

```
nft add rule inet filter output oifname "eth1" tcp dport 22 ct state new,established counter accept
nft add rule inet filter input iifname "eth1" tcp sport 22 ct state established counter accept
```

Probamos:

![img_4.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_4.png)

## Permitimos hacer ping desde la LAN a la máquina cortafuegos.

```
nft add rule inet filter output oifname "eth1" icmp type echo-reply counter accept
nft add rule inet filter input iifname "eth1" icmp type echo-request counter accept
```

Probamos:

![img_6.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_6.png)

## Permite realizar conexiones ssh desde los equipos de la LAN

```
nft add rule inet filter output oifname "eth1" tcp sport 22 ct state established counter accept
nft add rule inet filter input iifname "eth1" tcp dport 22 ct state new,established counter accept
nft add rule inet filter forward iifname "eth1" oifname "eth0" tcp dport 22 ct state new,established counter accept
nft add rule inet filter forward iifname "eth0" oifname "eth1" tcp sport 22 ct state established counter accept
```

Probamos a hacer ssh al cortafuegos:

![img_7.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_7.png)

Y al exterior:

![img_8.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_8.png)

## Instala un servidor de correos en la máquina de la LAN. Permite el acceso desde el exterior y desde el cortafuego al servidor de correos

```
nft add rule inet filter output oifname "eth1" tcp dport 25 ct state new,established counter accept
nft add rule inet filter input iifname "eth1" tcp sport 25 ct state established counter accept
```

Para acceder desde fuera debemos crear antes una regla DNAT:

```
nft add rule inet nat prerouting iifname "eth0" tcp dport 25 counter dnat ip to 10.1.0.2
nft add rule inet filter forward iifname "eth0" oifname "eth1" ip daddr 10.1.0.0/24 tcp dport 25 ct state new,established counter accept
nft add rule inet filter forward iifname "eth1" oifname "eth0" ip saddr 10.1.0.0/24 tcp sport 25 ct state established counter accept
```

Probamos a hacerlo desde la propia máquina cortafuegos:

![img_9.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_9.png)

Y probamos desde el exterior:

![img_10.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_10.png)

## Permite poder hacer conexiones ssh desde exterior a la LAN

Al igual que antes, debemos crear también una regla DNAT:

```
nft add rule inet nat prerouting iifname "eth0" tcp dport 22 counter dnat ip to 10.1.0.2
nft add rule inet filter forward iifname "eth0" oifname "eth1" ip daddr 10.1.0.0/24 tcp dport 22 ct state new,established counter accept
nft add rule inet filter forward iifname "eth1" oifname "eth0" ip saddr 10.1.0.0/24 tcp sport 22 ct state established counter accept
```

Lo probamos:

![img_11.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_11.png)

## Modifica la regla anterior, para que al acceder desde el exterior por ssh tengamos que conectar al puerto 2222, aunque el servidor ssh este configurado para acceder por el puerto 22.

```
nft add rule inet nat prerouting iifname "eth0" tcp dport 2222 counter dnat ip to 10.1.0.2:22
```

![img_12.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_12.png)

## Permite hacer consultas DNS desde la LAN sólo al servidor 192.168.202.2

```
nft add rule inet filter forward iifname "eth1" oifname "eth0" ip daddr 192.168.202.2/32 udp dport 53 ct state new,established counter accept
nft add rule inet filter forward iifname "eth0" oifname "eth1" ip saddr 192.168.202.2/32 udp sport 53 ct state established counter accept
```

Probamos a hacer una consulta a ese servidor:

![img_20.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_20.png)

Sin embargo, al hacer una consulta a otro servidor:

![img_21.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_21.png)

## Permite que los equipos de la LAN puedan navegar por internet

```
nft add rule inet filter forward iifname "eth1" oifname "eth0" tcp dport 80 ct state new,established counter accept
nft add rule inet filter forward iifname "eth0" oifname "eth1" tcp sport 80 ct state established counter accept
nft add rule inet filter forward iifname "eth1" oifname "eth0" tcp dport 443 ct state new,established counter accept
nft add rule inet filter forward iifname "eth0" oifname "eth1" tcp sport 443 ct state established counter accept
```

Probamos:

![img_13.png](/images/ejercicio4_cortafuegosperimetral_nftables/img_13.png)

## Hacer la configuración permanente

Para ello, añadiremos todas las reglas que mencionemos en este ejercicio en un script ubicado en `/usr/local/bin/`:

```
nano /usr/local/bin/nftables.sh

#! /bin/sh

## Se crean las tablas y cadenas necesarias
nft add table inet filter
nft add table inet nat
nft add chain inet filter input { type filter hook input priority 0 \; counter \; policy drop \; }
nft add chain inet filter output { type filter hook output priority 0 \; counter \; policy drop \; }
nft add chain inet filter forward { type filter hook forward priority 0 \; counter \; policy drop \; }
nft add chain inet nat prerouting { type nat hook prerouting priority -100 \; }
nft add chain inet nat postrouting { type nat hook postrouting priority 100 \; }

## Borramos las reglas antiguas
nft flush chain inet filter input
nft flush chain inet filter output
nft flush chain inet filter forward
nft flush chain inet nat prerouting
nft flush chain inet nat postrouting

## La regla SNAT para que la LAN salga al exterior
nft add rule inet nat postrouting oifname "eth0" ip saddr 10.1.0.0/24 counter masquerade

## Permitimos tráfico para la interfaz loopback
nft add rule inet filter input iifname "lo" counter accept    
nft add rule inet filter output oifname "lo" counter accept

## Permite el ping al cortafuegos desde el exterior
nft add rule inet filter input iifname "eth0" icmp type echo-request counter accept
nft add rule inet filter output oifname "eth0" icmp type echo-reply counter accept

## Permite el ping desde el cortafuegos a la LAN
nft add rule inet filter input iifname "eth1" icmp type echo-reply counter accept
nft add rule inet filter output oifname "eth1" icmp type echo-request counter accept

## Permitimos el acceso a nuestro servidor web de la LAN desde el exterior
nft add rule inet nat prerouting iifname "eth0" tcp dport 80 counter dnat ip to 10.1.0.2
nft add rule inet filter forward iifname "eth0" oifname "eth1" ip daddr 10.1.0.0/24 tcp dport 80 ct state new,established counter accept
nft add rule inet filter forward iifname "eth1" oifname "eth0" ip saddr 10.1.0.0/24 tcp sport 80 ct state established counter accept

## Regla que nos permite conectarnos por SSH al cortafuegos
nft add rule inet filter input ip saddr 10.0.3.0/24 tcp dport 22 ct state new,established counter accept
nft add rule inet filter output ip daddr 10.0.3.0/24 tcp sport 22 ct state established counter accept

## Permite poder hacer conexiones ssh al exterior desde la máquina cortafuegos
nft add rule inet filter output oifname "eth0" tcp dport 22 ct state new,established counter accept
nft add rule inet filter input iifname "eth0" tcp sport 22 ct state established counter accept

## Permite hacer consultas DNS desde la máquina cortafuegos sólo al servidor `192.168.202.2`
nft add rule inet filter output oifname "eth0" ip daddr 192.168.202.2/32 udp dport 53 ct state new,established counter accept
nft add rule inet filter input iifname "eth0" ip saddr 192.168.202.2/32 udp sport 53 ct state established counter accept

## Permite que la máquina cortafuegos pueda navegar por internet
nft add rule inet filter output oifname "eth0" tcp dport 80 ct state new,established counter accept
nft add rule inet filter input iifname "eth0" tcp sport 80 ct state established counter accept
nft add rule inet filter output oifname "eth0" tcp dport 443 ct state new,established counter accept
nft add rule inet filter input iifname "eth0" tcp sport 443 ct state established counter accept

## Los equipos de la red local deben poder tener conexión al exterior
nft add rule inet filter forward iifname "eth1" oifname "eth0" ip saddr 10.1.0.0/24 icmp type echo-request counter accept
nft add rule inet filter forward iifname "eth0" oifname "eth1" ip daddr 10.1.0.0/24 icmp type echo-reply counter accept

## Permitimos el ssh desde el cortafuegos a la LAN
nft add rule inet filter output oifname "eth1" tcp dport 22 ct state new,established counter accept
nft add rule inet filter input iifname "eth1" tcp sport 22 ct state established counter accept

## Permitimos hacer ping desde la LAN a la máquina cortafuegos.
nft add rule inet filter output oifname "eth1" icmp type echo-reply counter accept
nft add rule inet filter input iifname "eth1" icmp type echo-request counter accept

## Permite realizar conexiones ssh desde los equipos de la LAN
nft add rule inet filter output oifname "eth1" tcp sport 22 ct state established counter accept
nft add rule inet filter input iifname "eth1" tcp dport 22 ct state new,established counter accept
nft add rule inet filter forward iifname "eth1" oifname "eth0" tcp dport 22 ct state new,established counter accept
nft add rule inet filter forward iifname "eth0" oifname "eth1" tcp sport 22 ct state established counter accept

## Permite el acceso desde el exterior y desde el cortafuego al servidor de correos
nft add rule inet filter output oifname "eth1" tcp dport 25 ct state new,established counter accept
nft add rule inet filter input iifname "eth1" tcp sport 25 ct state established counter accept
nft add rule inet nat prerouting iifname "eth0" tcp dport 25 counter dnat ip to 10.1.0.2
nft add rule inet filter forward iifname "eth0" oifname "eth1" ip daddr 10.1.0.0/24 tcp dport 25 ct state new,established counter accept
nft add rule inet filter forward iifname "eth1" oifname "eth0" ip saddr 10.1.0.0/24 tcp sport 25 ct state established counter accept

## Permite poder hacer conexiones ssh desde exterior a la LAN (con la modificación del puerto)
# nft add rule inet nat prerouting iifname "eth0" tcp dport 22 counter dnat ip to 10.1.0.2
nft add rule inet filter forward iifname "eth0" oifname "eth1" ip daddr 10.1.0.0/24 tcp dport 22 ct state new,established counter accept
nft add rule inet filter forward iifname "eth1" oifname "eth0" ip saddr 10.1.0.0/24 tcp sport 22 ct state established counter accept
nft add rule inet nat prerouting iifname "eth0" tcp dport 2222 counter dnat ip to 10.1.0.2:22

## Permite que los equipos de la LAN puedan navegar por internet
nft add rule inet filter forward iifname "eth1" oifname "eth0" tcp dport 80 ct state new,established counter accept
nft add rule inet filter forward iifname "eth0" oifname "eth1" tcp sport 80 ct state established counter accept
nft add rule inet filter forward iifname "eth1" oifname "eth0" tcp dport 443 ct state new,established counter accept
nft add rule inet filter forward iifname "eth0" oifname "eth1" tcp sport 443 ct state established counter accept

## Permite hacer consultas DNS desde la máquina cortafuegos sólo al servidor `192.168.202.2`
nft add rule inet filter output oifname "eth0" ip daddr 192.168.202.2/32 udp dport 53 ct state new,established counter accept
nft add rule inet filter input iifname "eth0" ip saddr 192.168.202.2/32 udp sport 53 ct state established counter accept

## Permite hacer consultas DNS desde la LAN sólo al servidor 192.168.202.2
nft add rule inet filter forward iifname "eth1" oifname "eth0" ip daddr 192.168.202.2/32 udp dport 53 ct state new,established counter accept
nft add rule inet filter forward iifname "eth0" oifname "eth1" ip saddr 192.168.202.2/32 udp sport 53 ct state established counter accept
```

Y le daremos permisos de ejecución:

```
chmod +x /usr/local/bin/nftables.sh
```

Ahora crearemos una unidad de systemd que ejecute ese script en cada arranque de la máquina:

```
nano /etc/systemd/system/nftables.service

[Unit]
Description=Reglas de nftables
After=systemd-sysctl.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/nftables.sh

[Install]
WantedBy=multi-user.target
```

Ahora iniciamos el servicio y lo habilitamos:

```
systemctl enable nftables.service
systemctl start nftables.service
```
