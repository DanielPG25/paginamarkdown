+++ 
draft = true
date = 2021-12-05T16:58:06+01:00
title = "Sistemas de Ficheros Avanzados (BTRFS)"
description = "Sistemas de Ficheros Avanzados (BTRFS)"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Cloud Computing"]
externalLink = ""
series = []
+++

# Sistemas de ficheros “avanzados” ZFS/Btrfs

Elige uno de los dos sistemas de ficheros “avanzados”.

## Crea un escenario que incluya una máquina y varios discos asociados a ella.
    
## Instala si es necesario el software de ZFS/Btrfs
    
## Gestiona los discos adicionales con ZFS/Btrfs
    
## Configura los discos en RAID, haciendo pruebas de fallo de algún disco y sustitución, restauración del RAID. Comenta ventajas e inconvenientes respecto al uso de RAID software con mdadm.
    
## Realiza ejercicios con pruebas de funcionamiento de las principales funcionalidades: compresión, cow, deduplicación, cifrado, etc.

-------------------------------------------------------------------------

He elegido trabajar con Btrfs.

Para empezar, he creado una instancia en openstack a la cual he asignado cinco volúmenes de 1GB cada uno. Con este escenario inicial, vamos a empezar por instalar btrfs:

```
apt install btrfs-progs
```

Una vez instalado, pasamos a formatear los discos usando este sistema de ficheros:

```
mkfs.btrfs /dev/sdb 
mkfs.btrfs /dev/sdc
mkfs.btrfs /dev/sdd
mkfs.btrfs /dev/sde
mkfs.btrfs /dev/sdf
```

Podemos ver que tienen el formato correcto usando el siguiente comando:

```
lsblk -f
NAME FSTYPE FSVER LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda                                                                         
├─sda1
│    ext4   1.0         cbab3c3f-b0e7-407b-b255-8486e1894520    7.9G    14% /
├─sda14
│                                                                           
└─sda15
     vfat   FAT16       8716-3A9F                             117.8M     5% /boot/efi
sdb  btrfs              2ef5add2-d8d8-4194-857e-5e4e79474c7a                
sdc  btrfs              827be1bc-effa-485b-8160-35339aebba9e                
sdd  btrfs              c82f833a-bf6d-4f29-ad84-0ab18a1dabf0                
sde  btrfs              56418c24-befd-4395-ae97-3e82bda3cddb                
sdf  btrfs              78702368-88aa-48a4-b2b9-23ad84b23799 
```

Una vez que los hemos formateado, podemos empezar a trabajar con ellos. Para empezar, vamos a montar el primer disco en el directorio /mnt:

```
mount /dev/sdb /mnt
```

Una vez hecho esto, podemos usar una de las características de btrfs: añadir volúmenes al sistema de ficheros montado. Para ello, usamos el siguiente comando:

```
btrfs device add -f /dev/sdc /mnt
btrfs device add -f /dev/sdd /mnt
``` 

Como vemos, hemos añadido dos volúmenes al sistema de fichero que habíamos montado en /mnt. Podemos ver las características de dicho sistema usando el siguiente comando:

```
btrfs fi usage /mnt

Overall:
    Device size:           3.00GiB
    Device allocated:        896.00MiB
    Device unallocated:        2.12GiB
    Device missing:          0.00B
    Used:            384.00KiB
    Free (estimated):          2.44GiB  (min: 1.37GiB)
    Free (statfs, df):         2.43GiB
    Data ratio:               1.00
    Metadata ratio:           2.00
    Global reserve:        3.25MiB  (used: 0.00B)
    Multiple profiles:              no

Data,single: Size:320.00MiB, Used:128.00KiB (0.04%)
   /dev/sdb  320.00MiB

Metadata,DUP: Size:256.00MiB, Used:112.00KiB (0.04%)
   /dev/sdc  512.00MiB

System,DUP: Size:32.00MiB, Used:16.00KiB (0.05%)
   /dev/sdb   64.00MiB

Unallocated:
   /dev/sdb  640.00MiB
   /dev/sdc  512.00MiB
   /dev/sdd    1.00GiB
```

