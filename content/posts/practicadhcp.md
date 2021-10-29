+++ 
draft = true
date = 2021-10-14T20:32:54+02:00
title = "Práctica de configuración de un servidor DHCP manualmente y con ansible"
description = "Práctica de configuración de un servidor DHCP manualmente y con ansible"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Servicios de Red"]
externalLink = ""
series = []
+++

# Práctica DHCP

## Escenario

```
Preparación del escenario

Crea un escenario en libvirt/kvm (no uses Vagrant) de la siguiente manera:

    Máquina Servidor: Tiene tres tarjetas de red: una que le da acceso a internet (NAT o pública) y dos redes privadas (muy aisladas).
    Máquina nodo_lan1: Un cliente linux conectado a la primera red privada.
    Máquina nodo_lan2: Un cliente linux conectado a la segunda red privada.

Servidor dhcp

Instala un servidor dhcp en el ordenador “servidor” que de servicio a los ordenadores de red local, teniendo en cuenta:

    Por la red privada 1: Reparte configuración en la red 192.168.100.0/24. El tiempo de concesión es de 12 horas.
    Por la red privada 2: Reparte configuración en la red 192.168.200.0/24. El tiempo de concesión es de 1 hora.

Para los dos ámbitos los servidores DNS deben ser el 1.1.1.1 y 1.0.0.1. Piensa que puertas de acceso se deben mandar a cada red.
Router-nat

Configura la máquina “servidor” para que haga router-nat para los clientes de ambas redes.
Funcionamiento del dhcp

Vamos a conectar un cliente windows a una de las redes. Vamos a comprobar que ocurre con la configuración de los clientes en determinadas circunstancias, para ello vamos a poner un tiempo de concesión muy bajo.
```



## Objetivos de la práctica

```
Tarea 1: Explica brevemente cómo has creado el escenario con libvirt/KVM.

Tarea 2: Muestra el fichero de configuración del servidor, la lista de concesiones, la modificación en la configuración que has hecho en el cliente para que tome la configuración de forma automática y muestra la salida del comando ` ip a` en los clientes.

Tarea 3: Configura el servidor para que funcione como router y NAT, de esta forma los clientes tengan internet. Muestra las rutas por defecto del servidor y los clientes. Realiza una prueba de funcionamiento para comprobar que el cliente tiene acceso a internet (utiliza nombres, para comprobar que tiene resolución DNS).

Tarea 4: Los clientes toman una configuración, y a continuación apagamos el servidor dhcp. ¿qué ocurre con el cliente windows? ¿Y con el cliente linux?. Entrega pruebas de funcionamiento.

Tarea 5: Los clientes toman una configuración, y a continuación cambiamos la configuración del servidor dhcp (por ejemplo el rango). ¿qué ocurriría con un cliente windows? ¿Y con el cliente linux?. Entrega pruebas de funcionamiento.

Tarea 6: Realiza un playbook con ansible que configure de forma automática el servidor, para que haga de servidor DHCP y de router-NAT (no es necesario que se haga la configuración en los clientes). Entrega la URL del repositorio.
```




## Tarea 1: Explica brevemente cómo has creado el escenario con libvirt/KVM.


Vamos a crear primero las tres máquinas que funcionarán como servidor y clientes. Primero crearemos el servidor, y después usaremos la imagen creada como base para aprovisionamiento ligero para las tres máquinas necesarias. Para crear la máquina que tendrá la imagen base usamos el siguiente comando:

`
virt-install --connect qemu:///system --cdrom /var/lib/libvirt/images/debian-11.0.0-amd64-netinst.iso --network network=default --name Servidor-DHCP --memory 1024 --vcpus 1 --disk size=10
`

Ahora creamos los tres volúmenes de aprovisionamiento ligero que usaremos para el servidor y los clientes:

```
qemu-img create -b /var/lib/libvirt/images/Servidor-DHCP.qcow2 -f qcow2 /var/lib/libvirt/images/servidor_dhcp.qcow2

qemu-img create -b /var/lib/libvirt/images/Servidor-DHCP.qcow2 -f qcow2 /var/lib/libvirt/images/cliente_dhcp1.qcow2

qemu-img create -b /var/lib/libvirt/images/Servidor-DHCP.qcow2 -f qcow2 /var/lib/libvirt/images/cliente_dhcp2.qcow2
```

Ya podemos crear las tres máquinas basadas en esos volúmenes:

```
virt-install --connect qemu:///system --name Servidor-DHCP --memory 1024 --vcpus 1 --disk /var/lib/libvirt/images/servidor_dhcp.qcow2 --import

virt-install --connect qemu:///system --name ClienteDhcp1 --memory 1024 --vcpus 1 --disk /var/lib/libvirt/images/cliente_dhcp1.qcow2 --import

virt-install --connect qemu:///system --name ClienteDhcp2 --memory 1024 --vcpus 1 --disk /var/lib/libvirt/images/cliente_dhcp2.qcow2 --import

```

