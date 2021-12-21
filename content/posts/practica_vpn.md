+++ 
draft = true
date = 2021-12-21T13:18:10+01:00
title = "Configuración de VPN en OpenVPN y Wireguard"
description = "Configuración de VPN en OpenVPN y Wireguard"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Seguridad y Alta Disponibilidad"]
externalLink = ""
series = []
+++

# Redes Privadas Virtuales (VPN)

## VPN de acceso remoto con OpenVPN y certificados x509

Configura una conexión VPN de acceso remoto entre dos equipos del cloud: 

* Uno de los dos equipos (el que actuará como servidor) estará conectado a dos redes 
* Para la autenticación de los extremos se usarán obligatoriamente certificados digitales, que se generarán utilizando openssl y se almacenarán en el directorio `/etc/openvpn`, junto con  los parámetros Diffie-Hellman y el certificado de la propia Autoridad de Certificación. 
* Se utilizarán direcciones de la red 10.99.99.0/24 para las direcciones virtuales de la VPN. La dirección 10.99.99.1 se asignará al servidor VPN. 
* Los ficheros de configuración del servidor y del cliente se crearán en el directorio /etc/openvpn de cada máquina, y se llamarán servidor.conf y cliente.conf respectivamente. 
* Tras el establecimiento de la VPN, la máquina cliente debe ser capaz de acceder a una máquina que esté en la otra red a la que está conectado el servidor. 
---------------------------------------------------------------------------

Para empezar vamos a crear el escenario usando vagrant. Para ello hemos creado el siguiente Vagrantfile:

```
  Vagrant.configure("2") do |config|
    config.vm.provider :libvirt do |libvirt|
        libvirt.memory = 1024
    end
    config.vm.define :nodo1 do |nodo1|
      nodo1.vm.box = "debian/bullseye64"
      nodo1.vm.hostname = "Servidorvpn"
      nodo1.vm.synced_folder ".", "/vagrant", disabled: true
      nodo1.vm.network :private_network,
	   :libvirt__network_name => "vpn1",
	   :libvirt__dhcp_enabled => false,
	   :ip => "192.168.10.10",
       :mode => "veryisolated"
      nodo1.vm.network :private_network,
        :libvirt__network_name => "vpn2",
        :libvirt__dhcp_enabled => false,
        :ip => "192.168.11.10",
        :libvirt__forward_mode => "veryisolated"
     end
    config.vm.define :nodo2 do |nodo2|
      nodo2.vm.synced_folder ".", "/vagrant", disabled: true
      nodo2.vm.box = "debian/bullseye64"
      nodo2.vm.hostname = "Clientevpn1"
      nodo2.vm.network :private_network,
        :libvirt__network_name => "vpn1",
        :libvirt__dhcp_enabled => false,
        :ip => "192.168.10.11",
        :libvirt__forward_mode => "veryisolated"
     end
     config.vm.define :nodo3 do |nodo3|
      nodo3.vm.synced_folder ".", "/vagrant", disabled: true
      nodo3.vm.box = "debian/bullseye64"
      nodo3.vm.hostname = "Clientevpn2"
      nodo3.vm.network :private_network,
        :libvirt__network_name => "vpn2",
        :libvirt__dhcp_enabled => false,
        :ip => "192.168.11.11",
        :libvirt__forward_mode => "veryisolated"
     end

  end
```

Ahora, en la máquina que actúa como servidor debemos instalar openvpn y activar el bit de forwarding:

```
apt install openvpn

nano /etc/sysctl.conf
net.ipv4.ip_forward=1
```

A continuación copiaremos la configuración que se encuentra en `/usr/share/easy-rsa` a `/etc/openvpn` para evitar que futuras actualizaciones del paquete sobrescriban los cambios que hagamos:

```
cp -r /usr/share/easy-rsa /etc/openvpn
cd /etc/openvpn/easy-rsa/
```

Inicializamos el directorio PKI:

```
./easyrsa init-pki

init-pki complete; you may now create a CA or requests.
Your newly created PKI dir is: /etc/openvpn/easy-rsa/pki
```

Después vamos a generar el certificado de la CA y la clave con la que firmaremos los certificados de los clientes y el servidor.

```
./easyrsa build-ca

Using SSL: openssl OpenSSL 1.1.1k  25 Mar 2021

Enter New CA Key Passphrase: 
Re-Enter New CA Key Passphrase: 
Generating RSA private key, 2048 bit long modulus (2 primes)
................................+++++
..........................+++++
e is 65537 (0x010001)
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [Easy-RSA CA]:DanielP CA

CA creation complete and you may now import and sign cert requests.
Your new CA certificate file for publishing is at:
/etc/openvpn/easy-rsa/pki/ca.crt
```

He usado como frase de paso "admin". Tal y como indica la salida del comando, el certificado de ha creado en `/etc/openvpn/easy-rsa/pki/ca.crt`, mientras la clave privada se encuentra en `/etc/openvpn/easy-rsa/pki/private/ca.key`.

Ahora tenemos que generar los parámetros Diffie-Hellman, los cuáles se usaran para el intercambio de claves durante el apretón de manos TLS entre el servidor de OpenVPN y los clientes que se conecten:

```
./easyrsa gen-dh

Using SSL: openssl OpenSSL 1.1.1k  25 Mar 2021
Generating DH parameters, 2048 bit long safe prime, generator 2
This is going to take a long time
..........+..........................................................................................................................................................................................................................+......................................+................................+........................................................................................................................++*++*++*++*

DH parameters of size 2048 created at /etc/openvpn/easy-rsa/pki/dh.pem
```

Como vemos, nos lo ha generado en `/etc/openvpn/easy-rsa/pki/dh.pem`.

A continuación generaremos el certificado y la clave privada del servidor OpenVPN:

```
./easyrsa build-server-full server nopass

Using SSL: openssl OpenSSL 1.1.1k  25 Mar 2021
Generating a RSA private key
...............+++++
.......................+++++
writing new private key to '/etc/openvpn/easy-rsa/pki/easy-rsa-11151.6BgzTs/tmp.kB24eY'
-----
Using configuration from /etc/openvpn/easy-rsa/pki/easy-rsa-11151.6BgzTs/tmp.i9X318
Enter pass phrase for /etc/openvpn/easy-rsa/pki/private/ca.key:
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'server'
Certificate is to be certified until Mar 20 18:37:06 2024 GMT (825 days)

Write out database with 1 new entries
Data Base Updated
```

* **"nopass"** deshabilita el uso de la frase de paso.

El certificado se ha guardado en `/etc/openvpn/easy-rsa/pki/issued/server.crt` y la clave privada se ha generado en `/etc/openvpn/easy-rsa/pki/private/server.key`.

Al igual que hemos hecho con el servidor, generaremos el certificado y la clave privada del cliente de la vpn (al que yo llamé Clientevpn1):

```
./easyrsa build-client-full Clientevpn1 nopass

Using SSL: openssl OpenSSL 1.1.1k  25 Mar 2021
Generating a RSA private key
............................+++++
......................................................................................................................+++++
writing new private key to '/etc/openvpn/easy-rsa/pki/easy-rsa-11244.eojn3N/tmp.XGHmjw'
-----
Using configuration from /etc/openvpn/easy-rsa/pki/easy-rsa-11244.eojn3N/tmp.JwEEK7
Enter pass phrase for /etc/openvpn/easy-rsa/pki/private/ca.key:
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'Clientevpn1'
Certificate is to be certified until Mar 20 18:55:53 2024 GMT (825 days)

Write out database with 1 new entries
Data Base Updated
```

El certificado se ha generado en `/etc/openvpn/easy-rsa/pki/issued/Clientevpn1.crt` y la clave privada se ha generado en `/etc/openvpn/easy-rsa/pki/private/Clientevpn1.key`. Tenemos todos estos ficheros en el lado del servidor, pero para que sea efectivo tenemos que traspasar los ficheros necesarios al cliente. Para ello, primero vamos a introducirlos todos en una carpeta para tenerlos más organizados:

