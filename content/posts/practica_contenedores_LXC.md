+++ 
draft = true
date = 2022-01-26T10:19:43+01:00
title = "Contenedores LXC"
description = "Contenedores LXC"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Cloud Computing"]
externalLink = ""
series = []
+++

# Práctica: Contenedores LXC

Crea la siguiente infraestructura con contenedores LXC:

* Un contenedor LXC llamado `router`. Este contenedor se creará a partir de la plantilla Debian Bullseye. Este contenedor tendrá dos interfaces de red: la primera conectada a una red pública (bridge br0). Por esta interfaz el contenedor tendrá acceso a internet. Además estará conectada la bridge de un red muy aislada que crearás con virsh y tendrá como dirección IP la 10.0.0.1.
* Un contenedor LXC llamado `servidor_web`. Este contenedor se creará a partir de la plantilla Ubuntu Focal Fossa. Este contenedor estará conectado a la red muy aislada con la dirección IP 10.0.0.2.

Los dos contenedores deben tener las siguientes características:

* Se deben auto arrancar cuando se encienda el host.
* Deben tener una limitación de memoria RAM de 512M. El contenedor `router` debe usar dos CPU y el contenedor `servidor_web` una CPU.

Servicios que debemos instalar en los contenedores (si quieres lo puedes hacer con ansible):

* Los dos contenedores deben estar configurados para acceder por SSH con el usuario root con tu clave privada. El usuario root no tiene contraseña.
* El contenedor router debe hacer SNAT para que el contenedor servidor_web tenga acceso a internet.
* El contenedor servidor_web tiene un servidor web (apache2 o nginx). El servidor web sirve los ficheros del directorio `/var/www/pagina`. En este directorio se monta el directorio `/opt/pagina del host` y es donde tendrá los ficheros de la página web.
* El contenedor router debe hacer DNAT para que podamos acceder a la página web alojada en el contenedor servidor_web.

--------------------------------------------------------------

Para empezar vamos a crear los dos contenedores:

```
lxc-create -n router -t debian -- -r bullseye

lxc-create -n servidor_web -t ubuntu -- -r focal
```

Ahora modificaremos la plantilla de ambos contenedores para que se adapte a lo que nos piden:

```
nano /var/lib/lxc/router/config

# Template used to create this container: /usr/share/lxc/templates/lxc-debian
# Parameters passed to the template: -r bullseye
# For additional config options, please look at lxc.container.conf(5)

# Uncomment the following line to support nesting containers:
#lxc.include = /usr/share/lxc/config/nesting.conf
# (Be aware this has security implications)

# Arranque automático
lxc.start.auto = 1

# Conectado al puente
lxc.net.0.type = veth
lxc.net.0.hwaddr = 00:16:3e:b6:f8:c0
lxc.net.0.link = br0
lxc.net.0.flags = up

# Conectado a la una red muy aislada
lxc.net.1.type = veth
lxc.net.1.hwaddr = 00:16:3e:b6:f7:c0
lxc.net.1.link = virbr4
lxc.net.1.flags = up

lxc.apparmor.profile = generated
lxc.apparmor.allow_nesting = 1
lxc.rootfs.path = dir:/var/lib/lxc/router/rootfs

# Limitamos la memoria y el número de CPUs
lxc.cgroup2.memory.max = 512M
lxc.cgroup2.cpuset.cpus = 0 1

# Common configuration
lxc.include = /usr/share/lxc/config/debian.common.conf

# Container specific configuration
lxc.tty.max = 4
lxc.uts.name = router
lxc.arch = amd64
lxc.pty.max = 1024
```

```
nano /var/lib/lxc/servidor_web/config

# Template used to create this container: /usr/share/lxc/templates/lxc-ubuntu
# Parameters passed to the template: -r focal
# For additional config options, please look at lxc.container.conf(5)

# Uncomment the following line to support nesting containers:
#lxc.include = /usr/share/lxc/config/nesting.conf
# (Be aware this has security implications)

# Arranque automático
lxc.start.auto = 1

# Limitamos la memoria y el número de CPUs
lxc.cgroup2.memory.max = 512M
lxc.cgroup2.cpuset.cpus = 0

# Common configuration
lxc.include = /usr/share/lxc/config/ubuntu.common.conf

# Container specific configuration
lxc.apparmor.profile = generated
lxc.apparmor.allow_nesting = 1
lxc.rootfs.path = dir:/var/lib/lxc/servidor_web/rootfs
lxc.uts.name = servidor_web
lxc.arch = amd64

# Network configuration
lxc.net.0.type = veth
lxc.net.0.hwaddr = 00:16:3e:08:42:cf
lxc.net.0.link = virbr4
lxc.net.0.flags = up
```

Con esto hemos terminado de configurar el servidor externamente. Ahora podemos arrancar los contenedores y entrar en ellos para seguir configurándolos:

```
lxc-start router

lxc-start servidor_web
```

Empecemos por la máquina router:

```
lxc-attach router
```

Modificamos el fichero `/etc/network/interfaces` para añadir la ip que nos han indicado y añadimos también aquí las reglas DNAT y SNAT que necesitaremos más adelante (también activaremos el ip de forward):

```
root@router:/# apt install nano
root@router:/# apt install iptables
root@router:~# echo 1 > /proc/sys/net/ipv4/ip_forward
```

```
root@router:~# nano /etc/sysctl.conf 
net.ipv4.ip_forward=1
```

```
root@router:/# nano /etc/network/interfaces

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
        address 10.0.0.1
        netmask 255.255.255.0
        post-up iptables -t nat -A PREROUTING -p tcp -i eth0 --dport 80 -j DNAT --to 10.0.0.2    
        post-up iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
```

