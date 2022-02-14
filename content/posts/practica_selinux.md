+++ 
draft = true
date = 2022-02-14T12:54:46+01:00
title = "NFS y Samba en Rocky 8 con SELinux"
description = "NFS y Samba en Rocky 8 con SELinux"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Administración de Sistemas Operativos"]
externalLink = ""
series = []
+++

# Configuración/activación de SELinux

Habilita SELinux en un servidor basado en Rocky y asegúrate que los servicios samba y nfs funcionan correctamente con una configuración estricta y segura de SELinux. 

---------------------------

El escenario consta de dos máquinas basadas en Rocky 8. Una actuará de cliente y otra de servidor, ambas con SELinux activado y en modo enforcing.

En primer lugar tenemos que instalar los paquetes necesarios para los servicios de samba y nfs en el lado del servidor:

```
dnf install samba samba-common samba-client nfs-utils
```

Una vez instalados podemos empezar.

## NFS

Iniciamos y habilitamos el servicio:

```
systemctl start nfs-server.service
systemctl enable nfs-server.service
```

A continuación vamos a crear el directorio que compartiremos a través de nfs:

```
mkdir -p /mnt/nfs/compartir
```

Indicamos en el fichero `/etc/exports` el directorio que queremos compartir:

```
nano /etc/exports

/mnt/nfs/compartir  172.22.0.0/16(rw,sync,no_all_squash,no_root_squash)
```

Debemos ejecutar el siguiente comando para comenzar a exportar los ficheros indicados:

```
exportfs -arv

exporting 172.22.0.0/16:/mnt/nfs/compartir
```

Podemos comprobar que se están exportando de forma adecuada usando el siguiente comando:

```
exportfs  -s
```

![img_1.png](/images/practica_selinux/img_1.png)

Después, debemos permitir que los servicios necesarios (mountd, nfs, rpc-bind) puedan atravesar el firewall de Rocky. Para ello ejecutamos lo siguiente:

```
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --add-service=mountd
firewall-cmd --reload
``` 

Ahora en el lado del cliente, instalamos los paquetes necesarios del cliente nfs:

```
dnf install nfs-utils nfs4-acl-tools
```

Desde el lado del cliente podemos comprobar que recursos está exportando el servidor:

```
showmount -e 172.22.2.196
```

![img_2.png](/images/practica_selinux/img_2.png)

En el cliente, creamos el directorio en el que montaremos el recurso compartido, y lo montamos:

```
mkdir /mnt/nfs

mount -t nfs  172.22.2.196:/mnt/nfs/compartir /mnt/nfs
```

![img_3.png](/images/practica_selinux/img_3.png)

Con esto, ya podríamos escribir en el lado del servidor y aparecería en el cliente:

```
# Ejecutamos esto desde el servidor
echo 'Hola desde el servidor' > /mnt/nfs/compartir/desdeelservidor.txt
```

![img_4.png](/images/practica_selinux/img_4.png)

Y viceversa:

```
# Ejecutamos esto desde el cliente
echo 'Hola desde el cliente' > /mnt/nfs/desdeelcliente.txt
```

![img_5.png](/images/practica_selinux/img_5.png)

Con esto ya hemos demostrado que nfs funciona en un escenario con SELinux habilitado y en modo "enforcing".

## Samba

Antes de ponernos a configurar nada, vamos a hacer un copia de seguridad de la configuración básica:

```
cp /etc/samba/smb.conf /etc/samba/smb.con.bak
```

Ahora crearemos la carpeta que vamos a compartir usando samba, cambiando la propiedad y los permisos según es necesario:

```
mkdir -p /mnt/samba/compartir
chmod -R 0755 /mnt/samba/compartir
chown -R dparrales:dparrales /mnt/samba/compartir
chcon -t samba_share_t /mnt/samba/compartir
```

Y añadimos lo siguiente al fichero de configuración:

```
[Anonymous]
path = /mnt/samba/compartir
browsable =yes
writable = yes
guest ok = yes
read only = no
valid users = dparrales
```

Para comprobar que la configuración es correcta, ejecutamos lo siguiente:

```
testparm
```

![img_6.png](/images/practica_selinux/img_6.png)

A continuación, añadimos al cortafuegos las reglas necesarias para el servicio de samba:

```
firewall-cmd --add-service=samba --zone=public --permanent
firewall-cmd --reload
```

Y habilitamos e iniciamos los servicios de samba:

```
systemctl start smb
systemctl enable smb

systemctl start nmb
systemctl enable nmb
```

En el servidor, tenemos que crear el usuario samba con el que accederemos a los recursos compartidos:

```
smbpasswd -a dparrales

New SMB password:
Retype new SMB password:
Added user dparrales.
```

Ahora en el lado del cliente, para acceder a los recursos compartidos ejecutamos lo siguiente:

```
smbclient --user=dparrales -L //172.22.2.196
```

![img_7.png](/images/practica_selinux/img_7.png)

Para montar dicho directorio en nuestro sistema, ejecutamos lo siguiente:

```
mount -t cifs -o user=dparrales //172.22.2.196/Anonymous /home/usuario/samba
```

Ahora desde el servidor podemos crear un fichero y se verá en el cliente:

```
# En el servidor
touch /mnt/samba/compartir/pruebaservidor.txt
```

![img_8.png](/images/practica_selinux/img_8.png)

Y viceversa:

```
# En el cliente
touch samba/desdeelcliente.txt
```

![img_9.png](/images/practica_selinux/img_9.png)

Con esto hemos comprobado que los servicios NFS y Samba funcionan bien con SELinux activado.
