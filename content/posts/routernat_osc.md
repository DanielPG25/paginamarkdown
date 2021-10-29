+++ 
draft = true
date = 2021-10-29T20:05:56+02:00
title = "Infraestructura de red router-nat desde OSC"
description = "Infraestructura de red router-nat desde OSC"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Cloud Computing"]
externalLink = ""
series = []
+++

# Infraestructura de red router-nat desde OSC

Vamos a crear la siguiente infraestructura:

![infraestructura.png](/images/routernat_osc/infraestructura.png)

Con las siguientes características:

* Crea una red que se debe llamar “red_interna”, con direccionamiento 192.168.0.0/24, tendrá el DHCP activado, el gateway será el 192.168.0.1 y el DNS que reparte el 192.168.202.2.
* Crea una instancia a partir de una imagen, llamada router conecta a tu red y a la red “red_interna” en la dirección 192.168.0.1. Esta máquina será la puerta de enlace del la otra máquina.
* Crea otra instancia a partir de un volumen, que se llame cliente y que tenga la ip 192.168.0.100, evidentemente conectada a la red_interna.
* Configura la instancia router para que haga router-nat y podamos tener conexión al exterior en la máquina cliente.


*Nota:*
```
Openstack nos ofrece los grupos de seguridad que es un cortafuego que permite controlar el tráfico saliente y entrante en cada nodo de una instancia, además este cortafuego aplica reglas anti-spoofing a todos los puertos para garantizar que el tráfico inesperado o no deseado no pueda originarse o pasar a través de un puerto. Esto incluye reglas que prohíben que las instancias actúen como servidores DHCP, actúen como enrutadores u obtengan tráfico de una dirección IP que no sea su IP fija. Para solucionar esta limitación, nosotros vamos a desactivar las reglas de seguridad en las instancias, para ello:
```

* En cada instancia edita los grupos de seguridad y quita el grupo de seguridad default. en este momento la instancia no admite ningún tráfico.
* Para cada interface (puerto) de las instancias implicadas (en nuestro caso 3 puertos) tenemos que deshabilitar la seguridad del puerto. en este momento ya no tenemos cortafuegos en las instancias.


## Crea una red que se debe llamar “red_interna”, con direccionamiento 192.168.0.0/24, tendrá el DHCP activado, el gateway será el 192.168.0.1 y el DNS que reparte el 192.168.202.2.

Empezamos creando la red:

`
openstack network create red_ìnterna
`

A continuación, la editamos para añadir lo que se nos pide:

`
openstack subnet create --network red_interna --subnet-range 192.168.0.0/24 --dhcp --gateway 192.168.0.1 --dns-nameserver 192.168.202.2 mi_red
`

Una vez creadas la redes, vamos a crear los puertos que usaremos en el ejercicio:

```
openstack port create --network red_interna --fixed-ip ip-address=192.168.0.100 cliente1

openstack port create --network red_interna --fixed-ip ip-address=192.168.0.1 puerta_enlace
```


## Crea una instancia a partir de una imagen, llamada router conecta a tu red y a la red “red_interna” en la dirección 192.168.0.1. Esta máquina será la puerta de enlace del la otra máquina.

Empecemos a crear la instancia conectada a mi red:

```
openstack server create --flavor m1.normal --image "Debian 11.0 - Bullseye" --security-group default --key-name clave_danielp --network "red de daniel.parrales" router
```

Ahora vamos a añadirle el puerto con la dirección "192.168.0.1" que hemos creado antes:

`
openstack server add port router puerta_enlace
`

Ya podemos añadir la ip flotante a la instancia:

`
openstack server add floating ip router 172.22.201.245
`

## Crea otra instancia a partir de un volumen, que se llame cliente y que tenga la ip 192.168.0.100, evidentemente conectada a la red_interna.

Primero creamos el volumen desde el cual crearemos la instancia:

`
openstack volume create --bootable --size 10 --image "Debian 11.0 - Bullseye" cliente
`

A continuación creamos la instancia a partir de ese volumen y con el puerto que hemos creado antes:

`
openstack server create --flavor vol.normal --volume cliente --security-group default --key-name clave_danielp --port cliente1 cliente
`

## Configura la instancia router para que haga router-nat y podamos tener conexión al exterior en la máquina cliente.

Entramos en la instancia por ssh y usamos los siguientes comandos para configurar el router-nat:

```
iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o ens3 -j MASQUERADE

echo 1 > /proc/sys/net/ipv4/ip_forward
```

Sin embargo, aún no podemos acceder al exterior desde el cliente. Esto se debe a que openstack tiene incorporado un firewall por defecto que impide el spoofing. Es por ello que para este ejercicio, vamos a tener que desactivarlo.


## En cada instancia edita los grupos de seguridad y quita el grupo de seguridad default. En este momento la instancia no admite ningún tráfico.

Para ello usamos los siguientes comandos:

```
openstack server remove security group router default

openstack server remove security group cliente default
```

## Para cada interface (puerto) de las instancias implicadas (en nuestro caso 3 puertos) tenemos que deshabilitar la seguridad del puerto. en este momento ya no tenemos cortafuegos en las instancias.

Usaremos los siguientes comandos para deshabilitar la seguridad de los puetos:

```
openstack port set --disable-port-security cliente1

openstack port set --disable-port-security puerta_enlace

openstack port set --disable-port-security 8ad318f8-84c0-4aef-9b90-d08b148384c9
```

Una vez que hayamos hecho esto, podemos acceder a la máquina cliente a través del agente ssh:

```
ssh-add ~/.ssh/id_rsa

ssh -A debian@172.22.201.245

ssh debian@192.168.0.100
```

Ahora comprobaremos que, efectivamente, la máquina "cliente" tiene conexión con el exterior y resolución de nombres:

![ping_final.png](/images/routernat_osc/ping_final.png)
