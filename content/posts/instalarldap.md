+++ 
draft = true
date = 2021-12-14T08:33:02+01:00
title = "Instalación de OpenLDAP"
description = "Instalación y configuración inicial de OpenLDAP"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Administración de Sistemas Operativos"]
externalLink = ""
series = []
+++

# Instalación de OpenLDAP

Antes de comenzar realmente con la instalación, debemos asegurarnos de que tenemos configurado el FQDN de la máquina en la que lo vamos a instalar, ya que va a hacer uso del mismo para generar la entrada base (esta entrada se puede modificar más adelante, pero es conveniente tenerla bien desde el principio para facilitar las cosas). Para saber si está bien configurado ejecutamos el siguiente comando:

```
hostname -f 

apolo.dparrales.gonzalonazareno.org
```

Como vemos, el FQDN está configurado correctamente. Con esto, ya podemos instalar OpenLDAP en nuestra máquina servidora:

```
apt install slapd
```

Durante la instalación nos pedirá la contraseña que usará el usuario administrador de LDAP:

![contrasena_admin.png](/images/instalar_ldap/contrasena_admin.png)

Una vez instalado, podemos comprobar que nos ha abierto el puerto TCP 389, que es por el que estará escuchando las peticiones:

```
netstat -tlnp | egrep slap
tcp        0      0 0.0.0.0:389             0.0.0.0:*               LISTEN      730/slapd           
tcp6       0      0 :::389                  :::*                    LISTEN      730/slapd 
```

Ahora que hemos comprobado que ldap está activo y funcionando, procedemos a instalar el paquete de herramientas con las que trabajaremos:

```
apt install ldap-utils
```

Ahora ya podemos usar el comando ldapsearch con las credenciales que introducimos durante la instalación (si queremos hacer la búsqueda como administrador) para buscar el contenido que tenemos en nuestro directorio:

```
ldapsearch -x -D "cn=admin,dc=dparrales,dc=gonzalonazareno,dc=org" -b "dc=dparrales,dc=gonzalonazareno,dc=org" -W
Enter LDAP Password: 
# extended LDIF
#
# LDAPv3
# base <dc=dparrales,dc=gonzalonazareno,dc=org> with scope subtree
# filter: (objectclass=*)
# requesting: ALL
#

# dparrales.gonzalonazareno.org
dn: dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: dcObject
objectClass: organization
o: dparrales.gonzalonazareno.org
dc: dparrales

# search result
search: 2
result: 0 Success

# numResponses: 2
# numEntries: 1
```

Con esto hemos finalizado la instalación de LDAP, pero para tener una mayor organización de los objetos que creemos, vamos a crear un par de objetos llamados unidades organizativas. Para ello vamos a crear un fichero `.ldif` con la siguiente información:

```
nano UnidadesOrganizativas.ldif

dn: ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: organizationalUnit
ou: Personas 

dn: ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
objectclass: organizationalUnit
ou: Grupos
```

* "dn" indica el nombre distintivo que el objeto tendrá dentro de la jerarquía de directorios.
* "objectClass" indica la clase del objeto que queremos añadir.
* "ou" es el atributo obligatorio de la clase que hemos elegido, que indica el nombre del objeto.


Una vez creado el fichero, podemos incluirlo a nuestro árbol de directorios usando el comando `ldapadd`:

```
ldapadd -x -D "cn=admin,dc=dparrales,dc=gonzalonazareno,dc=org" -f UnidadesOrganizativas.ldif -W
Enter LDAP Password: 
adding new entry "ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org"

adding new entry "ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"
```

Podemos ver si se han creado los objetos si volvemos a realizar la misma búsqueda que antes:

```
ldapsearch -x -D "cn=admin,dc=dparrales,dc=gonzalonazareno,dc=org" -b "dc=dparrales,dc=gonzalonazareno,dc=org" -W
Enter LDAP Password: 
# extended LDIF
#
# LDAPv3
# base <dc=dparrales,dc=gonzalonazareno,dc=org> with scope subtree
# filter: (objectclass=*)
# requesting: ALL
#

# dparrales.gonzalonazareno.org
dn: dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: dcObject
objectClass: organization
o: dparrales.gonzalonazareno.org
dc: dparrales

# Personas, dparrales.gonzalonazareno.org
dn: ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: organizationalUnit
ou:: UGVyc29uYXMg

# Grupos, dparrales.gonzalonazareno.org
dn: ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: organizationalUnit
ou: Grupos

# search result
search: 2
result: 0 Success

# numResponses: 4
# numEntries: 3
```

Como podemos ver se han añadido de forma correcta los dos objetos que hemos creado. 

Con esto hemos terminado de realizar la instalación de ldap. En las siguientes prácticas nos dedicaremos a poblar más nuestro árbol de directorios y a trabajar sobre él.
