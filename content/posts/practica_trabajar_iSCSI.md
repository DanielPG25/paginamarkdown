+++ 
draft = true
date = 2021-12-06T17:13:07+01:00
title = "Trabajar con iSCSI"
description = "Trabajar con iSCSI"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Cloud Computing"]
externalLink = ""
series = []
+++

# Trabajar con iSCSI

Configura un escenario donde tengas un servidor que exporte algunos targets por iSCSI y los conecte a diversos clientes, explicando con detalle la forma de trabajar.

* Crea un target con una LUN y conéctala a un cliente GNU/Linux. Explica cómo escaneas desde el cliente buscando los targets disponibles y utiliza la unidad lógica proporcionada, formateándola si es necesario y montándola.
    
* Utiliza systemd mount para que el target se monte automáticamente al arrancar el cliente.
    
* Crea un target con 2 LUN y autenticación por CHAP y conéctala a un cliente windows. Explica cómo se escanea la red en windows y cómo se utilizan las unidades nuevas (formateándolas con NTFS)
    
* El sistema debe funcionar después de un reinicio de las máquinas.

-------------------------------------------------------------------------------------------

Para empezar vamos a describir el escenario:

* Una máquina Debian 11 que funcionará como servidor. Dispone de tres discos asociados de 1GiB cada uno y tiene como ip 192.168.121.188/24.

* Una máquina Debian 11 que funcionará como cliente. Tiene como ip 192.168.121.107/24.

* Una máquina Windows 7 que funcionará como cliente. Tiene como ip 192.168.121.12/24.


Para empezar vamos a crear un target en el servidor con un LUN que posteriormente compartiremos con el cliente Debian. Podemos comprobar que mi máquina servidora tiene los discos anexados que hemos mencionado anteriormente:

```
lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
vda    254:0    0  20G  0 disk 
└─vda1 254:1    0  20G  0 part /
vdb    254:16   0   1G  0 disk 
vdc    254:32   0   1G  0 disk 
vdd    254:48   0   1G  0 disk 
```

Así pues, instalamos el paquete que nos proporcionará las funcionalidades de servidor iSCSI:

```
apt install tgt
```

Una vez instalado, creamos el primer target usando el siguiente comando:

```
tgtadm --lld iscsi --op new --mode target --tid 1 -T iqn.2021-12.servidor:clientedebian
```

Una vez creado el target, procedemos a crear la unidad lógica (LUM) que añadimos al target que acabamos de crear:

```
tgtadm --lld iscsi --op new --mode logicalunit --tid 1 --lun 1 -b /dev/vdb
```

También debemos indicar la interfaz por la vamos a permitir que el target se comparta (en mi caso elijo todas):

```
tgtadm --lld iscsi --op bind --mode target --tid 1 -I ALL
```

Podemos ver los targets que tenemos definidos:

```
tgtadm --lld iscsi --op show --mode target
Target 1: iqn.2021-12.servidor:clientedebian
    System information:
        Driver: iscsi
        State: ready
    I_T nexus information:
    LUN information:
        LUN: 0
            Type: controller
            SCSI ID: IET     00010000
            SCSI SN: beaf10
            Size: 0 MB, Block size: 1
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: null
            Backing store path: None
            Backing store flags: 
        LUN: 1
            Type: disk
            SCSI ID: IET     00010001
            SCSI SN: beaf11
            Size: 1074 MB, Block size: 512
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: rdwr
            Backing store path: /dev/vdb
            Backing store flags: 
    Account information:
    ACL information:
        ALL
```

Ahora podemos hacer permanente la configuración si la exportamos con el siguiente comando:

```
tgt-admin --dump > /etc/tgt/conf.d/servidor_clientedebian.conf
```

Podemos ver el fichero que se ha creado con el anterior comando:

```
cat /etc/tgt/conf.d/servidor_clientedebian.conf 

default-driver iscsi

<target iqn.2021-12.servidor:clientedebian>
    backing-store /dev/vdb
</target>
```

Con esto, hemos acabado en la parte del servidor por ahora. 

## Cliente Debian

En el cliente debian, primero debemos instalar el paquete que usaremos para conectarnos con el servidor iSCSI y utilizar sus targets:

```
apt install open-iscsi
```

Al instalarlo, se genera automáticamente un nombre para el cliente (inicializador) en `/etc/iscsi/initiatorname.iscsi`:

```
cat /etc/iscsi/initiatorname.iscsi

## DO NOT EDIT OR REMOVE THIS FILE!
## If you remove this file, the iSCSI daemon will not start.
## If you change the InitiatorName, existing access control lists
## may reject this initiator.  The InitiatorName must be unique
## for each iSCSI initiator.  Do NOT duplicate iSCSI InitiatorNames.
InitiatorName=iqn.1993-08.org.debian:01:5f8160f0539c
```

