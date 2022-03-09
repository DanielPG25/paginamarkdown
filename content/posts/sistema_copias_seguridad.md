+++ 
draft = true
date = 2022-02-13T16:41:06+01:00
title = "Sistema de copias de seguridad (Bacula)"
description = "Sistema de copias de seguridad"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Administración de Sistemas Operativos"]
externalLink = ""
series = []
+++

# Sistema de copias de seguridad

Vamos a realizar copias de seguridad de las máquinas que tenemos en el escenario (Zeus, Apolo, Hera y Ares). Para ello vamos a crear un nuevo volumen en Ares en el que se guardarán las copias de seguridad y vamos a usar la herramienta "Bacula" para realizar y gestionar dichas copias de seguridad.

## Bacula

Bacula es un conjunto de programas que permite al administrador de sistemas gestionar las copias de seguridad, su recuperación y comprobación de los datos en una red de dispositivos. Bacula puede funcionar también en un solo dispositivo, y puede hacer las copias de seguridad en diferentes tipos de dispositivos (incluyendo discos y cintas).

Es un programa basado en el sistema "Cliente/Servidor", por lo que es relativamente fácil de usar y eficiente, a la vez que ofrece una gestión avanzada de copias de seguridad, como encontrar y restaurar ficheros perdidos o dañados. Debido a su diseño modular, "Bacula" es escalable, por lo que podemos pasar de gestionar una serie de dispositivos en una pequeña red a cientos de dispositivos en una red amplia.

### Componentes de Bacula

* **Bacula Director:** Es el programa que supervisa todas las operaciones relacionadas con las copias de seguridad, restauración, verificación y archivado. El administrador usa el "Director" para programar las copias de seguridad y recuperar ficheros. Funciona como un "demonio", es decir, en segundo plano.

* **Bacula Console:** Es el programa que permite al administrador de sistemas comunicarse con el director. Generalmente se usa la consola de comandos, aunque también existen aplicaciones gráficas tanto en Windows como en Linux.

* **Bacula File:** También conocido como el programa del cliente, es el software que debe ser instalado y configurado en el lado del cliente. Este software proporcionará al Director la información que necesite para realizar sus operaciones, y es por tanto, dependiente del sistema operativo que use el cliente. 

* **Bacula Storage:** Es el software que se encarga de realizar el almacenamiento y recuperación de ficheros en los dispositivos de almacenamiento donde se alacenen dichas copias de seguridad. Funciona como un "demonio" en la máquina donde está dicho(s) dispositivo(s) de almacenamiento.

* **Catalog:** Hace referencia al software que se encargará de mantener los índices de los ficheros y las bases de datos de los volúmenes, es decir, hace referencia al sistema gestor de base de datos en el que se apoya Bacula. Actualmente permite hacer uso de MariaDB/MySQL y PostgreSQL.

* **Bacula Monitor:** Es el programa que usa el administrador para ver el estado actual de los directores y los demonios del "Bacula Storage" y "Bacula File". Actualmente solo hay disponible una herramienta gráfica que funciona con GNOME, KDE, etc.

### Copias de Seguridad

Como ya hemos mencionado antes, la máquina que actuará como director (y cliente) será Ares, que es la máquina en el escenario que también actúa como servidor de base de datos (con MariaDB). Así pues, en dicha máquina instalamos los siguientes paquetes (si no tuviéramos ya instalada la base de datos, también habría que instalarla):

```
apt install bacula bacula-common-mysql bacula-director-mysql
```

Durante la instalación nos aparece el siguiente mensaje, al cual responderemos "Yes" para indicar a bacula que vamos a usar MariaDB/MySQL como gestor de base de datos:

![img_1.png](/images/sistema_copias_seguridad/img_1.png)

Tras esto nos preguntará que contraseña queremos usar para la base de datos de Bacula y finalizará la instalación.

Ahora vamos a tener que configurar a "Ares" como director de Bacula, para lo cual tendremos que tocar el fichero de configuración, ubicado en `/etc/bacula/bacula-dir.conf`. En este fichero hay varios bloques de información, por lo que vamos a ir definiendo un poco cada uno:

```
nano /etc/bacula/bacula-dir.conf

Director {                             
  Name = ares-dir
  DIRport = 9101                 
  QueryFile = "/etc/bacula/scripts/query.sql"
  WorkingDirectory = "/var/lib/bacula"
  PidDirectory = "/run/bacula"
  Maximum Concurrent Jobs = 20
  Password = "******"          
  Messages = Daemon
  DirAddress = 10.0.1.101
}
```

Este primer bloque define al director. La mayoría de opciones se pueden dejar por defecto por lo que voy a mencionar lo que es cada una de las opciones:

* **Name:** El nombre que tendrá el director.
* **DIRport:** El puerto que usará bacula (9101 por defecto).
* **Password:** La contraseña que se proporcionará a "Bacula Console" para que sea autorizada. Debe ser la misma que aparezca en el recurso "Director" de la configuración del "Bacula Console".
* **QueryFile:** Especifica la ruta del fichero del cual "Bacula Console" obtendrá las sentencias "sql" para el comando `query`.
* **WorkingDirectory:** Especifica el directorio en el cual el Director almacena sus ficheros de estado.
* **PidDirectory:** Especifica el directorio en el cual el Director pone su fichero de información del PID.
* **Maximum Concurrent Jobs:** El número total de trabajos que el Director puede ejecutar de forma concurrente.
* **Messages:** Especifica donde el director debe enviar los mensajes que no estén relacionados con un trabajo concreto.
* **DirAddress:** La dirección ip (y puerto) en la cual el Director escuchará a la "Bacula Console".

Pasemos al segundo bloque de configuración:

```
JobDefs {
  Name = "DefaultJob"
  Type = Backup
  Level = Incremental
  Client = ares-fd
  FileSet = "Full Set"
  Schedule = "WeeklyCycle"
  Storage = File1
  Messages = Standard
  Pool = File
  SpoolAttributes = yes
  Priority = 10
  Write Bootstrap = "/var/lib/bacula/%c.bsr"
}
```

Este bloque llamado "JobDefs" básicamente define platillas de configuración para los trabajos que definamos después, proporcionando valores por defecto para los campos que no especifiquemos directamente en dichos trabajos. Así pues, definamos las diferentes opciones:

* **Name:** Nombre del trabajo.
* **Type:** Tipo del trabajo. Aquí nos encontramos con varias opciones:
    + **Backup:** Realiza una copia de seguridad.
    + **Restore:** Realiza una restauración de las copias.
    + **Verify:** Realiza una comprobación de los ficheros, comparando los ficheros del catálogo y los ficheros del sistema de ficheros.
    + **Admin:** Realiza una eliminación de ficheros del catálogo.
    + **Migration:** Realiza la migración de los datos almacenados en un volumen a otro volumen distinto.
    + **Copy:** Realiza una copia de un "backup" en otro volumen diferente.