Nos muestra información sobre el sistema de ficheros, incluyendo el espacio total, el disponible, volúmenes que lo forman, etc. Tras añadir nuevos dispositivos al sistema de ficheros, es conveniente equilibrar el almacenamiento, para lo que usaríamos el siguiente comando:

```
btrfs balance start /mnt
```

Con esto se han repartido los ficheros entre los discos que acabamos de introducir. Otra características de btrfs es que es capaz de crear dispositivos RAID sin necesidad de hacer uso de mdadm. Para ello volveremos a hacer uso de "balance", pero esta indicando que queremos que lo convierta en raid 1:

```
btrfs balance start -dconvert=raid1 -mconvert=raid1 /mnt
```

Si volvemos a ver la información del sistema de ficheros, vemos que nos indica que es un RAID 1:

```
btrfs fi usage /mnt

Overall:
    Device size:           5.00GiB
    Device allocated:          2.62GiB
    Device unallocated:        2.38GiB
    Device missing:          0.00B
    Used:            640.00KiB
    Free (estimated):          2.19GiB  (min: 2.19GiB)
    Free (statfs, df):         1.72GiB
    Data ratio:               2.00
    Metadata ratio:           2.00
    Global reserve:        3.25MiB  (used: 0.00B)
    Multiple profiles:              no

Data,RAID1: Size:1.00GiB, Used:192.00KiB (0.02%)
   /dev/sdb  512.00MiB
   /dev/sdc  512.00MiB
   /dev/sdd  512.00MiB
   /dev/sde  512.00MiB

Metadata,RAID1: Size:256.00MiB, Used:112.00KiB (0.04%)
   /dev/sdc  256.00MiB
   /dev/sdd  256.00MiB

System,RAID1: Size:64.00MiB, Used:16.00KiB (0.02%)
   /dev/sdb   32.00MiB
   /dev/sdd   64.00MiB
   /dev/sde   32.00MiB

Unallocated:
   /dev/sdb  480.00MiB
   /dev/sdc  256.00MiB
   /dev/sdd  192.00MiB
   /dev/sde  480.00MiB
   /dev/sdf    1.00GiB

```

Si en algún momento algún disco falla y tenemos que reemplazarlo, haremos lo siguiente (supongamos que el disco que falla es /dev/sdc):

* En primer lugar, montamos el sistema de ficheros en modo degradado:

```
mount -o degraded /dev/sdb /mnt
```

* Buscamos el "devid" del disco que falla (en este caso el 2, ya que hemos dicho que es el dispositivo /dev/sdc):

```
btrfs filesystem show /mnt       
Label: none  uuid: 2ef5add2-d8d8-4194-857e-5e4e79474c7a
    Total devices 5 FS bytes used 352.00KiB
    devid    1 size 1.00GiB used 0.00B path /dev/sdb
    devid    2 size 1.00GiB used 768.00MiB path /dev/sdc
    devid    3 size 1.00GiB used 288.00MiB path /dev/sdd
    devid    4 size 1.00GiB used 544.00MiB path /dev/sde
    devid    5 size 1.00GiB used 0.00B path /dev/sdf
```

* Reemplazamos el disco dañado por el nuevo:

```
btrfs replace start -B 2 /dev/sdf /mnt
```

* Podemos ver el proceso de reemplazo:

```
btrfs replace status /mnt
```

Con esto hemos reemplazado el disco que falla con el disco nuevo.

