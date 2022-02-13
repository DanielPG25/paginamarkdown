+++ 
draft = true
date = 2022-02-13T13:19:45+01:00
title = "Auditorías de Bases de Datos"
description = "Auditorías de Bases de Datos"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Administración de Bases de Datos"]
externalLink = ""
series = []
+++

# Auditorías de Bases de Datos

#### 1. Activa desde SQLPlus la auditoría de los intentos de acceso fallidos al sistema

Para comprobar si las auditorías se encuentran activadas en nuestra base de datos, ejecutamos la siguiente sentencia:

```
SELECT name, value FROM v$parameter WHERE name like 'audit_trail';
```

![img_1.png](/images/auditorias_basedatos/img_1.png)

Como vemos, el parámetro `audit_trail` tiene el valor de `db`, lo que quiere decir que las auditorías están activadas y se almacenan en la base de datos. Si no estuvieran activadas, el valor de `audit_trail` sería de `NONE`, y se activarían con la siguiente sentencia:

```
ALTER SYSTEM SET audit_trail=db scope=spfile;
```

Una vez mencionado esto, vamos a pasar a la actividad que tenemos entre manos. Para activar la auditoría de intentos de acceso fallidos, ejecutamos lo siguiente:

```
AUDIT CREATE SESSION WHENEVER NOT SUCCESSFUL;
```

Una vez activada, vamos a intentar entrar con un usuario inexistente:

![img_2.png](/images/auditorias_basedatos/img_2.png)

Ahora veamos si se ha registrado en la base de datos el intento fallido de acceso:

```
SELECT OS_USERNAME, USERNAME, EXTENDED_TIMESTAMP, ACTION_NAME FROM DBA_AUDIT_SESSION;
```

![img_3.png](/images/auditorias_basedatos/img_3.png)

Como vemos, se ha registrado el acceso, por lo que podemos concluir con este ejercicio. 

#### 2. Realiza un procedimiento en PL/SQL que te muestre los accesos fallidos junto con el motivo de los mismos, transformando el código de error almacenado en un mensaje de texto comprensible

```
CREATE OR REPLACE PROCEDURE P_EXPLICAR_CODIGO_ERROR (P_CODIGO DBA_AUDIT_SESSION.RETURNCODE%TYPE)
IS
BEGIN
CASE P_CODIGO 
	WHEN 911 THEN
		DBMS_OUTPUT.PUT_LINE('Contiene un carácter inválido');
	WHEN 1004 THEN
		DBMS_OUTPUT.PUT_LINE('El acceso se ha denegado');
	WHEN 1017 THEN
		DBMS_OUTPUT.PUT_LINE('El usuario/contraseña es inválido');
	WHEN 1045 THEN
		DBMS_OUTPUT.PUT_LINE('El usuario no tiene el permiso CREATE SESSION');
	WHEN 28000 THEN
		DBMS_OUTPUT.PUT_LINE('La cuenta está bloqueada');
	WHEN 28001 THEN
		DBMS_OUTPUT.PUT_LINE('La contraseña ha expirado');
	WHEN 28002 THEN
		DBMS_OUTPUT.PUT_LINE('La contraseña va a caducar pronto, deberías cambiarla');
	WHEN 28003 THEN
		DBMS_OUTPUT.PUT_LINE('La contraseña no es lo bastante compleja');
	WHEN 28007 THEN
		DBMS_OUTPUT.PUT_LINE('No puedes reutilizar la contraseña');
	WHEN 28008 THEN
		DBMS_OUTPUT.PUT_LINE('Contraseña antigua inválida');
	WHEN 28009 THEN
		DBMS_OUTPUT.PUT_LINE('La conexión a SYS debe ser a través de SYSDBA o SYSOPER');
	WHEN 28011 THEN
		DBMS_OUTPUT.PUT_LINE('La contraseña va a caducar pronto, deberías cambiarla');
	WHEN 28009 THEN
		DBMS_OUTPUT.PUT_LINE('La contraseña original no se ha introducido');
	ELSE
		DBMS_OUTPUT.PUT_LINE('Póngase en contacto con el administrador para saber la razón');
END CASE;
END P_EXPLICAR_CODIGO_ERROR;
/
```