* **Level:** Especifica el nivel del trabajo definido en el punto anterior. Nos encontramos los siguientes niveles:
    + **Full:** Realiza un trabajo a nivel completo, es decir, copia todos los ficheros independientemente de si se han producido cambios o no.
    + **Incremental:** Solo almacena los ficheros que hayan sufrido cambios desde la ultima copia (de cualquier tipo). Si no se ha producido una copia completa, este trabajo pasa a realizar una copia completa la primera vez.
    + **Differential:** Realiza una copia de los ficheros que hayan sufrido cambios desde la última copia completa. Si no se ha producido una copia completa, este trabajo pasa a realizar una copia completa la primera vez.
    + **VirtualFull:** Realiza una combinación de los datos de la última copia completa, junto con las modificaciones que haya en copias incrementales y diferenciales, creando así una nueva copia completa que contenga todos los cambios sufridos hasta la fecha de la última copia.
* **Client:** Nombre del cliente del trabajo.
* **FileSet:** Especifica que ficheros serán usados en el trabajo, es decir, los directorios o ficheros que serán copiados y si se va a realizar algún tipo de compresión o no.
* **Schedule:** Indica cuando se realizarán los trabajos indicados.
* **Storage:** Especifica el nombre del servicio del almacenamiento donde almacenaremos las copias.
* **Messages:** Especifica como se enviarán los mensajes del trabajo.
* **Pool:** Indica el "pool" de volúmenes en el que se almacenarán las copias.
* **SpoolAttributes:** Indica si se van a guardar los atributos de la copia en un fichero temporal antes de ser enviados al director, o si se van a mandar directamente mientras se realiza la copia.
* **Priority:** Indica la prioridad del trabajo, siendo 1 la prioridad más alta. Para los trabajos concurrentes, deben tener todos la misma prioridad.
* **Write Bootstrap:** Indica la ruta en la que se escribirá el fichero "bootstrap". Dicho fichero será usado a la hora de restaurar los datos.

Una vez explicadas cada una de las opciones que aparecen por defecto, vamos a crear tres bloques diferentes de "JobDefs", uno para cada tipo de copia (diaria, semanal y mensual):

```
JobDefs {
  Name = "CopiaDiaria"
  Type = Backup
  Level = Incremental
  Client = ares-fd
  FileSet = "Full Set"
  Schedule = "Daily"
  Storage = volcopias
  Messages = Standard
  Pool = Daily
  SpoolAttributes = yes
  Priority = 10
  Write Bootstrap = "/var/lib/bacula/%c.bsr"
}

JobDefs {
  Name = "CopiaSemanal"
  Type = Backup
  Level = Full
  Client = ares-fd
  FileSet = "Full Set"
  Schedule = "Weekly"
  Storage = volcopias
  Messages = Standard
  Pool = Weekly
  SpoolAttributes = yes
  Priority = 10
  Write Bootstrap = "/var/lib/bacula/%c.bsr"
}

JobDefs {
  Name = "CopiaMensual"
  Type = Backup
  Level = Full
  Client = ares-fd
  FileSet = "Full Set"
  Schedule = "Monthly"
  Storage = volcopias
  Messages = Standard
  Pool = Monthly
  SpoolAttributes = yes
  Priority = 10
  Write Bootstrap = "/var/lib/bacula/%c.bsr"
}
```

Con esto hemos terminado de definir las plantillas para cada tipo de copia. A continuación tendremos que crear los "Jobs" que harán uso de estas plantillas (y otras que crearemos más adelante). Por cada cliente vamos a crear tres "Jobs" (uno por cada tipo de copia):

```
# Ares
Job {
  Name = "Ares-Diario"
  Client = "ares-fd"
  JobDefs = "CopiaDiaria"
  FileSet= "Ares-Datos"
}

Job {
  Name = "Ares-Semanal"
  Client = "ares-fd"
  JobDefs = "CopiaSemanal"
  FileSet= "Ares-Datos"
}

Job {
  Name = "Ares-Mensual"
  Client = "ares-fd"
  JobDefs = "CopiaMensual"
  FileSet= "Ares-Datos"
}

# Apolo
Job {
  Name = "Apolo-Diario"
  Client = "apolo-fd"
  JobDefs = "CopiaDiaria"
  FileSet= "Apolo-Datos"
}

Job {
  Name = "Apolo-Semanal"
  Client = "apolo-fd"
  JobDefs = "CopiaSemanal"
  FileSet= "Apolo-Datos"
}

Job {
  Name = "Apolo-Mensual"
  Client = "apolo-fd"
  JobDefs = "CopiaMensual"
  FileSet= "Apolo-Datos"
}

# Hera
Job {
  Name = "Hera-Diario"
  Client = "hera-fd"
  JobDefs = "CopiaDiaria"
  FileSet= "Hera-Datos"
}

Job {
  Name = "Hera-Semanal"
  Client = "hera-fd"
  JobDefs = "CopiaSemanal"
  FileSet= "Hera-Datos"
}

Job {
  Name = "Hera-Mensual"
  Client = "hera-fd"
  JobDefs = "CopiaMensual"
  FileSet= "Hera-Datos"
}

# Zeus
Job {
  Name = "Zeus-Diario"
  Client = "zeus-fd"
  JobDefs = "CopiaDiaria"
  FileSet= "Zeus-Datos"
}

Job {
  Name = "Zeus-Semanal"
  Client = "zeus-fd"
  JobDefs = "CopiaSemanal"
  FileSet= "Zeus-Datos"
}

Job {
  Name = "Zeus-Mensual"
  Client = "zeus-fd"
  JobDefs = "CopiaMensual"
  FileSet= "Zeus-Datos"
}
```

Ahora que hemos creado las tareas de realización de las copias de seguridad, tenemos que realizar también las tareas para que se realice la restauración de los datos si fuera necesario:

```
# Ares
Job {
  Name = "AresRestore"
  Type = Restore
  Client=ares-fd
  Storage = volcopias
  FileSet="Ares-Datos"
  Pool = Backup-Restore
  Messages = Standard
}

# Apolo
Job {
  Name = "ApoloRestore"
  Type = Restore
  Client=apolo-fd
  Storage = volcopias
  FileSet="Apolo-Datos"
  Pool = Backup-Restore
  Messages = Standard
}

# Hera
Job {
  Name = "HeraRestore"
  Type = Restore
  Client=hera-fd
  Storage = volcopias
  FileSet="Hera-Datos"
  Pool = Backup-Restore
  Messages = Standard
}

# Zeus
Job {
  Name = "ZeusRestore"
  Type = Restore
  Client=zeus-fd
  Storage = volcopias
  FileSet="Zeus-Datos"
  Pool = Backup-Restore
  Messages = Standard
}
```

Ahora crearemos en el mismo fichero los bloques que harán refencia a los datos que serán copiados, y si estarán comprimidos o no. Crearemos un bloque por cliente, y un bloque general que será usado si no definimos de forma concreta en los "Jobs" que bloque usar:

