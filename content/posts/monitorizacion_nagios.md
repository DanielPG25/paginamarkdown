+++ 
draft = true
date = 2022-02-18T10:18:02+01:00
title = "Monitorización con Nagios"
description = "Monitorización del escenario de trabajo con Nagios"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Administración de Sistemas Operativos"]
externalLink = ""
series = []
+++

# Monitorización con Nagios

Nagios es un sistema de monitorización que vigila los equipos y los servicios que le sean configurados, pudiendo alertar al administrador si algo no funciona como debería. Puede además extender sus funcionalidades a través de plugins desarrollados por organizaciones y la comunidad.

Algunas de sus características:

* Monitorización de servicios de red como: SMTP, HTTP, HTTPS, etc
* Monitorización de los recursos del hardware: CPU, uso de disco, estado de la memoria RAM, puertos, etc
* No depende de los sistemas operativos
* Posibilidad de monitorización remota mediante túneles SSL cifrados o SSH
* Posibilidad de programar plugins específicos para nuevos sistemas o servicios
* Verificación de servicios en paralelo
* Notificaciones cuando suceden problemas en servicios o máquinas y cuando son resueltos
* Posibilidad de definir disparadores que se ejecuten al ocurrir un evento de un servicio o máquinas
* Soporte para implementar redundancia en la monitorización
* Visualización del estado de la red en tiempo real a través de su interfaz web, junto con la posibilidad de generar informes y gráficos de comportamiento de los sistemas monitorizados.

Debido a que necesita de un servidor web para mostrar la monitorización, he decido instalar Nagios en Hera (Rocky 8), ya que es la máquina del escenario que ya posee un servidor web.

Antes de instalar "Nagios Core", es necesario instalar sus plugins (en todos los clientes). Para instalar dichos plugins, hemos de irnos al sitio web de Nagios, y descargamos el fichero `.tar.gz` y lo descomprimimos:

```
wget https://github.com/nagios-plugins/nagios-plugins/releases/download/release-2.4.0/nagios-plugins-2.4.0.tar.gz

tar -xf nagios-plugins-2.4.0.tar.gz
``` 

Este fichero descomprimido contiene el código fuente, por lo que tendremos que compilarlo a mano nosotros. Para ello debemos instalar las siguientes dependencias si no lo estuvieran ya:

```
dnf install bind-utils libpq-devel gcc make unzip -y
```

A continuación, dentro del directorio descomprimido, ejecutamos lo siguiente:

```
./configure
```

Y cuando haya acabado, realizamos la compilación y la instalación de los plugins:

```
make

make install
```

Dichos plugins se han instalado, y se encuentran dentro del directorio `/usr/local/nagios/libexec/`:

![img_1.png](/images/monitorizacion_nagios/img_1.png)

Hemos de repetir este proceso en todos los clientes. Ahora debemos descargarnos el "Nagios Core" en Hera:

```
wget https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-4.4.6/nagios-4.4.6.tar.gz

tar -xf 
```

Ahora, al igual que antes, compilamos el paquete por nuestra cuenta y lo instalamos:

```
./configure

make all

make install-groups-users install install-webconf install-config install-init install-daemoninit install-commandmode
```

Una vez que hayamos instalado los paquetes, tenemos que crear el usuario "nagiosadmin" para acceder al panel de control de Nagios y meter a apache en el grupo nagios:

```
htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

usermod -a -G nagios apache
```

Ahora habilitamos y activamos el servicio de Nagios:

```
systemctl start nagios

systemctl enable nagios
```

Ahora podemos acceder a la dirección web de nuestra máquina (`www.dparrales.gonzalonazareno.org/nagios`) para acceder al panel de control:

![img_2.png](/images/monitorizacion_nagios/img_2.png)

Podemos ver la lista de hosts y servicios que monitoriza:

![img_3.png](/images/monitorizacion_nagios/img_3.png)

![img_4.png](/images/monitorizacion_nagios/img_4.png)

Ahora tendremos que instalar en todos los clientes "Nagios NRPE":

```
apt install nagios-nrpe-server nagios-plugins-basic nagios-plugins -y
```

E iniciamos y habilitamos los servicios:

```
systemctl start nagios-nrpe-server && systemctl enable nagios-nrpe-server
```

Una vez hecho esto, debemos modificar la configuración en cada cliente, para permitir que la máquina Hera tenga acceso a Nagios-NRPE y para que tenga los permisos necesarios para acceder a la información que necesita:

```
nano /etc/nagios/nrpe.cfg

allowed_hosts=127.0.0.1,::1,172.16.0.200

dont_blame_nrpe=1
```

También debemos adaptar la línea de chequeo de disco a nuestro escenario, ya que por defecto busca en 'hda1', mientras que nuestros escenario usa discos virtual 'vda1':

```
command[check_hda1]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /dev/vda1
``` 

