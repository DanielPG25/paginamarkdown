+++ 
draft = true
date = 2021-10-16T20:11:36+02:00
title = "Instalación de BookMedik y acceso usando LAMP"
description = "Instalación de BookMedik y acceso usando LAMP"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = []
externalLink = ""
series = []
+++


# Instalación de la aplicación BookMedik

Vamos a instala la aplicación BookMedik, un sistema para llevar el control de citas medicas, pacientes, médicos, historiales e citas, áreas medicas y mucho mas, pensado para centros médicos, clínicas y médicos independientes. Puedes encontrar la aplicación en https://github.com/evilnapsis/bookmedik.

Para realizar la instalación sigue los siguientes pasos:


## Crea la base de datos y las tablas necesarias recuperando la copia de seguridad e la base de datos que encuentras en el fichero schema.sql. Se creará una base de datos llamada bookmedik crea un usuario que tenga privilegios sobre dicha base de datos.

Partimos de que tenemos instalado un servidor LAMP en nuestra máquina. Así pues, lo primero es entrar como root en mariadb, crear la base la base de datos y poblarla usando los datos que encontramos en ek fichero *schema.sql*.

```
mysql -u root -p
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 30
Server version: 10.5.12-MariaDB-0+deb11u1 Debian 11

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> create database bookmedik;
Query OK, 1 row affected (0.001 sec)

MariaDB [(none)]> use bookmedik; 
Database changed
MariaDB [bookmedik]> set sql_mode='';
Query OK, 0 rows affected (0.000 sec)

MariaDB [bookmedik]> create table user (
    -> id int not null auto_increment primary key,
    -> username varchar(50),
    -> name varchar(50),
    -> lastname varchar(50),
    -> email varchar(255),
    -> password varchar(60),
    -> is_active boolean not null default 1,
    -> is_admin boolean not null default 0,
    -> created_at datetime
    -> );
Query OK, 0 rows affected (0.038 sec)

MariaDB [bookmedik]> 
MariaDB [bookmedik]> insert into user (username,password,is_admin,is_active,created_at) value ("admin",sha1(md5("admin")),1,1,NOW());
Query OK, 1 row affected (0.003 sec)

MariaDB [bookmedik]> 
MariaDB [bookmedik]> 
MariaDB [bookmedik]> create table pacient (
    -> id int not null auto_increment primary key,
    -> no varchar(50),
    -> name varchar(50),
    -> lastname varchar(50),
    -> gender varchar(1),
    -> day_of_birth date,
    -> email varchar(255),
    -> address varchar(255),
    -> phone varchar(255),
    -> image varchar(255),
    -> sick varchar(500),
    -> medicaments varchar(500),
    -> alergy varchar(500),
    -> is_favorite boolean not null default 1,
    -> is_active boolean not null default 1,
    -> created_at datetime
    -> );
Query OK, 0 rows affected (0.015 sec)

MariaDB [bookmedik]> 
MariaDB [bookmedik]> create table category (
    -> id int not null auto_increment primary key,
    -> name varchar(200)
    -> );
Query OK, 0 rows affected (0.015 sec)

MariaDB [bookmedik]> 
MariaDB [bookmedik]> insert into category (name) value ("Modulo 1");
Query OK, 1 row affected (0.002 sec)

MariaDB [bookmedik]> 
MariaDB [bookmedik]> 
MariaDB [bookmedik]> create table medic (
    -> id int not null auto_increment primary key,
    -> no varchar(50),
    -> name varchar(50),
    -> lastname varchar(50),
    -> gender varchar(1),
    -> day_of_birth date,
    -> email varchar(255),
    -> address varchar(255),
    -> phone varchar(255),
    -> image varchar(255),
    -> is_active boolean not null default 1,
    -> created_at datetime,
    -> category_id int,
    -> foreign key (category_id) references category(id)
    -> );
Query OK, 0 rows affected (0.014 sec)

MariaDB [bookmedik]> 
MariaDB [bookmedik]> 
MariaDB [bookmedik]> 
MariaDB [bookmedik]> create table status (
    -> id int not null auto_increment primary key,
    -> name varchar(100)
    -> );
Query OK, 0 rows affected (0.015 sec)

MariaDB [bookmedik]> 
MariaDB [bookmedik]> insert into status (id,name) values (1,"Pendiente"), (2,"Aplicada"),(3,"No asistio"),(4,"Cancelada");
Query OK, 4 rows affected (0.004 sec)
Records: 4  Duplicates: 0  Warnings: 0

MariaDB [bookmedik]> 
MariaDB [bookmedik]> create table payment (
    -> id int not null auto_increment primary key,
    -> name varchar(100)
    -> );
Query OK, 0 rows affected (0.036 sec)

MariaDB [bookmedik]> 
MariaDB [bookmedik]> insert into payment (id,name) values  (1,"Pendiente"),(2,"Pagado"),(3,"Anulado");
Query OK, 3 rows affected (0.005 sec)
Records: 3  Duplicates: 0  Warnings: 0

MariaDB [bookmedik]> 
MariaDB [bookmedik]> create table reservation(
    -> id int not null auto_increment primary key,
    -> title varchar(100),
    -> note text,
    -> message text,
    -> date_at varchar(50),
    -> time_at varchar(50),
    -> created_at datetime,
    -> pacient_id int,
    -> symtoms text,
    -> sick text,
    -> medicaments text,
    -> user_id int,
    -> medic_id int,
    -> price double,
    -> is_web boolean not null default 0,
    -> payment_id int not null default 1,
    -> foreign key (payment_id) references payment(id),
    -> status_id int not null default 1,
    -> foreign key (status_id) references status(id),
    -> foreign key (user_id) references user(id),
    -> foreign key (pacient_id) references pacient(id),
    -> foreign key (medic_id) references medic(id)
    -> );
Query OK, 0 rows affected (0.067 sec)

```