```
# Full Set
FileSet {
 Name = "Full Set"
 Include {
   Options {
     signature = MD5
     compression = GZIP
   }
   File = /home
   File = /etc
   File = /var
   File = /usr/share
   File = /usr/local/nagios
 }
 Exclude {
    File = /var/lib/bacula
    File = /nonexistant/path/to/file/archive/dir
    File = /proc
    File = /etc/fstab
    File = /var/run/systemd/generator
    File = /tmp
    File = /sys
    File = /.journal
    File = /.fsck
  }
}

# Zeus
FileSet {
 Name = "Zeus-Datos"
 Include {
   Options {
     signature = MD5
     compression = GZIP
   }
   File = /home
   File = /etc
   File = /var
   File = /usr/share
   File = /usr/local/nagios 
}
 Exclude {
   File = /var/lib/bacula
   File = /nonexistant/path/to/file/archive/dir
   File = /proc
   File = /etc/fstab
   File = /var/run/systemd/generator
   File = /var/cache
   File = /var/tmp
   File = /tmp
   File = /sys
   File = /.journal
   File = /.fsck
 }
}

# Ares
FileSet {
 Name = "Ares-Datos"
 Include {
   Options {
     signature = MD5
     compression = GZIP
   }
   File = /home
   File = /etc
   File = /var
   File = /opt
   File = /usr/share
   File = /usr/local/nagios
 }
 Exclude {
   File = /nonexistant/path/to/file/archive/dir
   File = /proc
   File = /var/cache
   File = /var/tmp
   File = /etc/fstab
   File = /var/run/systemd/generator
   File = /tmp
   File = /sys
   File = /.journal
   File = /.fsck
 }
}

# Apolo (no he excluido /var/cache ya que apolo tiene los datos del dns guardados ahí)
FileSet {
 Name = "Apolo-Datos"
 Include {
   Options {
     signature = MD5
     compression = GZIP
   }
   File = /home
   File = /etc
   File = /var
   File = /opt
   File = /usr/share
   File = /usr/local/nagios
 }
 Exclude {
   File = /var/lib/bacula
   File = /nonexistant/path/to/file/archive/dir
   File = /proc
   File = /etc/fstab
   File = /var/run/systemd/generator
   File = /var/tmp
   File = /tmp
   File = /sys
   File = /.journal
   File = /.fsck
 }
}

# Hera (no he excluido /var/cache ya que hera tiene los datos de la pagina web guardados ahí)
FileSet {
 Name = "Hera-Datos"
 Include {
   Options {
     signature = MD5
     compression = GZIP
   }
   File = /home
   File = /etc
   File = /var
   File = /usr/share
   File = /usr/local/nagios
   File = /run/nagios.lock
 }
 Exclude {
   File = /var/lib/bacula
   File = /nonexistant/path/to/file/archive/dir
   File = /proc
   File = /etc/fstab
   File = /var/run/systemd/generator
   File = /var/tmp
   File = /tmp
   File = /sys
   File = /.journal
   File = /.fsck
 }
}
```

Ahora tenemos que crear los bloques "Schedule", a los que hemos hecho referencia anteriormente, y que definirán cada cuando se realizarán los trabajos:

```
Schedule {
 Name = "Daily"
 Run = Level=Incremental Pool=Daily daily at 12:00
}

Schedule {
 Name = "Weekly"
 Run = Level=Full Pool=Weekly mon at 12:00
}

Schedule {
 Name = "Monthly"
 Run = Level=Full Pool=Monthly 1st mon at 12:00
}
```

A continuación vamos a definir los bloques "Client", en los cuales definiremos los datos de los clientes:

```
# Ares
Client {
 Name = ares-fd
 Address = 10.0.1.101
 FDPort = 9102
 Catalog = MyCatalog
 Password = "bacula"
 File Retention = 60 days
 Job Retention = 6 months
 AutoPrune = yes
}

# Apolo
Client {
 Name = apolo-fd
 Address = 10.0.1.102
 FDPort = 9102
 Catalog = MyCatalog
 Password = "bacula"
 File Retention = 60 days
 Job Retention = 6 months
 AutoPrune = yes
}

# Hera
Client {
 Name = hera-fd
 Address = 172.16.0.200
 FDPort = 9102
 Catalog = MyCatalog
 Password = "bacula"
 File Retention = 60 days
 Job Retention = 6 months
 AutoPrune = yes
}

# Zeus
Client {
 Name = zeus-fd
 Address = 10.0.1.1
 FDPort = 9102
 Catalog = MyCatalog
 Password = "bacula"
 File Retention = 60 days
 Job Retention = 6 months
 AutoPrune = yes
}
```

Donde:

* **Name:** Nombre que hemos dado al cliente (por defecto añade "-fd" al final del nombre, por lo que lo hemos dejado así).
* **Address:** Dirección ip del cliente.
* **FDPort:** Puerto al que se conectará bacula (hemos dejado el que está por defecto).
* **Catalog:** El nombre del catálogo que será usado por el cliente (dejamos el valor por defecto).
* **Password:** Contraseña que usará para conectarse a los clientes. Deberá ser la misma que aparece en los ficheros de configuración de los clientes.
* **File Retention:** El tiempo que permanecerá la información de los ficheros en el catálogo si "Autoprune" está a "Yes". Solo afecta a la información que se guarda en la base de datos, y no afecta a las copias de seguridad en sí.
* **Job Retention:** El tiempo que se guardarán los registros de los trabajos en el catálogo si "Autoprune" está a "Yes". Solo afecta a la información que se guarda en la base de datos, y no afecta a las copias de seguridad en sí.
* **Autoprune:** Si Bacula eliminará de forma automática los registros en el catálogo pasado el tiempo estipulado anteriormente.

Una vez definidos los clientes, vamos a hacer lo mismo con el bloque "Storage", en el cuál especificaremos el tipo de almacenamiento que vamos a tener:

```
Storage {
 Name = volcopias
 Address = 10.0.1.101
 SDPort = 9103
 Password = "bacula"
 Device = FileChgr1
 Media Type = File
 Maximum Concurrent Jobs = 10
}
```

Donde:

* **Name:** Nombre del bloque, al que hemos hecho referencia anteriormente.
* **Address:** Dirección ip de la máquina en la que se almacenarán las copias de seguridad.
* **SDPort:** Puerto que se va a utilizar.
* **Password:** Contraseña que se va a utilizar.
* **Device:** Hacemos referencia al bloque "Device" que configuraremos más adelante, y en el cual definiremos el almacenamiento de forma más detallada.
* **Media Type:** Tipo de medio que se usará para almacenar los datos. Es una cadena de hasta 127 caracteres y podemos escribir lo que queramos (es descriptiva).
* **Maximum Concurrent Jobs:** Número máximo de trabajos concurrentes.

A continuación está el bloque "Catalog", en el cual simplemente describiremos las credenciales de la base de datos que usaremos:

```
Catalog {
  Name = MyCatalog
  dbname = "bacula"; DB Address = "localhost"; DB Port= "3306"; dbuser = "bacula"; dbpassword = "bacula"
}
```

Por último, tenemos el bloque "Pool" en este fichero:

```
Pool {
 Name = Daily
 Pool Type = Backup
 Recycle = yes
 AutoPrune = yes
 Volume Retention = 8d
}

Pool {
 Name = Weekly
 Pool Type = Backup
 Recycle = yes
 AutoPrune = yes
 Volume Retention = 32d
}

Pool {
 Name = Monthly
 Pool Type = Backup
 Recycle = yes
 AutoPrune = yes
 Volume Retention = 365d
}

Pool {
 Name = Backup-Restore
 Pool Type = Backup
 Recycle = yes
 AutoPrune = yes
 Volume Retention = 366 days
 Maximum Volume Bytes = 50G
 Maximum Volumes = 100
 Label Format = "Remoto"
}
```

Donde:

* **Name:** Nombre del Pool.
* **Pool Type:** Define el tipo del "Pool", que debe corresponder con el tipo del trabajo.
* **Recycle:** Si Bacula reusará volúmenes en estado "Purge", es decir, volúmenes cuyos registros hayan caducado por completo.
* **Autoprune:** Si los volúmenes expirarán de forma automática cuando pase el tiempo establecido.
* **VolumeRetention:** El tiempo que permanecerán los registros de los volúmenes en el catálogo.
* **Maximum Volume Bytes:** El máximo de bytes que pueden ser escritos en los volúmenes antes de considerarse llenos.
* **Maximum Volumes:** El máximo de volúmenes que puede contener el "Pool".
* **Label Format:** Etiquetas con las que se crearán los volúmenes.

Con esto hemos finalizado con el fichero `/etc/bacula/bacula-dir.conf`. Podemos comprobar si hay algún error de configuración ejecutando el siguiente comando:

```
bacula-dir -tc /etc/bacula/bacula-dir.conf
```

Si no nos indica ningún error podemos continuar. Antes de continuar añadiendo configuración, crear el volumen donde vamos a guardar las copias de seguridad y darle formato. En mi caso, he decidido crear un volumen de 20GB y anexarlo en Ares.

![img_2.png](/images/sistema_copias_seguridad/img_2.png)

Como vemos, aunque el volumen se encuentre anexado, aun no tiene particiones ni tiene formato. Así pues, he decidido crear una única partición en la que se almacenarán las copias y darle un sistema de ficheros "BTRFS". He elegido este sistema de ficheros ya que se encargará de comprimir automáticamente las copias de seguridad, además de intentar corregir cualquier tipo de corrupción en los ficheros si se diera el caso. También posee otras características que nos serán bastante útiles.

```
gdisk /dev/vdb
GPT fdisk (gdisk) version 1.0.5

Partition table scan:
  MBR: not present
  BSD: not present
  APM: not present
  GPT: not present

Creating new GPT entries in memory.

Command (? for help): n
Partition number (1-128, default 1): 
First sector (34-41943006, default = 2048) or {+-}size{KMGTP}: 
Last sector (2048-41943006, default = 41943006) or {+-}size{KMGTP}: 
Current type is 8300 (Linux filesystem)
Hex code or GUID (L to show codes, Enter = 8300): 
Changed type of partition to 'Linux filesystem'

Command (? for help): w

Final checks complete. About to write GPT data. THIS WILL OVERWRITE EXISTING
PARTITIONS!!

Do you want to proceed? (Y/N): Y
OK; writing new GUID partition table (GPT) to /dev/vdb.
The operation has completed successfully.
```

Ahora con la partición creada, podemos darle el sistema de ficheros que hemos indicado anteriormente. Para ello, primero instalamos los paquetes necesarios:

```
apt install btrfs-progs
```

```
mkfs.btrfs /dev/vdb1
btrfs-progs v5.4.1 
See http://btrfs.wiki.kernel.org for more information.

Label:              (null)
UUID:               17177d8b-3392-4055-9850-f9802452b5ba
Node size:          16384
Sector size:        4096
Filesystem size:    20.00GiB
Block group profiles:
  Data:             single            8.00MiB
  Metadata:         DUP             256.00MiB
  System:           DUP               8.00MiB
SSD detected:       no
Incompat features:  extref, skinny-metadata
Checksum:           crc32c
Number of devices:  1
Devices:
   ID        SIZE  PATH
    1    20.00GiB  /dev/vdb1
```

Ahora, como nos interesa que el volumen se monte cada vez que el sistema arranque, debemos crear una unidad systemd que se encargue de ello. Para ello, primero vamos a crear el directorio en el que queremos que se monte automáticamente:

```
mkdir -p /bacula

chown -R bacula:bacula /bacula/

chmod 755 -R /bacula
```

```
ls -l /
total 2009164
drwxr-xr-x   3 bacula bacula       4096 ene 21 08:15 bacula
```

Ahora creamos la unidad systemd:

```
nano /etc/systemd/system/bacula.mount

[Unit]
Description=Volumen de copias de seguridad   

[Mount]
What=/dev/disk/by-uuid/17177d8b-3392-4055-9850-f9802452b5ba
Where=/bacula  
Type=btrfs
Options=defaults,compress=zlib

[Install]
WantedBy=multi-user.target
```

Y lo habilitamos:

```
systemctl enable bacula.mount
```

Probamos a reinicar ares y comprobar si monta el dispositivo automáticamente:

```
reboot

lsblk -f
NAME   FSTYPE   LABEL                           UUID                                 FSAVAIL FSUSE% MOUNTPOINT
loop0  squashfs                                                                            0   100% /snap/core18/2253
loop1  squashfs                                                                            0   100% /snap/lxd/21835
loop2  squashfs                                                                            0   100% /snap/snapd/14295
loop3  squashfs                                                                            0   100% /snap/snapd/14066
loop4  squashfs                                                                            0   100% /snap/core20/1270
loop5  squashfs                                                                            0   100% /snap/core18/2284
loop6  squashfs                                                                            0   100% /snap/core20/1242
loop7  squashfs                                                                            0   100% /snap/lxd/21029
sr0    iso9660  Ubuntu-Server 20.04.3 LTS amd64 2021-08-24-09-09-05-00                              
vda                                                                                                 
├─vda1                                                                                              
└─vda2 ext4                                     ddee3a0d-c701-46c3-848e-a4f2b177c2fb    3,6G    58% /
vdb                                                                                                 
└─vdb1 btrfs                                    17177d8b-3392-4055-9850-f9802452b5ba   19,5G     0% /bacula
```

Como vemos lo ha montado correctamente. Ahora crearemos un directorio dentro del volumen en el cual almacenaremos las copias de seguridad:

```
mkdir /bacula/backup

chown -R bacula:bacula /bacula/

chmod 755 -R /bacula
```

Con el volumen y el directorio creados y listos, podemos pasar a configurar el fichero `/etc/bacula/bacula-sd.conf`, en el cual definiremos el almacenamiento que usaremos. En este fichero vamos a tener que crear también varios bloques de información, por lo que iremos explicando uno por uno las diferentes opciones que poseen:

```
Storage {
  Name = ares-sd
  SDPort = 9103
  WorkingDirectory = "/var/lib/bacula"
  Pid Directory = "/run/bacula"
  Plugin Directory = "/usr/lib/bacula"
  Maximum Concurrent Jobs = 20
  SDAddress = 10.0.1.101
}
```