```
CREATE OR REPLACE PROCEDURE P_MOSTRAR_ACCESOS_FALLIDOS 
IS
CURSOR C_INTENTOS_FALLIDOS IS SELECT OS_USERNAME, USERNAME, EXTENDED_TIMESTAMP, RETURNCODE FROM DBA_AUDIT_SESSION;
V_REG C_INTENTOS_FALLIDOS%ROWTYPE;
BEGIN
FOR V_REG IN C_INTENTOS_FALLIDOS LOOP
	DBMS_OUTPUT.PUT_LINE('Intento fallido de acceso');
	DBMS_OUTPUT.PUT_LINE('Usuario del sistema: '||V_REG.OS_USERNAME);
	DBMS_OUTPUT.PUT_LINE('Usuario de la base de datos: '||V_REG.USERNAME);
	DBMS_OUTPUT.PUT_LINE('Fecha y Hora: '||V_REG.EXTENDED_TIMESTAMP);
	P_EXPLICAR_CODIGO_ERROR(V_REG.RETURNCODE);
	DBMS_OUTPUT.PUT_LINE(CHR(9));
END LOOP;
END P_MOSTRAR_ACCESOS_FALLIDOS;
/
```

![img_4.png](/images/auditorias_basedatos/img_4.png)

#### 3. Activa la auditoría de las operaciones DML realizadas por SCOTT

Para activar la auditoría de las operaciones DML realizadas por SCOTT, ejecutamos la siguiente sentencia:

```
AUDIT INSERT TABLE, UPDATE TABLE, DELETE TABLE BY C##SCOTT;
```

Vamos a comprobar si funciona entrando como ese usuario y ejecutando algunas sentencias:

![img_5.png](/images/auditorias_basedatos/img_5.png)

![img_6.png](/images/auditorias_basedatos/img_6.png)

Veamos si se han registrado los cambios que hemos hecho:

```
SELECT USERNAME, OBJ_NAME, ACTION_NAME, EXTENDED_TIMESTAMP FROM DBA_AUDIT_OBJECT;
```

![img_7.png](/images/auditorias_basedatos/img_7.png)

![img_8.png](/images/auditorias_basedatos/img_8.png)

Como vemos, las operaciones DML realizadas por el usuario SCOTT han quedado registradas, por lo que podemos concluir este ejercicio.

#### 4. Realiza una auditoría de grano fino para almacenar información sobre la inserción de empleados del departamento 10 en la tabla emp de scott

Una auditoría de grano fino es una auditoría que no solo guarda sobre que objeto se realizó una determinada operación, sino que también nos permite saber con más detalle que datos fueron consultados, o que datos fueron insertados, modificados o borrados por un usuario. Esto nos permite un mayor nivel de control sobre los datos de la base de datos, y también nos permite averiguar que usuarios podrían estar abusando de sus privilegios.

Para realizar la auditoría de grano fino que nos han indicado, ejecutamos lo siguiente:

```
BEGIN
	DBMS_FGA.ADD_POLICY (
	OBJECT_SCHEMA      => 'C##SCOTT',
	OBJECT_NAME        => 'EMP',
	POLICY_NAME        => 'AUDIT_FINA_DPARRALES',
	AUDIT_CONDITION    => 'DEPTNO = 10',
	STATEMENT_TYPES    => 'INSERT'
	);
END;
/
```

Ahora entramos con el usuario SCOTT e insertamos varios registros, para comprobar si se registran en la auditoría:

![img_9.png](/images/auditorias_basedatos/img_9.png)

Miremos si se han registrado:

```
SELECT DB_USER, OBJECT_NAME, SQL_TEXT, EXTENDED_TIMESTAMP FROM DBA_FGA_AUDIT_TRAIL WHERE POLICY_NAME='AUDIT_FINA_DPARRALES';
```

![img_10.png](/images/auditorias_basedatos/img_10.png)

![img_11.png](/images/auditorias_basedatos/img_11.png)

Como podemos ver, aparecen todos los datos relacionados con las inserciones en la tabla EMP de SCOTT, incluyendo las sentencias ejecutadas, por lo que podemos dar por concluido este ejercicio.

