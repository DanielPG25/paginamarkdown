+++ 
draft = true
date = 2021-11-07T12:50:20+01:00
title = "Interconexión de un servidor Oracle 19c con PostgreSQL"
description = "Interconexión de un servidor Oracle 19c con PostgreSQL"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Administración de Bases de Datos"]
externalLink = ""
series = []
+++

# Interconexión de Oracle19c con PostgreSQL

Tenemos las siguientes dos máquinas en el escenario:

* Oracle (Centos 8): con ip 192.168.122.12
* Postgre (Debian 10): con ip 192.168.122.18

Partimos también de la base de que ambas máquinas están ya configuradas para el acceso remoto.

## Desde Oracle19c a PostgreSQL

Oracle no cuenta con un soporte nativo para realizar interconexiones con otros gestores de bases de datos que no sean Oracle, por lo que vamos a utlizar ODBC (Open Database Connectivity), que nos permite el acceso a cualquier base de datos en cualquier aplicación.

Es por ello, que en primer lugar, vamos a instalar la paquetería necesaria para hacer uso de ODBC:

```
dnf update && dnf install unixODBC 
```

Como vamos a realizar una interconexión con PostgreSQL, debemos descargar el driver necesario para conectarnos con PostgreSQL:

```
dnf install postgresql-odbc
```

Ahora miraremos y modificaremos el fichero configuración de los drivers de ODBBC, ubicado en ‘/etc/odbcinst.ini’. Vamos a comentar todos los drivers salvo el de PostgreSQL, debido a que no van a ser necesarios en este ejercicio. 

```
nano /etc/odbcinst.ini

[PostgreSQL]
Description     = ODBC for PostgreSQL
Driver          = /usr/lib/psqlodbcw.so
Setup           = /usr/lib/libodbcpsqlS.so
Driver64        = /usr/lib64/psqlodbcw.so
Setup64         = /usr/lib64/libodbcpsqlS.so
FileUsage   = 1
```

Ahora tenemos que crear un DSN (Data Source Name) en el fichero ‘/etc/odbc.ini’, que será el que usaremos para definir la conexión, y que proximamente usaremos para conectarnos con PostgreSQL:

```
nano /etc/odbc.ini

[PSQLU]
Debug           = 0
CommLog         = 0
ReadOnly        = 0
Driver          = PostgreSQL
Servername      = 192.168.122.18
Username        = dparrales1
Password        = dparrales1
Port            = 5432
Database        = prueba1
Trace           = 0
TraceFile       = /tmp/sql.log
```

Una vez hecho esto, podemos probar la conexión usando el comando ‘isql’:

```
isql PSQLU
+---------------------------------------+
| Connected!                            |
|                                       |
| sql-statement                         |
| help [tablename]                      |
| quit                                  |
|                                       |
+---------------------------------------+
```

Como vemos, ha conseguido conectar con la base de datos PostgreSQL. Tambien nos ha abierto un cliente desde el cual podemos ejecutar consultas en dicha base de datos:

```
SQL> select * from dept;
+------------+---------------+--------------+
| deptno     | dname         | loc          |
+------------+---------------+--------------+
| 10         | ACCOUNTING    | NEW YORK     |
| 20         | RESEARCH      | DALLAS       |
| 30         | SALES         | CHICAGO      |
| 40         | OPERATIONS    | BOSTON       |
+------------+---------------+--------------+
SQLRowCount returns 4
4 rows fetched
```

Ahora que hemos configurado el driver, tenemos que modificar la configuración de Oracle para que use ese driver. Para ello, vamos a crear un fichero en ‘$ORACLE_HOME/hs/admin/’, cuyo nombre será `init[DSN].ora`. Como hemos llamado a nuestro DSN “PSQLU”, nuestro fichero se llamará ‘initPSQLU.ora’:

```
nano /opt/oracle/product/19c/dbhome_1/hs/admin/initPSQLU.ora

HS_FDS_CONNECT_INFO = PSQLU
HS_FDS_TRACE_LEVEL = DEBUG
HS_FDS_SHAREABLE_NAME = /usr/lib64/psqlodbcw.so
HS_LANGUAGE = AMERICAN_AMERICA.WE8ISO8859P1
set ODBCINI=/etc/odbc.ini
```

Una vez hecho esto, vamos a configurar el listener para que utilice la configuración que acabamos de crear:

```
nano /opt/oracle/product/19c/dbhome_1/network/admin/listener.ora

SID_LIST_LISTENER=
  (SID_LIST=
      (SID_DESC=
         (SID_NAME=PSQLU)
         (ORACLE_HOME=/opt/oracle/product/19c/dbhome_1)
         (PROGRAM=dg4odbc)
      )
  )
```

