+++ 
draft = true
date = 2021-12-17T09:07:39+01:00
title = "Configuración de LDAP en alta disponibilidad"
description = "Configuración de LDAP en alta disponibilidad"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Administración de Sistemas Operativos"]
externalLink = ""
series = []
+++

# Configuración de LDAP en alta disponibilidad

Vamos a instalar un servidor LDAP en ares que va a actuar como servidor secundario o de respaldo del servidor LDAP instalado en apolo, para ello habrá que seleccionar un modo de funcionamiento y configurar la sincronización entre ambos directorios, para que los cambios que se realicen en uno de ellos se reflejen en el otro.

* Selecciona el método más adecuado para configurar un servidor LDAP secundario, viendo y/o probando las opciones posibles.
* Explica claramente las características, ventajas y limitaciones del método seleccionado
* Realiza las configuraciones adecuadas en el directorio cn=config
* Como prueba de funcionamiento, prepara un pequeño fichero ldif, que se insertará en el directorio en la corrección y se verificará que se ha sincronizado.

------------------------------------------------------------------------------------------------

En esta práctica vamos a instalar y configurar un servidor LDAP secundario en "Ares" que ofrecerá redundancia y alta disponibilidad al servidor LDAP principal instalado en "Apolo". La alta disponibilidad es fundamental a la hora de ofrecer cualquier tipo de servicio, pero en el caso de LDAP, lo es más aún, ya que de ello dependen multitud de otros servicios, por lo que nos podemos permitir una caída total del servicio de LDAP.

Para ello haremos uso de *LDAP Syncy Replication*, también conocido como *syncrepl*. OpenLDAP es muy flexible, y admite varios modos de funcionamiento para *syncrepl* para adaptarse a distintos escenarios:

* **LDAP Content Synchronization Protocol:** Es el método de funcionamiento más básico,lo que comúnmente llamaríamos maestro-esclavo si fuera otro tipo de sistema, que en LDAP es conocido como "provider-consumer". Consiste básicamente en copiar una porción del árbol de información de directorio (también llamado DIT) en el servidor secundario que actúa de "consumer" a través de una lectura del servidor principal ("provider"). Tras esta lectura inicial, el "consumer" tratará de mantener actualizada la información haciendo uso de uno de los siguientes métodos:

    * **pull-based:** El "consumer" hace preguntas de forma periódica al "provider" en busca de actualizaciones.
    * **push-based:** Es el "provider" el que manda la información sobre actualizaciones al "consumer", que se dedica a estar a la escucha de dichas actualizaciones.
    

    * Ventajas:
        - Si se producen varios cambios en un solo objeto, no es necesario guardar la secuencia de dichos cambios, ya que lo que se traslada al "consumer" es el objeto final al completo.
        - Solo debe configurarse el lado del "consumer".
    * Desventajas:
        - Deriva de la primera ventaja, ya que al procesarse los objetos al completo, se usan más recursos de los necesarios.
        - Solo permite escrituras en el lado del "provider", ya que los "consumers" sacan su información del mismo.
        
* **Delta-syncrepl:** Es una variante del método anterior creada para solventar el problema de uso excesivo de recursos. Para ello el provider guardará un registro de los cambios en una base de datos aparte. El consumer entonces, consultará dicha base de datos, y si hay diferencias las aplicará. Si se encuentra muy diferenciado del provider, hará uso del primer método para ponerse al día, y a partir de ahí hara uso de la base de datos (método Delta).

    * Ventajas:
        - Al modificarse un objeto, el consumer procesará únicamente los cambios efectuados, ahorrando así recursos que de la anterior forma se habrían gastado ineficientemente.
    * Desventajas:
        - Ya que el estado de la base de datos se guarda en el lado del provider tanto en el registro de cambios como en la base de datos en sí, es necesario restaurar ambas partes en caso de corrupción o migración.
        - Al igual que pasaba en el método anterior, únicamente se permiten escrituras en el lado del provider.
        - La configuración debe realizarse en ambos lados (provider y consumer).

* **N-Way Multi-Provider:** Es una técnica de replicado que usa Syncrepl para replicar los datos entre múltiples providers (multi-master):

    * Ventajas:
        - Si un provider falla, los otros podrán seguir respondiendo peticiones.
        - Los providers pueden estar situados en diferentes localizaciones geográficas, evitando así problemas por la localización (incendios, terremotos, robos, etc).
        - Facilita la Alta Disponibilidad (no confundir con balanceo de carga).
    * Desventajas:
        - Se puede llegar a romper la consistencia de datos si hay problemas de red.
        - Es difícil distinguir si una máquina ha perdido la conexión con el provider debido a problemas de red o porque el provider ha caído.
        - Si falla la red y varios clientes empiezan a escribir a los providers, la unificación de esos datos puede ser difícil.