En primer lugar tenemos el bloque "Storage", en el cual añadiremos información referente al director:

* **Name:** Nombre del director.
* **SDPort:** Puerto por el que escucha el demonio.
* **Working Directory:** Indica el directorio donde Bacula guardará sus ficheros de estado.
* **Pid Directory:** Indica el directorio donde Bacula guardará sus ficheros de identificación de procesos.
* **Plugin Directory:** Directorio donde bacula almacenará y buscará sus "Plugins".
* **Maximum Concurrent Jobs:** Número máximo de trabajos concurrentes.
* **SDAddress:** Dirección ip del demonio (la misma que la del director).

A continuación crearemos dos bloques "Director", uno para indicar que directores están autorizados a ejecutar el demonio de almacenamiento y otro para indicar los directores que están autorizados a monitorizar el almacenamiento:

```
Director {
  Name = ares-dir
  Password = "bacula"
}

Director {
  Name = ares-mon
  Password = "bacula"
  Monitor = yes
}
```

Por último, están los bloques "Autochanger" y "Device", al cual hicimos referencia en el otro fichero, y el cual configuraremos para que guarde las copias de seguridad en el volumen que creamos y montamos anteriormente (la mayoría de parámetros los he dejado por defecto):

```
Autochanger {
  Name = FileChgr1
  Device = FileStorage
  Changer Command = ""
  Changer Device = /dev/null
}

Device {
  Name = FileStorage
  Media Type = File
  Archive Device = /bacula/backup
  LabelMedia = yes;
  Random Access = Yes;
  AutomaticMount = yes;
  RemovableMedia = no;
  AlwaysOpen = no;
  Maximum Concurrent Jobs = 5
}
```

Donde en "Autochanger":

* **Name:** Indica el nombre del cargador automático (al que hicimos referencia en el primer fichero).
* **Device:** Hace referencia al bloque "Device" que mencionaremos a continuación.
* **Changer Command:** Indicamos el nombre del programa externo al que llamará Bacula para cambiar los volúmenes según sea necesario.
* **Changer Device:** Indicamos el nombre que el sistema de fichero da al cambiador. Si lo indicamos tendrá preferencia sobre el que indicamos antes, por lo que lo hemos dejado como está por defecto.

En el bloque "Device" tenemos:

* **Name:** Nombre del dispositivo al cual hemos hecho referencia en otros bloques, incluido el "Autochanger".
* **Media Type:** Indicamos el tipo de dispositivo en el que guardaremos las copias de seguridad. 
* **Archive Device:** Indicamos el dispositivo en el que guardaremos las copias de seguridad. Como en mi caso es un disco duro montado en el sistema, debo poner la ruta absoluta a dicho directorio.
* **Random Access:** Deberá ser puesto a "yes" para todos los dispositivos que puedan ser accedidos de forma aleatoria, y a "no" para los que no (como las cintas).
* **AutomaticMount:** Si debe intentar montar el dispositivo si no lo está ya (lo dejamos por defecto).
* **RemovableMedia:** Si el dispositivo es extraíble (como un USB).
* **AlwaysOpen:** Si bacula debe dejar siempre el dispositivo abierto, o solo abrirlo cuando vaya a trabajar con él.
* **Maximum Concurrent Jobs:** Número máximo de trabajos concurrentes.

Ahora que hemos terminado con este fichero, comprobemos que no hay errores usando el siguiente comando:

```
bacula-sd -tc /etc/bacula/bacula-sd.conf
```

Si no nos indica ningún error podemos continuar. Así pues, reiniciaremos los servicios que hemos configurado para aplicar los cambios, y los habilitaremos si no lo están ya para que se inicien automáticamente en el arranque:

```
systemctl restart bacula-sd.service
systemctl enable bacula-sd.service
systemctl restart bacula-director.service
systemctl enable bacula-director.service
```

Ahora, en la parte del director solo nos queda configurar un fichero. Ese fichero es `/etc/bacula/bconsole.conf`, y en él tendremos la configuración para poder acceder a la consola del director. En este fichero solo tenemos que modificar el bloque "Director", para indicarle que máquina será el director (ella misma):

```
Director {
  Name = ares-dir
  DIRport = 9101
  address = 10.0.1.101
  Password = "bacula"
}
```

Como ya hemos explicado antes cada uno de esos parámetros, no veo necesario repetirlos. Con esto hemos terminado de configurar el director. Así pues, podemos pasar a configurar los clientes. En cada cliente se repetiran los mismos pasos (salvo en Hera, ya que al ser una máquina con un SO Rocky, tiene incorporado un cortafuegos, por lo que tendremos que abrir los puertos necesarios):

* En Ares:

Como Ares es a la vez director y cliente, tenemos que crear también en él su fichero de configuración de cliente. De esta forma, empezamos por instalar el sofware necesario (que Ares ya lo tiene por ser el director):

```
apt install bacula-client
```

Habilitamos el servicio para que arranque en cada inicio:

```
systemctl enable bacula-fd.service
```

Ahora configuraremos el cliente en el fichero `/etc/bacula/bacula-fd.conf`:

```
Director {
  Name = ares-dir
  Password = "bacula"
}

Director {
  Name = ares-mon
  Password = "bacula"
  Monitor = yes
}

FileDaemon {
  Name = ares-fd
  FDport = 9102
  WorkingDirectory = /var/lib/bacula
  Pid Directory = /run/bacula
  Maximum Concurrent Jobs = 20
  Plugin Directory = /usr/lib/bacula
  FDAddress = 10.0.1.101
}

Messages {
  Name = Standard
  director = ares-dir = all, !skipped, !restored
}
```

Cada uno de estos parámetros ha sido definido anteriormente, por lo que no veo la necesidad de volver a explicarlos. 

Reiniciamos el servico para aplicar los cambios y habríamos terminado con este cliente:

```
systemctl restart bacula-fd.service
```

* En Apolo:

Al igual que Ares, instalamos los paquetes necesarios:

```
apt install bacula-client
```

Habilitamos el servicio para que arranque en cada inicio:

```
systemctl enable bacula-fd.service
```

Configuramos el fichero de cliente (`/etc/bacula/bacula-fd.conf`):

```
Director {
  Name = ares-dir
  Password = "bacula"
}

Director {
  Name = ares-mon
  Password = "bacula"
  Monitor = yes
}

FileDaemon {
  Name = apolo-fd
  FDport = 9102
  WorkingDirectory = /var/lib/bacula
  Pid Directory = /run/bacula
  Maximum Concurrent Jobs = 20
  Plugin Directory = /usr/lib/bacula
  FDAddress = 10.0.1.102
}

Messages {
  Name = Standard
  director = ares-dir = all, !skipped, !restored
}
```

Y reiniciamos el servicio para aplicar los cambios:

```
systemctl restart bacula-fd.service
```

* En Zeus:

Al igual que antes, instalamos los paquetes necesarios:

```
apt install bacula-client
```

