+++ 
draft = true
date = 2022-02-04T09:02:14+01:00
title = "Poblar un directorio LDAP desde un fichero CSV"
description = "Poblar un directorio LDAP desde un fichero CSV"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Administración de Sistemas Operativos"]
externalLink = ""
series = []
+++

# Poblar un directorio LDAP desde un fichero CSV

* Crear entre todos los alumnos de la clase que vayan a hacer esta tarea un fichero CSV que incluya información personal de cada uno incluyendo los siguientes datos:

    * Nombre

    * Apellidos

    * Dirección de correo electrónico

    * Nombre de usuario

    * Clave pública ssh

* Añadir el esquema openssh-lpk al directorio para poder incluir claves públicas ssh en un directorio LDAP.

* Hacer un script en bash o en python que utilice el fichero como entrada y pueble el directorio LDAP con un objeto para cada alumno utilizando los ObjectClass posixAccount e inetOrgPerson.

* Configurar el sistema para que sean válidos los usuarios del LDAP.

* Configurar el servicio ssh para que permita acceder a los usuarios del LDAP utilizando las claves públicas que hay allí, en lugar de almacenarlas en `.ssh/authorized_keys` y que se cree el directorio "home" al vuelo.

--------------------------------------

Para empezar vamos a explicar un poco lo que es un fichero csv (Comma Separated Values). Tal y como su nombre indica, es un fichero que tiene información separada por comas (u otro delimitador si queremos). Lo importante en nuestro caso, es que cada usuario tendrá toda la información en una línea, y cada línea representará a un usuario. Quedaría de la siguiente forma:

```
nombre,apellidos,correo,usuario,clave_pública
```

Una vez explicado esto, procedemos a crear el fichero en cuestión:

```
nano usuarios.csv

Daniel,Parrales Garcia,daniparrales16@gmail.com,dparrales,ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBkhwPlBiJghsCe5xE4AQBQQIpq7lUrWgFeZATGkIQ0cmQWI55Qy5T3GSLiDjA0+lvw0eWpIYvKigtlBtQNxxFAON4rzL5vSpsm7IAiCRhpGBEXYbuCCVURmcapwd0ifRHt3ocxTfbqtebvA0CfT7GFBkryjS9B26uSJ43/BECxIB3boxkHUAXIHtVpQNXCavoZjm6S6EKGt/8bSWfPtgdFdCu62doN739Nk5RzdrTIw5CdqdUEGuwCMj8fWuePLZkLfmXx1ckwilf0n6U6gG2FV21/wS8BWqVeMcYpmOn6ZxlkDMnVJX+fl7kOLQoyZewrRwJy9P9MuyzXihtmJP89ERcC+kWFrP0/1YbXJ1XZQD1pRXjLJjDHj1th33DBDx77W5DoBAoJlAE7wqf50wCVSyiVEK91IhevSMmFbxOmhGPAh6BiYXx8QNo1sDLsvfQOEoCE5XRWJ+sn8coEULnY7igEbbaiQcVA8YpqM3PrxaBTAb4Gez+48nAP4sf3N8= dparrales@debian 
Lara,Pruna Ternero,larapruter@gmail.com,lpruna,ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDegOTxSBw35gaDyA+fvKieQ48uSqSGFfQMHRGLwVTt4DmGlBo9ACXtnuyGTbD9Vwk4FhTGwz53khdwfkqztIjD850oO644Y6FM2tcHFATeCjicgda7F4sE/LIqApgdUEvIAKogZlwIZpjrfwqAqztNtfsDQ21FOQk+VXMBM7ojK36hdc3pY3vWQvZ0kWoYw1kjgClPJ0NldedfwYWfiKVk+w675ugn/FacxmWXICY9i2RtN65gMlx1RgYmk2Bam3X+cYixUd4FvxozTh0edv5Ru5YviJbK564z+T+ev6KnS+swMw9FCG4SMoW4FKsQBvs/RjC6GFswp4Tl22/nTiqpo6gyFMjlyJnkXAFMDr2tgvhaHZZPsKflRuipK3owu/22cVJ9QVmriEUwWh9ooD7Hr2naiuOdiKj3c5eF1+3zPNkaxccXqHaQ1M8XrcTJQMSDWYqiCt7EKyrsiYDppKULO/lIuTTDMHMlZWV1+I5JNUcBAvakyumgvIXOvlD8SYM= lpruna@debian
```