Como vemos hemos montado un RAID 1 de forma rápida y sin complicaciones. Tampoco hemos tenido que instalar ningún software como mdadm para generar el raid y podemos ampliarlo de manera más rápida y cómoda que con mdadm. También hay que tener en cuenta que brtfs comprueba si hay datos corruptos y los intenta arreglar, mientras que si usáramos mdadm, tendríamos que localizar e intentar corregir los datos por nuestra cuenta. Otro punto a tener en cuenta en cuanto a brtfs, es que podemos crear RAIDs con discos de diferentes tamaños, cosa que no nos permite mdadm. Sin embargo, mdadm tiene un mejor rendimiento y ofrece estabilidad.

Una vez explicado lo anterior, vamos a seguir probando las funcionalidades de btrfs:

## Compresión:

Por defecto. btrfs no usa ningún método de compresión ya que tenemos que indicarle cual usar (se indica durante el montaje). Así pues probemos con diferentes métodos, entre otros:

* ZLIB:

Este método es capaz de comprimir un gran fichero en poco tamaño. Para hacer la prueba, vamos a usar el siguiente comando para generar un fichero de gran tamaño:

```
mount -o compress=zlib /dev/sdb /mnt

dd if=/dev/zero of=/mnt/prueba count=3072 bs=1048576
```

Pasado un tiempo, comprobamos el tamaño del fichero creado:

```
ls -lh /mnt/
total 3.0G
-rw-r--r-- 1 root root 3.0G Dec  4 12:29 prueba
```

Como vemos, se ha creado un fichero de 30GB. Ahora veamos cuanto ocupa dicho fichero según btrfs:

```
btrfs fi usage /mnt
Overall:
    Device size:           5.00GiB
    Device allocated:        630.38MiB
    Device unallocated:        4.38GiB
    Device missing:          0.00B
    Used:            104.14MiB
    Free (estimated):          4.79GiB  (min: 2.60GiB)
    Free (statfs, df):         4.79GiB
    Data ratio:               1.00
    Metadata ratio:           2.00
    Global reserve:        3.25MiB  (used: 0.00B)
    Multiple profiles:              no

Data,single: Size:512.00MiB, Used:96.14MiB (18.78%)
   /dev/sdf  512.00MiB

Metadata,DUP: Size:51.19MiB, Used:3.98MiB (7.78%)
   /dev/sdb  102.38MiB

System,DUP: Size:8.00MiB, Used:16.00KiB (0.20%)
   /dev/sdb   16.00MiB

Unallocated:
   /dev/sdb  905.62MiB
   /dev/sdc    1.00GiB
   /dev/sdd    1.00GiB
   /dev/sde    1.00GiB
   /dev/sdf  512.00MiB
```

De esta forma, podemos observar que usando zlib, btrfs es capaz de comprimir un fichero de 3GB en 104MB, lo que es bastante impresionante.

* LZO:

Al igual que con zlib, debemos especificar el modo de compresión al montar el dispositivo:

```
mount -o compress=lzo /dev/sdb /mnt
```

Ahora volveremos a crear un fichero de 30GB:

```
dd if=/dev/zero of=/mnt/prueba.txt count=3072 bs=1048576
```

Y volvemos a comprobar el tamaño usado:

```
btrfs fi usage /mnt
Overall:
    Device size:           5.00GiB
    Device allocated:        630.38MiB
    Device unallocated:        4.38GiB
    Device missing:          0.00B
    Used:            104.24MiB
    Free (estimated):          4.79GiB  (min: 2.60GiB)
    Free (statfs, df):         4.79GiB
    Data ratio:               1.00
    Metadata ratio:           2.00
    Global reserve:        3.25MiB  (used: 0.00B)
    Multiple profiles:              no

Data,single: Size:512.00MiB, Used:96.15MiB (18.78%)
   /dev/sdf  512.00MiB

Metadata,DUP: Size:51.19MiB, Used:4.03MiB (7.88%)
   /dev/sdb  102.38MiB

System,DUP: Size:8.00MiB, Used:16.00KiB (0.20%)
   /dev/sdb   16.00MiB

Unallocated:
   /dev/sdb  905.62MiB
   /dev/sdc    1.00GiB
   /dev/sdd    1.00GiB
   /dev/sde    1.00GiB
   /dev/sdf  512.00MiB
```

