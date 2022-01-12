+++ 
draft = true
date = 2022-01-12T14:19:31+01:00
title = "DRBD y OCFS2"
description = "DRBD y OCFS2"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Cloud Computing"]
externalLink = ""
series = []
+++

# DRBD y OCFS2

Configura un escenario con dos máquinas. Cada una tiene que tener dos discos adicionales (tamaño 1Gb para que la sincronización sea rápida).

* Crea dos recursos RDBD: wwwdata y dbdata. Cada uno utilizaran uno de los discos de cada máquina.
* Configura en modo Single-primary el recurso wwwdata.
    * Una vez creado y sincronizado el recurso, formatéalo con XFS.
    * Monta el recurso en el nodo primario y crea un fichero. ¿Se puede montar en el secundario?
    * Desmonta el recurso.
    * Cambia los roles, pon primario el que era secundario, y secundario el primario.
    * Monta el recurso en el que ahora es primario y comprueba que existe el fichero creado anteriormente.
* Configura en modo Dual-primary el recurso dbdata.
    * Una vez creado y sincronizado el recurso, configúralo en modo Dual-primary.
    * Crea un cluster OCFS2.
    * Crea un volumen OCFS2 en el recurso (mkfs.ocfs2).
    * Monta en los nodos el recurso, y prueba a escribir en los dos al mismo tiempo.

--------------------------------------------------------------------

Para empezar vamos a describir el escenario que tenemos montado:

* Dos máquinas en openstack con dos volúmenes de 1GiB asociados a cada una:
    * nodo1: máquina con Debian 11 y con ip 10.0.0.59.
    * nodo2: máquina con Debian 11 y con ip 10.0.0.218.

# Configura en modo Single-primary el recurso wwwdata

Ahora vamos a ir a los dos nodos y vamos a instalar el paquete necesario para utilizar DRBD:

```
apt install drbd-utils
```

Una vez instalado, creamos el fichero que definirá el recurso que vamos a sincronizar entre las máquinas: wwwdata, que se corresponde con el volumen de 1 GiB que ambas máquinas están representados como '/dev/sdc'. Para ello, lo creamos en `/etc/drbd.d/`:

```
nano /etc/drbd.d/wwwdata.res

resource wwwdata { 
  protocol C;
  meta-disk internal;
  device /dev/drbd1;
  syncer {
    verify-alg sha1;
  }
  net {
    allow-two-primaries;
  }
  on nodo1 {
    disk /dev/sdc;
    address 10.0.0.59:7789;
  }
  on nodo2 {
    disk /dev/sdc;
    address 10.0.0.218:7789;
  }
}
```

En el anterior fichero detacamos:

* "Resource": indica el nombre del recurso que vamos a crear, el cual contiene todas las características y dipositivos de bloques que indiquemos entre los corchetes.
* "Protocol": indica el protocolo que vamos a usar. DRBD tiene tres protocolos (A, B, C), siendo el C, el más lento de todos, pero el que garantiza mayor seguridad de los datos.
* "Meta-disk": indicamos donde queremos que el recurso que vamos a crear guarde sus metadatos.
* "Device": indicamos el nombre que tendrá en el sistema el recurso que creemos, en este caso, /dev/drbd1.
* Destacar que al indicar "on nodo1/nodo2" tenemos que indicar el nombre de las máquinas de forma precisa, ya que de lo contrario salta un error.
* También tenemos que indicar el dispositivo de bloques que vamos a sincronizar y la ip de la máquina que lo contiene, acompañado del puerto que usaremos para la sincronización.

Una vez que hemos creado el anterior fichero, vamos a proceder a crear el recurso en ambas máquinas:

```
drbdadm create-md wwwdata 

initializing activity log
initializing bitmap (32 KB) to all zero
Writing meta data...
New drbd meta data block successfully created.
```

```
drbdadm up wwwdata
```

Ahora tenemos que indicar cuál de las dos máquinas será la primaria. En mi caso elegiré el nodo1, en el que ejecutamos el siguiente comando:

```
drbdadm primary --force wwwdata
```

Podemos ver como va la sincronización:

```
drbdadm status wwwdata
wwwdata role:Primary
  disk:UpToDate
  peer role:Secondary
    replication:SyncSource peer-disk:Inconsistent done:76.26
```

Como vemos, aún no están sincronizados (Inconsistent). Cuando haya acabado nos saldrá lo siguiente:

```
drbdadm status wwwdata
wwwdata role:Primary
  disk:UpToDate
  peer role:Secondary
    replication:Established peer-disk:UpToDate
```

Como vemos, nos indica que ya están sincronizados, y además nos indica que en el recurso wwwdata, el nodo1 (máquina en la que he ejecutado el comando) es el primario.

Ahora, tal como nos indican, vamos a dar formato al recurso que acabamos en crear (en el nodo1):

```
apt install xfsprogs

mkfs.xfs /dev/drbd1
```

Ahora lo montamos y creamos algún fichero dentro: 

```
mount /dev/drbd1 /mnt

nano /mnt/prueba.txt

  GNU nano 5.4                                  /mnt/prueba.txt                                           

                      | |__|__|__|__|__|__|__|__|__|_|
 __    __    __       |_|___|___|___|___|___|___|___||       __    __    __
|__|  |__|  |__|      |___|___|___|___|___|___|___|__|      |__|  |__|  |__|
|__|__|__|__|__|       \____________________________/       |__|__|__|__|__|
|_|___|___|___||        |_|___|___|___|___|___|___||        |_|___|___|___||
|___|___|___|__|        |___|___|___|___|___|___|__|        |___|___|___|__|
 \_|__|__|___|/          \________________________/          \_|__|__|__|_/
  \__|____|__/            |___|___|___|___|___|__|            \__|__|__|_/
   |||_|_|_||             |_|___|___|___|___|__|_|             |_|_|_|_||
   ||_|_|||_|__    __    _| _  __ |_ __  _ __  _ |_    __    __||_|_|_|_|
   |_|_|_|_||__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|_|_|_|_||
   ||_|||_|||___|___|___|___|___|___|___|___|___|___|___|___|__||_|_|_|_|
   |_|_|_|_||_|___|___|___|___|___|___|___|___|___|___|___|___||_|_|_|_||
   ||_|_|_|_|___|___|___|___|___|___|___|___|___|___|___|___|__||_|_|_|_|
   |_|||_|_||_|___|___|___|___|___|___|___|___|___|___|___|___||_|_|_|_||
   ||_|_|_|_|___|___|___|___|___|_/| | | \__|___|___|___|___|__||_|_|_|_|
   |_|_|_|_||_|___|___|___|___|__/ |D| | |\___|___|___|___|___||_|_|_|_||
   ||_|_|_|||___|___|___|___|___|| |R| | | |____|___|___|___|__||_|_|_|_|
   |_|_|_|_||_|___|___|___|___|_|| |B| | | |__|___|___|___|___||_|_|_|_||
  /___|___|__\__|___|___|___|___|| |D| | | |____|___|___|___|_/_|___|__|_\
 |_|_|_|_|_|_||___|___|___|___|_|| | | | | |__|___|___|___|__|_|__|__|__|_|
 ||_|_|_|_|_|_|_|___|___|___|___||_|_|_|_|_|____|___|___|____|___|__|__|__|
```

Como hemos establecido que el el nodo primario sea "nodo1", no podemos montar el recurso en el nodo2. Si lo intentamos hacer nos salta el siguiente mensaje:

```
mount /dev/drbd1 /mnt
mount: /mnt: mount(2) system call failed: Wrong medium type.
```

Podríamos hacer que los dos fueran primarios, pero al haber usado un sistema de ficheros xfs, no podríamos tener sincronizados ambos nodos sin que se corrompieran, ya que este sistema de ficheros no lo permite. Para ello usaremos un sistema de ficheros como OCFS2, pero eso será más adelante. Por ahora vamos a desmontar el recurso y vamos a asignar al nodo2 el rol de primario para poder montarlo.