También debemos crear las redes aisladas a las que conectaremos los clientes y el servidor. A continuación el xml de cada una de las redes:

```
<network>
  <name>veryprivate1</name>
  <bridge name="puente2" stp="on" delay="0"/>
</network>


----------------------------------------------------------

<network>
  <name>veryprivate2</name>
  <bridge name="puente4" stp="on" delay="0"/>
</network>

```

Ahora añadimos ambas interfaces al Servidor, y añadir una a cada uno de los clientes además que quitarles la interfaz *default* que tienen:

```
Servidor:

virsh -c qemu:///system attach-interface --domain Servidor-DHCP --persistent network veryprivate1

virsh -c qemu:///system attach-interface --domain Servidor-DHCP --persistent network veryprivate2


Clientes:

virsh -c qemu:///system attach-interface --domain ClienteDhcp1 --persistent network veryprivate1

virsh -c qemu:///system attach-interface --domain ClienteDhcp2 --persistent network veryprivate2

virsh -c qemu:///system detach-interface --domain ClienteDhcp2 network 52:54:00:99:f4:34 --persistent

virsh -c qemu:///system detach-interface --domain ClienteDhcp1 network 52:54:00:7d:a1:37 --persistent
```


Ya solo queda configurar las interfaces del servidor y el escenario estaría listo:

```
nano /etc/network/interfaces

# The primary network interface
allow-hotplug ens3
iface ens3 inet dhcp


# Red privada 1
allow_hotplug ens8
auto ens8
iface ens8 inet static
        address 192.168.100.1
        netmask 255.255.255.0

# Red privada 2
allow_hotplug ens9
auto ens9
iface ens9 inet static
        address 192.168.200.1
        netmask 255.255.255.0
```


Con esto ya estaría montado el escenario que usaremos en el ejercicio.


## Tarea 2: Muestra el fichero de configuración del servidor, la lista de concesiones, la modificación en la configuración que has hecho en el cliente para que tome la configuración de forma automática y muestra la salida del comando `ip a` en los clientes.

En el fichero de configuración añadimos las siguientes líneas:

```
/etc/dhcp/dhcpd.conf

subnet 192.168.100.0 netmask 255.255.255.0 {
        range 192.168.100.50 192.168.100.100;
        option subnet-mask 255.255.255.0;
        option routers 192.168.100.1;
        option domain-name-servers 1.1.1.1, 1.0.0.1;
        default-lease-time 43200;
        max-lease-time 43200;
}
 
subnet 192.168.200.0 netmask 255.255.255.0 {
        range 192.168.200.50 192.168.200.100;
        option subnet-mask 255.255.255.0;
        option routers 192.168.200.1;
        option domain-name-servers 1.1.1.1, 1.0.0.1;
        default-lease-time 3600;
        max-lease-time 3600;
}
```

También hemos de añadir las siguientes líneas en `/etc/default/isc-dhcp-server`:

`
INTERFACESv4="ens8 ens9"
`

Ahora reiniciamos el servicio:

`
systemctl restart isc-dhcp-server
`

Una vez hayamos acabado con el servidor, vamos a revisar la configuración de las interfaces de los clientes:

* Cliente 1:

```
/etc/network/interfaces

auto ens8
allow-hotplug ens8
iface ens8 inet dhcp
```

* Cliente 2:

```
/etc/network/interfaces

auto ens8
allow-hotplug ens8
iface ens8 inet dhcp
```

Ya solo tenemos que reiniciar la máquina y se configurará por dhcp:

![ipa_cliente1.png](/images/dhcp_practica/ipa_cliente1.png)

![ipa_cliente2.png](/images/dhcp_practica/ipa_cliente2.png)

Como podemos ver, cada cliente ha recibido su ip. Veamos ahora la lista de concesiones en el servidor:

```
cat /var/lib/dhcp/dhcpd.leases

# The format of this file is documented in the dhcpd.leases(5) manual page.
# This lease file was written by isc-dhcp-4.4.1

# authoring-byte-order entry is generated, DO NOT DELETE
authoring-byte-order little-endian;

server-duid "\000\001\000\001(\371\272\340RT\000\276B\001";

lease 192.168.100.50 {
  starts 3 2021/10/13 15:57:25;
  ends 4 2021/10/14 03:57:25;
  cltt 3 2021/10/13 15:57:25;
  binding state active;
  next binding state free;
  rewind binding state free;
  hardware ethernet 52:54:00:37:c6:19;
  uid "\377\0007\306\031\000\001\000\001(\371\276cRT\0007\306\031";
  client-hostname "ClienteDhcp1";
}
lease 192.168.200.50 {
  starts 3 2021/10/13 16:01:49;
  ends 3 2021/10/13 17:01:49;
  cltt 3 2021/10/13 16:01:49;
  binding state active;
  next binding state free;
  rewind binding state free;
  hardware ethernet 52:54:00:b0:34:a7;
  uid "\377\000\2604\247\000\001\000\001(\371D\\RT\000\307\367\020";
  client-hostname "ClienteDhcp2";
}
```