En esta ocasión, el tamaño usado es algo mayor, pero no es una diferencia apreciable.

## Copy on Write (COW)

La técnica "copy on write" sirve para que al copiar un fichero, este realmente no se copia, sino que se crean punteros que apuntan al fichero original. Solo cuando se producen cambios sobre ese fichero, se crea realmente la copia. Para probar esto, vamos a crear un fichero y comprobar el tamaño que ocupa en el disco:

```
dd if=/dev/zero of=/mnt/prueba bs=2048 count=200k
```

```
ls -lh /mnt/
total 400M
-rw-r--r-- 1 root root 400M Dec  4 15:14 prueba
```

Este fichero ocupa lo siguiente en el sistema de ficheros:

```
btrfs fi usage /mnt
Overall:
    Device size:           5.00GiB
    Device allocated:          1.06GiB
    Device unallocated:        3.94GiB
    Device missing:          0.00B
    Used:             14.26MiB
    Free (estimated):          4.42GiB  (min: 2.46GiB)
    Free (statfs, df):         4.42GiB
    Data ratio:               1.00
    Metadata ratio:           2.00
    Global reserve:        3.25MiB  (used: 0.00B)
    Multiple profiles:              no

Data,single: Size:512.00MiB, Used:12.70MiB (2.48%)
   /dev/sdc  512.00MiB

Metadata,DUP: Size:256.00MiB, Used:784.00KiB (0.30%)
   /dev/sde  512.00MiB

System,DUP: Size:32.00MiB, Used:16.00KiB (0.05%)
   /dev/sdf   64.00MiB

Unallocated:
   /dev/sdb    1.00GiB
   /dev/sdc  512.00MiB
   /dev/sdd    1.00GiB
   /dev/sde  512.00MiB
   /dev/sdf  960.00MiB
```

Unos 14.26MiB. Ahora realizaremos una copia, y como tiene activado el CoW, no debería aumentar el tamaño, ya que no hemos realizado ningún cambio. Para realizar una copia con estas características usamos el parámetro '--reflink=always':

```
cp --reflink=always /mnt/prueba /mnt/prueba2
```

Ahora comprobemos que el espacio usado no es el doble, ya que realmente no se ha copiado el fichero:

```
btrfs fi usage /mnt
Overall:
    Device size:           5.00GiB
    Device allocated:          1.06GiB
    Device unallocated:        3.94GiB
    Device missing:          0.00B
    Used:             14.73MiB
    Free (estimated):          4.42GiB  (min: 2.46GiB)
    Free (statfs, df):         4.42GiB
    Data ratio:               1.00
    Metadata ratio:           2.00
    Global reserve:        3.25MiB  (used: 0.00B)
    Multiple profiles:              no

Data,single: Size:512.00MiB, Used:12.70MiB (2.48%)
   /dev/sdc  512.00MiB

Metadata,DUP: Size:256.00MiB, Used:1.00MiB (0.39%)
   /dev/sde  512.00MiB

System,DUP: Size:32.00MiB, Used:16.00KiB (0.05%)
   /dev/sdf   64.00MiB

Unallocated:
   /dev/sdb    1.00GiB
   /dev/sdc  512.00MiB
   /dev/sdd    1.00GiB
   /dev/sde  512.00MiB
   /dev/sdf  960.00MiB
```

Como vemos, ha funcionado como es debido.

## Deduplicación

La deduplicación consiste en buscar ficheros que se han escrito dos o más veces en el disco (como al copiar un fichero) y combinarlos en un solo fichero, creado punteros en los diferentes directorios que apunten hacia ese único fichero. De esta forma, se intenta maximizar el espacio de disco disponible, al no tener la misma información escrita más de una vez.