Habilitamos el servicio para que arranque en cada inicio:

```
systemctl enable bacula-fd.service
```

Configuramos el fichero de cliente (`/etc/bacula/bacula-fd.conf`):

```
Director {
  Name = ares-dir
  Password = "bacula"
}

Director {
  Name = ares-mon
  Password = "bacula"
  Monitor = yes
}

FileDaemon {
  Name = zeus-fd
  FDport = 9102
  WorkingDirectory = /var/lib/bacula
  Pid Directory = /run/bacula
  Maximum Concurrent Jobs = 20
  Plugin Directory = /usr/lib/bacula
  FDAddress = 10.0.1.1
}

Messages {
  Name = Standard
  director = ares-dir = all, !skipped, !restored
}
```

Y reiniciamos el servicio para aplicar los cambios:

```
systemctl restart bacula-fd.service
```

* En Hera:

Al igual que antes, instalamos los paquetes necesarios:

```
dnf install bacula-client
```

Habilitamos el servicio para que arranque en cada inicio:

```
systemctl enable bacula-fd.service
```

Configuramos el fichero de cliente (`/etc/bacula/bacula-fd.conf`):

```
Director {
  Name = ares-dir
  Password = "bacula"
}

Director {
  Name = ares-mon
  Password = "bacula"
  Monitor = yes
}

FileDaemon {
  Name = hera-fd
  FDport = 9102
  WorkingDirectory = /var/spool/bacula
  Pid Directory = /var/run
  Maximum Concurrent Jobs = 20
  Plugin Directory = /usr/lib64/bacula
}

Messages {
  Name = Standard
  director = ares-dir = all, !skipped, !restored
}
```

Y reiniciamos el servicio para aplicar los cambios:

```
systemctl restart bacula-fd.service
```

No debemos olvidar, que al ser una máquina Rocky, debemos habilitar en el cortafuegos que trae por defecto los puertos necesarios:

```
firewall-cmd --permanent --add-port=9101/tcp

firewall-cmd --permanent --add-port=9102/tcp

firewall-cmd --permanent --add-port=9103/tcp

firewall-cmd --reload
```

Con esto hemos terminado en Hera.

--------------------------

Con esto ya hemos terminado de configurar todos los clientes. Ahora entremos en la consola del director y veamos si puede conectarse con todas las máquinas (reiniciamos los servicios para que vuelva a intentar conectarse):

```
systemctl restart bacula-fd.service

systemctl restart bacula-sd.service

systemctl restart bacula-director.service
```

```
bconsole
Connecting to Director 10.0.1.101:9101
1000 OK: 103 ares-dir Version: 9.4.2 (04 February 2019)
Enter a period to cancel a command.
*status client
The defined Client resources are:
     1: ares-fd
     2: apolo-fd
     3: hera-fd
     4: zeus-fd
     5: vpsdparrales-fd
Select Client (File daemon) resource (1-5): 1
Connecting to Client ares-fd at 10.0.1.101:9102

ares-fd Version: 9.4.2 (04 February 2019)  x86_64-pc-linux-gnu ubuntu 20.04
Daemon started 22-ene-22 16:18. Jobs: run=0 running=0.
 Heap: heap=106,496 smbytes=21,983 max_bytes=22,000 bufs=68 max_bufs=68
 Sizes: boffset_t=8 size_t=8 debug=0 trace=0 mode=0,0 bwlimit=0kB/s
 Plugin: bpipe-fd.so 

Running Jobs:
Director connected at: 22-ene-22 16:21
No Jobs running.
====

Terminated Jobs:
====
You have messages.
*status client
The defined Client resources are:
     1: ares-fd
     2: apolo-fd
     3: hera-fd
     4: zeus-fd
     5: vpsdparrales-fd
Select Client (File daemon) resource (1-5): 2
Connecting to Client apolo-fd at 10.0.1.102:9102

apolo-fd Version: 9.6.7 (10 December 2020)  x86_64-pc-linux-gnu debian bullseye/sid
Daemon started 22-Jan-22 16:03. Jobs: run=0 running=0.
 Heap: heap=0 smbytes=24,380 max_bytes=24,397 bufs=88 max_bufs=88
 Sizes: boffset_t=8 size_t=8 debug=0 trace=0 mode=0,0 bwlimit=0kB/s
 Plugin: bpipe-fd.so 

Running Jobs:
Director connected at: 22-Jan-22 17:22
No Jobs running.
====

Terminated Jobs:
====
*status client
The defined Client resources are:
     1: ares-fd
     2: apolo-fd
     3: hera-fd
     4: zeus-fd
     5: vpsdparrales-fd
Select Client (File daemon) resource (1-5): 3
Connecting to Client hera-fd at 172.16.0.200:9102

hera-fd Version: 9.0.6 (20 November 2017) x86_64-redhat-linux-gnu redhat (Green
Daemon started 22-ene-22 11:18. Jobs: run=0 running=0.
 Heap: heap=114,688 smbytes=21,955 max_bytes=21,972 bufs=68 max_bufs=68
 Sizes: boffset_t=8 size_t=8 debug=0 trace=0 mode=0,0 bwlimit=0kB/s
 Plugin: bpipe-fd.so 

Running Jobs:
Director connected at: 22-ene-22 11:22
No Jobs running.
====

Terminated Jobs:
====
*status client
The defined Client resources are:
     1: ares-fd
     2: apolo-fd
     3: hera-fd
     4: zeus-fd
     5: vpsdparrales-fd
Select Client (File daemon) resource (1-5): 4
Connecting to Client zeus-fd at 10.0.1.1:9102

zeus-fd Version: 9.6.7 (10 December 2020)  x86_64-pc-linux-gnu debian bullseye/sid
Daemon started 22-Jan-22 16:06. Jobs: run=0 running=0.
 Heap: heap=0 smbytes=24,373 max_bytes=24,390 bufs=88 max_bufs=88
 Sizes: boffset_t=8 size_t=8 debug=0 trace=0 mode=0,0 bwlimit=0kB/s
 Plugin: bpipe-fd.so 

Running Jobs:
Director connected at: 22-Jan-22 17:22
No Jobs running.
====

Terminated Jobs:
====
*status client
The defined Client resources are:
     1: ares-fd
     2: apolo-fd
     3: hera-fd
     4: zeus-fd
     5: vpsdparrales-fd
Select Client (File daemon) resource (1-5): 5
Connecting to Client vpsdparrales-fd at 82.223.197.98:9102

vpsdparrales-fd Version: 9.6.7 (10 December 2020)  x86_64-pc-linux-gnu debian bullseye/sid
Daemon started 22-Jan-22 15:18. Jobs: run=0 running=0.
 Heap: heap=106,496 smbytes=24,430 max_bytes=24,447 bufs=88 max_bufs=88
 Sizes: boffset_t=8 size_t=8 debug=0 trace=0 mode=0,0 bwlimit=0kB/s
 Plugin: bpipe-fd.so 

Running Jobs:
Director connected at: 22-Jan-22 16:22
No Jobs running.
====

Terminated Jobs:
====
*
```

