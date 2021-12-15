+++ 
draft = true
date = 2021-12-15T10:14:28+01:00
title = "Configuración de LDAPs en OpenLDAP"
description = "Configuración de LDAPs en OpenLDAP"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Administración de Sistemas Operativos"]
externalLink = ""
series = []
+++

# Configuración de LDAPs en OpenLDAP

Configura el servidor LDAP de apolo para que utilice el protocolo `ldaps://` a la vez que el `ldap://` utilizando el certificado x509 de la práctica de https o solicitando el correspondiente a través de gestiona. Realiza las modificaciones adecuadas en el cliente ldap de apolo para que todas las consultas se realicen por defecto utilizando `ldaps://`:

----------------------------------------------------------------

En esta práctica vamos a hacer que el servidor LDAP que tenemos instalado en apolo haga uso de SSL/TLS para cifrar las conversaciones con los clientes. Para ello vamos a utilizar unos certificados que he descargado de la página 'gestiona' del Gonzalo Nazareno.

Tenemos, de esta forma, los siguientes ficheros en apolo:

```
ls -l

-rw-r--r-- 1 apolo apolo 10075 Dec  3 08:59 escenario_DP.crt
-rw------- 1 apolo apolo  3243 Dec  3 09:07 escenario_DP.key
-rw-r--r-- 1 apolo apolo  3634 Dec  3 08:59 gonzalonazareno.crt
```

Una vez llevados los ficheros a apolo, debemos añadirlos a sus correspondientes directorios para tener una mayor organización y un mayor control sobre ellos:

```
mv gonzalonazareno.crt /etc/ssl/certs/
mv escenario_DP.crt /etc/ssl/certs/
mv escenario_DP.key /etc/ssl/private/
```

Tenemos que asegurarnos de que el propietario de dichos ficheros sea root y los permisos que tengan no hayan cambiado durante la transferencia:

```
ls -l /etc/ssl/certs | egrep 'gonzalo|escenario'
-rw-r--r-- 1 root root  10075 Dec  3 08:59 escenario_DP.crt
-rw-r--r-- 1 root root   3634 Dec  3 08:59 gonzalonazareno.crt

ls -l /etc/ssl/private
total 4
-r-------- 1 root root 3243 Dec  3 09:07 escenario_DP.key
``` 

En este momento, debemos replantearnos algunas cuestiones sobre la seguridad. El usuario que ejecuta por defecto el servicio de LDAP es 'openldap', y dicho usuario no tiene en este momento acceso a la clave (ya que es propiedad de root en un directorio propiedad de root). Así pues tenemos tres opciones: o bien cambiamos el propietario de dichos ficheros y directorios (peligro para la seguridad), o bien damos permiso al grupo "Otros" para que puedan acceder a dichos ficheros y directorios (peligro para la seguridad, aunque menor que la anterior opción), o creamos unas acls que permitan únicamente al usuario 'openldap' tener acceso a dichos ficheros (mejor opción). Así pues, nos decantamos por la última opción:

```
setfacl -m u:openldap:r-x /etc/ssl/private
setfacl -m u:openldap:r-x /etc/ssl/private/escenario_DP.key
```  

Podemos visualizar las acls de la siguiente forma:

```
getfacl /etc/ssl/private 

getfacl: Removing leading '/' from absolute path names
# file: etc/ssl/private
# owner: root
# group: root
user::rwx
user:openldap:r-x
group::---
mask::r-x
other::---
```

```
getfacl /etc/ssl/private/escenario_DP.key 

getfacl: Removing leading '/' from absolute path names
# file: etc/ssl/private/escenario_DP.key
# owner: root
# group: root
user::r--
user:openldap:r-x
group::---
mask::r-x
other::---
```

Una vez que hemos solucionado este tema, podemos proceder a configurar ldap para que use SSL/TLS. Para ello, no tenemos que tocar ningún fichero de configuración en el sistema, como haríamos con cualquier otro servicio. LDAP, para evitar tener que realizar un reinicio del servicio cada que cambiemos la configuración, decidió incorporar la misma al árbol de directorios como si fuera un registro más. Es por ello, que debemos incorporar los cambios a un fichero `.ldif` y subirlos al servidor. 

```
nano ldaps_config.ldif 

dn: cn=config
changetype: modify
replace: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/ssl/certs/gonzalonazareno.crt
-
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ssl/private/escenario_DP.key
-
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ssl/certs/escenario_DP.crt
```