#### 5. Explica la diferencia entre auditar una operación "by access" o "by session"

La diferencia entre ambos radica en que "by access" almacena un registro por cada acción que se realice, sin importar que se haya repetido. No obstante, "by session" almacena un solo registro por una misma acción, lo que evita la repetición.

Para elegir una u otra, habría que indicarlo al final de la creación de la auditoría. Por ejemplo, si usáramos la auditoría del ejercicio 3, la sintaxis sería la siguiente:

```
AUDIT INSERT TABLE, UPDATE TABLE, DELETE TABLE BY C##SCOTT BY {ACCESS/SESSION};
```

#### 6. Documenta las diferencias entre los valores "db" y "db, extended" del parámetro audit_trail de ORACLE

Los dos valores indican que las auditorías están activadas en el sistema. La diferencia radica en que "db, extended", además almacena los datos que se corresponden con "SQLBIND" y "SQLTEXT" en la tabla "SYS.AUD$", mientras que "db" no los almacena.

Si quisiéramos cambiar el valor de nuestra base de datos de "db" a "db, extended" deberemos ejecutar lo siguiente:

```
ALTER SYSTEM SET audit_trail = DB,EXTENDED SCOPE=SPFILE;
``` 

Tras esto, para aplicar los cambios, deberíamos reiniciar la base de datos:

![img_12.png](/images/auditorias_basedatos/img_12.png)

Comprobemos si ha cambiado:

![img_13.png](/images/auditorias_basedatos/img_13.png)

#### 7. Averigua si en Postgres se pueden realizar los apartados 1, 3 y 4.

La comprobación de los accesos fallidos a la base de datos no es como en Oracle. Si queremos ver dichos intentos, tenemos que mirar en los logs de postgresql. Dichos logs se encuentran en la ruta `/var/log/postgresql`, y no contienen tanta información como en oracle:

![img_14.png](/images/auditorias_basedatos/img_14.png)

PostgreSQL no incorpora una herramienta para realizar auditorías, por lo que tenemos que hacer uso de una herramienta que ha creado la comunidad para realizar dichas auditorías: **Audit trigger 91plus**.

Así pues, lo primero es descargarnos la herramienta:

```
wget https://raw.githubusercontent.com/2ndQuadrant/audit-trigger/master/audit.sql
```

Para activar la herramienta en el servidor, ejecutamos lo siguiente:

```
 \i audit.sql
```

Una vez activadas las auditorías con esta herramienta, si queremos ver las operaciones DML que realice SCOTT, deberemos indicarlo tabla por tabla, ya que no podemos activar esta herramienta de forma global. Dicho de otra forma, con esta herramienta no podemos auditar a los usuarios, sino las tablas en sí. Si ejecutamos lo siguiente, por lo tanto, veríamos las operaciones realizadas sobre la tabla "emp" del esquema SCOTT:

```
select audit.audit_table('scott.emp');

NOTICE:  disparador «audit_trigger_row» para la relación «scott.emp» no existe, ignorando
NOTICE:  disparador «audit_trigger_stm» para la relación «scott.emp» no existe, ignorando
NOTICE:  CREATE TRIGGER audit_trigger_row AFTER INSERT OR UPDATE OR DELETE ON scott.emp FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');
NOTICE:  CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON scott.emp FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');
 audit_table 
-------------
 
(1 fila)
```

Ahora, podemos entrar con el usuario scott y realizar operaciones de prueba, para ver si se registran (aunque podríamos hacerlo con otro usuario):

![img_15.png](/images/auditorias_basedatos/img_15.png)

Miremos si se han registrado correctamente:

```
select session_user_name, action, table_name, action_tstamp_clk, client_query from audit.logged_actions;
```

![img_16.png](/images/auditorias_basedatos/img_16.png)

Como vemos, nos muestra el usuario, la tabla, la fecha, la acción y le sentencia ejecutada, por lo que podemos decir que esta herramienta genera auditorías de grano fino.

#### 8. Averigua si en MySQL se pueden realizar los apartados 1, 3 y 4.