Una vez hecho esto, creamos un usuario y le damos acceso a la base de datos que hemos creado:


```
grant all on bookmedik.* to 'medik'@'%' identified by '******' with grant option;
```

Con esto hemos acabado la primera parte.


## Crea un virtualhost con el que accederas con el nombre bookmedik.tunombre.org. Copia en el DocumentRoot los ficheros de la aplicación.

Empecemos por crear el virtualhost. Para ello vamos a copiar los datos del fichero */etc/apache2/sites-available/000-default.conf* en otro fichero en la misma carpeta al que llamaremos *medik.conf*:

`
cat /etc/apache2/sites-available/000-default.conf > /etc/apache2/sites-available/medik.conf
`

Ahora vamos a modificar ese nuevo fichero para adaptarlo a nuestro escenario:

```
<VirtualHost *:80>

        ServerName bookmedik.dparrales.org
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/bookmedik
        ErrorLog ${APACHE_LOG_DIR}/bookmedik.error.log
        CustomLog ${APACHE_LOG_DIR}/bookmedik.access.log combined

</VirtualHost>
```

Ahora clonaremos el repositorio en el directorio que hemos indicado en el DocumentRoot:

`
root@servidormariadb:/var/www# git clonehttps://github.com/evilnapsis/bookmedik.git
`


## Vamos a configurar el acceso a la base de datos desde la aplicación.

Tenemos que cambiar el fichero *core/controller/Database.php* que se encuentra dentro del directorio clonado. Lo rellenaremos con los datos del usuario que creamos en el primer paso:

```
<?php
class Database {
        public static $db;
        public static $con;
        function Database(){
                $this->user="medik";$this->pass="******";$this->host="localhost";$this->ddbb="bookmedik";
        }

        function connect(){
                $con = new mysqli($this->host,$this->user,$this->pass,$this->ddbb);
                $con->query("set sql_mode=''");
                return $con;
        }

        public static function getCon(){
                if(self::$con==null && self::$db==null){
                        self::$db = new Database();
                        self::$con = self::$db->connect();
                }
                return self::$con;
        }

}
?>
```


Ahora tenemos que habilitar el virtualhost que creamos antes y reiniciar el servicio:

```
a2ensite medik.conf

systemctl reload apache2
```

Una vez hecho esto, añadimos la siguiente línea al fichero */etc/hosts* de la máquina con la que accederemos a la base de datos:

`
192.168.122.201 bookmedik.dparrales.org
`


## Accedemos al virtualhost:


Para ello usamos la url que hemos añadido antes al DocumentRoot:


![login.png](/images/bookmedik/login.png)


Las credenciales por defecto son *admin*/*admin*


![acceso.png](/images/bookmedik/acceso.png)


Con esto ya habríamos acabado de instalar *bookmedik*



## Extra: Como parte del ejercicio se nos pide cambiar la memoria máxima de uso de un script PHP (parámetro memory_limit) a 256Mb.


Para ello nos dirigimos al fichero */etc/php/7.4/apache2/php.ini* y cambiamos el parámetro *memory_limit* a 256:


![memory.png](/images/bookmedik/memory.png)


Podemos comprobar que ha funcionado, crearemos un fichero en el DocumentRoot al que llamaremos *info.php* y le añadiremos la siguiente línea:


```
<?php phpinfo(); ?>
```

Recargamos el servicio y accedemos a la ip del servidor junto con el nombre del fichero que hemos creado (*info.php*):

`
systemctl reload apache2
`


![infophp.png](/images/bookmedik/infophp.png)


Como podemos ver, el parámetro sobre la memoria máxima ha sido modificado de forma satisfactoria.