```
umount /mnt

drbdadm secondary wwwdata  -> En el nodo1

drbdadm primary --force wwwdata  -> En el nodo2
```

Una vez que hemos hecho eso, podemos ver que se han cambiado los roles de forma efectiva:

![roles_cambiados.png](/images/DRBD_OCFS2/roles_cambiados.png)

Ahora ya podemos montar el recurso en el nodo2 y ver si el fichero se encuentra ahí:

```
root@nodo2:/home/debian# mount /dev/drbd1 /mnt

root@nodo2:/home/debian# cat /mnt/prueba.txt
                      | |__|__|__|__|__|__|__|__|__|_|
 __    __    __       |_|___|___|___|___|___|___|___||       __    __    __
|__|  |__|  |__|      |___|___|___|___|___|___|___|__|      |__|  |__|  |__|
|__|__|__|__|__|       \____________________________/       |__|__|__|__|__|
|_|___|___|___||        |_|___|___|___|___|___|___||        |_|___|___|___||
|___|___|___|__|        |___|___|___|___|___|___|__|        |___|___|___|__|
 \_|__|__|___|/          \________________________/          \_|__|__|__|_/
  \__|____|__/            |___|___|___|___|___|__|            \__|__|__|_/
   |||_|_|_||             |_|___|___|___|___|__|_|             |_|_|_|_||
   ||_|_|||_|__    __    _| _  __ |_ __  _ __  _ |_    __    __||_|_|_|_|
   |_|_|_|_||__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|_|_|_|_||
   ||_|||_|||___|___|___|___|___|___|___|___|___|___|___|___|__||_|_|_|_|
   |_|_|_|_||_|___|___|___|___|___|___|___|___|___|___|___|___||_|_|_|_||
   ||_|_|_|_|___|___|___|___|___|___|___|___|___|___|___|___|__||_|_|_|_|
   |_|||_|_||_|___|___|___|___|___|___|___|___|___|___|___|___||_|_|_|_||
   ||_|_|_|_|___|___|___|___|___|_/| | | \__|___|___|___|___|__||_|_|_|_|
   |_|_|_|_||_|___|___|___|___|__/ |D| | |\___|___|___|___|___||_|_|_|_||
   ||_|_|_|||___|___|___|___|___|| |R| | | |____|___|___|___|__||_|_|_|_|
   |_|_|_|_||_|___|___|___|___|_|| |B| | | |__|___|___|___|___||_|_|_|_||
  /___|___|__\__|___|___|___|___|| |D| | | |____|___|___|___|_/_|___|__|_\
 |_|_|_|_|_|_||___|___|___|___|_|| | | | | |__|___|___|___|__|_|__|__|__|_|
 ||_|_|_|_|_|_|_|___|___|___|___||_|_|_|_|_|____|___|___|____|___|__|__|__|
```

Efectivamente, el fichero se encuentra ahí, por lo que podemos decir que esta parte de práctica ha sido un éxito.

# Configura en modo Dual-primary el recurso dbdata

El comienzo es el el mismo que en el anterior apartado. Como ya tenemos instalado el paquete necesario, pasamos a crear el fichero de defición del nuevo recurso:

```
nano /etc/drbd.d/dbdata.res

resource dbdata { 
  protocol C;
  meta-disk internal;
  device /dev/drbd2;
  syncer {
    verify-alg sha1;
  }
  net {
    allow-two-primaries;
  }
  on nodo1 {
    disk /dev/sdb;
    address 10.0.0.59:7790;
  }
  on nodo2 {
    disk /dev/sdb;
    address 10.0.0.218:7790;
  }
}
```

Ahora creamos el recurso y lo levantamos:

```
drbdadm create-md dbdata 

drbdadm up dbdata
```