```
mkdir /home/vagrant/Clientevpn1

cp -rp /etc/openvpn/easy-rsa/pki/{ca.crt,issued/Clientevpn1.crt,private/Clientevpn1.key} /home/vagrant/Clientevpn1

chown -R vagrant: /home/vagrant/Clientevpn1/

scp -r /home/vagrant/Clientevpn1/ vagrant@192.168.10.11:
```

Ahora crearemos en el lado del servidor el fichero de configuración del túnel que crearemos a partir del fichero de ejemplo existente:

```
cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/server/servidor.conf
```

```
nano /etc/openvpn/server/servidor.conf 

port 1194
proto udp
dev tun

ca /etc/openvpn/easy-rsa/pki/ca.crt
cert /etc/openvpn/easy-rsa/pki/issued/server.crt
key /etc/openvpn/easy-rsa/pki/private/server.key
dh /etc/openvpn/easy-rsa/pki/dh.pem

topology subnet

server 10.99.99.0 255.255.255.0  -> El rango de ip de la interfaz que se creará (el servidor coge por defecto la primera)
ifconfig-pool-persist /var/log/openvpn/ipp.txt

push "route 192.168.11.0 255.255.255.0" -> La ruta que pasaremos al cliente de la vpn

keepalive 10 120
cipher AES-256-CBC
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
verb 3
explicit-exit-notify 1
```

Una vez creado este fichero en el servidor, podemos activar y habilitar el servicio:

```
systemctl enable --now openvpn-server@servidor
```

Vemos el servicio activo:

```
systemctl status openvpn-server@servidor
● openvpn-server@servidor.service - OpenVPN service for servidor
     Loaded: loaded (/lib/systemd/system/openvpn-server@.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2021-12-16 20:03:27 UTC; 32s ago
       Docs: man:openvpn(8)
             https://community.openvpn.net/openvpn/wiki/Openvpn24ManPage
             https://community.openvpn.net/openvpn/wiki/HOWTO
   Main PID: 11404 (openvpn)
     Status: "Initialization Sequence Completed"
      Tasks: 1 (limit: 1132)
     Memory: 1020.0K
        CPU: 8ms
     CGroup: /system.slice/system-openvpn\x2dserver.slice/openvpn-server@servidor.service
             └─11404 /usr/sbin/openvpn --status /run/openvpn-server/status-servidor.log --status-version 2 --suppress-timestamps --config servidor.conf

Dec 16 20:03:27 Servidorvpn openvpn[11404]: net_iface_up: set tun0 up
Dec 16 20:03:27 Servidorvpn openvpn[11404]: net_addr_v4_add: 10.99.99.1/24 dev tun0
Dec 16 20:03:27 Servidorvpn openvpn[11404]: Could not determine IPv4/IPv6 protocol. Using AF_INET
Dec 16 20:03:27 Servidorvpn openvpn[11404]: Socket Buffers: R=[212992->212992] S=[212992->212992]
Dec 16 20:03:27 Servidorvpn openvpn[11404]: UDPv4 link local (bound): [AF_INET][undef]:1194
Dec 16 20:03:27 Servidorvpn openvpn[11404]: UDPv4 link remote: [AF_UNSPEC]
Dec 16 20:03:27 Servidorvpn openvpn[11404]: MULTI: multi_init called, r=256 v=256
Dec 16 20:03:27 Servidorvpn openvpn[11404]: IFCONFIG POOL IPv4: base=10.99.99.2 size=252
Dec 16 20:03:27 Servidorvpn openvpn[11404]: IFCONFIG POOL LIST
Dec 16 20:03:27 Servidorvpn openvpn[11404]: Initialization Sequence Completed
```

En el cliente que queremos que use la vpn (Clientevpn1), tenemos que instalar el paquete openvpn:

```
apt install openvpn
```

Movemos al lugar adecuado los ficheros que pasamos antes por scp:

```
mv Clientevpn1/* /etc/openvpn/client/
```

Y les cambiamos el propietario a root:

```
chown root: /etc/openvpn/client/*
``` 

Al igual que hicimos con el servidor, copiamos la plantilla de configuración del cliente y la modificamos para que se adapte a nuestras circunstancias:

```
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/openvpn/client/cliente.conf
```

```
nano /etc/openvpn/client/cliente.conf

client
dev tun
proto udp

remote 192.168.10.10 1194
resolv-retry infinite
nobind
persist-key
persist-tun

ca /etc/openvpn/client/ca.crt
cert /etc/openvpn/client/Clientevpn1.crt
key /etc/openvpn/client/Clientevpn1.key

remote-cert-tls server
cipher AES-256-CBC
verb 3
```

Habilitamos y empezamos el servicio:

```
systemctl enable --now openvpn-client@cliente
```

Y verificamos si el servicio está funcionando correctamente:

```
systemctl status openvpn-client@cliente

● openvpn-client@cliente.service - OpenVPN tunnel for cliente
     Loaded: loaded (/lib/systemd/system/openvpn-client@.service; enabled; vendor preset: enabled)
     Active: active (running) since Fri 2021-12-17 08:48:00 UTC; 1min 1s ago
       Docs: man:openvpn(8)
             https://community.openvpn.net/openvpn/wiki/Openvpn24ManPage
             https://community.openvpn.net/openvpn/wiki/HOWTO
   Main PID: 1049 (openvpn)
     Status: "Initialization Sequence Completed"
      Tasks: 1 (limit: 1132)
     Memory: 2.1M
        CPU: 15ms
     CGroup: /system.slice/system-openvpn\x2dclient.slice/openvpn-client@cliente.service
             └─1049 /usr/sbin/openvpn --suppress-timestamps --nobind --config cliente.conf

Dec 17 08:48:00 Clientevpn1 openvpn[1049]: net_route_v4_best_gw query: dst 0.0.0.0
Dec 17 08:48:00 Clientevpn1 openvpn[1049]: net_route_v4_best_gw result: via 192.168.121.1 dev eth0
Dec 17 08:48:00 Clientevpn1 openvpn[1049]: ROUTE_GATEWAY 192.168.121.1/255.255.255.0 IFACE=eth0 HWADDR=52:54:00:ce:13:ed
Dec 17 08:48:00 Clientevpn1 openvpn[1049]: TUN/TAP device tun0 opened
Dec 17 08:48:00 Clientevpn1 openvpn[1049]: net_iface_mtu_set: mtu 1500 for tun0
Dec 17 08:48:00 Clientevpn1 openvpn[1049]: net_iface_up: set tun0 up
Dec 17 08:48:00 Clientevpn1 openvpn[1049]: net_addr_v4_add: 10.99.99.2/24 dev tun0
Dec 17 08:48:00 Clientevpn1 openvpn[1049]: net_route_v4_add: 192.168.11.0/24 via 10.99.99.1 dev [NULL] table 0 metric -1
Dec 17 08:48:00 Clientevpn1 openvpn[1049]: WARNING: this configuration may cache passwords in memory -- use the auth-nocache option to prevent this
Dec 17 08:48:00 Clientevpn1 openvpn[1049]: Initialization Sequence Completed
```

Podemos ver que tanto en el servidor como en el cliente se han creado dos interfaces llamadas "tun0" con la ip que asignamos en el servidor:

![interfaces_tun0.png](/images/practica_vpn/interfaces_tun0.png)

En el cliente interno (yo lo he llamado Clientevpn2) solo tenemos que cambiar la ruta por defecto para que use el servidor:

```
ip route del default
ip route add default via 192.168.11.10
```

**Pruebas de funcionamiento (todas hechas desde Clientevpn1):**

* Ping a Clientevpn2:

![ping_a_interno.png](/images/practica_vpn/ping_a_interno.png)

* Traceroute a Clientevpn2:

![traceroute_interno.png](/images/practica_vpn/traceroute_interno.png)

Como vemos, el clientevpn (Clientevpn1) puede hacer ping perfectamente a la máquina en la otra red y si vemos la salida del comando traceroute, atraviesa el túnel para llegar a su destino.

## VPN sitio a sitio con OpenVPN y certificados x509

Configura una conexión VPN sitio a sitio entre dos equipos del cloud: 

* Cada equipo estará conectado a dos redes, una de ellas en común 
* Para la autenticación de los extremos se usarán obligatoriamente certificados digitales, que se generarán utilizando openssl y se almacenarán en el directorio /etc/openvpn, junto con con los parámetros Diffie-Hellman y el certificado de la propia Autoridad de Certificación. 
* Se utilizarán direcciones de la red 10.99.99.0/24 para las direcciones virtuales de la VPN. 
* Tras el establecimiento de la VPN, una máquina de cada red detrás de cada servidor VPN debe ser capaz de acceder a una máquina del otro extremo. 
------------------------------------------------------------------------------

Para esta parte de la práctica, he optado por hacerla en dos escenarios Vagrant, por lo cuál esta parte habrá dos Vagrantfiles diferentes:  

El Vagrantfile del primer escenario que montaremos (el que actuará como servidor):

```
Vagrant.configure("2") do |config|
    config.vm.provider :libvirt do |libvirt|
        libvirt.memory = 1024
    end
    config.vm.define :nodo1 do |nodo1|
      nodo1.vm.box = "debian/bullseye64"
      nodo1.vm.hostname = "Servidor"
      nodo1.vm.synced_folder ".", "/vagrant", disabled: true
      nodo1.vm.network :private_network,
        :libvirt__network_name => "privadavpn",
        :libvirt__dhcp_enabled => false,
        :ip => "172.30.0.10",
        :netmask => "255.255.255.0",
        :libvirt__forward_mode => "veryisolated"
    end
    config.vm.define :nodo2 do |nodo2|
      nodo2.vm.synced_folder ".", "/vagrant", disabled: true
      nodo2.vm.box = "debian/bullseye64"
      nodo2.vm.hostname = "Cliente"
      nodo2.vm.network :private_network,
        :libvirt__network_name => "privadavpn",
        :libvirt__dhcp_enabled => false,
        :ip => "172.30.0.11",
        :netmask => "255.255.255.0",
        :libvirt__forward_mode => "veryisolated"
     end
  end
```

El Vagrantfile del segundo escenario que montaremos (el que actuará como cliente):

```
Vagrant.configure("2") do |config|
    config.vm.provider :libvirt do |libvirt|
        libvirt.memory = 1024
    end
    config.vm.define :nodo1 do |nodo1|
      nodo1.vm.box = "debian/bullseye64"
      nodo1.vm.hostname = "Servidor2"
      nodo1.vm.synced_folder ".", "/vagrant", disabled: true
      nodo1.vm.network :private_network,
        :libvirt__network_name => "privadvpn2",
        :libvirt__dhcp_enabled => false,
        :ip => "172.20.0.10",
        :netmask => "255.255.255.0",
        :libvirt__forward_mode => "veryisolated"
    end
    config.vm.define :nodo2 do |nodo2|
      nodo2.vm.synced_folder ".", "/vagrant", disabled: true
      nodo2.vm.box = "debian/bullseye64"
      nodo2.vm.hostname = "Cliente2"
      nodo2.vm.network :private_network,
        :libvirt__network_name => "privadvpn2",
        :libvirt__dhcp_enabled => false,
        :ip => "172.20.0.11",
        :netmask => "255.255.255.0",
        :libvirt__forward_mode => "veryisolated"
     end
  end
```

Tendremos el siguiente escenario:

* En la red del escenario 1 (172.30.0.0/24): Habrá dos máquinas conectadas a través de una red interna. La máquina "Servidor" tendrá salida a Internet y será alcanzable por "Servidor2", mientras que la máquina "Cliente" solo tendrá acceso a la máquina "Servidor" del primer escenario.
* En la red del escenario 2 (172.20.0.0/24): Habrá también dos máquinas, una "Servidor2" que será accesible por mi máquina "Servidor", y otra máquina "Cliente2", que estará conectada únicamente a la máquina "Servidor2".

El escenario que deberíamos tener al final sería el siguiente:

![openvpn2_escenario.png](/images/practica_vpn/openvpn2_escenario.png)

### Configuración en el escenario 1 (servidor)

En primer lugar tendremos que crear un fichero llamado vars (cuyo contenido lo sacaremos de una plantilla que hay en el mismo directorio), para que contenga la información que después tendrá nuestra Autoridad Certificadora:

```
apt install openvpn

cd /usr/share/easy-rsa/

cp vars.example vars
```

```
nano vars

set_var EASYRSA_REQ_COUNTRY     "ES"
set_var EASYRSA_REQ_PROVINCE    "Sevilla"
set_var EASYRSA_REQ_CITY        "Dos Hermanas"
set_var EASYRSA_REQ_ORG         "DParrales Corp"
set_var EASYRSA_REQ_EMAIL       "daniparrales16@gmail.com"
set_var EASYRSA_REQ_OU          "Ejercicio VPN"
```

Ahora tendremos que crear el directorio en el que se almacenarán todos los documentos de la Autoridad Certificadora (certificados, claves, base de datos, etc):

```
./easyrsa init-pki

Note: using Easy-RSA configuration from: /usr/share/easy-rsa/vars

init-pki complete; you may now create a CA or requests.
Your newly created PKI dir is: /usr/share/easy-rsa/pki
```

Por último, antes de crear la Autoridad Certificadora, tendremos que crear una clave "Diffie-Hellman":

```
./easyrsa gen-dh

Note: using Easy-RSA configuration from: /usr/share/easy-rsa/vars
Using SSL: openssl OpenSSL 1.1.1k  25 Mar 2021
Generating DH parameters, 2048 bit long safe prime, generator 2
This is going to take a long time
...

DH parameters of size 2048 created at /usr/share/easy-rsa/pki/dh.pem
```

Ahora ya podemos crear la Autoridad Certificadora propiamente dicha:

```
./easyrsa build-ca

Note: using Easy-RSA configuration from: /usr/share/easy-rsa/vars
Using SSL: openssl OpenSSL 1.1.1k  25 Mar 2021

Enter New CA Key Passphrase: 
Re-Enter New CA Key Passphrase: 
Generating RSA private key, 2048 bit long modulus (2 primes)
.....................+++++
........+++++
e is 65537 (0x010001)
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [Easy-RSA CA]:Daniel Parrales

CA creation complete and you may now import and sign cert requests.
Your new CA certificate file for publishing is at:
/usr/share/easy-rsa/pki/ca.crt
```

*Nota:* He usado como frase de paso "admin".

Ya tenemos nuestra Autoridad Certificadora lista, por lo que lo primero que tenemos que hacer es crear y firmar el certificado que usará nuestra máquina "Servidor":

```
./easyrsa gen-req server

Note: using Easy-RSA configuration from: /usr/share/easy-rsa/vars
Using SSL: openssl OpenSSL 1.1.1k  25 Mar 2021
Generating a RSA private key
.................................................................+++++
.............................................................+++++
writing new private key to '/usr/share/easy-rsa/pki/easy-rsa-2607.kRaUMy/tmp.xmX9Ls'
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [server]:Daniel Parrales

Keypair and certificate request completed. Your files are:
req: /usr/share/easy-rsa/pki/reqs/server.req
key: /usr/share/easy-rsa/pki/private/server.key
```