Para poder hacer uso de esta funcionalidad, es necesario instalar un paquete adicional:

```
apt install duperemove
```

Ahora volvemos a crear un fichero:

```
dd if=/dev/zero of=/mnt/prueba2 bs=2048 count=50k
```

Vemos cuanto ocupa el fichero que hemos creado:

```
btrfs fi usage /mnt
Overall:
    Device size:           5.00GiB
    Device allocated:        638.38MiB
    Device unallocated:        4.38GiB
    Device missing:          0.00B
    Used:            100.20MiB
    Free (estimated):          4.69GiB  (min: 2.50GiB)
    Free (statfs, df):         4.68GiB
    Data ratio:               1.00
    Metadata ratio:           2.00
    Global reserve:        3.25MiB  (used: 0.00B)
    Multiple profiles:              no

Data,single: Size:520.00MiB, Used:199.75MiB (38.41%)
   /dev/sdg    8.00MiB
   /dev/sdh  512.00MiB

Metadata,DUP: Size:51.19MiB, Used:368.00KiB (0.70%)
   /dev/sdg  102.38MiB

System,DUP: Size:8.00MiB, Used:16.00KiB (0.20%)
   /dev/sdg   16.00MiB

Unallocated:
   /dev/sdg  897.62MiB
   /dev/sdh  512.00MiB
   /dev/sdi    1.00GiB
   /dev/sdj    1.00GiB
   /dev/sdk    1.00GiB
```

Unos 100 MiB. Ahora vamos a copiarlo:

```
cp /mnt/prueba2 /mnt/prueba_copia

btrfs fi usage /mnt
Overall:
    Device size:           5.00GiB
    Device allocated:        638.38MiB
    Device unallocated:        4.38GiB
    Device missing:          0.00B
    Used:            200.50MiB
    Free (estimated):          4.69GiB  (min: 2.50GiB)
    Free (statfs, df):         4.68GiB
    Data ratio:               1.00
    Metadata ratio:           2.00
    Global reserve:        3.25MiB  (used: 0.00B)
    Multiple profiles:              no

Data,single: Size:520.00MiB, Used:199.75MiB (38.41%)
   /dev/sdg    8.00MiB
   /dev/sdh  512.00MiB

Metadata,DUP: Size:51.19MiB, Used:368.00KiB (0.70%)
   /dev/sdg  102.38MiB

System,DUP: Size:8.00MiB, Used:16.00KiB (0.20%)
   /dev/sdg   16.00MiB

Unallocated:
   /dev/sdg  897.62MiB
   /dev/sdh  512.00MiB
   /dev/sdi    1.00GiB
   /dev/sdj    1.00GiB
   /dev/sdk    1.00GiB
```

Como vemos, el espacio usado se ha duplicado. Ahora usaremos el paquete que hemos descargado antes para hacer la deduplicación:

```
duperemove -d /mnt
Gathering file list...
Using 2 threads for file hashing phase
[1/2] (50.00%) csum: /mnt/prueba_copia
[2/2] (100.00%) csum: /mnt/prueba2
Total files:  2
Total extent hashes: 2
Loading only duplicated hashes from hashfile.
Found 2 identical extents.
Simple read and compare of file data found 1 instances of extents that might benefit from deduplication.
Showing 2 identical extents of length 104857600 with id 19b81479
Start       Filename
0   "/mnt/prueba_copia"
0   "/mnt/prueba2"
Using 2 threads for dedupe phase
[0x55d1c3d260c0] (1/1) Try to dedupe extents with id 19b81479
[0x55d1c3d260c0] Skipping - extents are already deduped.
Comparison of extent info shows a net change in shared extents of: 0
```

Como vemos ha encontrado los ficheros iguales (hice otra copia para más pruebas). Ahora veamos si vuelve a ocupar lo mismo que antes (unos 100MiB):