Tras haber modificado esto, podemos reiniciar el servicio:

```
systemctl restart nagios-nrpe-server
```

Ahora, en el lado del servidor, debemos instalar el plugin de Nagios-NRPE:

```
dnf install nagios-plugins-nrpe -y
```

Podemos probar si tiene conectividad con el resto de clientes:

![img_5.png](/images/monitorizacion_nagios/img_5.png)

Si no funciona el plugin anterior (cosa que me ha ocurrido por haber compilado Nagios en lugar de instalarlo desde las fuentes), debemos compilar el plugin NRPE nosotros. Para ello, descargamos el fichero con las fuentes:

```
wget --no-check-certificate -O nrpe.tar.gz https://github.com/NagiosEnterprises/nrpe/archive/nrpe-4.0.3.tar.gz

tar xzf nrpe.tar.gz
```

Y lo compilamos:

```
cd nrpe-nrpe-4.0.3/

./configure --enable-command-args

make all

make install
```

Con esto, ya hemos terminado de compilar el plugin.

Vemos que podemos conectarnos con todos los clientes, aunque la versión de Ares es diferente por ser una máquina Ubuntu, por lo que podemos seguir configurando en el lado del servidor. Así pues, en el fichero `/usr/local/nagios/etc/objects/commands.cfg` debemos añadir el siguiente bloque de configuración para el plugin que acabamos de instalar:

```
define command {
        command_name    check_nrpe
        command_line    $USER1$/check_nrpe -H $HOSTADDRESS$ -c $ARG1$
}
```

A continuación, para poder configurar en el servidor cuales son los clientes que debe monitorizar, primero, debemos descomentar la siguiente línea en el fichero de configuración de Nagios (`/usr/local/nagios/etc/nagios.cfg`):

```
cfg_dir=/usr/local/nagios/etc/servers
```

Como vemos esta línea hace referencia a un directorio que no existe, por lo que debemos crearlo primero:

```
mkdir /usr/local/nagios/etc/servers
```

En ese directorio vamos a crear el fichero de configuración en el cual definiremos los clientes y servicios que queramos monitorizar:

```
nano /etc/nagios/servers/config.cfg

# HOSTS

# Zeus
define host {
        use                     linux-server
        host_name               zeus
        alias                   Zeus
        address                 172.16.0.1
}

# Ares
define host {
        use                     linux-server
        host_name               ares
        alias                   Ares
        address                 10.0.1.101
}

# Apolo
define host {
        use                     linux-server
        host_name               apolo
        alias                   Apolo
        address                 10.0.1.102
}

# SERVICIOS

# Zeus
define service{
        use                     generic-service
        host_name               zeus
        service_description     Numero usuarios
        check_command           check_nrpe!check_users
}


define service{
        use                     generic-service
        host_name               zeus
        service_description     SSH
        check_command           check_ssh
}

define service{
        use                     generic-service
        host_name               zeus
        service_description     Carga CPU
        check_command           check_nrpe!check_load
}

define service{
        use                     generic-service
        host_name               zeus
        service_description     Total Procesos
        check_command           check_nrpe!check_total_procs
}

# Ares
define service{
        use                     generic-service
        host_name               ares
        service_description     Numero usuarios
        check_command           check_nrpe!check_users
}


define service{
        use                     generic-service
        host_name               ares
        service_description     SSH
        check_command           check_ssh
}

define service{
        use                     generic-service
        host_name               ares
        service_description     Carga CPU
        check_command           check_nrpe!check_load
}

define service{
        use                     generic-service
        host_name               ares
        service_description     Total Procesos
        check_command           check_nrpe!check_total_procs
}

# Apolo
define service{
        use                     generic-service
        host_name               apolo
        service_description     Numero usuarios
        check_command           check_nrpe!check_users
}


define service{
        use                     generic-service
        host_name               apolo
        service_description     SSH
        check_command           check_ssh
}

define service{
        use                     generic-service
        host_name               apolo
        service_description     Carga CPU
        check_command           check_nrpe!check_load
}

define service{
        use                     generic-service
        host_name               apolo
        service_description     Total Procesos
        check_command           check_nrpe!check_total_procs
}
```

Ahora debemos añadir al cortafuegos de Hera la regla que permita el paso al servicio 'Nagios NRPE':

```
firewall-cmd --permanent --add-service=nrpe

firewall-cmd --reload
```

Y reiniciamos el servicio de Nagios:

```
systemctl restart nagios
```

En este momento, ya deberíamos poder visualizar a todos los clientes en el panel de control de Nagios:

![img_6.png](/images/monitorizacion_nagios/img_6.png)

Si nos dirigimos a la pestaña de servicios, vemos que todos todos están en verde y funcionando:

![img_7.png](/images/monitorizacion_nagios/img_7.png)

Con esto, damos por finalizada la práctica.