Como vemos, ha podido conectarse con todos los clientes, por lo que solo nos queda crear los nodos de almacenamiento donde se guardarán las diferentes copias:

```
root@ares:/home/ares# bconsole
Connecting to Director 10.0.1.101:9101
1000 OK: 103 ares-dir Version: 9.4.2 (04 February 2019)
Enter a period to cancel a command.
*label
Automatically selected Catalog: MyCatalog
Using Catalog "MyCatalog"
The defined Storage resources are:
     1: volcopias
     2: File1
     3: File2
Select Storage resource (1-3): 1
Enter new Volume name: backup-diario
Defined Pools:
     1: Backup-Restore
     2: Daily
     3: Default
     4: File
     5: Monthly
     6: Scratch
     7: Weekly
Select the Pool (1-7): 2
Connecting to Storage daemon volcopias at 10.0.1.101:9103 ...
Sending label command for Volume "backup-diario" Slot 0 ...
3000 OK label. VolBytes=217 VolABytes=0 VolType=1 Volume="backup-diario" Device="FileStorage" (/bacula/backup)
Catalog record for Volume "backup-diario", Slot 0  successfully created.
Requesting to mount FileChgr1 ...
3906 File device ""FileStorage" (/bacula/backup)" is always mounted.
You have messages.
*label
The defined Storage resources are:
     1: volcopias
     2: File1
     3: File2
Select Storage resource (1-3): 1
Enter new Volume name: backup-semanal
Defined Pools:
     1: Backup-Restore
     2: Daily
     3: Default
     4: File
     5: Monthly
     6: Scratch
     7: Weekly
Select the Pool (1-7): 7
Connecting to Storage daemon volcopias at 10.0.1.101:9103 ...
Sending label command for Volume "backup-semanal" Slot 0 ...
3000 OK label. VolBytes=219 VolABytes=0 VolType=1 Volume="backup-semanal" Device="FileStorage" (/bacula/backup)
Catalog record for Volume "backup-semanal", Slot 0  successfully created.
Requesting to mount FileChgr1 ...
3906 File device ""FileStorage" (/bacula/backup)" is always mounted.
*label
The defined Storage resources are:
     1: volcopias
     2: File1
     3: File2
Select Storage resource (1-3): 1
Enter new Volume name: backup-mensual
Defined Pools:
     1: Backup-Restore
     2: Daily
     3: Default
     4: File
     5: Monthly
     6: Scratch
     7: Weekly
Select the Pool (1-7): 5
Connecting to Storage daemon volcopias at 10.0.1.101:9103 ...
Sending label command for Volume "backup-mensual" Slot 0 ...
3000 OK label. VolBytes=220 VolABytes=0 VolType=1 Volume="backup-mensual" Device="FileStorage" (/bacula/backup)
Catalog record for Volume "backup-mensual", Slot 0  successfully created.
Requesting to mount FileChgr1 ...
3906 File device ""FileStorage" (/bacula/backup)" is always mounted.
```

Pasado un tiempo, se habrán hecho varias copias de seguridad:

```
*listjobs

|    98 | Zeus-Semanal         | 2022-02-07 12:00:41 | B    | F     |   23,701 |   263,881,751 | T         |
|    89 | Ares-Semanal         | 2022-02-07 12:00:49 | B    | F     |   32,412 |   827,935,695 | T         |
|    95 | Hera-Semanal         | 2022-02-07 12:00:49 | B    | F     |   52,074 |   481,586,848 | T         |
|    92 | Apolo-Semanal        | 2022-02-07 12:01:10 | B    | F     |   24,207 |   268,954,256 | T         |
|    90 | Ares-Mensual         | 2022-02-07 12:02:41 | B    | F     |   32,412 |   839,713,338 | T         |
|    96 | Hera-Mensual         | 2022-02-07 12:03:02 | B    | F     |   52,074 |   481,586,856 | T         |
|    93 | Apolo-Mensual        | 2022-02-07 12:03:12 | B    | F     |   24,217 |   269,030,930 | T         |
|    99 | Zeus-Mensual         | 2022-02-07 12:03:12 | B    | F     |   23,701 |   263,882,685 | T         |
|   100 | Ares-Diario          | 2022-02-08 12:00:01 | B    | I     |      627 |    75,716,447 | T         |
|   101 | Apolo-Diario         | 2022-02-08 12:00:01 | B    | I     |      592 |    10,099,279 | T         |
|   102 | Hera-Diario          | 2022-02-08 12:00:01 | B    | I     |      545 |   109,235,399 | T         |
|   103 | Zeus-Diario          | 2022-02-08 12:00:03 | B    | I     |       80 |     2,111,967 | T         |
|   104 | Ares-Diario          | 2022-02-09 12:00:01 | B    | I     |      683 |    74,228,785 | T         |
|   105 | Apolo-Diario         | 2022-02-09 12:00:01 | B    | I     |      549 |     3,384,742 | T         |
|   106 | Hera-Diario          | 2022-02-09 12:00:01 | B    | I     |      111 |    30,793,842 | T         |
|   107 | Zeus-Diario          | 2022-02-09 12:03:26 | B    | I     |       89 |     2,324,266 | T         |
|   108 | Ares-Diario          | 2022-02-10 12:00:00 | B    | I     |      582 |    64,543,104 | T         |
|   109 | Apolo-Diario         | 2022-02-10 12:00:00 | B    | I     |      548 |     3,875,511 | T         |
|   110 | Hera-Diario          | 2022-02-10 12:00:00 | B    | I     |       76 |     3,021,143 | T         |
|   111 | Zeus-Diario          | 2022-02-10 12:00:05 | B    | I     |       38 |    24,564,257 | T         |
|   112 | Ares-Diario          | 2022-02-11 12:00:00 | B    | I     |    1,191 |    78,835,304 | T         |
|   113 | Apolo-Diario         | 2022-02-11 12:00:00 | B    | I     |      611 |    32,270,963 | T         |
|   114 | Hera-Diario          | 2022-02-11 12:00:01 | B    | I     |      171 |   106,224,201 | T         |
|   115 | Zeus-Diario          | 2022-02-11 12:00:03 | B    | I     |      395 |    27,664,512 | T         |
|   116 | Ares-Diario          | 2022-02-12 12:00:06 | B    | I     |      562 |    65,017,366 | T         |
```

Como vemos se han creado múltiples copias con el paso de tiempo. Uno de los directorios de los que hemos copia está cifrado. Dentro de zeus, para hacer dicho cifrado, hemos ejecutado lo siguiente: 

```
gpgtar --encrypt --symmetric --output top-secret.gpg --gpg-args="--passphrase=secreto --batch" top-secret
```

Esto generará un fichero `.gpg`, qué será guardado junto con las copias de seguridad. Para desencriptarlo, una vez que hayamos restaurado la copia, ejecutamos lo siguiente:

```
mkdir nosecreto
gpgtar --decrypt --directory nosecreto --gpg-args="--passphrase=secreto --batch" top-secret.gpg
```