```
./easyrsa sign-req server server

Note: using Easy-RSA configuration from: /usr/share/easy-rsa/vars
Using SSL: openssl OpenSSL 1.1.1k  25 Mar 2021


You are about to sign the following certificate.
Please check over the details shown below for accuracy. Note that this request
has not been cryptographically verified. Please be sure it came from a trusted
source or that you have verified the request checksum with the sender.

Request subject, to be signed as a server certificate for 825 days:

subject=
    commonName                = Daniel Parrales


Type the word 'yes' to continue, or any other input to abort.
  Confirm request details: yes
Using configuration from /usr/share/easy-rsa/pki/easy-rsa-2630.7OVVJb/tmp.Y58ckr
Enter pass phrase for /usr/share/easy-rsa/pki/private/ca.key:
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'Daniel Parrales'
Certificate is to be certified until Mar 21 12:55:35 2024 GMT (825 days)

Write out database with 1 new entries
Data Base Updated

Certificate created at: /usr/share/easy-rsa/pki/issued/server.crt
```

Una vez que hemos creado el certificado del servidor y lo hemos firmado, pasemos a crear y firmar el certificado que usará la máquina "Servidor2" del escenario 2 para acceder a la VPN:

```
./easyrsa gen-req vpn_escenario2

Note: using Easy-RSA configuration from: /usr/share/easy-rsa/vars
Using SSL: openssl OpenSSL 1.1.1k  25 Mar 2021
Generating a RSA private key
.................................................................+++++
..................................+++++
writing new private key to '/usr/share/easy-rsa/pki/easy-rsa-812.6YAPy7/tmp.NEciwr'
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [vpn_escenario2]:Servidor2

Keypair and certificate request completed. Your files are:
req: /usr/share/easy-rsa/pki/reqs/vpn_escenario2.req
key: /usr/share/easy-rsa/pki/private/vpn_escenario2.key
```

```
./easyrsa sign-req client vpn_escenario2

Note: using Easy-RSA configuration from: /usr/share/easy-rsa/vars
Using SSL: openssl OpenSSL 1.1.1k  25 Mar 2021


You are about to sign the following certificate.
Please check over the details shown below for accuracy. Note that this request
has not been cryptographically verified. Please be sure it came from a trusted
source or that you have verified the request checksum with the sender.

Request subject, to be signed as a client certificate for 825 days:

subject=
    commonName                = Servidor2


Type the word 'yes' to continue, or any other input to abort.
  Confirm request details: yes
Using configuration from /usr/share/easy-rsa/pki/easy-rsa-834.fEy1Wv/tmp.MaxeLQ
Enter pass phrase for /usr/share/easy-rsa/pki/private/ca.key:
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'Servidor2'
Certificate is to be certified until Mar 22 11:41:33 2024 GMT (825 days)

Write out database with 1 new entries
Data Base Updated

Certificate created at: /usr/share/easy-rsa/pki/issued/vpn_escenario2.crt
```

Ahora vamos a tener que copiar los ficheros que necesitaremos para que el servidor vpn funcione a `/etc/openvpn/server`:

```
cp ca.crt /etc/openvpn/server/

cp dh.pem /etc/openvpn/server/

cp issued/server.crt /etc/openvpn/server/

cp private/server.key /etc/openvpn/server/
```

Tenemos que hacer llegar a la máquina "Servidor2" los ficheros que necesitará para conectarse a mi servidor VPN. En mi caso he usado scp, pero hay muchos más métodos para pasarlos:

```
scp ca.crt vagrant@192.168.121.212:

scp issued/vpn_escenario2.crt vagrant@192.168.121.212:

scp private/vpn_escenario2.key vagrant@192.168.121.212:
```

En este momento tendremos que crear el fichero de configuración del servidor vpn, para lo cual podremos apoyarnos en una plantilla que nos ofrece el paquete de OpenVPN:

```
cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/server/servidor.conf
```

```
nano /etc/openvpn/server/servidor.conf

dev tun    -> La interfaz que se creará será de tipo tun, es decir, encapsula IPv4 o IPv6

ifconfig 10.99.99.1 10.99.99.2     -> Indicamos la ip de este lado del túnel (10.99.99.1) y la ip del otro extremo del túnel (10.99.99.2)

route 172.20.0.0 255.255.255.0     -> Indicamos la ruta de la red(es) a la que llevará el túnel. 

tls-server -> Indica que esta máquina va a funcionar como servidor en modo seguro (activando las capas de TLS activadas)

ca ca.crt  -> Certificado de la autoridad certificadora

cert server.crt  -> Certificado del servidor firmado por la autoridad certificadora

key server.key   -> Clave privada que corresponde al certificado anterior

dh dh.pem  -> Parámetros de Diffie-Hellman que hemos generado antes

comp-lzo  -> Modo de compresión para compatibilidad con antiguos clientes (en un futuro esta opción desaparecerá)

keepalive 10 120  ->  Indica el intervalo en que los extremos del túnel comprueban si están conectados (10 segundos). Si no hay ninguna respuesta en 120 segundos se 
                      asume que el otro lado del túnel está caído

log /var/log/openvpn/server.log   -> La ruta del log de openvpn

verb 3   ->  Nivel de verbosidad del log, siendo 0 lo mínimo y 9 el máximo

askpass contra.txt   ->  Fichero donde hemos guardada la contraseña (fase de paso) del certificado. Es recomendable cambiar los permisos del fichero para aumentar la
                         seguridad
```

Ahora podemos iniciar el servicio en el lado del servidor:

```
systemctl start openvpn-server@servidor
```

Podemos ver el servicio activo:

![openvpn2_estadoservidor.png](/images/practica_vpn/openvpn2_estadoservidor.png)

No debemos olvidar el bit de forwarding en el servidor:

```
echo 1 > /proc/sys/net/ipv4/ip_forward
```

También en el cliente del escenario 1 debemos cambiar la ruta por defecto:

```
ip r del default

ip r add default via 172.30.0.10
```

Con esto hemos terminado en el lado del escenario 1.

### Configuración en el escenario 2 (cliente)

En este escenario tenemos que configurar la máquina "Servidor2" para que actúe como el otro extremo del túnel vpn. Para ello, lo primero es mover los ficheros que enviamos desde el escenario 1 a la carpeta adecuada:

```
mv ca.crt /etc/openvpn/client/
mv vpn_escenario2.crt /etc/openvpn/client/
mv vpn_escenario2.key /etc/openvpn/client/
```

Ahora crearemos el fichero de configuración de esta máquina. Para ello tenemos un modelo que podemos seguir, al igual que pasó con el apartado anterior:

```
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/openvpn/client/cliente.conf
```

```
nano /etc/openvpn/client/cliente.conf

dev tun   -> La interfaz que se creará será de tipo tun, es decir, encapsula IPv4 o IPv6

remote 192.168.121.236  -> La ip del servidor en la que estará el otro extremo del túnel

ifconfig 10.99.99.2 10.99.99.1   -> Indicamos la ip de este lado del túnel (10.99.99.2) y la ip del otro extremo del túnel (10.99.99.1)

route 172.30.0.0 255.255.255.0   -> Indicamos la ruta de la red(es) a la que llevará el túnel.

tls-client  -> Indica que esta máquina va a funcionar como cliente en modo seguro (activando las capas de TLS activadas)

ca ca.crt   -> Certificado de la autoridad certificadora

cert vpn_escenario2.crt   -> Certificado del cliente firmado por la autoridad certificadora

key vpn_escenario2.key    -> Clave privada que corresponde al certificado anterior

comp-lzo   -> Modo de compresión para compatibilidad con antiguos clientes (en un futuro esta opción desaparecerá)

keepalive 10 60  -> Indica el intervalo en que los extremos del túnel comprueban si están conectados (10 segundos). Si no hay ninguna respuesta en 60 segundos se 
                    asume que el otro lado del túnel está caído

verb 3  ->  Nivel de verbosidad del log, siendo 0 lo mínimo y 9 el máximo

askpass contra2.txt  -> Fichero donde hemos guardada la contraseña (fase de paso) del certificado. Es recomendable cambiar los permisos del fichero para aumentar la
                        seguridad
```