Ahora tenemos que descubrir que targets están siendo compartidos por el servidor:

```
iscsiadm --mode discovery --type sendtargets --portal 192.168.121.188
192.168.121.188:3260,1 iqn.2021-12.servidor:clientedebian
```

Una vez que conocemos el nombre del target que se está compartiendo, podemos hacer la conexión:

```
iscsiadm --mode node -T iqn.2021-12.servidor:clientedebian --portal 192.168.121.188 --login

Logging in to [iface: default, target: iqn.2021-12.servidor:clientedebian, portal: 192.168.121.188,3260]
Login to [iface: default, target: iqn.2021-12.servidor:clientedebian, portal: 192.168.121.188,3260] successful.
```

Podemos visualizar las sesiones que tenemos abiertas:

```
iscsiadm -m session

tcp: [1] 192.168.121.188:3260,1 iqn.2021-12.servidor:clientedebian (non-flash)
```

También podemos ver que tenemos disponible el disco que se estaba compartiendo, y podemos hacer lo que queramos con él:

```
lsblk 
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0   1G  0 disk 
vda    254:0    0  20G  0 disk 
└─vda1 254:1    0  20G  0 part /
```

Vamos a montarlo, formatearlo y crear algún fichero en él:

```
mkfs.ext4 /dev/sda
mke2fs 1.46.2 (28-Feb-2021)
Creating filesystem with 262144 4k blocks and 65536 inodes
Filesystem UUID: f14b6627-f901-4960-b406-19c6ad7be27b
Superblock backups stored on blocks: 
    32768, 98304, 163840, 229376

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done
```

```
mount /dev/sda /mnt/iscsi/

lsblk 
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0   1G  0 disk /mnt/iscsi
vda    254:0    0  20G  0 disk 
└─vda1 254:1    0  20G  0 part /
```

```
dd if=/dev/zero of=/mnt/iscsi/prueba bs=2048 count=50k
51200+0 records in
51200+0 records out
104857600 bytes (105 MB, 100 MiB) copied, 0.348157 s, 301 MB/s
```

```
lsblk -f
NAME   FSTYPE FSVER LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda    ext4   1.0         f14b6627-f901-4960-b406-19c6ad7be27b  806.2M    10% /mnt/iscsi
vda                                                                           
└─vda1 ext4   1.0         5767898c-d464-4a3c-8911-6a964518f002   17.5G     5% /
```

Como vemos, podemos trabajar con ese nuevo volumen de forma normal, pudiendo hacer cualquier cosa con él al igual que haríamos con un disco que anexáramos nosotros físicamente. Ahora tenemos que hacer que se monte automáticamente al reiniciar la máquina. Para ello en primer lugar ejecutamos el siguiente comando para hacer que haga el login en el servidor de forma automática:

```
iscsiadm --mode node -T iqn.2021-12.servidor:clientedebian --portal 192.168.121.188 -o update -n node.startup -v automatic
```

Ahora crearemos una unidad systemd para hacer que el montaje se haga de forma automática (también podríamos usar fstab, pero no es lo recomendable actualmente).

```
nano /etc/systemd/system/mnt-iscsi.mount

[Unit]
Description=Primera prueba con iSCSI    

[Mount]
What=/dev/disk/by-uuid/f14b6627-f901-4960-b406-19c6ad7be27b
Where=/mnt/iscsi  
Type=ext4
Options=_netdev

[Install]
WantedBy=multi-user.target
```

Donde:

* "Description": La descripción que queramos darle a la unidad
* "What": Lo que queremos montar, en este caso identificado por el uuid del disco. También podríamos haber indicado el disco como "/dev/sda".
* "Where": El lugar donde los vamos a montar. Debe coincidir con el nombre que demos al fichero. En este caso he decidido montarlo en "/mnt/iscsi", así que el nombre del fichero debe ser "mnt-iscsi.mount".
* "Type": el tipo de sistema de ficheros (es opcional añadir esta línea).
* "Options": opciones del montaje (también es opcional).

Habilitamos la unidad que acabamos de crear:

```
systemctl enable mnt-iscsi.mount
```

Ahora podemos reiniciar la máquina, y debería montarse automáticamente el volumen:

```
reboot

lsblk -f
NAME   FSTYPE FSVER LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda    ext4   1.0         f14b6627-f901-4960-b406-19c6ad7be27b  806.2M    10% /mnt/iscsi
vda                                                                           
└─vda1 ext4   1.0         5767898c-d464-4a3c-8911-6a964518f002   17.5G     5% /
```

## Cliente Windows

Ahora hagamos lo mismo para el cliente Windows. En primer lugar, debemos crear un nuevo target en el servidor:

```
tgtadm --lld iscsi --op new --mode target --tid 2 -T iqn.2021-12.servidor:clientewindows
```