Ahora crearemos la carpeta `.ssh` en el directorio `/root` y le incorporaremos nuestra clave pública:

```
root@router:~# mkdir .ssh

root@router:~# nano .ssh/authorized_keys

ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBkhwPlBiJghsCe5xE4AQBQQIpq7lUrWgFeZATGkIQ0cmQWI55Qy5T3GSLiDjA0+lvw0eWpIYvKigtlBtQNxxFAON4rzL5vSpsm7IAiCRhpGBEXYbuCCVURmcapwd0ifRHt3ocxTfbqtebvA0CfT7GFBkryjS9B26uSJ43/BECxIB3boxkHUAXIHtVpQNXCavoZjm6S6EKGt/8bSWfPtgdFdCu62doN739Nk5RzdrTIw5CdqdUEGuwCMj8fWuePLZkLfmXx1ckwilf0n6U6gG2FV21/wS8BWqVeMcYpmOn6ZxlkDMnVJX+fl7kOLQoyZewrRwJy9P9MuyzXihtmJP89ERcC+kWFrP0/1YbXJ1XZQD1pRXjLJjDHj1th33DBDx77W5DoBAoJlAE7wqf50wCVSyiVEK91IhevSMmFbxOmhGPAh6BiYXx8QNo1sDLsvfQOEoCE5XRWJ+sn8coEULnY7igEbbaiQcVA8YpqM3PrxaBTAb4Gez+48nAP4sf3N8= dparrales@debian
```

Si salimos de la máquina ya podemos entrar por ssh:

![img_1.png](/images/practica_contenedores_LXC/img_1.png)

Comprobemos si se han limitado de forma correcta los recursos:

![img_2.png](/images/practica_contenedores_LXC/img_2.png)

Ahora entremos en el contenedor `servidor_web`:

```
lxc-attach servidor_web
```

Aquí configuraremos también en primer lugar el fichero `/etc/netplan/10-lxc.yaml`:

```
root@servidorweb:/# vim /etc/netplan/10-lxc.yaml

network:
  ethernets:
    eth0:  
      addresses:
        - 10.0.0.2/24
      gateway4: 10.0.0.1
  version: 2
```

Y añadimos la clave pública ssh al igual que hicimos con el contendedor "router":

```
root@servidorweb:/# apt install nano
root@servidorweb:/# mkdir ~/.ssh

root@servidorweb:/# nano ~/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBkhwPlBiJghsCe5xE4AQBQQIpq7lUrWgFeZATGkIQ0cmQWI55Qy5T3GSLiDjA0+lvw0eWpIYvKigtlBtQNxxFAON4rzL5vSpsm7IAiCRhpGBEXYbuCCVURmcapwd0ifRHt3ocxTfbqtebvA0CfT7GFBkryjS9B26uSJ43/BECxIB3boxkHUAXIHtVpQNXCavoZjm6S6EKGt/8bSWfPtgdFdCu62doN739Nk5RzdrTIw5CdqdUEGuwCMj8fWuePLZkLfmXx1ckwilf0n6U6gG2FV21/wS8BWqVeMcYpmOn6ZxlkDMnVJX+fl7kOLQoyZewrRwJy9P9MuyzXihtmJP89ERcC+kWFrP0/1YbXJ1XZQD1pRXjLJjDHj1th33DBDx77W5DoBAoJlAE7wqf50wCVSyiVEK91IhevSMmFbxOmhGPAh6BiYXx8QNo1sDLsvfQOEoCE5XRWJ+sn8coEULnY7igEbbaiQcVA8YpqM3PrxaBTAb4Gez+48nAP4sf3N8= dparrales@debian
```

Ahora comprobemos si se puede entrar por ssh (a través de la máquina router):

![img_3.png](/images/practica_contenedores_LXC/img_3.png)

Una vez que ya tenemos añadida la clave ssh, cambiamos la configuración de ssh (en las dos máquinas) para hacer que el usuario root puede entrar con la clave ssh pero no por contraseña:

```
root@servidorweb:~# nano /etc/ssh/sshd_config
PermitRootLogin prohibit-password
```

```
root@router:~# nano /etc/ssh/sshd_config
PermitRootLogin prohibit-password
```

Veamos también si la limitación de resursos se ha aplicado:

![img_4.png](/images/practica_contenedores_LXC/img_4.png)

La regla SNAT funciona también:

![img_5.png](/images/practica_contenedores_LXC/img_5.png)

Ahora instalamos nginx:

```
root@servidorweb:~# apt install nginx
```

Creamos el directorio `/var/www/pagina` y lo configuramos nginx para que use ese directorio:

```
root@servidorweb:~# mkdir /var/www/pagina
root@servidorweb:~# nano /etc/nginx/sites-available/default

root /var/www/pagina;
```

Ahora salimos del contenedor para modificar su fichero de configuración y hacer que monte el directorio `/opt/pagina` de mi anfitrión en el directorio `/var/www/pagina` de mi máquina contenedor:

```
nano /var/lib/lxc/servidor_web/config

# Montamos el directorio en el contenedor
lxc.mount.entry=/opt/pagina var/www/pagina none bind 0 0
```

Antes de reiniciar la máquina para aplicar los cambios, veamos que contiene dicho directorio en el anfitrión:

```
cat /opt/pagina/index.html 
<h1>HOLA, ESTO ES UNA PRUEBA DE LXC</h1>
```

Ahora reiniciamos el contenedor e intentamos entrar desde el navegador web (así veremos también si funciona la regla DNAT):

![img_6.png](/images/practica_contenedores_LXC/img_6.png)

Con esto hemos demostrado que funciona correctamente y hemos finalizado en ejercicio.
