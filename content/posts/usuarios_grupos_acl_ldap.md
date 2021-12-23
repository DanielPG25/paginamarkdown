+++ 
draft = true
date = 2021-12-23T15:25:07+01:00
title = "Usuarios, grupos y ACLs en OpenLDAP"
description = "Usuarios, grupos y ACLs en OpenLDAP"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Administración de Sistemas Operativos"]
externalLink = ""
series = []
+++

# Usuarios, Grupos y ACLs en LDAP

* Crea 10 usuarios con los nombres que prefieras en LDAP, esos usuarios deben ser objetos de los tipos posixAccount e inetOrgPerson. Estos usuarios tendrán un atributo userPassword.
* Crea 3 grupos en LDAP dentro de una unidad organizativa diferente que sean objetos del tipo groupOfNames. Estos grupos serán: comercial, almacen y admin
* Añade usuarios que pertenezcan a:
    * Solo al grupo comercial
    * Solo al grupo almacén
    * Al grupo comercial y almacén
    * Al grupo admin y comercial
    * Solo al grupo admin
    * Modifica OpenLDAP apropiadamente para que se pueda obtener los grupos a los que pertenece cada usuario a través del atributo "memberOf".
* Crea las ACLs necesarias para que los usuarios del grupo almacén puedan ver todos los atributos de todos los usuarios pero solo puedan modificar las suyas.
* Crea las ACLs necesarias para que los usuarios del grupo admin puedan ver y modificar cualquier atributo de cualquier objeto.

----------------------------------------------------------------------------------------

En primer lugar crearemos los usuarios con los tipos que nos han indicado: posixAccount e inetOrgPerson. Estos objetos tienen los atributos obligatorios de "cn, uid, uidNumber, gidNumber, homeDirectory" por parte de posixAccount y "sn" indirectamente por parte de inetOrgPerson. Dicho esto, creamos el siguiente fichero con los siguientes usuarios:

```
nano usuarios.ldif

dn: uid=impmon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: impmon
gidNumber: 2001
homeDirectory: /home/impmon
loginShell: /bin/bash
sn: impmon
uid: impmon
uidNumber: 2001
userPassword: {SSHA}n5FNyVJzksz90xjiO9HVxsanJsLoNw/y

dn: uid=veemon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: veemon
gidNumber: 2002
homeDirectory: /home/veemon
loginShell: /bin/bash
sn: veemon
uid: veemon
uidNumber: 2002
userPassword: {SSHA}purfQbJm6twhhcdLuzC0cVekY4J9UVgk

dn: uid=guilmon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: guilmon
gidNumber: 2003
homeDirectory: /home/guilmon
loginShell: /bin/bash
sn: guilmon
uid: guilmon
uidNumber: 2003
userPassword: {SSHA}B5b7Wk2vKbDUSj2HwmEw09q9MMJowVt1

dn: uid=agumon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: agumon
gidNumber: 2004
homeDirectory: /home/agumon
loginShell: /bin/bash
sn: agumon
uid: agumon
uidNumber: 2004
userPassword: {SSHA}MrWv03mj1JfvUyy3PdU7I7LU+Taat8t2

dn: uid=gabumon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: gabumon
gidNumber: 2005
homeDirectory: /home/gabumon
loginShell: /bin/bash
sn: gabumon
uid: gabumon
uidNumber: 2005
userPassword: {SSHA}soFvqY3wASuGKouQ+JKL/8q5xdt1j62u

dn: uid=gatomon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: gatomon
gidNumber: 2006
homeDirectory: /home/gatomon
loginShell: /bin/bash
sn: gatomon
uid: gatomon
uidNumber: 2006
userPassword: {SSHA}aoWUqerJcYfmQaAOQHXICynMjNoIpspg

dn: uid=betamon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: betamon
gidNumber: 2007
homeDirectory: /home/betamon
loginShell: /bin/bash
sn: betamon
uid: betamon
uidNumber: 2007
userPassword: {SSHA}4VmUNXcBQwD6cwvQnsjBfH8f8UL3r0OZ

dn: uid=gaomon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: gaomon
gidNumber: 2008
homeDirectory: /home/gaomon
loginShell: /bin/bash
sn: gaomon
uid: gaomon
uidNumber: 2008
userPassword: {SSHA}vhk5qOzVRUtbih3AxVKxfURJ5VTZ09S6

dn: uid=infermon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: infermon
gidNumber: 2009
homeDirectory: /home/infermon
loginShell: /bin/bash
sn: infermon
uid: infermon
uidNumber: 2009
userPassword: {SSHA}Lv2jC01YLCjPAtherAHBSqq5bK6yLWSH

dn: uid=alphamon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: alphamon
gidNumber: 2010
homeDirectory: /home/alphamon
loginShell: /bin/bash
sn: alphamon
uid: alphamon
uidNumber: 2010
userPassword: {SSHA}QBZ9ruturPJSZR2d6l/WmC68pXAQfwoz
```