Si queremos ver los registros de intentos fallidos de acceso, debemos verlos en los logs que genera mariadb. Para ello, primero debemos habilitar esto en la configuración (`/etc/mysql/mariadb.conf.d/50-server.cnf`):

```
general_log_file       = /var/log/mysql/mysql.log
general_log            = 1
log_error = /var/log/mysql/error.log
```

Ahora cambiamos la propiedad de directorio (`/var/log/mysql/`) a "mysql" y reiniciamos los servicios de mariadb y mysql:

```
chown mysql: mysql/
systemctl restart mariadb
systemctl restart mysql
```

Ahora si miramos el log de errores, nos aparecen los intentos fallidos de acceso al servidor de base de datos:

![img_17.png](/images/auditorias_basedatos/img_17.png)

Ahora bien, si queremos habilitar las auditorias, debemos instalar un plugin adicional de mariadb:

```
INSTALL SONAME 'server_audit';
```

Una vez hecho esto, para habilitar la auditoría DML de scott, debemos modificar la configuración de mariadb (`/etc/mysql/mariadb.conf.d/50-server.cnf`) con lo siguiente:

```
[server]
server_audit_events=CONNECT,QUERY,TABLE
server_audit_logging=ON
server_audit_incl_users=scott
```

Ahora reiniciamos el servicio de mariadb para aplicar los cambios:

```
systemctl restart mariadb
```

Ahora, entramos con el usuario scott y ejecutamos algunas sentencias, para ver si se registran adecuadamente:

![img_18.png](/images/auditorias_basedatos/img_18.png)

Miremos en el fichero de auditorías para ver si han guardado (por defecto se encuentra en `/var/lib/mysql/server_audit.log`):

![img_19.png](/images/auditorias_basedatos/img_19.png)

Como vemos, se ha registrado el usuario que ejecutó la sentencia, la fecha y hora, la tabla y la sentencia que se ejecutó, por lo que podemos decir que esta auditoría es de grano fino.

#### 9. Averigua las posibilidades que ofrece MongoDB para auditar los cambios que va sufriendo un documento

Mongodb Enterprise nos ofrece la capacidad de hacer auditorías. Para ello, nos da tres opciones a la hora de habilitarlas:

* Guardar las auditorías en el `syslog`.
* Guardar las auditorías en un fichero JSON o BSON.
* Hacer que las auditorías aparezcan directamente en la consola.

Podemos habilitar las auditorías de dos formas: a través de la consola o modificando la configuración. 

* A través de la consola:

    * Syslog:

    ```
    mongod --dbpath data/db --auditDestination syslog
    ```

    * JSON/BSON:
    
    ```
    mongod --dbpath data/db --auditDestination file --auditFormat JSON --auditPath data/db/auditLog.json
    mongod --dbpath data/db --auditDestination file --auditFormat BSON --auditPath data/db/auditLog.bson
    ```

    * Consola:
    
    ```
    mongod --dbpath data/db --auditDestination console
    ```

* Modificando la configuración (`/etc/mongod.conf`):

    * Syslog:
    
    ```
    storage:
      dbPath: data/db
    auditLog:
      destination: syslog
    ```

    * JSON/BSON:
    
    ```
    storage:
      dbPath: data/db
    auditLog:
      destination: file
      format: JSON
      path: data/db/auditLog.json
    ```

    ```
    storage:
      dbPath: data/db
    auditLog:
      destination: file
      format: BSON
      path: data/db/auditLog.bson
    ```

    * Consola:
    
    ```
    storage:
      dbPath: data/db
    auditLog:
      destination: console
    ```

#### 10. Averigua si en MongoDB se pueden auditar los accesos al sistema

Para ello, desde la consola de MongoDB ejecutamos lo siguiente:

```
db.setLogLevel(3, "accessControl")
```

El número indica el nivel de verbosidad, siendo "0" equivalente a desactivado, y "5" el máximo. Una vez hecho esto, si intentamos entrar con un usuario equivocado y miramos los logs, nos aparece lo siguiente:

![img_20.png](/images/auditorias_basedatos/img_20.png)

Como vemos, se nos indica que ha habido un intento de acceso al sistema no autorizado, aportando además bastante información al respecto (usuario, host, fecha y hora, etc.).