Ahora iniciamos el servicio:

```
systemctl start openvpn-client@cliente
```

Podemos ver el servicio que acabamos de iniciar:

![openvpn2_estadocliente.png](/images/practica_vpn/openvpn2_estadocliente.png)

También debemos activar el ip de forwarding en esta máquina:

```
echo 1 > /proc/sys/net/ipv4/ip_forward
```

Al igual que antes, también debemos cambiar la ruta del cliente en este escenario:

```
ip r del default

ip r add default via 172.20.0.10
```

Ya hemos terminado de configurar este escenario y podemos pasar a hacer las pruebas:

* Las rutas del servidor del escenario 1:

![openvpn2_rutas1.png](/images/practica_vpn/openvpn2_rutas1.png)

* Las rutas del servidor del escenario 2:

![openvpn2_rutas2.png](/images/practica_vpn/openvpn2_rutas2.png)

* Desde el cliente del escenario 1:

![openvpn2_cliente1.png](/images/practica_vpn/openvpn2_cliente1.png)

* Desde el cliente del escenario 2:

![openvpn2_cliente2.png](/images/practica_vpn/openvpn2_cliente2.png)

Como vemos ambas máquinas clientes tienen conexión entre ellas y observando el "traceroute" podemos ver que pasan a través del túnel para llegar a ellas.

## VPN de acceso remoto con WireGuard

Monta una VPN de acceso remoto usando Wireguard. Intenta probarla con clientes Windows, Linux y Android.
------------------------------------------------

Vamos a montar una vpn de acceso remoto con wireguard la cuál va a tener tres clientes: una máquina debian 11, una máquina windows 7, y una máquina android. La máquina que actuará como servidor será mi anfitrión (Debian 11), y los clientes serán todos máquinas virtuales salvo el dispositivo android. Para hacer las pruebas, he creado otra máquina Debian que estará conectada a una red interna con el anfitrión. Esta máquina será accedida por los clientes a través del túnel vpn que vamos a crear.

A conticuación el Vagrantfile del cliente interno:

```
  Vagrant.configure("2") do |config|
    config.vm.provider :libvirt do |libvirt|
        libvirt.memory = 1024
    end
    config.vm.define :nodo1 do |nodo1|
      nodo1.vm.box = "debian/bullseye64"
      nodo1.vm.hostname = "Interno"
      nodo1.vm.synced_folder ".", "/vagrant", disabled: true
      nodo1.vm.network :private_network,
        :libvirt__network_name => "vpn1",
        :libvirt__dhcp_enabled => false,
        :ip => "192.168.10.10",
        :mode => "veryisolated"
     end
  end
```

En este cliente solo cambiaremos la ruta por defecto:

```
ip r del default

ip r add default via 192.168.10.1
```

### Servidor

Así pues, comencemos con la configuración del servidor. Lo primero es instalar el paquete:

```
apt install wireguard
```

Tenemos que asegurarnos de haber activado el bit de forwarding en nuestro servidor:

```
nano /etc/sysctl.conf

net.ipv4.ip_forward = 1
```

Ahora vamos a tener que crear los ficheros de configuración necesarios en el directorio base de wireguard: 

```
cd /etc/wireguard/
```