A continuación asignamos a los dos el rol primario:

```
drbdadm primary --force dbdata
```

Como hicimos antes, debemos esperar a que acaben de sincronizarse:

![dos_primarios.png](/images/DRBD_OCFS2/dos_primarios.png)

Ahora que están sincronizados, vamos a crear el cluster con OCFS2. Para ello, en primer lugar, vamos a instalar las herramientas para ello en ambas máquinas:

```
apt install ocfs2-tools
```

Creamos la definición del cluster, que se almacenará en un fichero en `/etc/ocfs2/cluster.conf`:

```
o2cb add-cluster tclust -> Creamos un cluster de nombre tclust

o2cb add-node tclust nodo1 --ip 10.0.0.59
o2cb add-node tclust nodo2 --ip 10.0.0.218 -> Añadimos las máquinas que van a ser parte del cluster
```

Vemos que la configuración que hemos añadido se ha guardado en el fichero indicado anteriormente:

```
cat /etc/ocfs2/cluster.conf 

cluster:
    name = tclust
    heartbeat_mode = local
    node_count = 2

node:
    cluster = tclust
    number = 0
    ip_port = 7777
    ip_address = 10.0.0.59
    name = nodo1

node:
    cluster = tclust
    number = 1
    ip_port = 7777
    ip_address = 10.0.0.218
    name = nodo2
```

Ahora podemos copiar esta configuración a la otra máquina. En este momento ya podemos modificar el fichero `/etc/default/o2cb` para adaptarlo a nuestro escenario:

```
nano /etc/default/o2cb

# O2CB_ENABLED: 'true' means to load the driver on boot.
O2CB_ENABLED=true

# O2CB_BOOTCLUSTER: If not empty, the name of a cluster to start.
O2CB_BOOTCLUSTER=tclust

# O2CB_HEARTBEAT_THRESHOLD: Iterations before a node is considered dead.
O2CB_HEARTBEAT_THRESHOLD=21

# O2CB_IDLE_TIMEOUT_MS: Time in ms before a network connection is considered dead.
O2CB_IDLE_TIMEOUT_MS=15000

# O2CB_KEEPALIVE_DELAY_MS: Max. time in ms before a keepalive packet is sent.
O2CB_KEEPALIVE_DELAY_MS=2000

# O2CB_RECONNECT_DELAY_MS: Min. time in ms between connection attempts.
O2CB_RECONNECT_DELAY_MS=2000
```

Copiamos el contenido de este fichero a la otra máquina para que tengan las dos la misma configuración. También hemos de asegurarnos que el servicio se activa en al iniciar las máquinas:

```
systemctl enable o2cb
systemctl enable ocfs2
```

Debemos registrar el cluster en configfs en ambas máquinas:

```
o2cb register-cluster tclust
```

A continuación podemos iniciar el cluster en ambas máquinas:

```
systemctl start o2cb
```

Para que funcione correctamente, tenemos que modificar algunos parámetros del kernel en ambas máquinas:

```
nano /etc/sysctl.conf

kernel.panic = 30
kernel.panic_on_oops = 1
```

Y aplicamos los cambios:

```
sysctl -p
```

Una que hemos terminado con esto, ya podemos dar un sistema de ficheros al recurso y montarlo:

```
mkfs.ocfs2 --cluster-size 8K -J size=32M -T mail --node-slots 2 --label ocfs2_fs --mount cluster --fs-feature-level=max-features --cluster-stack=o2cb --cluster-name=tclust /dev/drbd2

mount /dev/drbd2 /mnt -> En ambos nodos
```

Ahora podemos probar a crear ficheros en ambos nodos y a escribir en uno de ellos, y debería aparecernos en el otro también:

![escritura_doble.png](/images/DRBD_OCFS2/escritura_doble.png)

Como vemos, en ambas máquinas aparecen todos los fichero y modificaciones que hemos hecho, por lo que podemos concluir que la práctica ha sido un éxito.