```
btrfs fi usage /mnt
Overall:
    Device size:           5.00GiB
    Device allocated:        638.38MiB
    Device unallocated:        4.38GiB
    Device missing:          0.00B
    Used:            100.62MiB
    Free (estimated):          4.79GiB  (min: 2.60GiB)
    Free (statfs, df):         4.78GiB
    Data ratio:               1.00
    Metadata ratio:           2.00
    Global reserve:        3.25MiB  (used: 0.00B)
    Multiple profiles:              no

Data,single: Size:520.00MiB, Used:100.12MiB (19.25%)
   /dev/sdg    8.00MiB
   /dev/sdh  512.00MiB

Metadata,DUP: Size:51.19MiB, Used:240.00KiB (0.46%)
   /dev/sdg  102.38MiB

System,DUP: Size:8.00MiB, Used:16.00KiB (0.20%)
   /dev/sdg   16.00MiB

Unallocated:
   /dev/sdg  897.62MiB
   /dev/sdh  512.00MiB
   /dev/sdi    1.00GiB
   /dev/sdj    1.00GiB
   /dev/sdk    1.00GiB
```

Como vemos, ha funcionado, volviendo a ocupar el mismo espacio, ya que ambos ficheros eran idénticos. También podemos comprobar que los dos ficheros siguen ahí, convirtiéndose en un proceso transparente para el usuario:

```
ls -l /mnt/
total 204800
-rw-r--r-- 1 root root 104857600 Dec  4 16:48 prueba2
-rw-r--r-- 1 root root 104857600 Dec  4 16:35 prueba_copia
```

## Redimensión

Btrfs también puede redimensionarse en caliente. Veamos como:

* En primer lugar comprobamos es espacio de que dispone el sistema de ficheros:

```
btrfs filesystem show /mnt/
Label: none  uuid: 8cc177de-d784-4761-9f94-a9f962516417
    Total devices 5 FS bytes used 100.38MiB
    devid    1 size 1.00GiB used 126.38MiB path /dev/sdg
    devid    2 size 1.00GiB used 512.00MiB path /dev/sdh
    devid    3 size 1.00GiB used 0.00B path /dev/sdi
    devid    4 size 1.00GiB used 0.00B path /dev/sdj
    devid    5 size 1.00GiB used 0.00B path /dev/sdk
```

Como vemos hay cinco discos anexados de 1GiB cada uno.

* Reducimos el tamaño del sistema de ficheros:

```
btrfs filesystem resize -500M /mnt/
Resize '/mnt/' of '-500M'
```

Comprobamos si ha funcionado:

```
btrfs filesystem show /mnt/
Label: none  uuid: 8cc177de-d784-4761-9f94-a9f962516417
    Total devices 5 FS bytes used 288.00KiB
    devid    1 size 524.00MiB used 126.38MiB path /dev/sdg
    devid    2 size 1.00GiB used 0.00B path /dev/sdh
    devid    3 size 1.00GiB used 0.00B path /dev/sdi
    devid    4 size 1.00GiB used 0.00B path /dev/sdj
    devid    5 size 1.00GiB used 0.00B path /dev/sdk
```

Se ha reducido de forma correcta. 

* Aumentamos el tamaño:

```
btrfs filesystem resize +500M /mnt/
Resize '/mnt/' of '+500M'

btrfs filesystem show /mnt/
Label: none  uuid: 8cc177de-d784-4761-9f94-a9f962516417
    Total devices 5 FS bytes used 128.00KiB
    devid    1 size 1.00GiB used 126.38MiB path /dev/sdg
    devid    2 size 1.00GiB used 0.00B path /dev/sdh
    devid    3 size 1.00GiB used 0.00B path /dev/sdi
    devid    4 size 1.00GiB used 0.00B path /dev/sdj
    devid    5 size 1.00GiB used 0.00B path /dev/sdk
```

Como vemos, ha vuelto a tener el tamaño anterior.

