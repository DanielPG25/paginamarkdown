+++ 
draft = true
date = 2021-11-15T17:36:46+01:00
title = "Delegación de subdominios con bind9"
description = "Delegación de subdominios con bind9"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Servicios de Red"]
externalLink = ""
series = []
+++

# Delegación de subdominios con bind9

Tenemos un servidor DNS que gestiona la zona correspondiente al nombre de dominio iesgn.org, en esta ocasión queremos delegar el subdominio informatica.iesgn.org para que lo gestione otro servidor DNS. Por lo tanto tenemos un escenario con dos servidores DNS:

* `tunombre.iesgn.org`, es servidor DNS autorizado para la zona iesgn.org.
* `tunombre-ns.informatica.iesgn.org`, es el servidor DNS para la `zona informatica.iesgn.org` y, está instalado en otra máquina.

Los nombres que vamos a tener en ese subdominio son los siguientes:

* `www.informatica.iesgn.org` corresponde a un sitio web que está alojado en el servidor web del departamento de informática.
* Vamos a suponer que tenemos un servidor ftp que se llame `ftp.informatica.iesgn.org` y que está en la misma máquina.
* Vamos a suponer que tenemos un servidor para recibir los correos que se llame `correo.informatica.iesgn.org`.

Realiza la instalación y configuración del nuevo servidor dns con las características anteriormente señaladas.

------------------------------------------------------------------------------------------------------------------------------------------------

En primer lugar debemos cambiar el nombre (FQDN) de nuestra máquina que va a funcionar como el delegado del subdominio:

![FQDN_delegado.png](/images/delegacion_subdominios/FQDN_delegado.png)

Una vez hecho eso, vamos a configurar la máquina principal para que delegue el subdominio `informatica.iesgn.org`. Para ello hemos de modificar el fichero de la zona `iesgn.org` y añadir la siguiente información al final del mismo:

```
nano /var/cache/bind/db.iesgn.org 

$ORIGIN informatica.iesgn.org.

@               IN      NS      dparrales-ns
dparrales-ns    IN      A       192.168.121.215
```

También hemos de modificar el fichero `nano /etc/bind/named.conf.options` y añadir/modificar la siguiente línea para permitir que el servidor principal pregunte al delegado:

```
allow-recursion { any; };
```

Con esto ya podemos crear la configuración de la zona directa, así como la zona directa en la máquina `dparrales-ns.informatica.iesgn.org`:

```
nano /etc/bind/named.conf.local

include "/etc/bind/zones.rfc1918";
zone "informatica.iesgn.org" {
        type master;
        file "db.informatica.iesgn.org";
};
```

```
nano /var/cache/bind/db.informatica.iesgn.org

$TTL    86400
@       IN      SOA     dparrales-ns.informatica.iesgn.org. root-informatica.iesgn. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                          86400 )       ; Negative Cache TTL
;
@       IN      NS      dparrales-ns.informatica.iesgn.org.
@       IN      MX      10 correo.informatica.iesgn.org.

$ORIGIN informatica.iesgn.org.

dparrales-ns    IN      A       192.168.121.215
departamento    IN      A       192.168.121.218
ftp             IN      A       192.168.121.215
correo          IN      A       192.168.121.217
www             IN      CNAME   departamento
```

Ya podemos reiniciar el servicio en las dos máquinas y comenzar a hacer pruebas:

```
systemctl restart bind9
```

* **Nota:** Hay que recordar modificar el fichero `/etc/resolv.conf` para que usemos el dns principal.

Empecemos a hacer consultas:

* `www.informatica.iesgn.org`:

![dig_wwwinformatica.png](/images/delegacion_subdominios/dig_wwwinformatica.png)

* `ftp.informatica.iesgn.org`:

![dig_ftpinformatica.png](/images/delegacion_subdominios/dig_ftpinformatica.png)

* Zona de autoridad de `informatica.iesgn.org`:

![dig_soa_informatica.png](/images/delegacion_subdominios/dig_soa_informatica.png)

* Zona de autoridad de `iesgn.org`:

![dig_soa_iesgn.png](/images/delegacion_subdominios/dig_soa_iesgn.png)

* Servidor de correo de `informatica.iesgn.org`:

![dig_mx_informatica.png](/images/delegacion_subdominios/dig_mx_informatica.png)