En este fichero se han registrado los dos préstamos que acaba de hacer el servidor.


## Tarea 3: Configura el servidor para que funcione como router y NAT, de esta forma los clientes tengan internet. Muestra las rutas por defecto del servidor y los clientes. Realiza una prueba de funcionamiento para comprobar que el cliente tiene acceso a internet (utiliza nombres, para comprobar que tiene resolución DNS).

Lo primero es activar el bit de "forwarding". Para hacerlo de forma permanente descomentamos la siguiente línea en el fichero /etc/sysctl.conf:

`
net.ipv4.ip_forward=1
`

Ahora añadimos las reglas de iptables (hay que instalar el paquete si no está ya instalado) necesarias para que el servidor haga nat y los clientes puedan salir a internet. Las reglas vamos a añadirlas al fichero */etc/network/interfaces* para hacerlas permanentes:

```
# Red privada 1
allow_hotplug ens8
auto ens8
iface ens8 inet static
        address 192.168.100.1
        netmask 255.255.255.0
        post-up iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o ens3 -j MASQUERADE
# Red privada 2
allow_hotplug ens9
auto ens9
iface ens9 inet static
        address 192.168.200.1
        netmask 255.255.255.0
        post-up iptables -t nat -A POSTROUTING -s 192.168.200.0/24 -o ens3 -j MASQUERADE
```

Ahora debemos reiniciar la máquina y ya estaría lista (debido a que el servidor ya tiene como ruta por defecto la salida a internet, no hace falta cambiarla).

Veamos ahora si los clientes pueden acceder a Internet y si les funciona el dns:

![ping_cliente1.png](/images/dhcp_practica/ping_cliente1.png)


![ping_cliente2.png](/images/dhcp_practica/ping_cliente2.png)


Como podemos ver, pueden acceder a internet. Ahora veamos las rutas por defecto de cada uno:


![ruta_cliente1.png](/images/dhcp_practica/ruta_cliente1.png)


![ruta_cliente2.png](/images/dhcp_practica/ruta_cliente2.png)


![ruta_servidor.png](/images/dhcp_practica/ruta_servidor.png)


## Tarea 4: Los clientes toman una configuración, y a continuación apagamos el servidor dhcp. ¿qué ocurre con el cliente windows? ¿Y con el cliente linux?. Entrega pruebas de funcionamiento.

Para esta prueba hemos cambiado el tiempo de préstamo del servidor dhcp a 60 segundos. Tenemos encedidos el cliente Linux y el cliente Windows. Ahora apagamos el servidor:

`
systemctl stop isc-dhcp-server
`

Dejamos que pasen los 60 segundos y vemos que ha pasado con cada cliente.

* Cliente Linux:

Tras los 60 segundos ha perdido la configuración que recibió y ya no puede acceder a Internet:


![no_dhcp_clientelinux.png](/images/dhcp_practica/no_dhcp_clientelinux.png)


* Cliente Windows:

El cliente Windows, por otro lado, no ha perdido la configuración que recibió, y como no han cambiado ni la puerta de enlace ni los servidores dns, puede seguir accediendo a Internet:


![no_dhcp_clientewindows.png](/images/dhcp_practica/no_dhcp_clientewindows.png)


## Tarea 5: Los clientes toman una configuración, y a continuación cambiamos la configuración del servidor dhcp (por ejemplo el rango). ¿qué ocurriría con un cliente windows? ¿Y con el cliente linux?. Entrega pruebas de funcionamiento.

Hemos cambiado el rango de direcciones que proporciona el servidor dhcp. Reniciamos el servicio y vemos que pasa en cada cliente:


* Cliente Linux:

Cuando el cliente Linux llegó al tiempo T2 (15 segundos), volvió a hacer la petición al servidor y cambió su ip.


![cambio_dhcp_clientelinux.png](/images/dhcp_practica/cambio_dhcp_clientelinux.png)


* Cliente Windows:

A pesar de que pasaron más de 60 segundos, el cliente Windows no cambio su configuración, y siguió usando la misma ip que recibió la primera vez:


![cambio_dhcp_clientewindows.png](/images/dhcp_practica/cambio_dhcp_clientewindows.png)


He tenido que ejecutar los comandos `ipconfig /release` e `ipconfig /renew` para que cogiera la nueva ip.


## Tarea 6: Realiza un playbook con ansible que configure de forma automática el servidor, para que haga de servidor DHCP y de router-NAT (no es necesario que se haga la configuración en los clientes). Entrega la URL del repositorio.

Aquí la url del mi repositorio de [Github](https://github.com/DanielPG25/practica_servidordhcp_ansible)