* **MirrorMode:** Es un híbrido que intenta aportar todas las garantias de consistencia de los datos de un único provider y las ventajas de la alta disponibilidad del multi provider. Consiste en hacer que dos providers se repliquen entre ellos, haciendo que una interfaz externa (frontend) redirija todas las escrituras hacia uno de ellos, haciendo que el otro solo funcione si el primero falla. Cuando se corrija el fallo, se sincronizarán entre ellos para no perder la información que haya cambiado en ese tiempo.

    * Ventajas:
        - Proporciona alta disponibilidad.
        - Mientras uno de los providers siga funcionando, seguirá aceptando escrituras.
        - Los providers se mantienen siempre actualizados entre ellos, por lo que están listos para cualquier eventualidad.
        - Se re-sincronizan los providers tras una caída de uno de ellos.
    * Desventajas:
        - Las escrituras se realizan solo en uno de los providers (aunque son replicadas posteriormente).
        - Se necesita un servidor externo (slapd en modo proxy) o un dispositivo (balanceador de carga) para gestionar que provider se encuentra activo.


Habiendo visto todos los modos disponibles, considero que la mejor opción para mi situación es el MirrorMode, ya que trata de unificar todas las ventajas de los anteriores, ofreciendo pocas desventajas.

Una vez decidido esto, hemos de preparar el escenario para su configuración, por lo que he instalado OpenLDAP en Ares y lo he configurado de tal forma que se encuentra en el mismo estado que Apolo (con ldaps activado, pero sin los objetos creados). De esta forma partimos en los dos servidores desde el mismo punto.

Así pues, vamos a configurar en primer lugar Apolo, creando un nuevo usuario con permisos para leer en todo el directorio, para que de esta forma podamos replicarlas en Ares sin necesidad de usar el usuario "admin", a la vez que pueda mantener las replicas sincronizadas. Para ello crearemos un fichero `.ldif` con la siguiente información:

```
nano usuarioprivilegios.ldif

dn: uid=mirroradmin,dc=dparrales,dc=gonzalonazareno,dc=org
objectClass: account
objectClass: simpleSecurityObject
uid: mirroradmin
description: Usuario que se encargara del MirrorMode
userPassword: {SSHA}1bnyrFzrXXSqPOAKTvSPgKttaYW+DG4C
```

Para obtener la contraseña encriptada usamos el siguiente comando:

```
slappasswd

New password: 
Re-enter new password: 
{SSHA}1bnyrFzrXXSqPOAKTvSPgKttaYW+DG4C
```

Ahora añadimos el fichero a nuestro directorio usando un comando que ya hemos utilizado anteriormente:

```
ldapadd -x -D "cn=admin,dc=dparrales,dc=gonzalonazareno,dc=org" -f usuarioprivilegios.ldif -W

Enter LDAP Password: 
adding new entry "uid=mirroradmin,dc=dparrales,dc=gonzalonazareno,dc=org"
```

Una vez creado el nuevo usuario, tenemos que darle los permisos adecuados, para lo cual usaremos las ACL de LDAP, que como pasaba con el usuario, tendremos que crear en un fichero `.ldif`:

```
nano privilegios.ldif

dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: to attrs=userPassword
  by self =xw
  by dn.exact="cn=admin,dc=dparrales,dc=gonzalonazareno,dc=org" =xw
  by dn.exact="uid=mirroradmin,dc=dparrales,dc=gonzalonazareno,dc=org" read
  by anonymous auth
  by * none
olcAccess: to *
  by anonymous auth
  by self write
  by dn.exact="uid=mirroradmin,dc=dparrales,dc=gonzalonazareno,dc=org" read
  by users read
  by * none
```

Una vez creado el fichero, lo añadimos con el siguiente comando:

```
ldapmodify -Y EXTERNAL -H ldapi:/// -f privilegios.ldif 

SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
modifying entry "olcDatabase={1}mdb,cn=config"
```

Ahora tendremos que cargar en memoria el módulo que se encargará de realizar la sincronización de los dos servidores (syncprov), para lo cual tendremos que crear otro fichero `.ldif`:

```
nano syncprov.ldif

dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: syncprov
```

Lo añadimos igual que antes:

```
ldapmodify -Y EXTERNAL -H ldapi:/// -f syncprov.ldif

SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
modifying entry "cn=module{0},cn=config"
```

En este momento ya tenemos cargado el módulo, pero no tiene ninguna configuración, así que tendremos que creársela. Para ello crearemos otro fichero `.ldif`:

```
nano syncprov_conf.ldif

dn: olcOverlay=syncprov,olcDatabase={1}mdb,cn=config
changetype: add
objectClass: olcSyncProvConfig
olcOverlay: syncprov
olcSpCheckpoint: 3 3
```

El último parámetro indica cada cuantas operaciones o minutos se va a llevar a cabo un "checkpoint", pensado para minimizar la actividad de sincronización requerida en caso de que un proveedor caiga (he elegido 3 para ambos casos). Ahora lo importamos como hemos hecho antes:

```
ldapmodify -Y EXTERNAL -H ldapi:/// -f syncprov_conf.ldif 

SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
adding new entry "olcOverlay=syncprov,olcDatabase={1}mdb,cn=config"
```

Ahora añadiremos un número identificativo al servidor, para lo cual crearemos otro fichero `.ldif`:

```
nano num_iden.ldif

dn: cn=config
changetype: modify
add: olcServerId
olcServerId: 1
```

Al igual que antes, volvemos a importar el fichero:

```
ldapmodify -Y EXTERNAL -H ldapi:/// -f num_iden.ldif  

SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
modifying entry "cn=config"
```

Ahora hemos de crear el último fichero `.ldif` que usaremos en el servidor principal, el cual contendrá algunos parámetros de la sincronización y la habilitación de la misma:

```
nano habilitar_mirror.ldif

dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcSyncrepl
olcsyncrepl: rid=000
  provider=ldaps://ares.dparrales.gonzalonazareno.org 
  type=refreshAndPersist
  retry="3 3 300 +" 
  searchbase="dc=dparrales,dc=gonzalonazareno,dc=org"
  attrs="*,+" 
  bindmethod=simple
  binddn="uid=mirroradmin,dc=dparrales,dc=gonzalonazareno,dc=org"
  credentials=******* (la contraseña en claro)
-
add: olcDbIndex
olcDbIndex: entryUUID eq
olcDbIndex: entryCSN eq
-
replace: olcMirrorMode
olcMirrorMode: TRUE
```

Ahora lo importamos tal y como hemos hecho anteriormente:

```
ldapmodify -Y EXTERNAL -H ldapi:/// -f habilitar_mirror.ldif 

SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
modifying entry "olcDatabase={1}mdb,cn=config"
```

Ya hemos terminado en el lado de Apolo. En Ares, tendremos que hacer las mismas configuraciones (desde la creación del usuario mirroradmin) cambiando los siguientes ficheros:

```
nano num_iden.ldif

dn: cn=config
changetype: modify
add: olcServerId
olcServerId: 2
```

```
nano habilitar_mirror.ldif

dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcSyncrepl
olcsyncrepl: rid=000
  provider=ldaps://apolo.dparrales.gonzalonazareno.org 
  type=refreshAndPersist
  retry="3 3 300 +" 
  searchbase="dc=dparrales,dc=gonzalonazareno,dc=org"
  attrs="*,+" 
  bindmethod=simple
  binddn="uid=mirroradmin,dc=dparrales,dc=gonzalonazareno,dc=org"
  credentials=******* (la contraseña en claro)
-
add: olcDbIndex
olcDbIndex: entryUUID eq
olcDbIndex: entryCSN eq
-
replace: olcMirrorMode
olcMirrorMode: TRUE
```

Antes de hacer las pruebas, tenemos que asegurarnos de que en ares hemos permitido que el firewall (ufw) abra los puertos 636 y 389. Ahora podemos hacer la prueba de buscar el ares los elementos de nuestra estructura. Si lo hemos hecho bien, deberían aparecernos las unidades organizativas que creamos en apolo (pero no en ares) "Personas" y "Grupos", ya que debería replicar toda la información que haya en apolo:

![sincronizacion.png](/images/ldap_altadisponibilidad/sincronizacion.png)

Como podemos observar, nos ha aparecido toda la información que contiene el directorio de apolo, por lo que podemos concluir que la sincronización ha sido un éxito.
