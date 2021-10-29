+++ 
draft = true
date = 2021-10-29T09:49:22+02:00
title = "Infraestructura de red router-nat desde horizon"
description = "Infraestructura de red router-nat desde horizon"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Cloud Computing"]
externalLink = ""
series = []
+++

# Infraestructura de red router-nat desde horizon

El escenario tendrá las siguientes características:

* Crea una red que se debe llamar “red_interna”, con direccionamiento 192.168.0.0/24, tendrá el DHCP activado, el gateway será el 192.168.0.1 y el DNS que reparte el 192.168.202.2.
* Crea una instancia a partir de una imagen, llamada router conecta a tu red y a la red “red_interna” en la dirección 192.168.0.1. Esta máquina será la puerta de enlace del la otra máquina.
* Crea otra instancia a partir de un volumen, que se llame cliente y que tenga la ip 192.168.0.100, evidentemente conectada a la red_interna.


Crear las redes desde horizon es bastante sencillo e intuitivo, por lo que voy a mostrar la configuración de como quedó la red tras crearla:

![redinterna.png](/images/routernat_horizon/redinterna.png)


Después creamos la máquina router, que estará conectada a mi red y a la nueva red interna que he creado, con la dirección 192.168.0.1, y la máquina cliente, que estará conectada a la red interna con ip 192.168.0.100:

![topologia_red.png](/images/routernat_horizon/topologia_red.png)

A continuación, debemos eliminar los grupos de seguridad y la seguridad de los puertos de cada máquina (es necesario para realizar el ejercicio):

![seguridad_router.png](/images/routernat_horizon/seguridad_router.png)

![puerto_seguridad_router.png](/images/routernat_horizon/puerto_seguridad_router.png)

![puerto_seguridad_router_interna.png](/images/routernat_horizon/puerto_seguridad_router_interna.png)

![cliente1_seguridad.png](/images/routernat_horizon/cliente1_seguridad.png)

![puerto_seguridad_cliente1.png](/images/routernat_horizon/puerto_seguridad_cliente1.png)

Una vez eliminada la seguridad de las máquinas, podemos configurar la instancia 'router' para que enrute los paquetes que pasan a través de él:

```
iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o ens3 -j MASQUERADE

echo 1 > /proc/sys/net/ipv4/ip_forward
```

Ya podemos acceder a nuestra máquina cliente para probar si de verdad tiene acceso a Internet, pero para ello no podemos utilizar una conexión ssh convencional, ya que no tenemos acceso a ella directamente desde el exterior. Es por ello que usaremos el ssh agent:

* Vemos si tenemos cargado el agente ssh en memoria:

`
ssh-add -L
`

* Si no nos aparece nada, lo cargamos con el siguiente comando:

`
ssh-add ~/.ssh/id_rsa
`

* Accedemos primero al router con el ssh-agent:

`
ssh -A debian@172.22.201.245
`

* Desde el router, ya podemos hacer una conexión ssh con el cliente:

`
ssh debian@192.168.0.100
`

Ahora ya podemos probar si tenemos conexión con el exterior y resolución de nombres:

![ping_cliente.png](/images/routernat_horizon/ping_cliente.png)

Como vemos, ya podemos conectarnos con el exterior, y la resolución de nombres funciona perfectamente.

