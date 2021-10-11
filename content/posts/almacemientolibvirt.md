# Ejercicios para trabajar con el almacenamiento en libvirt


### Crea un nuevo pool de almacenamiento de tipo lvm, y crea un volumen de 3Gi dentro que sea una volumen lógico. Con virt-install instala una máquina que se llame original_tunombre cuyo disco sea el volumen creado.

Lo primero es crear un fichero .xml que defina el pool de almacenamiento que vamos a crear:

```
<pool type='logical'>
  <name>lvm-pool</name>
  <capacity unit='bytes'>5368709120</capacity>
  <source>
  <name>vg1</name>
  </source>
  <target>
    <path>/home/dparrales/Descargas/pool-lvm</path>
    <permissions>
      <mode>0711</mode>
      <owner>0</owner>
      <group>0</group>
    </permissions>
  </target>
</pool>
```

Después definimos el pool de almacenamiento y lo iniciamos:

```
virsh -c qemu:///system pool-define --file pool_lvm.xml

virsh -c qemu:///system pool-start lvm-pool
```

Ahora creamos el volumen lógico en el pool de almacenamiento:

`
lvcreate -L 3G -n logico1 vg1 
`

Con el volumen creado, ya podemos crear la máquina:

`
virt-install --connect qemu:///system --network network=default --name=original_dparrales --memory 1024 --vcpus 1 --disk /dev/vg1/logico1 --cdrom /var/lib/libvirt/images/debian-10.10.0-amd64-netinst.iso
`

En la siguiente captura, podemos ver que el dominio está usando el volúmen lógico que le hemos asignado antes:

![definicion_dom.png](/images/almacenamientolibvirt/definicion_dom.png)


### Convierte el volumen anterior en un fichero de imagen qcow2 que estará en el pool default.


Para convertir el volumen lógico en qcow2, podemos usar el siguiente comando:

`
qemu-img convert -O qcow2 /dev/vg1/logico1 /var/lib/libvirt/images/original_dparrales.qcow2
`

Nos deja el volumen de la siguiente forma:

![conversion.png](/images/almacenamientolibvirt/conversion.png)


### Crea dos máquinas virtuales (nodo1_tunombre y nodo2_tunombre) que utilicen la imagen construida en el punto anterior como imagen base (aprovisonamiento ligero). Una vez creada accede a las máquinas para cambiarle el nombre.

Lo primero es crear el volumen de aprovisionamiento:

```
qemu-img create -b /var/lib/libvirt/images/original_dparrales.qcow2 -f qcow2 aprovv_dparrales.qcow2

qemu-img create -b /var/lib/libvirt/images/original_dparrales.qcow2 -f qcow2 aprovv2_dparrales.qcow2
```


Lo primero es crear las máquinas con los siguiente comandos:

```
virt-install --connect qemu:///system --network network=default --name=nodo1_dparrales --memory 1024 --vcpus 1 --disk /var/lib/libvirt/images/aprovv_dparrales.qcow2 --import

virt-install --connect qemu:///system --network network=default --name=nodo2_dparrales --memory 1024 --vcpus 1 --disk /var/lib/libvirt/images/aprovv2_dparrales.qcow2 --import
```

Como podemos ver, están usando el disco qcow2 que hemos creado antes:


![nodo1.png](/images/almacenamientolibvirt/nodo1.png)


A continuación una captura que demuestra que el "nodo 2" tiene acceso a internet tras haber configurado las interfaces:


![ping_nodo2.png](/images/almacenamientolibvirt/ping_nodo2.png)


### Transforma la imagen de la máquina nodo1_tunombre a formato raw. Realiza las modificaciones necesarias en la definición de la máquina virtual (virsh edit <maquina>), para que pueda seguir funcionando con el nuevo formato de imagen.


Para cambiar el formato de imagen, ejecutamos el siguiente comando:

`
sudo qemu-img convert ~/aprovv_dparrales.qcow2 /var/lib/libvirt/images/aprovv_dparrales.raw
`

Ahora hay que cambiar la definición del dominio para que use el nuevo disco. Para ello usamos el siguiente comando y cambiamos la siguiente información:

```
sudo virsh edit --domain nodo1_dparrales

```


![nodo1_raw.png](/images/almacenamientolibvirt/nodo1_raw.png)


Una vez que hayamos modificado la información anterior, podemos iniciar la máquina. Si todo ha ido bien, nos saldrá la autentificación de usuario y la máquina funcionará correctamente:


![prueba_funcionamiento.png](/images/almacenamientolibvirt/prueba_funcionamiento.png)



### Redimensiona la imagen de la máquina nodo2_tunombre, añadiendo 1 GiB y utiliza la herramienta guestfish para redimensionar también el sistema de ficheros definido dentro de la imagen

Lo primero es determinar el volumen que está usando la máquina virtual. Para ello usamos el siguiente comando:

```
virsh -c qemu:///system domblklist --domain nodo2_dparrales

 Destino   Fuente
----------------------------------------------------
 hda       /home/dparrales/aprovv2_dparrales.qcow2
```


A continuación obtenemos información sobre el fichero de imagen:

```
qemu-img info  /home/dparrales/aprovv2_dparrales.qcow2
image: /home/dparrales/aprovv2_dparrales.qcow2
file format: qcow2
virtual size: 3 GiB (3221225472 bytes)
disk size: 3.45 MiB
cluster_size: 65536
backing file: /var/lib/libvirt/images/original_dparrales.qcow2
backing file format: qcow2
Format specific information:
    compat: 1.1
    compression type: zlib
    lazy refcounts: false
    refcount bits: 16
    corrupt: false
    extended l2: false
```


Después creamos una nueva imagen con un tamaño de 4GB:

```
qemu-img create -f qcow2 -o preallocation=metadata aprovv2_dparrales_new.qcow2 4G

Formatting 'aprovv2_dparrales_new.qcow2', fmt=qcow2 cluster_size=65536 extended_l2=off preallocation=metadata compression_type=zlib size=4294967296 lazy_refcounts=off refcount_bits=16
```

Ahora redimensionamos el nuevo disco a partir del disco antiguo:

```
virt-resize --expand /dev/sda1 aprovv2_dparrales aprovv2_dparrales_new.qcow2  

[   0.0] Examining aprovv2_dparrales.qcow2
**********

Summary of changes:

/dev/sda1: This partition will be resized from 2.0G to 3.0G.  The 
filesystem ext4 on /dev/sda1 will be expanded using the ‘resize2fs’ 
method.

/dev/sda2: This partition will be left alone.

**********
[   4.3] Setting up initial partition table on aprovv2_dparrales_new.qcow2
[   5.8] Copying /dev/sda1
 100% ⟦▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒⟧ 00:00
[  15.7] Copying /dev/sda2
[  19.9] Expanding /dev/sda1 using the ‘resize2fs’ method

Resize operation completed with no errors.  Before deleting the old disk, 
carefully check that the resized disk boots and works correctly
```

Una vez terminado, cambiamos el nombre a los discos para que coincidan con la ruta que aparece en la configuración de la máquina:

```
mv aprovv2_dparrales.qcow2 aprovv2_dparrales_old.qcow2

mv aprovv2_dparrales_new.qcow2 aprovv2_dparrales.qcow2
```

Ya podemos iniciar la máquina, y si todo ha ido bien, arrancará con el nuevo disco y podremos comprobar que tiene 1 GB más de tamaño:


![redimension.png](/images/almacenamientolibvirt/redimension.png)


### Crea un snapshot de la máquina nodo1_tunombre, modifica algún fichero de la máquina y alguna caracteristica de la misma (por ejemplo cantidad e memoria). Recupera el estado de la máquina desde el snapshot y comprueba que lo cambios se han perdido (tanto en el disco como en la configuración).