Para las obtener las contraseñas anteriores hemos usado el siguiente comando:

```
slappasswd -h {SSHA}
```

Una vez que ya tenemos ese fichero listo, podemos incluirlo a nuestro directorio con el siguiente comando:

```
ldapadd -x -D cn=admin,dc=dparrales,dc=gonzalonazareno,dc=org -W -f usuarios.ldif
Enter LDAP Password: 
adding new entry "uid=impmon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org"

adding new entry "uid=veemon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org"

adding new entry "uid=guilmon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org"

adding new entry "uid=agumon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org"

adding new entry "uid=gabumon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org"

adding new entry "uid=gatomon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org"

adding new entry "uid=betamon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org"

adding new entry "uid=gaomon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org"

adding new entry "uid=infermon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org"

adding new entry "uid=alphamon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org"
```

Ahora crearemos los grupos que nos han indicado la misma forma:

```
nano grupos.ldif

dn: cn=comercial,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: groupOfNames
cn: comercial
member:

dn: cn=almacen,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: groupOfNames
cn: almacen
member:

dn: cn=admin,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: groupOfNames
cn: admin
member:
```

Y lo añadimos igual que hicimos antes:

```
ldapadd -x -D cn=admin,dc=dparrales,dc=gonzalonazareno,dc=org -W -f grupos.ldif
Enter LDAP Password: 
adding new entry "cn=comercial,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"

adding new entry "cn=almacen,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"

adding new entry "cn=admin,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"
```

En este momento tendremos que modificar los grupos que acabamos de crear para añadir los usuarios a los mismos:

```
nano modificargrupos.ldif

# Solo al grupo comercial
dn: cn=comercial,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=agumon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org

dn: cn=comercial,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=gabumon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org

# Solo al grupo almacen 
dn: cn=almacen,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=betamon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org

dn: cn=almacen,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=gatomon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org

# Al grupo comercial y almacen
dn: cn=comercial,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=gaomon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org

dn: cn=almacen,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=gaomon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org

dn: cn=comercial,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=veemon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org

dn: cn=almacen,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=veemon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org

# Al grupo admin y al comercial

dn: cn=admin,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=infermon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org

dn: cn=comercial,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=infermon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org

dn: cn=admin,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=guilmon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org

dn: cn=comercial,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=guilmon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org

# Solo al grupo admin 

dn: cn=admin,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=impmon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org

dn: cn=admin,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=alphamon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
```

Esta vez, tenemos que modificar un registro, no añadirlo, por lo que usaremos el siguiente comando:

```
ldapmodify -x -D cn=admin,dc=dparrales,dc=gonzalonazareno,dc=org -W -f modificargrupos.ldif
Enter LDAP Password: 
modifying entry "cn=comercial,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"

modifying entry "cn=comercial,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"

modifying entry "cn=almacen,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"

modifying entry "cn=almacen,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"

modifying entry "cn=comercial,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"

modifying entry "cn=almacen,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"

modifying entry "cn=comercial,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"

modifying entry "cn=almacen,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"

modifying entry "cn=admin,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"

modifying entry "cn=comercial,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"

modifying entry "cn=admin,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"

modifying entry "cn=comercial,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"

modifying entry "cn=admin,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"

modifying entry "cn=admin,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"
```