Ahora, generaremos el par de claves usando el comando que nos proporcionan en la página oficial de [Wireguard](https://www.wireguard.com/quickstart/):

```
wg genkey | tee serverprivatekey | wg pubkey > serverpublickey
```

```
cat serverprivatekey 
AMY15UaxVGBf5RZGRTQ+GdO5sGZgopQnBW3zocHKG3k=
```

```
cat serverpublickey 
hmgnqoH9VBD9GvDCM5m2rsbZtT+YdBvDDDBWoDV3KW0=
```

En este momento crearemos el fichero de configuración, que tendrá de nombre la interfaz que se creará (wg0):

```
nano wg0.conf

# Server config
[Interface]
Address = 10.99.99.1
PrivateKey = AMY15UaxVGBf5RZGRTQ+GdO5sGZgopQnBW3zocHKG3k=
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o wlp3s0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o wlp3s0 -j MASQUERADE
```

En el fichero anterior nos encontramos con un bloque llamado "Interface" que contiene lo siguiente:

* **Address:** La dirección ip que tendrá el servidor (la dirección de la vpn).
* **PrivateKey:** La clave privada que hemos generado en el servidor.
* **ListenPort:** El puerto por el que escuchará wireguard. No es obligatorio, pero es recomendable (sobre todo a la hora de tratar con firewalls).
* **PostUp / PostDown:** Reglas de iptables que se activarán y desactivarán cuando levantemos la interfaz que hemos definido.

En este momento ya podemos activar la interfaz que hemos creado:

```
wg-quick up wg0
[#] ip link add wg0 type wireguard
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.99.99.1 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o wlp3s0 -j MASQUERADE
```

Podemos ver que el servidor se encuentra activo:

```
wg

interface: wg0
  public key: hmgnqoH9VBD9GvDCM5m2rsbZtT+YdBvDDDBWoDV3KW0=
  private key: (hidden)
  listening port: 51820
```

También podemos ver que se ha creado la interfaz que hemos definido:

![wireguard1_interfaz_servidor.png](/images/practica_vpn/wireguard1_interfaz_servidor.png)

Hemos terminado con la configuración básica del servidor. A continuación configuraremos los clientes.

### Cliente Linux (Debian 11)

El Vagrantfile del cliente:

```
  Vagrant.configure("2") do |config|

    config.vm.provider :libvirt do |v|
      v.memory = 1024
      end
    config.vm.define :nodo1 do |nodo1|
      nodo1.vm.box = "debian/bullseye64"
      nodo1.vm.hostname = "Externo"
      nodo1.vm.synced_folder ".", "/vagrant", disabled: true
      end
    end
```

Al igual que hicimos con el servidor, tendremos que instalar wireguard y crear el par de claves:

```
apt install wireguard

cd /etc/wireguard/

wg genkey | tee clientprivatekey | wg pubkey > clientpublickey
```

```
cat clientprivatekey 
QIahYjtCOHdya2DcjvqksBmTD3L27n3IcD5Ie8eaVmU=
```

```
cat clientpublickey 
QjJfegKzofdcjbpu4Gjl0TX6g0Wj7w1hTHTJNa2cplE=
```

Al igual que hicimos en el servidor, también crearemos un fichero de configuración con la siguiente información:

```
nano wg0.conf

[Interface]
Address = 10.99.99.2
PrivateKey = QIahYjtCOHdya2DcjvqksBmTD3L27n3IcD5Ie8eaVmU=
ListenPort = 51820
PostUp = ip route add 192.168.10.0/24 dev wg0
PostDown = ip route del 192.168.10.0/24 dev wg0

[Peer]
PublicKey = hmgnqoH9VBD9GvDCM5m2rsbZtT+YdBvDDDBWoDV3KW0=
AllowedIPs = 0.0.0.0/0
Endpoint = 192.168.1.11:51820
```

El bloque de "Interface" es similar al del servidor, pero en el cliente hemos añadido un bloque llamado "Peer" que más tarde replicaremos en el servidor, que contiene los siguientes datos:

* **PublicKey:** La clave pública del servidor.
* **PostUp:** Hemos añadido la ruta estática a la red interna con la que nos conectaremos.
* **AllowedIPs:** Lista de direcciones IP de las que puede llegar un paquete sin ser descartado. Actúa de firewall en wireguard.
* **Endpoint:** Ip del servidor de Wireguard (el que configuramos en el apartado anterior).

Con esto ya podemos activar la interfaz que hemos configurado:

```
wg-quick up wg0
[#] ip link add wg0 type wireguard
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.99.99.2/32 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] wg set wg0 fwmark 51820
[#] ip -4 route add 0.0.0.0/0 dev wg0 table 51820
[#] ip -4 rule add not fwmark 51820 table 51820
[#] ip -4 rule add table main suppress_prefixlength 0
[#] sysctl -q net.ipv4.conf.all.src_valid_mark=1
[#] nft -f /dev/fd/63
```

También podemos ver la interfaz que hemos creado:

![wireguard1_interfaz_clientedebian.png](/images/practica_vpn/wireguard1_interfaz_clientedebian.png)

Con esto hemos terminado de configurar el cliente, pero para esto funcione debemos añadir también el bloque "Peer" en el lado del cliente (uno por cada cliente que conectemos). Así pues, el fichero de configuración del servidor quedaría de la siguiente forma:

```
nano wg0.conf

# Server config
[Interface]
Address = 10.99.99.1
PrivateKey = AMY15UaxVGBf5RZGRTQ+GdO5sGZgopQnBW3zocHKG3k=
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o wlp3s0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o wlp3s0 -j MASQUERADE

# Clients configs

# Cliente Debian 11

[Peer]
Publickey = QjJfegKzofdcjbpu4Gjl0TX6g0Wj7w1hTHTJNa2cplE=
AllowedIPs = 10.99.99.2/32
PersistentKeepAlive = 25
```

En el bloque "Peer" hemos incluido lo siguiente:

* **PublicKey:** La clave pública del cliente.
* **PersistentKeepAlive:** Si no hay intercambio de paquetes entre las máquinas tras 25 segundos, se enviará un paquete para averiguar si la conexión sigue activa.

Con este bloque que hemos añadido, ya podemos reiniciar el servicio:

```
wg-quick down wg0

[#] ip link delete dev wg0
[#] iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o wlp3s0 -j MASQUERADE
```

```
wg-quick up wg0

[#] ip link add wg0 type wireguard
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.99.99.1 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] ip -4 route add 10.99.99.2/32 dev wg0
[#] iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o wlp3s0 -j MASQUERADE
```

Podemos ver el servicio activado con el cliente conectado:

```
wg

interface: wg0
  public key: hmgnqoH9VBD9GvDCM5m2rsbZtT+YdBvDDDBWoDV3KW0=
  private key: (hidden)
  listening port: 51820

peer: QjJfegKzofdcjbpu4Gjl0TX6g0Wj7w1hTHTJNa2cplE=
  endpoint: 192.168.121.140:51820
  allowed ips: 10.99.99.2/32
  latest handshake: 3 minutes, 7 seconds ago
  transfer: 1.29 KiB received, 876 B sent
  persistent keepalive: every 25 seconds
```

Con esto ya hemos terminado completamente con el lado del cliente Linux. Probemos si ha funcionado:

* Ping y traceroute desde el cliente externo a la red interna:

![wireguard1_clientedebian.png](/images/practica_vpn/wireguard1_clientedebian.png)

* Ping y traceroute desde el cliente interno a la interfaz del túnel en el cliente externo:

![wireguard1_clientedebian_interno.png](/images/practica_vpn/wireguard1_clientedebian_interno.png)

### Cliente Windows (Windows 7)

El fichero de configuración en Windows es igual que en Linux, por lo que no nos pararemos mucho en ello. Así pues, lo primero es instalar el programa en Windows, que puede descargarse de la [página oficial](https://www.wireguard.com/install/). Una vez hecho esto, abrimos el programa y creamos un túnel vacío (empty tunnel). Windows nos crea automáticamente las claves al pulsar el botón, por lo solo tendremos que rellenar el fichero de configuración de la siguiente forma:

![wireguard1_clientewindows_configuracion.png](/images/practica_vpn/wireguard1_clientewindows_configuracion.png)

Una vez hecho esto, pasamos al lado del servidor, en el cual tendremos que añadir un nuevo bloque "Peer" al igual que hicimos con el cliente linux:

```
nano /etc/wireguard/wg0.conf
 
# Server config
[Interface]
Address = 10.99.99.1
PrivateKey = AMY15UaxVGBf5RZGRTQ+GdO5sGZgopQnBW3zocHKG3k=
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o wlp3s0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o wlp3s0 -j MASQUERADE

# Clients configs

# Cliente Debian 11
[Peer]
Publickey = QjJfegKzofdcjbpu4Gjl0TX6g0Wj7w1hTHTJNa2cplE=
AllowedIPs = 10.99.99.2/32
PersistentKeepAlive = 25

# Cliente Windows 7
[Peer]
Publickey = 5pZtBRqvn9bceifMZypv1Z3F1CcQNLSGKRCBo1ooiVg=
AllowedIPs = 10.99.99.3/32
PersistentKeepAlive = 25
```

Ahora que lo hemos hecho, podemos reiniciar el servicio en el servidor:

```
wg-quick down wg0

wg-quick up wg0
```

Una vez iniciado en el servidor, activamos el túnel en el cliente windows:

![wireguard1_clientewindows_activar.png](/images/practica_vpn/wireguard1_clientewindows_activar.png)

Podemos ver en el lado del servidor que se ha añadido un nuevo "Peer":

![wireguard1_clientewindows_wg.png](/images/practica_vpn/wireguard1_clientewindows_wg.png)

Ahora hagamos las pruebas:

* Ping y traceroute desde el cliente windows a la red interna:

![wireguard1_clientewindows_pruebas.png](/images/practica_vpn/wireguard1_clientewindows_pruebas.png)

* Ping y traceroute desde el cliente interno a la interfaz del túnel en el cliente windows:

![wireguard1_clientewindows_pruebas_interno.png](/images/practica_vpn/wireguard1_clientewindows_pruebas_interno.png)

### Cliente Android

Para usar Wireguard con Android, primero tenemos que descargarnos la aplicación desde la playstore:

![wireguard1_clienteandroid_aplicacion.jpeg](/images/practica_vpn/wireguard1_clienteandroid_aplicacion.jpeg)

Una vez en la aplicación, veremos que nos da tres opciones para crear el túnel:

![wireguard1_clienteandroid_opciones.jpeg](/images/practica_vpn/wireguard1_clienteandroid_opciones.jpeg)

En nuestro caso, considero que es más sencillo usar la opción de "escanear desde código QR". Para ello, primero tendremos que crear el fichero de configuración en nuestra máquina, y después nos descargaremos un paquete para convertir dicho fichero en un código qr que pueda escanear nuestro dispositivo móvil (tenemos que generar el par de claves en el cliente):

```
wg genkey | tee clientprivatekey | wg pubkey > clientpublickey
```

```
cat clientprivatekey 
oBi97Vimt9ZW44Yp+LF8Vww1rCBVBsebbEtDBIsj7Uw=
```

```
cat clientpublickey 
cS8HnKYce0+ZN3SWNPj6x72xTdOJJwtfBCcderWzrGQ=
```

Nos generamos el fichero de configuración tal y como hicimos con el cliente linux:

```
nano clientelinux.conf

[Interface]
Address = 10.99.99.4
PrivateKey = oBi97Vimt9ZW44Yp+LF8Vww1rCBVBsebbEtDBIsj7Uw=
ListenPort = 51820

[Peer]
Publickey = hmgnqoH9VBD9GvDCM5m2rsbZtT+YdBvDDDBWoDV3KW0=
AllowedIPs = 0.0.0.0/0
Endpoint = 192.168.1.118:51820
```

Ahora nos instalamos el paquete para convertir esta configuración en un código qr:

```
apt install qrencode
```

Y lo ejecutamos:

```
qrencode -t ansiutf8 < clientelinux.conf 

█████████████████████████████████████████████████████████████
█████████████████████████████████████████████████████████████
████ ▄▄▄▄▄ █▀▀▄███ ▄█▄  █ ▄█ ▄█ █▄▄▄█ █ ▄▄▄▀██ ▀██ ▄▄▄▄▄ ████
████ █   █ █▀ █▄▀▀▀▀▄▄▄▀▄▀█▀ █▄▀▀  ██▄█▄ ▀▄▄▀ ▀▄▀█ █   █ ████
████ █▄▄▄█ █▀▀▀▄ ██▀▄   ▄ ▀█ ▄▄▄ ▀█▄▀▄█▄ ▄▄▄█▄ ███ █▄▄▄█ ████
████▄▄▄▄▄▄▄█▄█▄▀ █▄▀▄█ ▀ █▄▀ █▄█ ▀ ▀▄▀ ▀▄█ ▀▄▀ █▄█▄▄▄▄▄▄▄████
████▄▄▄▄▄█▄ ▄█▀▄▄██ ▄▄▀▄▀▄██   ▄  ▄▄▄▀▀▀▀▄▀██▄  █▄█▄▀▄▀ ▀████
████▄█▀▄  ▄ ▄▀▀▄▄██▄█  █▄▄▄▀▄▄█▀▄█ █▀ ▄▀ █ ▄ ▀ ▀▄ ▄▄  █▀█████
████▄▄▀█▄▀▄ █ █ ▀█▀▄ ▀█▀▀ ▀▀▄██ █▄▄██▀█▀  ▀▄▄  █▄▄▀█▀▀█▀▀████
████   ▄█▄▄  ▄▄▄▄█▄▄█▀█ ███ ▄▀▀█▄▄▀ █▄██▀▀█▀▀   ▀█▄▄▄ █ █████
████▄▄▄▄▀█▄▄ ▄█   ██▀ ██▀▄   █▀▀██▄▄▄▄▀█▀ ▀ █   ▄▄█  ▄▄█▀████
████▄ █▄▀▄▄▀█   ▄█▄ █▀▀▀███▄█ █ ▄█▀       ▀▄██▄███▄█▄ ▀▀▀████
████▄ ▄█  ▄▀▄ ▀█ █▀▄▀▄ █ ▀▄█ ▄█▀▄▄▄▄▄██ ▀▄▀▀▄▄ ▄  ▀ ▀▄██ ████
█████▄▀▀▄▄▄█ ▄ ▄▄██▄█▄▄▄█▄▄▄ █▀▀▄ █▀███▀██▀▀█▀  █ █▄ ▀▄██████
████▀█▀  ▄▄▄ ▀▀  ██ ▄▀▄  ▄▄▄ ▄▄▄ ▄  █▄▀▄▀▄▀▀ ▀▀▀ ▄▄▄ ▀▄  ████
████▀▄▄  █▄█  ▀▄▀▀▄ ▀▀ ███▄▀ █▄█  ██▄█▀█ █▀▄▀▄██ █▄█ ▄▀██████
████▄▀▄ ▄▄▄  █ █ ▄▀█▀▀█▄▄  █▄  ▄  ▄▄▄▀▀▀  █▄█▄ ▄     ▀█ ▄████
████▄▀▀▄▀▀▄ ██▀▄▀▄  ██▄▄▀▄█▄ ▀▄▄▀▄ ▄ █ █ ▀▄█▄▄▄▄▀▀▀██▀▄█▄████
█████ █  ▀▄▄ ▄▄  ▄▄█ █▄█▀▀▄▄ ██▀█▄  ████▀ ▀▀▀▄█▄▄▄█▄▄█ ▀█████
████ ▄▄ █▄▄▄█▄▀██ ▄██ ▀██ ▄▄▀█▄█▀ ▄ ██▀  ▄▀ █▄▀ ▄   ▄▄▀█▀████
████▀█  ▀█▄▀  ▄  ▄█ ▀▄▀█▄█▄ ▀▄▄█▀▄▄ █▀█▀▀ ▀▄█▀▄█████ ▄▄▄▄████
████▄██   ▄▄▀  ▀▄▀█▄█ ▀▀█▄█▄ ▀▄▄█▄▄▄ ▀▀▄▄▄█ ▀▀▀▀▄█▀ ▄ █▄▄████
████▀▀  █▄▄█ █ ▀█▀█▀▄ ▀ ▀▄ █ ▄▄██▀▄▄▄▀▀ ▀▄▀ ▀▄▄▄ ▄████▄██████
████▄ ▀▄▄▄▄▀▀█▄█ █▀ ▀▀▀▄▀█▄▄████▀▀▀█▀ ▄▄▄▄██▄   █▄  ▄▄▀██████
███████▄██▄█ ▀▀█▀█▀█  ▀  ███ ▄▄▄ ▄▄▀███   █▄█▄ ▀ ▄▄▄ █▄██████
████ ▄▄▄▄▄ █▄▀▄▄▄▀▄ ██▀▀▀█▄▀ █▄█ ▄  ▄██ ▀ █▄ ▄▄▄ █▄█  ▄▄▄████
████ █   █ █ █▀█▄▀▀▀█ █▄   ▄ ▄ ▄▄   ▄▀▀▀▀▄█▄▄ █▀▄ ▄  ▀▄▄█████
████ █▄▄▄█ █  ▀▄▄█▄▀ █  ███▀▀    ▄ ▄█▀ ▄██▄▄█ █▀▄█▄  ▄▀ █████
████▄▄▄▄▄▄▄█▄█▄█▄▄█▄███▄██▄██▄█▄█▄▄▄▄▄██████▄▄▄▄██▄▄▄████████
█████████████████████████████████████████████████████████████
█████████████████████████████████████████████████████████████
```

Ahora lo escaneamos con el móvil. Una vez escaneado podemos ver la configuración que ha importado:

![wireguard1_clienteandroid_configuracion.jpeg](/images/practica_vpn/wireguard1_clienteandroid_configuracion.jpeg)

Ya solo tenemos que añadir el nuevo bloque "Peer" a la configuración del servidor:

```
nano wg0.conf 

# Server config
[Interface]
Address = 10.99.99.1
PrivateKey = AMY15UaxVGBf5RZGRTQ+GdO5sGZgopQnBW3zocHKG3k=
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o br0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o br0 -j MASQUERADE

# Clients configs

# Cliente Debian 11
[Peer]
Publickey = QjJfegKzofdcjbpu4Gjl0TX6g0Wj7w1hTHTJNa2cplE=
AllowedIPs = 10.99.99.2/32
PersistentKeepAlive = 25

# Cliente Windows 7
[Peer]
Publickey = 5pZtBRqvn9bceifMZypv1Z3F1CcQNLSGKRCBo1ooiVg=
AllowedIPs = 10.99.99.3/32
PersistentKeepAlive = 25

# Cliente Android
[Peer]
Publickey = cS8HnKYce0+ZN3SWNPj6x72xTdOJJwtfBCcderWzrGQ=
AllowedIPs = 10.99.99.4/32
PersistentKeepAlive = 25
```

Ahora ya podemos reiniciar el servicio en el servidor:

```
wg-quick down wg0

wg-quick up wg0
```

En este momento podemos ver que están conectados los 3 peers que hemos añadido (tras iniciar el túnel en el dispositivo android):

![wireguard1_clienteandroid_wg.png](/images/practica_vpn/wireguard1_clienteandroid_wg.png)

Ahora ya podemos realizar las pruebas de funcionamiento (nos hemos instalado una aplicación llamada PingTools Network para ejecutar los comandos adecuados):

* Ping y traceroute desde el cliente android a la red interna:

![wireguard1_clienteandroid_ping.jpeg](/images/practica_vpn/wireguard1_clienteandroid_ping.jpeg)

![wireguard1_clienteandroid_traceroute.jpeg](/images/practica_vpn/wireguard1_clienteandroid_traceroute.jpeg)

* Ping y traceroute desde el cliente interno a la interfaz del túnel en el cliente windows:

![wireguard1_clienteandroid_interno_pruebas.png](/images/practica_vpn/wireguard1_clienteandroid_interno_pruebas.png)


### Comparativa con OpenVPN

Tras haber realizado toda la configuración necesaria para el acceso remoto con OpenVPN y Wireguard, puedo afirmar con total seguridad que Wireguard es bastante superior a OpenVPN en todos los sentidos:

* Para empezar, aunque todas las pruebas se han hecho en máquinas virtuales, podemos ver que WireGuard es más rápido que OpenVPN. Esto, en un escenario real puede suponer una gran diferencia, ya que mejoraría mucho la experiencia de los usuarios.
* A nivel de configuración, es mucho más fácil de configurar Wireguard que OpenVPN, compartiendo la misma configuración en los clientes, independientemente de los sistemas operativos de los mismos.
* No es necesario crear una autoridad certificadora con Wireguard, lo que es otro aspecto favorable (al menos para mí).


## VPN site to site con WireGuard

Configura una VPN sitio a sitio usando WireGuard.
--------------------------------------------------------

Al igual que hicimos con OpenVPN, ahora tendremos que montar el mismo escenario pero usando Wireguard. Así pues, he usado el mismo "Vagrantfile" que usé con el segundo apartado. Una vez montado el escenario, debemos configurar adecuadamente las máquinas. 

Empezando por ambos clientes, lo único que debemos hacer en ellos es cambiar la ruta por defecto (si no lo hubiéramos hecho en Vagrant, este paso no sería necesario):

En el cliente del escenario 1:

```
ip r del default

ip r add default via 172.30.0.10
```

En el cliente del escenario 2:

```
ip r del default

ip r add default via 172.20.0.10
```

Una vez que hemos hecho esto, podemos pasar a las máquinas que actuarán como servidor y cliente de Wireguard.

En la máquina "Servidor" del escenario 1 instalamos en primer lugar wireguard:

```
apt install wireguard
```

A continuación activamos el bit de forwarding y hacemos esta configuración permanente:

```
echo 1 > /proc/sys/net/ipv4/ip_forward

nano /etc/sysctl.conf                                          

net.ipv4.ip_forward=1
```

Después, al igual que hicimos antes, tenemos que generar el par de claves:

```
cd /etc/wireguard

wg genkey | tee serverprivatekey | wg pubkey > serverpublickey
```

```
cat serverprivatekey 

cHi1Gnj0aP82bNUJ9mp+3rMClVzvnCt1128uTaHk+mQ=
```

```
cat serverpublickey 

I3rVNtCFRHBOKpwXXk/MilBZOuAafBZq/zuCHt3/Pjs=
```

Ahora ya podemos crear el fichero de configuración, que será muy parecido al que creamos en el apartado anterior:

```
nano wg0.conf

# Server config
[Interface]
Address = 10.99.99.1
PrivateKey = cHi1Gnj0aP82bNUJ9mp+3rMClVzvnCt1128uTaHk+mQ=
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```

En este momento, ya podemos probar a iniciar el servicio:

```
wg-quick up wg0

wg-quick up wg0
[#] ip link add wg0 type wireguard
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.99.99.1 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

Podemos ver que el servicio se ha iniciado correctamente:

```
wg

interface: wg0
  public key: I3rVNtCFRHBOKpwXXk/MilBZOuAafBZq/zuCHt3/Pjs=
  private key: (hidden)
  listening port: 51820
```

Ahora debemos configurar la máquina "Servidor2" que actuará como cliente de wireguard en el escenario 2. Así pues, en primer lugar instalamos wireguard en esa máquina:

```
apt install wireguard
```

Y activamos el bit de forwarding, haciéndolo permanente:

```
echo 1 > /proc/sys/net/ipv4/ip_forward

nano /etc/sysctl.conf                                          

net.ipv4.ip_forward=1
```

Generaremos el par de claves que usará esta máquina:

```
cd /etc/wireguard

wg genkey | tee clientprivatekey | wg pubkey > clientpublickey
```

```
cat clientprivatekey 

UEPWi36UmIko9PFRcx96q1KHi3JAjYflLx4hTfw+ZHo=
```

```
cat clientpublickey 

bcuqxZFQMJcP2wITGMTZGV8EXv5o7p52C/UAiGgIWyg=
```

Y creamos el fichero de configuración que usará esta máquina tal y como hicimos en el aparatado anterior, creando también el bloque de "Peer":

```
nano wg0.conf

[Interface]
Address = 10.99.99.2
PrivateKey = UEPWi36UmIko9PFRcx96q1KHi3JAjYflLx4hTfw+ZHo=
ListenPort = 51820

[Peer]
PublicKey = I3rVNtCFRHBOKpwXXk/MilBZOuAafBZq/zuCHt3/Pjs=
AllowedIPs = 10.99.99.0/24, 172.30.0.0/24
Endpoint = 192.168.121.53:51820
```

Antes de activar este servicio, tenemos que añadir el correspondiente bloque "Peer" en el fichero de configuración del escenario 1:

```
nano wg0.conf

# Server config
[Interface]
Address = 10.99.99.1
PrivateKey = cHi1Gnj0aP82bNUJ9mp+3rMClVzvnCt1128uTaHk+mQ=
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Cliente Escenario 2
[Peer]
Publickey = bcuqxZFQMJcP2wITGMTZGV8EXv5o7p52C/UAiGgIWyg=
AllowedIPs = 10.99.99.0/24, 172.20.0.0/24
PersistentKeepAlive = 25
```

Ahora reiniciamos el servicio en la máquina "Servidor" del escenario 1:

```
wg-quick down wg0

wg-quick up wg0
```

Ya podemos iniciar el servicio en el escenario 2:

```
wg-quick up wg0

wg-quick up wg0
[#] ip link add wg0 type wireguard
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.99.99.2/32 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] ip -4 route add 172.30.0.0/24 dev wg0
[#] ip -4 route add 10.99.99.0/24 dev wg0
```

Y podemos ver que se han establecido la conexión:

![wireguard2_establecimiento_conexion.png](/images/practica_vpn/wireguard2_establecimiento_conexion.png)

Ahora ya podemos realizar las pruebas necesarias:

* Rutas en la máquina "Servidor" del escenario 1:

![wireguard2_rutas_escenario1.png](/images/practica_vpn/wireguard2_rutas_escenario1.png)

* Ping y traceroute desde el cliente del escenario 1 al cliente del escenario 2:

![wireguard2_pruebas_escenario1.png](/images/practica_vpn/wireguard2_pruebas_escenario1.png)

* Rutas en la máquina "Servidor2" del escenario 2:

![wireguard2_rutas_escenario2.png](/images/practica_vpn/wireguard2_rutas_escenario2.png)

* Ping y traceroute desde el cliente del escenario 2 al cliente del escenario 1:

![wireguard2_pruebas_escenario2.png](/images/practica_vpn/wireguard2_pruebas_escenario2.png)

### Comparativa con OpenVPN

Tras haber realizado toda la configuración necesaria para el site to site con OpenVPN y Wireguard, puedo afirmar con total seguridad que Wireguard es bastante superior a OpenVPN en todos los sentidos, al igual que pasaba con el acceso remoto.

* Para empezar tenemos la ya mencionada facilidad de configuración. Comparado con la configuración inicial y puesta de marcha de OpenVPN, se tarda mucho menos y requiere menos detalles la configuración en Wireguard (incluyendo una sintaxis más entendible).
* Al ser una práctica realizada en máquinas virtuales no lo he podido comprobar del todo, pero si que he notado una mayor rapidez a la hora de realizar pruebas y establecer las conexiones.
* Sigue sin ser necesario crear una autoridad certificadora, por lo que es más cómodo de configurar.