## Desfragmentación

Debido a singularidad del sistema de ficheros, Btrfs sufre de una fragmentación elevada. Es por ello, que es necesario desfragmentar el disco frecuentemente. Para ello vamos a usar la herramienta que viene incluida con btrfs:

```
btrfs filesystem defrag -r /mnt
```  

Usamos la opción '-r' para indicar que sea recursivo.

## Subvolumen

Btrfs nos permite crear subvolúmenes. Esto es como crear otro sistema de ficheros (puede considerarse también como un directorio con más funcionalidades) dentro del sistema de ficheros. Para poder crear los subvolúmenes debemos ejecutar los siguientes comandos:

```
btrfs subvolume create /mnt/subvolumenprueba
```

Podemos ver el subvolumen que hemos creado:

```
ls -l /mnt
total 0
drwxr-xr-x 1 root root 0 Dec  5 14:22 subvolumenprueba
```

Este subvolumen puede montarse en otros lugares del disco, aunque para ello primero debemos obtener su identificador. Para obtener dicho identificador ejecutamos lo siguiente:

```
btrfs subvolume list /mnt
ID 259 gen 30 top level 5 path subvolumenprueba
```

Como vemos, tenemos el identificador 259. Ahora para montar el subvolumen en otro lado, usamos lo siguiente:

```
mount -o subvolid=259 /dev/sdg /mnt2
```

Con esto ya lo hemos montado en el nuevo directorio. Para borrar un subvolumen, ejecutamos lo siguiente:

```
btrfs subvolume delete /mnt/subvolumenprueba/
```

## Snapshots

Antes dijimos que los subvolúmenes eran directorios con más funcionalidades. Pues bien, esta es una de ellas: podemos hacer snapshots del subvolumen. Para ello vamos a crear otro subvolumen como hicimos en el apartado anterior. También crearemos un fichero dentro del subvolumen para posteriores pruebas:

```
btrfs subvolume create /mnt/subvolumenprueba2
Create subvolume '/mnt/subvolumenprueba2'

dd if=/dev/zero of=/mnt/subvolumenprueba2/prueba.txt count=3072 bs=1048576
```

Ahora crearemos un snapshot de dicho subvolumen:

```
btrfs subvolume snapshot /mnt/subvolumenprueba2/ /mnt/snapshotprueba
Create a snapshot of '/mnt/subvolumenprueba2/' in '/mnt/snapshotprueba'
```

Hemos creado un snapshot en el directorio /mnt:

```
tree /mnt/
/mnt/
├── snapshotprueba
│        └── prueba.txt
└── subvolumenprueba2
    └── prueba.txt

2 directories, 2 files
```

Este snapshot ya funciona como un subvolumen, por lo que podemos montarlo o desmontarlo a nuestro gusto. También podemos recuperar información concreta del snapshot:

```
rm -r /mnt/subvolumenprueba2/prueba.txt

cp /mnt/snapshotprueba2/prueba.txt /mnt/subvolumenprueba2/prueba.txt
```

Con esto hemos recuperado el fichero que hemos borrado. También podemos seleccionar un subvolumen o snapshot para que se monte automáticamente al montar el sistema de ficheros. Para ello, al igual que antes, debemos obtener el identificador del subvolumen o snapshot:

```
btrfs subvolume list /mnt
ID 266 gen 44 top level 5 path subvolumenprueba2
ID 274 gen 41 top level 5 path snapshotprueba
```

En este caso configuraremos el snapshot para que se monte automáticamente en /mnt al montar el sistema de ficheros:

```
btrfs subvolume set-default 274 /mnt
```

Ahora, si desmontamos el sistema de ficheros y lo volvemos a montar, debería haberse montado el snapshot en /mnt:

```
ls -l /mnt
total 3145728
-rw-r--r-- 1 root root 3221225472 Dec  5 14:47 prueba.txt
```