De esta forma podemos hacer copias y restaurarlas sobre directorios cifrados. Explicado esto, vamos a indicar como restaurar las copias de seguridad usando el director de bacula. Para ello, vamos a restaurar, por ejemplo, a la máquina zeus (antes hemos tenido que configurar las redes y el cliente bacula en zeus). Así pues, entramos en la consola de bacula y ejecutamos lo siguiente:

```
*restore client=zeus-fd all

First you select one or more JobIds that contain files
to be restored. You will be presented several methods
of specifying the JobIds. Then you will be allowed to
select which files from those JobIds are to be restored.

To select the JobIds, you have the following choices:
     1: List last 20 Jobs run
     2: List Jobs where a given File is saved
     3: Enter list of comma separated JobIds to select
     4: Enter SQL list command
     5: Select the most recent backup for a client
     6: Select backup for a client before a specified time
     7: Enter a list of files to restore
     8: Enter a list of files to restore before a specified time
     9: Find the JobIds of the most recent backup for a client
    10: Find the JobIds for a backup for a client before a specified time
    11: Enter a list of directories to restore for found JobIds
    12: Select full restore to a specified Job date
    13: Cancel
Select item:  (1-13): 
```

Hemos puesto `all` al final del nombre del cliente para indicar que queremos recuperar todos los ficheros. Una vez hecho eso, nos da varias opciones de restauración. En nuestro caso, como suponemos que hemos perdido la máquina origen, elegimos la número 5, que restaurará la copia más reciente:

```
Select item:  (1-13): 5
Automatically selected FileSet: Zeus-Datos
+-------+-------+----------+-------------+---------------------+----------------+
| JobId | Level | JobFiles | JobBytes    | StartTime           | VolumeName     |
+-------+-------+----------+-------------+---------------------+----------------+
|    99 | F     |   23,701 | 263,882,685 | 2022-02-07 12:03:12 | backup-mensual |
|   103 | I     |       80 |   2,111,967 | 2022-02-08 12:00:03 | backup-diario  |
|   107 | I     |       89 |   2,324,266 | 2022-02-09 12:03:26 | backup-diario  |
|   111 | I     |       38 |  24,564,257 | 2022-02-10 12:00:05 | backup-diario  |
|   115 | I     |      395 |  27,664,512 | 2022-02-11 12:00:03 | backup-diario  |
|   119 | I     |       21 |   1,458,903 | 2022-02-12 12:00:08 | backup-diario  |
+-------+-------+----------+-------------+---------------------+----------------+
You have selected the following JobIds: 99,103,107,111,115,119

Building directory tree for JobId(s) 99,103,107,111,115,119 ...  ++++++++++++++++++++++++++++++++++++++++++++++
22,281 files inserted into the tree and marked for extraction.

You are now entering file selection mode where you add (mark) and
remove (unmark) files to be restored. No files are initially added, unless
you used the "all" keyword on the command line.
Enter "done" to leave this mode.

cwd is: /
$ 
```

Como antes hemos indicado `all` al seleccionar el cliente, en este paso podemos indicar `done`, ya que hemos indicado al principio que queremos restaurar todos los ficheros:

```
$ done
Bootstrap records written to /var/lib/bacula/ares-dir.restore.2.bsr

The Job will require the following (*=>InChanger):
   Volume(s)                 Storage(s)                SD Device(s)
===========================================================================
   
    backup-mensual            volcopias                 FileChgr1                
    backup-diario             volcopias                 FileChgr1                

Volumes marked with "*" are in the Autochanger.


24,053 files selected to be restored.

The defined Restore Job resources are:
     1: AresRestore
     2: ApoloRestore
     3: HeraRestore
     4: ZeusRestore
Select Restore Job (1-4): 
```

Ahora elegimos el trabajo de recuperación que queremos usar. Como estamos con zeus, elegiremos el 4:

```
Select Restore Job (1-4): 4
Run Restore job
JobName:         ZeusRestore
Bootstrap:       /var/lib/bacula/ares-dir.restore.2.bsr
Where:           *None*
Replace:         Always
FileSet:         Zeus-Datos
Backup Client:   zeus-fd
Restore Client:  zeus-fd
Storage:         volcopias
When:            2022-02-13 15:09:31
Catalog:         MyCatalog
Priority:        10
Plugin Options:  *None*
OK to run? (yes/mod/no): 
```

Ya solo debemos indicarle que empiece, y el trabajo se añadirá a la cola y se ejecutará. Pasado un tiempo, el trabajo finalizará:

```
*status client=zeus-fd 
Connecting to Client zeus-fd at 10.0.1.1:9102

zeus-fd Version: 9.6.7 (10 December 2020)  x86_64-pc-linux-gnu debian bullseye/sid
Daemon started 13-Feb-22 15:42. Jobs: run=0 running=0.
 Heap: heap=0 smbytes=24,614 max_bytes=24,631 bufs=89 max_bufs=89
 Sizes: boffset_t=8 size_t=8 debug=0 trace=0 mode=0,0 bwlimit=0kB/s
 Plugin: bpipe-fd.so 

Running Jobs:
Director connected at: 13-Feb-22 15:52
No Jobs running.
====

Terminated Jobs:
 JobId  Level    Files      Bytes   Status   Finished        Name 
===================================================================
   120  Rest     24,053    8.605 G  OK       13-Feb-22 15:32 ZeusRestore
====
```

Una vez que hemos finalizado aquí, en la máquina destino ya estarían todos los ficheros que hemos restaurado, incluyendo la configuración de los servicios. Como hemos guardado la lista de paquetes instalados (al haber hecho copia del directorio `/var`), para reinstalar todos los paquetes ejecutamos lo siguiente:

```
apt reinstall ~i
```

Si fuera hera, el comando sería el siguiente:

```
dnf reinstall \*
```

Tras un tiempo, todos los paquetes se habrán instalado otra vez y tras un reinicio, la máquina volverá a estar completamente operativa. Los pasos a seguir serían los mismos en Hera y Apolo, con la excepción de que en Apolo, la configuración de LDAP no se guarda correctamente, por lo que en la copia he exportado la configuración manualmente:

```
slapcat -n 0 -l config_slapd.ldif
```

Dicho fichero contiene toda la configuración de LDAP, por lo que al restaurar Apolo, solo tendremos que reinsertar la configuración a mano y reiniciar el servicio. Con esto podemos dar por finalizada la explicación de como realizar las copias y restaurarlas. Sin embargo, queda la problemática del almacenamiento de las copias a largo plazo. Actualmente tenemos hechas muchas copias, ya la mayoría son muy parecidas, ya que no hemos implementado nuevas funciones en nuestro escenario. No obstante, y con una previsión de futuro, habrá que guardar de forma permanente algunas copias, para poder restaurar el escenario si es necesario. Las copias que se guardarán de forma permanente serán aquellas que se realicen tras una implementación de un nuevo servicio en el escenario, además de una copia completa cada 3 meses que se guardará de forma permanente, para que podamos recuperar los datos de las aplicaciones de forma trimestral.