Le añadimos los dos LUMs que nos han indicado:

```
tgtadm --lld iscsi --op new --mode logicalunit --tid 2 --lun 1 -b /dev/vdc

tgtadm --lld iscsi --op new --mode logicalunit --tid 2 --lun 2 -b /dev/vdd
```

Volvemos a indicar la interfaz por la que se compartirá el target:

```
tgtadm --lld iscsi --op bind --mode target --tid 2 -I ALL
```

Ahora crearemos la autentificación CHAP que se nos ha indicado de la siguiente forma:

-Primero creamos la cuenta:

```
tgtadm --lld iscsi --op new --mode account --user dparrales --password dparrales_isc
```

-Después añadimos la cuenta al target indicado:

```
tgtadm --lld iscsi --op bind --mode account --tid 2 --user dparrales
```

Tras haber hecho esto, podemos ver el target que hemos creado:

```
tgt-admin -s
Target 1: iqn.2021-12.servidor:clientedebian
    System information:
        Driver: iscsi
        State: ready
    I_T nexus information:
        I_T nexus: 3
            Initiator: iqn.1993-08.org.debian:01:5f8160f0539c alias: Cliente
            Connection: 0
                IP Address: 192.168.121.107
    LUN information:
        LUN: 0
            Type: controller
            SCSI ID: IET     00010000
            SCSI SN: beaf10
            Size: 0 MB, Block size: 1
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: null
            Backing store path: None
            Backing store flags: 
        LUN: 1
            Type: disk
            SCSI ID: IET     00010001
            SCSI SN: beaf11
            Size: 1074 MB, Block size: 512
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: rdwr
            Backing store path: /dev/vdb
            Backing store flags: 
    Account information:
    ACL information:
        ALL
Target 2: iqn.2021-12.servidor:clientewindows
    System information:
        Driver: iscsi
        State: ready
    I_T nexus information:
    LUN information:
        LUN: 0
            Type: controller
            SCSI ID: IET     00020000
            SCSI SN: beaf20
            Size: 0 MB, Block size: 1
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: null
            Backing store path: None
            Backing store flags: 
        LUN: 1
            Type: disk
            SCSI ID: IET     00020001
            SCSI SN: beaf21
            Size: 1074 MB, Block size: 512
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: rdwr
            Backing store path: /dev/vdc
            Backing store flags: 
        LUN: 2
            Type: disk
            SCSI ID: IET     00020002
            SCSI SN: beaf22
            Size: 1074 MB, Block size: 512
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: rdwr
            Backing store path: /dev/vdd
            Backing store flags: 
    Account information:
        dparrales
    ACL information:
        ALL
```

Ahora lo haremos permanente al igual que hicimos antes:

```
tgt-admin --dump > /etc/tgt/conf.d/servidor_clientedebian.conf
```

Aquí el fichero de configuración que hemos creado:

```
cat /etc/tgt/conf.d/servidor_clientedebian.conf 
default-driver iscsi

<target iqn.2021-12.servidor:clientewindows>
    backing-store /dev/vdc
    backing-store /dev/vdd
    incominguser dparrales dparrales_isc
</target>

<target iqn.2021-12.servidor:clientedebian>
    backing-store /dev/vdb
</target>
```

Con esto hemos finalizado en el lado del servidor. Ahora vayamos al cliente Windows. Busquemos primero el programa del inicializador de iSCSI:

![windows_iniciador.png](/images/practica_trabajar_iSCSI/windows_iniciador.png)

Al abrir el programa, le damos al botón "Discover Portal" en el menú de "Discovery":

![windows_discover.png](/images/practica_trabajar_iSCSI/windows_discover.png)

En el menú que se nos abre indicamos la ip del servidor:

![windows_ip.png](/images/practica_trabajar_iSCSI/windows_ip.png)

Si volvemos al menú de targets, podremos apreciar que ya están los dos que creamos:

![windows_targets.png](/images/practica_trabajar_iSCSI/windows_targets.png)

Si intentamos conectarnos se nos abrirá el siguiente menú, en el que tenemos que darle a "Advanced" para introducir las credenciales que creamos antes:

![windows_targets2.png](/images/practica_trabajar_iSCSI/windows_targets2.png)

![windows_targets3.png](/images/practica_trabajar_iSCSI/windows_targets3.png)

Ahora podemos comprobar que se han añadido dos nuevos discos en el gestor de discos duros:

![windows_discos.png](/images/practica_trabajar_iSCSI/windows_discos.png)

Ahora le damos el formato adecuado:

![windows_discos2.png](/images/practica_trabajar_iSCSI/windows_discos2.png)

A la hora de conectarnos por primera vez, ya le indicamos que intentara montar el target cada vez que reiniciara la máquina, por lo que podemos decir que la configuración del cliente Windows ha finalizado.