Una vez que hayamos creado estos dos ficheros, tenemos que añadir el esquema openssh-lpk. Para ello crearemos el siguiente fichero ldif con la definición del esquema en `/etc/ldap/schema/`:

```
nano /etc/ldap/schema/openssh-lpk.ldif

dn: cn=openssh-lpk,cn=schema,cn=config
objectClass: olcSchemaConfig
cn: openssh-lpk
olcAttributeTypes: ( 1.3.6.1.4.1.24552.500.1.1.1.13 NAME 'sshPublicKey'
  DESC 'MANDATORY: OpenSSH Public key'
  EQUALITY octetStringMatch
  SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )
olcObjectClasses: ( 1.3.6.1.4.1.24552.500.1.1.2.0 NAME 'ldapPublicKey' SUP top AUXILIARY
  DESC 'MANDATORY: OpenSSH LPK objectclass'
  MAY ( sshPublicKey $ uid )
  )
```

Y lo importamos con el siguiente comando:

```
ldapadd -Y EXTERNAL -H ldapi:/// -f openssh-lpk.ldif
```

Pasemos ahora al script que añadirá los usuarios al directorio ldap a partir del fichero csv. He elegido realizar este script en python, usando un módulo de python llamado "pyhton3-ldap". Como vamos a añadir un nuevo módulo al sistema, lo recomendable es que creemos un entorno virtual e instalar en dicho entorno el módulo (para que de esta forma no se produzcan problemas de versiones entre paquetes). Así pues, creamos el entorno virtual:

```
apt install python3-venv

python3 -m venv ldap
```

Ahora instalamos el módulo correspondiente. Hay que decir que el módulo tiene algunos bugs si se utilizan determinadas versiones del mismo, por lo que he descargado e instalado una version que he comprobado que funciona:

```
pip install python3-ldap

pip install ldap3==2.6
```

Ahora vayamos al script en cuestión:

```
nano poblarusuarios.py 

#!/usr/bin/env python

import ldap3
from ldap3 import Connection, ALL
from getpass import getpass
from sys import exit

### VARIABLES

# Shell que se le asigna a los usuarios
shell = '/bin/bash'

# Ruta absoluta del directorio que contiene los directorios personales de los usuarios. Terminado en "/"
home_dir = '/home/'

# El valor inicial para los UID que se asignan al insertar usuarios. 
uid_number = 5000

# El GID que se le asigna a los usuarios. Si no se manda al anadir el usuario da error.
gid = 5000

### VARIABLES

# Leemos el fichero .csv de los usuarios y guardamos cada linea en una lista.
with open('usuarios.csv', 'r') as usuarios:
  usuarios = usuarios.readlines()


### Parametros para la conexion
ldap_ip = 'ldaps://apolo.dparrales.gonzalonazareno.org:636'
dominio_base = 'dc=dparrales,dc=gonzalonazareno,dc=org'
user_admin = 'admin' 
contrasena = getpass('Contrasena: ')

# Intenta realizar la conexion.
conn = Connection(ldap_ip, 'cn={},{}'.format(user_admin, dominio_base),contrasena)

# conn.bind() devuelve "True" si se ha establecido la conexion y "False" en caso contrario.

# Si no se establece la conexion imprime por pantalla un error de conexion.
if not conn.bind():
  print('No se ha podido conectar con ldap') 
  if conn.result['description'] == 'invalidCredentials':
    print('Credenciales no validas.')
  # Termina el script.
  exit(0)

# Recorre la lista de usuarios
for user in usuarios:
  # Separa los valores del usuario usando como delimitador ",", y asigna cada valor a la variable correspondiente.
  user = user.split(',')
  cn = user[0]
  sn = user[1]
  mail = user[2]
  uid = user[3]
  ssh = user[4]

  #Anade el usuario.
  conn.add(
    'uid={},ou=Personas,{}'.format(uid, dominio_base),
    object_class = 
      [
      'inetOrgPerson',
      'posixAccount', 
      'ldapPublicKey'
      ],
    attributes =
      {
      'cn': cn,
      'sn': sn,
      'mail': mail,
      'uid': uid,
      'uidNumber': str(uid_number),
      'gidNumber': str(gid),
      'homeDirectory': '{}{}'.format(home_dir,uid),
      'loginShell': shell,
      'sshPublicKey': str(ssh)
      })

  if conn.result['description'] == 'entryAlreadyExists':
    print('El usuario {} ya existe.'.format(uid))

  # Aumenta el contador para asignar un UID diferente a cada usuario (cada vez que ejecutemos el script debemos asegurarnos de ante mano que no existe dicho uid en el directorio ldap, o se solaparian los datos)
  uid_number += 1

#Cierra la conexion.
conn.unbind()
```