Antes de hacer el snapshot, debemos cambiar el tipo de imagen que tiene el nodo1 de raw a qcow2, ya que los ficheros raw no tienen soporte para hacer snapshots con el comando *"virsh snapshot-create-as"*.

Así pues, volvemos a cambiar el tipo de disco del nodo1 siguiendo los pasos anteriores. Tras cambiarlo, debería quedarnos algo así:

```
virsh -c qemu:///system domblklist nodo1_dparrales

 Destino   Fuente
---------------------------------------------------
 hda       /home/dparrales/aprovv_dparrales.qcow2
```

Ahora ya podemos crear el snapshot con el siguiente comando:

`
virsh snapshot-create-as --domain nodo1_dparrales --name nodo1_dparrales_snap --description "antes de los cambios"
`

Para comprobar que se ha creado el snapshot, usamos el siguiente comando:

`
virsh -c qemu:///system snapshot-list --domain nodo1_dparrales
`

Sacamos esta información:


![snapshot.png](/images/almacenamientolibvirt/snapshot.png)


Ya que hemos creado el snapshot, vamos a hacer algunos cambios y vamos a comprobar si podemos recuperar el estado de la máquina a partir del snaphot.

En mi caso he doblado la cantidad de memoria de la máquina (de 1GB a 2GB) y he creado un fichero de la máquina llamado "prueba":


![memoria_nodo1.png](/images/almacenamientolibvirt/memoria_nodo1.png)


![ficheroprueba_nodo1.png](/images/almacenamientolibvirt/ficheroprueba_nodo1.png)


Una vez realizados los cambios, vamos a revertir la máquina a su anterior estado. Para ello utilizamos:

`
virsh -c qemu:///system snapshot-revert --domain nodo1_dparrales --snapshotname nodo1_dparrales_snap --running
`

Vamos a comprobar que se han deshecho los cambios en la memoria y en el fichero creado:


![memoria_nodo1_2.png](/images/almacenamientolibvirt/memoria_nodo1_2.png)


![ficheroprueba_nodo1_2.png](/images/almacenamientolibvirt/ficheroprueba_nodo1_2.png)


Efectivamente, se ha devuelto a la máquina al estado que tenía cuando se realizó el snapshot.


### Crea un nuevo pool de tipo “dir” llamado discos_externos, crea un volumen de 1Gb dentro de este pool, y añádelo “en caliente” a la máquina nodo2_tunombre. Formatea el disco y móntalo.


Para crear este nuevo pool de tipo dir usamos el siguiente comando:

`
virsh -c qemu:///system pool-define-as --name discos_externos --target /home/dparrales/Descargas/pool-dir --type dir
`

Y lo iniciamos con:

`
virsh -c qemu:///system pool-start --pool discos_externos
`

Ahora creamos el volumen con:

`
qemu-img create -f raw /home/dparrales/Descargas/pool-dir/disk2.raw 1G
`


Lo anexamos en caliente  a la máquina nodo1:

`
virsh -c qemu:///system attach-disk --domain nodo2_dparrales --source /home/dparrales/Descargas/pool-dir/disk2.raw --target sdb --persistent
`

Entramos en la máquina y vemos que se ha anexado con éxito:

![sdb_nodo2.png](/images/almacenamientolibvirt/sdb_nodo2.png)


Con esto ya podemos dar formato al disco y montarlo:

`
gdisk /dev/sdb
`


![fdisk_nodo2.png](/images/almacenamientolibvirt/fdisk_nodo2.png)


Y le damos formato con:

`
mkfs.ext4 /dev/sdb1
`

Ya podemos montarlo con el comando **mount**:

`
mount /dev/sdb1 /mnt
`

![mount_nodo2.png](/images/almacenamientolibvirt/mount_nodo2.png)


Con esto ya estaría montado el disco.