Ahora modificaremos el fichero tnsnames.ora, para facilitar la interconexión de los servidores. Añadiremos la siguiente configuración:

```
nano /opt/oracle/product/19c/dbhome_1/network/admin/tnsnames.ora

PSQLU  =
  (DESCRIPTION=
    (ADDRESS=(PROTOCOL=tcp)(HOST=localhost)(PORT=1521))
    (CONNECT_DATA=(SID=PSQLU))
    (HS=OK)
  )
```

Ahora solo queda reinicar el ‘listener’ y ya estaríamos listos:

```
lsnrctl stop

lsnrctl start
```

Entramos en la shell de oracle, y creamos el enlace que vamos a usar:

```
CREATE DATABASE LINK postgreslink
CONNECT TO "dparrales1" IDENTIFIED BY "dparrales1"
USING 'PSQLU';
```

Ahora podemos probar si enlace que hemos funciona haciendo alguna consulta:

```
SELECT dept."dname", dept."deptno" from "dept"@postgreslink dept;

dname   deptno
---------------------------------------------
ACCOUNTING  10

RESEARCH   20

SALES   30

OPERATIONS  40
```

* Nota: Todo lo haga referencia a las tablas de Postgres, debemos meterlo entre comillas dobles.

Con esto ya hemos terminado de conectar Oracle con PostgreSQL, y hemos demostrado su funcionamiento.

-----------------------------------------

## Desde PostgreSQL a Oracle19c

Para ello vamos a usar las dos máquinas del ejercicio anterior, que ya están configuradas para el acceso remoto. Al igual que pasaba con Oracle, PostgreSQL no tiene un soporte nativo para conexiones con otros gestores, por lo que tendremos que usar otra herramienta externa. Es por ello que usaremos la herramienta ‘oracle_fdw’ (Foreign Data Wrapper for Oracle). Esta herramienta también cuenta con versiones para otros gestores de base de datos, pero nosotros nos centraremos en Oracle.
El paquete ‘oracle_fdw’ no se encuentra actualmente disponible para debian buster, por lo que tendremos que compilarlo a mano. Para ello instalaremos los siguientes paquetes, que usaremos para realizar dicha compilación:

```
apt update && apt install libaio1 postgresql-server-dev-all build-essential git
```

También tendremos que descargarnos los paquetes oficiales de ‘Oracle Instant Client’, lo que nos permitirá hacer uso del cliente Oracle para realizar las conexiones a bases de datos remotas. Esto lo haremos con el usuario ‘postgres’:

```
wget https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-basic-linux.x64-21.1.0.0.0.zip

wget https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-sdk-linux.x64-21.1.0.0.0.zip

wget https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-sqlplus-linux.x64-21.1.0.0.0.zip
```

Si descomprimimos los archivos, lo harán en una carpeta llamada ‘instantclient_21_1’, la cual tendrá todos los binarios que necesitaremos. Para poder usar esos binarios sin tener que indicar la ruta completa, vamos a tener que crear las variables de entorno necesaria:

```
export ORACLE_HOME=/home/postgres/instantclient_21_1

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ORACLE_HOME

export PATH=$PATH:$ORACLE_HOME
```

Podemos comprobar que podemos conectarnos remotamente usando ese binario a la base de datos de Oracle:

```
sqlplus c##dparrales1/dparrales1@192.168.122.12/ORCLCDB

SQL*Plus: Release 21.0.0.0.0 - Production on Sun Oct 31 20:49:18 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle.  All rights reserved.

Hora de Ultima Conexion Correcta: Dom Oct 31 2021 20:48:22 +01:00

Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL>
```

Ahora debemos descargar el fichero en el que se encuentra el código fuente de ‘oracle_fdw’:

```
wget https://github.com/laurenz/oracle_fdw/archive/refs/tags/ORACLE_FDW_2_3_0.zip
```

Lo descomprimimos:

```
unzip ORACLE_FDW_2_3_0.zip
```

Lo ponemos en el directorio ‘/home/postgres’ cambiándole el nombre:

```
mv oracle_fdw-ORACLE_FDW_2_3_0/ oracle_fdw
```

En este momento debemos compilar ‘oracle_fdw’:

```
make 

make install
```

Una vez hecho, debería dejarnos crear el link, pero en mi caso, a pesar de tener creadas las variables de entorno, me indicaba que no podía encontrar las librerías, por lo que tuve que crear un fichero llamado ‘oracle.conf’ en el directorio ‘/etc/ld.so.conf.d/’, en el cual puse la siguiente información:

```
/home/postgres/instantclient_21_1
/usr/share/postgresql/11/extension
```

Tras lo cual recargué las librerías que acabamos de crear y reinicié el servicio:

```
ldconfig

systemctl restart postgresql
```

Con esto, ya podemos entrar en la base de datos y crear el enlace:

```
psql -d prueba1

psql (11.13 (Debian 11.13-0+deb10u1))
Digite «help» para obtener ayuda.

prueba1=# create extension oracle_fdw;
CREATE EXTENSION
```

Podemos comprobar que se ha creado usando la siguiente orden en la base de datos:

```
\dx
                                Listado de extensiones instaladas
   Nombre   | Versión |  Esquema   |                         Descripción                          
------------+---------+------------+--------------------------------------------------------------
 dblink     | 1.2     | public     | connect to other PostgreSQL databases from within a database
 oracle_fdw | 1.2     | public     | foreign data wrapper for Oracle access
 plpgsql    | 1.0     | pg_catalog | PL/pgSQL procedural language
(3 filas)
```

El siguiente paso es crear un nuevo esquema al cual, posteriormente, importaremos las tablas de la base de datos Oracle:

```
CREATE SCHEMA oracle;
```

Para importar las tablas de la base de datos Oracle, tenemos que definir un nuevo servidor remoto que utilice la extensión que acabamos de crear:

```
CREATE SERVER oracle FOREIGN DATA WRAPPER oracle_fdw OPTIONS (dbserver '//192.168.122.12/ORCLCDB');
```

Ahora tenemos que mapear a nuestro usuario para que se corresponda con un usuario en la base de datos Oracle que tenga privilegios sobre las tablas que queremos importar:

```
CREATE USER MAPPING FOR dparrales1 SERVER oracle OPTIONS (user 'c##dparrales1', password 'dparrales1');
```

Es importante que no se nos olvide darle los privilegios necesario al usuario que hemos mapeado sobre el esquema  y el servidor que acabamos de crear:

```
GRANT ALL PRIVILEGES ON SCHEMA oracle TO dparrales1;

GRANT ALL PRIVILEGES ON FOREIGN SERVER oracle TO dparrales1;
```

En este momento salimos de la cuenta administrador, y entramos como el usuario dparrales1, para importar las tablas de la base de datos:

```
psql -h localhost -U dparrales1 -d prueba1

IMPORT FOREIGN SCHEMA "C##DPARRALES1" FROM SERVER oracle INTO oracle;
```

Ahora podemos ver los datos que acabamos de importar (concretamente la tabla ‘emp’) usando la siguiente sintaxis en la consulta:

```
select * from oracle.EMP;
 empno | ename  |    job    | mgr  |      hiredate       |   sal   |  comm   | deptno 
-------+--------+-----------+------+---------------------+---------+---------+--------
  7369 | SMITH  | CLERK     | 7902 | 1980-12-17 00:00:00 |  800.00 |         |     20
  7499 | ALLEN  | SALESMAN  | 7698 | 1981-02-20 00:00:00 | 1600.00 |  300.00 |     30
  7521 | WARD   | SALESMAN  | 7698 | 1981-02-22 00:00:00 | 1250.00 |  500.00 |     30
  7566 | JONES  | MANAGER   | 7839 | 1981-04-02 00:00:00 | 2975.00 |         |     20
  7654 | MARTIN | SALESMAN  | 7698 | 1981-09-28 00:00:00 | 1250.00 | 1400.00 |     30
  7698 | BLAKE  | MANAGER   | 7839 | 1981-05-01 00:00:00 | 2850.00 |         |     30
  7782 | CLARK  | MANAGER   | 7839 | 1981-06-09 00:00:00 | 2450.00 |         |     10
  7788 | SCOTT  | ANALYST   | 7566 | 1982-12-09 00:00:00 | 3000.00 |         |     20
  7839 | KING   | PRESIDENT |      | 1981-11-17 00:00:00 | 5000.00 |         |     10
  7844 | TURNER | SALESMAN  | 7698 | 1981-09-08 00:00:00 | 1500.00 |    0.00 |     30
  7876 | ADAMS  | CLERK     | 7788 | 1983-01-12 00:00:00 | 1100.00 |         |     20
  7900 | JAMES  | CLERK     | 7698 | 1981-12-03 00:00:00 |  950.00 |         |     30
  7902 | FORD   | ANALYST   | 7566 | 1981-12-03 00:00:00 | 3000.00 |         |     20
(13 filas)
```

Como vemos, hemos tenido éxito al mostrar las tablas del servidor oracle, por lo que la interconexión ya estaría realizada.