Ahora para incorporar esta configuración usamos el siguiente comando:

```
ldapmodify -Y EXTERNAL -H ldapi:/// -f ldaps_config.ldif 
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
modifying entry "cn=config"
```

* Con "-Y" especificamos el mecanismo SASL que vamos a utilizar para autentificarnos.
* Con "-H" indicamos la URI de conexión al servidor, en este caso usando el socket unix ldapi.
* Con "-f" indicamos el fichero a usar para configurar ldap.

Ahora tenemos que habilitar ldap para que use el puerto 636 (el puerto asignado para ldaps). Para ello debemos modificar el fichero `/etc/default/slapd` y añadir la siguiente información:

```
nano /etc/default/slapd

SLAPD_SERVICES="ldap:/// ldapi:/// ldaps:///"
```

Como hemos cambiado la configuración, tenemos que reiniciar el servicio:

```
systemctl restart slapd
```

Podemos comprobar que ya se encuentra escuchando por el puerto 636 mediante el siguiente comando:

```
netstat -tlnp | egrep slap
tcp        0      0 0.0.0.0:389             0.0.0.0:*               LISTEN      648/slapd           
tcp        0      0 0.0.0.0:636             0.0.0.0:*               LISTEN      648/slapd           
tcp6       0      0 :::389                  :::*                    LISTEN      648/slapd           
tcp6       0      0 :::636                  :::*                    LISTEN      648/slapd  
```

Ahora que la parte del servidor esta configurada para que escuche peticiones por el puerto, tenemos que configurar el cliente apolo para que las consultas usen por defecto ldaps. Para ello tenemos que hacer que las aplicaciones que usemos a través de línea de comando utilicen el certificado que importamos antes (gonzalonazareno.crt). El encargado de esto es un paquete llamado "ca-certificates", que ya está instalado por defecto, y se encarga de instalar y mantener actualizada la lista de autoridades certificadoras.

Así pues, debemos copiar el certificado en el directorio `/usr/local/share/ca-certificates/`, que es el directorio pensado para poner los certificados que instalemos localmente:

```
cp /etc/ssl/certs/gonzalonazareno.crt /usr/local/share/ca-certificates/
```

Una vez que hemos ubicado el certificado ahí, tenemos que actualizar la lista de certificados para que ca-certificates cree los enlaces simbólicos necesarios y las configuraciones necesarias para que podamos empezar a usar dicho certificado:

```
update-ca-certificates
Updating certificates in /etc/ssl/certs...
rehash: warning: skipping duplicate certificate in gonzalonazareno.pem
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
```

Si el certificado que usáramos no fuera válido, añadiríamos la siguiente línea al fichero de configuración del cliente (`/etc/ldap/ldap.conf`), para que de esta forma pudiéramos usar la conexión segura. Esto es útil si quieres usar dicha conexión pero no dispones de un certificado válido por cualquier motivo.

```
nano /etc/ldap/ldap.conf

TLS_REQCERT     allow
```

Con esto ya podemos ejecutar peticiones al servidor ldap usando SSL/TLS. Para probarlo, haremos primero una consulta especificando el uso de LDAPs:

```
ldapsearch -x -b "dc=dparrales,dc=gonzalonazareno,dc=org" -H ldaps://localhost:636

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

Como vemos, ha funcionado. Para hacer que el cliente use por defecto ldaps para realizar las conexiones, tenemos que volver a modificar el fichero de configuración del cliente, y añadir o modificar la siguiente línea (en el caso de apolo):

```
URI     ldaps://localhost
```

De esta forma usará el protocolo ldaps por defecto. Para probarlo, podemos hacer que el servidor deje de escuchar temporalmente por el puerto 389:

```
nano /etc/default/slapd

SLAPD_SERVICES="ldapi:/// ldaps:///"
```

```
systemctl restart slapd
```

Ahora podemos realizar una búsqueda normal, que usará por defecto ldaps, y solo podrá acceder al servidor usando el puerto 636:

```
ldapsearch -x -b "dc=dparrales,dc=gonzalonazareno,dc=org"
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

Con esto hemos terminado de configurar ldap para que use SSL/TLS. También, tras esta última prueba, volví a habilitar el protocolo `ldap:///` por si algún cliente no disponía de un certificado válido.
