+++ 
draft = true
date = 2021-10-07T18:03:08+02:00
title = "Compilación de un paquete escrito en C"
description = "Compilación de un paquete escrito en C"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Administración de Sistemas Operativos"]
externalLink = ""
series = []
+++

# Compilación de un programa en C utilizando un Makefile

Empezamos eligigiendo un paquete basado en C de la librería de paquetes de Debian. En mi caso, he elegido lvm2. Para descargar sus fuentes usamos lo siguiente (previamente hemos creado un directorio en /opt al que hemos llamado lvm):

```
mkdir /opt/lvm && cd /opt/lvm

apt source lvm2
```

Para compilar el paquete hemos de instalar primero las dependencias. Para ello podemos instalar todos los paquetes que aparecen en la línea build-depends del fichero .src que hemos descargado, o podemos usar el siguiente comando:

```
apt build-dep lvm2
```

Una vez hecho esto ya podemos entrar en la carpeta que se ha descargado, en mi caso llamada "lvm2-2.03.11" y ejecutamos lo siguiente:

```
./configure
```

Con este comando, se comprueba si todas las dependencias están cubiertas, y si es así, genera el fichero Makefile necesario para la compilación. Así pues, una vez que haya finalizado ejecutamos lo siguiente:

```
make

make install
```

Con esto ya estaría instalado el paquete. Para comprobarlo podemos intentar ejecutar el comando y tabular. Si completa la información del comando, es que el paquete se ha instalado con éxito:

![lvm.png](/images/lvm.png)

Ahora podemos limpiar los ficheros que no necesitemos con el siguiente comando:

```
make clean
```

También podemos desinstalar el paquete (si lo permite su Makefile) con el siguiente comando:

```
make uninstall
```

## También podemos usar las fuentes para crear un paquete .deb e instalarlo con dpkg

Para ello, vamos a necesitar dos paquetes primero:

```
apt install dpkg-dev devscripts
```

Ahora, al igual que antes, creamos un directorio en el que guardaremos las fuentes del paquete y nos aseguramos de que sus dependecias estén cubiertas:

```
mkdir /opt/lvm && cd /opt/lvm

apt source lvm2

apt build-dep lvm2
```

Una vez que hayamos modificado los archivos que necesitemos, procedemos a crear el fichero .deb:

```
dpkg-buildpackage -rfakeroot -b -uc -us
```

Estará un tiempo creando el paquete, y cuando termine el fichero .deb estará en el directorio padre

![paquetedeb.png](/images/paquetedeb.png)

Ahora solo debemos instalarlo con dpkg:

```
dpkg -i lvm2_2.03.11-2.1_amd64.deb 

Selecting previously unselected package lvm2.
(Reading database ... 44411 files and directories currently installed.)
Preparing to unpack lvm2_2.03.11-2.1_amd64.deb ...
Unpacking lvm2 (2.03.11-2.1) ...
Setting up lvm2 (2.03.11-2.1) ...
update-initramfs: deferring update (trigger activated)
Created symlink /etc/systemd/system/sysinit.target.wants/blk-availability.service → /lib/systemd/system/blk-availability.service.
Created symlink /etc/systemd/system/sysinit.target.wants/lvm2-monitor.service → /lib/systemd/system/lvm2-monitor.service.
Created symlink /etc/systemd/system/sysinit.target.wants/lvm2-lvmpolld.socket → /lib/systemd/system/lvm2-lvmpolld.socket.
Processing triggers for initramfs-tools (0.140) ...
update-initramfs: Generating /boot/initrd.img-5.10.0-8-amd64
Processing triggers for man-db (2.9.4-2) ...
```

Con esto ya está instalado el paquete. Podemos comprobarlo con el siguiente comando:

```
apt policy lvm2

lvm2:
  Installed: 2.03.11-2.1
  Candidate: 2.03.11-2.1
  Version table:
 *** 2.03.11-2.1 500
        500 http://deb.debian.org/debian bullseye/main amd64 Packages
        100 /var/lib/dpkg/status
```