Podemos comprobar que, efectivamente, se han producido los cambios:

```
ldapsearch -x -b ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
# extended LDIF
#
# LDAPv3
# base <ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org> with scope subtree
# filter: (objectclass=*)
# requesting: ALL
#

# Grupos, dparrales.gonzalonazareno.org
dn: ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: organizationalUnit
ou: Grupos

# admin, Grupos, dparrales.gonzalonazareno.org
dn: cn=admin,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: groupOfNames
cn: admin
member:
member: uid=infermon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
member: uid=guilmon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
member: uid=impmon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
member: uid=alphamon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org

# almacen, Grupos, dparrales.gonzalonazareno.org
dn: cn=almacen,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: groupOfNames
cn: almacen
member:
member: uid=betamon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
member: uid=gatomon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
member: uid=gaomon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
member: uid=veemon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org

# comercial, Grupos, dparrales.gonzalonazareno.org
dn: cn=comercial,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: groupOfNames
cn: comercial
member:
member: uid=agumon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
member: uid=gabumon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
member: uid=gaomon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
member: uid=veemon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
member: uid=infermon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
member: uid=guilmon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org

# search result
search: 2
result: 0 Success

# numResponses: 5
# numEntries: 4
```

En este momento tenemos que modificar OpenLDAP para poder obtener los grupos a los que pertenece cada usuario a través del atributo "memberOF", por lo que tendremos que crear una serie de fichero cuyo objetivo es la modificación de la configuración de OpenLDAP:

```
nano memberof_config.ldif

dn: cn=module,cn=config
cn: module
objectClass: olcModuleList
objectclass: top
olcModuleLoad: memberof.la
olcModulePath: /usr/lib/ldap

dn: olcOverlay={0}memberof,olcDatabase={1}mdb,cn=config
objectClass: olcConfig
objectClass: olcMemberOf
objectClass: olcOverlayConfig
objectClass: top
olcOverlay: memberof
olcMemberOfDangling: ignore
olcMemberOfRefInt: TRUE
olcMemberOfGroupOC: groupOfNames
olcMemberOfMemberAD: member
olcMemberOfMemberOfAD: memberOf
```

```
nano memberof_config2.ldif

dn: cn=module,cn=config
cn: module
objectclass: olcModuleList
objectclass: top
olcmoduleload: refint.la
olcmodulepath: /usr/lib/ldap

dn: olcOverlay={1}refint,olcDatabase={1}mdb,cn=config
objectClass: olcConfig
objectClass: olcOverlayConfig
objectClass: olcRefintConfig
objectClass: top
olcOverlay: {1}refint
olcRefintAttribute: memberof member manager owner
```

Lo añadimos de la siguiente forma:

```
ldapadd -Y EXTERNAL -H ldapi:/// -f memberof_config.ldif 
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
adding new entry "cn=module,cn=config"

adding new entry "olcOverlay={0}memberof,olcDatabase={1}mdb,cn=config"
```

```
ldapadd -Y EXTERNAL -H ldapi:/// -f memberof_config2.ldif 
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
adding new entry "cn=module,cn=config"

adding new entry "olcOverlay={1}refint,olcDatabase={1}mdb,cn=config"
```

Sin embargo, estos cambios que hemos hecho solo se aplican a los nuevos grupos que creemos a partir de ahora, por lo que para que afecten a los que creamos antes debemos borrarlos y volverlos a crear:

```
ldapdelete -x -D "cn=admin,dc=dparrales,dc=gonzalonazareno,dc=org" 'cn=comercial,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org' -W

ldapdelete -x -D "cn=admin,dc=dparrales,dc=gonzalonazareno,dc=org" 'cn=admin,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org' -W

ldapdelete -x -D "cn=admin,dc=dparrales,dc=gonzalonazareno,dc=org" 'cn=almacen,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org' -W
```

Volvemos a crear los grupos y a asignar los usuarios a dichos grupos:

```
ldapadd -x -D cn=admin,dc=dparrales,dc=gonzalonazareno,dc=org -W -f grupos.ldif

ldapmodify -x -D cn=admin,dc=dparrales,dc=gonzalonazareno,dc=org -W -f modificargrupos.ldif
```

Y comprobamos si podemos averiguar los grupos a los que pertenece cada usuario con el parámetro "memberOf":

```
ldapsearch -LL -Y EXTERNAL -H ldapi:/// "(uid=impmon)" -b dc=dparrales,dc=gonzalonazareno,dc=org memberOf
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
version: 1

dn: uid=impmon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
memberOf: cn=admin,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
```

```
ldapsearch -LL -Y EXTERNAL -H ldapi:/// "(uid=guilmon)" -b dc=dparrales,dc=gonzalonazareno,dc=org memberOf
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
version: 1

dn: uid=guilmon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
memberOf: cn=admin,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
memberOf: cn=comercial,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
```

```
ldapsearch -LL -Y EXTERNAL -H ldapi:/// "(uid=gatomon)" -b dc=dparrales,dc=gonzalonazareno,dc=org memberOf
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
version: 1

dn: uid=gatomon,ou=Personas,dc=dparrales,dc=gonzalonazareno,dc=org
memberOf: cn=almacen,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org
```

Como vemos, hemos sido capaces de hacer uso de "memberOf" para averiguar a que grupo pertenecen los usuarios. Así pues, lo único que nos quedaría para finalizar esta práctica es crear dos bloques de ACLs:

* Los usuarios del grupo almacén pueden ver todos los atributos de todos los usuarios pero solo pueden modificar los suyos.
* Los usuarios del grupo admin pueden ver y modificar cualquier atributo de cualquier objeto. 

Empecemos por la primera de ellas. Para empezar echemos un vistazo a las acls que tenemos activas:

```
ldapsearch -LLLQ -Y EXTERNAL -H ldapi:/// -b cn=config -s one olcAccess
dn: cn=module{0},cn=config

dn: cn=module{1},cn=config

dn: cn=module{2},cn=config

dn: cn=schema,cn=config

dn: olcDatabase={-1}frontend,cn=config
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external
 ,cn=auth manage by * break
olcAccess: {1}to dn.exact="" by * read
olcAccess: {2}to dn.base="cn=Subschema" by * read

dn: olcDatabase={0}config,cn=config
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external
 ,cn=auth manage by * break

dn: olcDatabase={1}mdb,cn=config
olcAccess: {0}to attrs=userPassword by self write by anonymous auth by * none
olcAccess: {1}to attrs=shadowLastChange by self write by * read
olcAccess: {2}to * by * read
olcAccess: {3}to attrs=userPassword by self =xw by dn.exact="cn=admin,dc=dparr
 ales,dc=gonzalonazareno,dc=org" =xw by dn.exact="uid=mirroradmin,dc=dparrales
 ,dc=gonzalonazareno,dc=org" read by anonymous auth by * none
olcAccess: {4}to * by anonymous auth by self write by dn.exact="uid=mirroradmi
 n,dc=dparrales,dc=gonzalonazareno,dc=org" read by users read by * none
```

Ahora crearemos el fichero con la acl definida:

```
nano acl_almacen.ldif

dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: to dn.base="" by group="cn=almacen,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org" by self write
olcAccess: to dn.base="" by group="cn=almacen,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org" read
olcAccess: to dn.base="" by group="cn=almacen,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org" search
```

Y lo subimos:

```
ldapmodify -Y EXTERNAL -H ldapi:/// -f acl_almacen.ldif 
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
modifying entry "olcDatabase={1}mdb,cn=config"
```

Y vamos que se nos ha añadido correctamente a la  lista de acls:

```
ldapsearch -LLLQ -Y EXTERNAL -H ldapi:/// -b cn=config -s one olcAccess
dn: cn=module{0},cn=config

dn: cn=module{1},cn=config

dn: cn=module{2},cn=config

dn: cn=schema,cn=config

dn: olcDatabase={-1}frontend,cn=config
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external
 ,cn=auth manage by * break
olcAccess: {1}to dn.exact="" by * read
olcAccess: {2}to dn.base="cn=Subschema" by * read

dn: olcDatabase={0}config,cn=config
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external
 ,cn=auth manage by * break

dn: olcDatabase={1}mdb,cn=config
olcAccess: {0}to attrs=userPassword by self write by anonymous auth by * none
olcAccess: {1}to attrs=shadowLastChange by self write by * read
olcAccess: {2}to * by * read
olcAccess: {3}to attrs=userPassword by self =xw by dn.exact="cn=admin,dc=dparr
 ales,dc=gonzalonazareno,dc=org" =xw by dn.exact="uid=mirroradmin,dc=dparrales
 ,dc=gonzalonazareno,dc=org" read by anonymous auth by * none
olcAccess: {4}to * by anonymous auth by self write by dn.exact="uid=mirroradmi
 n,dc=dparrales,dc=gonzalonazareno,dc=org" read by users read by * none
olcAccess: {5}to dn.base="" by group="cn=almacen,ou=Grupos,dc=dparrales,dc=gon
 zalonazareno,dc=org" by self write
olcAccess: {6}to dn.base="" by group="cn=almacen,ou=Grupos,dc=dparrales,dc=gon
 zalonazareno,dc=org" read
olcAccess: {7}to dn.base="" by group="cn=almacen,ou=Grupos,dc=dparrales,dc=gon
 zalonazareno,dc=org" search
```

Ahora crearemos la segunda acl:

```
nano acl_admin.ldif

dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {1}to * by dn="cn=admin,dc=dparrales,dc=gonzalonazareno,dc=org" write by group.exact="cn=admin,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org" write
```

Y la añadimos:

```
ldapmodify -Y EXTERNAL -H ldapi:/// -f acl_admin.ldif 
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
modifying entry "olcDatabase={1}mdb,cn=config"
```

Volvemos a mirar si se ha añadido correctamente:

```
ldapsearch -LLLQ -Y EXTERNAL -H ldapi:/// -b cn=config -s one olcAccess
dn: cn=module{0},cn=config

dn: cn=module{1},cn=config

dn: cn=module{2},cn=config

dn: cn=schema,cn=config

dn: olcDatabase={-1}frontend,cn=config
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external
 ,cn=auth manage by * break
olcAccess: {1}to dn.exact="" by * read
olcAccess: {2}to dn.base="cn=Subschema" by * read

dn: olcDatabase={0}config,cn=config
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external
 ,cn=auth manage by * break

dn: olcDatabase={1}mdb,cn=config
olcAccess: {0}to attrs=userPassword by self write by anonymous auth by * none
olcAccess: {1}to * by dn="cn=admin,dc=dparrales,dc=gonzalonazareno,dc=org" wri
 te by group.exact="cn=admin,ou=Grupos,dc=dparrales,dc=gonzalonazareno,dc=org"
  write
olcAccess: {2}to attrs=shadowLastChange by self write by * read
olcAccess: {3}to * by * read
olcAccess: {4}to attrs=userPassword by self =xw by dn.exact="cn=admin,dc=dparr
 ales,dc=gonzalonazareno,dc=org" =xw by dn.exact="uid=mirroradmin,dc=dparrales
 ,dc=gonzalonazareno,dc=org" read by anonymous auth by * none
olcAccess: {5}to * by anonymous auth by self write by dn.exact="uid=mirroradmi
 n,dc=dparrales,dc=gonzalonazareno,dc=org" read by users read by * none
olcAccess: {6}to dn.base="" by group="cn=almacen,ou=Grupos,dc=dparrales,dc=gon
 zalonazareno,dc=org" by self write
olcAccess: {7}to dn.base="" by group="cn=almacen,ou=Grupos,dc=dparrales,dc=gon
 zalonazareno,dc=org" read
olcAccess: {8}to dn.base="" by group="cn=almacen,ou=Grupos,dc=dparrales,dc=gon
 zalonazareno,dc=org" search
```

Tal y como podemos ver, las dos acls se encuentran perfectamente añadidas y funcionando.