Y vemos si funciona con el archivo anterior:

![script.png](/images/poblar_directorio_fichero_csv/script.png)

Comprobamos si se han añadido los usuarios indicados:

![resultado_script.png](/images/poblar_directorio_fichero_csv/resultado_script.png)

## Configurar el sistema para que sean válidos los usuarios del LDAP.
 
Para ello nos debemos ir al fichero `/etc/ldap/ldap.conf` del cliente y cambiar la siguiente información:

```
nano /etc/ldap/ldap.conf

BASE dc=dparrales,dc=gonzalonazareno,dc=org
URI ldaps://127.0.0.1
```

También debemos modificar la configuración del nss (Name Service Switch) para que el sistema sea capaz de comprobar los UID y GID en el directorio ldap:

```
nano /etc/nsswitch.conf

passwd:         files systemd ldap
group:          files systemd ldap
shadow:         files ldap
```

Para que esto funcione, debemos instalarnos el siguiente paquete y configurarlo de forma correcta:

```
apt install libnss-ldap
```

![conf1.png](/images/poblar_directorio_fichero_csv/conf1.png)

![conf2.png](/images/poblar_directorio_fichero_csv/conf2.png)

![conf3.png](/images/poblar_directorio_fichero_csv/conf3.png)

![conf4.png](/images/poblar_directorio_fichero_csv/conf4.png)

A las ultimas dos cuestiones respondí que no, ya que me parecieron opcionales. Ahora ya podemos inciar sesión en nuestra máquina usando los usuarios que tenemos en el directorio ldap (usaré por ejemplo el usuario impmon que creé en otro ejercicio):

![acceso_usuario.png](/images/poblar_directorio_fichero_csv/acceso_usuario.png)

## Configurar el servicio ssh para que permita acceder a los usuarios del LDAP utilizando las claves públicas que hay allí, en lugar de almacenarlas en `.ssh/authorized_keys` y que se cree el directorio "home" al vuelo.

Para que al acceder con dichos usuarios se cree el directorio home del usuario, debemos ejecutar lo siguiente:

```
echo "session    required        pam_mkhomedir.so" >> /etc/pam.d/common-session
```

Ahora volvemos a entrar con el usuario anterior y vemos si se ha creado su directorio home:

![crear_directorio.png](/images/poblar_directorio_fichero_csv/crear_directorio.png)

Pasemos a configurar el sistema para que acepte el acceso por ssh a los usuarios que tengan sus claves públicas en el directorio de ldap.

Para empezar debemos crear un script que busque las claves públicas registradas al usuario indicado. Debido a algunos parámetros de seguridad de ssh, se nos requiere que el script en cuestión se encuentre en un directorio perteneciente a root y que el script tenga unos permisos concretos. Así pues, he decidido crear el script en /opt:

```
nano /opt/buscarclave.sh 

#!/bin/bash

ldapsearch -x -u -LLL -o ldif-wrap=no '(&(objectClass=posixAccount)(uid='"$1"'))' 'sshPublicKey' | sed -n 's/^[ \t]*sshPublicKey::[ \t]*\(.*\)/\1/p' | base64 -d
```

Y cambiamos los permisos del script:

```
chmod 755 /opt/buscarclave.sh 
```

Podemos ver que el script encuentra las claves de forma adecuada:

![sacar_clave.png](/images/poblar_directorio_fichero_csv/sacar_clave.png)

Ahora añadimos las siguientes líneas al fichero `/etc/ssh/sshd_config`:

```
nano /etc/ssh/sshd_config

AuthorizedKeysCommand /opt/buscarclave.sh
AuthorizedKeysCommandUser nobody
```

Y reiniciamos el servicio de ssh para aplicar los cambios:

```
systemctl restart sshd
```

Comprobamos si podemos acceder por ssh usando los usuarios de ldap que tengan su clave en el directorio:

![acceso_usuario_ssh.png](/images/poblar_directorio_fichero_csv/acceso_usuario_ssh.png)

Como vemos hemos podido acceder de forma adecuada usando dicho usuario.
