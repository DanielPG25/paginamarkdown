+++ 
draft = true
date = 2021-12-01T08:18:05+01:00
title = "Certificados Digitales y HTTPS"
description = "Certificados Digitales y HTTPS"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Seguridad y Alta Disponibilidad"]
externalLink = ""
series = []
+++

# Certificados digitales. HTTPS

## Certificado digital de persona física

### Tarea 1: Instalación del certificado

#### Una vez que hayas obtenido tu certificado, explica brevemente como se instala en tu navegador favorito.

Antes de instalar el certificado, e incluso antes de solicitarlo, debemos tener instalado el [software](https://www.sede.fnmt.gob.es/certificados/persona-fisica/obtener-certificado-software/configuracion-previa) necesario para ello. A continuación, tras rellenar los formularios adecuados y sacar cita para obtener el certificado, podemos ir a la autoridad certificadora y obtener el certificado. 

Una vez que lo hemos obtenido, tras descargar el certificado, podemos instalarlo siguiendo estos pasos:

* Miramos la configuración de los certificados de nuestro navegador web:

![instalar_certificado1.png](/images/practica_certificadosdigitales_https/instalar_certificado1.png)

* Seleccionamos el ceritificado, en mi caso en formato `.pfx`, e introducimos la contraseña para importarlo:

![cerificado_importado.png](/images/practica_certificadosdigitales_https/cerificado_importado.png)

Con esto ya lo tenemos importado en nuestro navegador y podemos hacer uso del mismo.
    
#### ¿Cómo puedes hacer una copia de tu certificado?, ¿Como vas a realizar la copia de seguridad de tu certificado?. Razona la respuesta.
 
Para hacer copia del certificado, basta con seleccionar el certificado y darle al botón de hacer copia:

![certificado_copia.png](/images/practica_certificadosdigitales_https/certificado_copia.png)

Tras esto, nos pedirá que le indiquemos una contraseña para exportarlo. Esto nos asegura un cierto nivel de seguridad en caso de perder el certificado, por lo que es recomendable hacerlo:

![certificado_contrasena.png](/images/practica_certificadosdigitales_https/certificado_contrasena.png)

Una vez hecha la copia de seguridad, podemos transportarla como queramos (USB, llave electrónica, etc.), pudiendo importarla en cualquier navegador a nuestra elección tras introducir la contraseña correcta. 

En mi caso, firefox solo me da la opción de exportar el certificado en formato `.pfx` con contraseña (el método más seguro), pero algunos navegadores ofrecen la opción de exportarlo como `.cert` y sin contraseña. Esta última opción es la más insegura, y por tanto, no es recomendable.

#### Investiga como exportar la clave pública de tu certificado.

Para exportar solamente la clave pública hay dos opciones:

* Si usas una máquina Windows, basta con no seleccionar exportar la clave privada al exportar el certificado. Esto nos dejará con sólo la pública.

* Si usas Debian 11 (como en mi caso), debemos exportar el par de claves con la contraseña, y después usar la herramienta `openssl` para extraer la pública:

    * Primero extraemos el par de claves del certificado:

   	```
   	openssl pkcs12 -in DanielParralesCert.pfx -nocerts -nodes -out DanielParralesCert.key
   	```

    * Ahora ya podemos extraer la clave pública:

    ```
    openssl rsa -in DanielParralesCert.key -pubout -out DanielParralesPub.key
    ```

### Tarea 2: Validación del certificado

#### Instala en tu ordenador el software [autofirma](https://firmaelectronica.gob.es/Home/Descargas.html) y desde la página de VALIDe valida tu certificado. Muestra capturas de pantalla donde se comprueba la validación.

Antes de instalar Autofirma, debemos asegurarnos de hemos instalado las dependencias que nos indica en la página principal:

```
sudo apt install default-jdk libnss3-tools
```

Una vez instalados, podemos proseguir con Autofirma. Para ello nos descargamos el paquete de la página oficial y lo extraemos:

```
unzip AutoFirma_Linux.zip
```

Tras esto instalamos el fichero `.deb` que hemos extraído:

```
sudo apt install ./AutoFirma_1_6_5.deb
```

Una vez instalado, podemos abrirlo directamente desde la aplicación:

![autofirma.png](/images/practica_certificadosdigitales_https/autofirma.png)

Procedamos ahora a validar nuestro certificado en la página de [Valide](https://valide.redsara.es/valide/validarCertificado/ejecutar.html). Para validarlo entramos en dicha página y seleccionamos validar el certificado. Nos saldrá la siguiente ventana:

![validar_certificado.png](/images/practica_certificadosdigitales_https/validar_certificado.png)

Si aceptamos la ventana nos confirmará si el certificado es válido o no:

![validar_certificado2.png](/images/practica_certificadosdigitales_https/validar_certificado2.png)

**Nota:** Actualmente hay problemas si usas firefox con KDE, por lo que es recomendable cambiar de navegador si usas este escritorio.

### Tarea 3: Firma electrónica

#### Utilizando la página VALIDe y el programa autofirma, firma un documento con tu certificado y envíalo por correo a un compañero.

Vamos a crear dos ficheros para empezar, uno para firmarlo a través de Valide y otro para firmarlo con Autofirma:

```
nano firmar_autofirmaDP.txt

こんにちわララさん~~~ 

nano firmar_valideDP.txt

海賊王に俺はなる!!!!!!
```

Una vez creados los ficheros, procedemos a ir a la página de Valide para firmar el documento correspondiente:

![valide_firmar.png](/images/practica_certificadosdigitales_https/valide_firmar.png)

Seleccionamos el fichero que queremos firmar. Una vez que lo hemos hecho, guardamos la firma:

![valide_firmar2.png](/images/practica_certificadosdigitales_https/valide_firmar2.png)

Nos pedirá un nombre para el fichero firmado (en mi caso `firmar_valideDP_firmado.csig`). Con esto ya hemos firmado un documento. Vamos a por el siguiente. Para ello abrimos el programa de autofirma y seleccionamos el fichero a firmar:

![autofirma_firmar.png](/images/practica_certificadosdigitales_https/autofirma_firmar.png)

Le damos a firmar, tras lo cual nos preguntará por el certificado que queremos usar y el nombre del fichero resultante. Tras seleccionar el certificado y el nombre, guardamos y nos saldrá la siguiente ventana:

![autofirma_firmar2.png](/images/practica_certificadosdigitales_https/autofirma_firmar2.png)

Con esto, ya hemos firmado ambos documentos, por lo que lo único que resta es mandárselo a un compañero y recibir los suyos firmados. En mi caso, mi compañera es Lara Pruna Ternero.

#### Tu debes recibir otro documento firmado por un compañero y utilizando las herramientas anteriores debes visualizar la firma (Visualizar Firma) y (Verificar Firma). ¿Puedes verificar la firma aunque no tengas la clave pública de tu compañero?, ¿Es necesario estar conectado a internet para hacer la validación de la firma?. Razona tus respuestas.

He recibido los siguientes dos documentos firmados por mi compañera usando los métodos mencionados anteriormente:

![firma_lara.png](/images/practica_certificadosdigitales_https/firma_lara.png)

Así pues, vamos a comenzar usando Autofirma para ver la firma de uno de los ficheros. Para ello, abrimos el programa y seleccionamos "Ver firma", en el menú superior. Si seleccionamos un fichero firmado por Lara nos sale lo siguiente:

![verificar_lara_autofirma.png](/images/practica_certificadosdigitales_https/verificar_lara_autofirma.png)

Como vemos, nos indica que la firma es válida. Probemos a validar la firma del otro archivo usando esta vez las herramientas que ofrece Valide:

* Validar Firma:

![valide_lara1.png](/images/practica_certificadosdigitales_https/valide_lara1.png)

* Visualizar Firma:

![valide_lara2.png](/images/practica_certificadosdigitales_https/valide_lara2.png)

Como vemos, usemos el método que usemos, la firma de Lara es validada aunque yo no disponga directamente de la clave pública de ella. Sin embargo, ella, al firmar los ficheros, les ha adjuntado su clave pública, lo que hace posible que podamos verificar su firma a través de estas herramientas. Por otro lado, necesitamos de conexión a Internet para comprobar que el certificado de la persona que ha firmado no ha sido revocado y que la autoridad certificadora es de confianza.

#### Entre dos compañeros, firmar los dos un documento, verificar la firma para comprobar que está firmado por los dos.

Para esta parte, he firmado uno de los documentos que me pasó firmado Lara usando Autofirma. Podemos comprobar que, efectivamente, está firmado por ambos:

* Desde Autofirma:

![autofirma_ambos.png](/images/practica_certificadosdigitales_https/autofirma_ambos.png)

* Desde Valide (validar firma):

![valide_ambos1.png](/images/practica_certificadosdigitales_https/valide_ambos1.png)

* Desde Valide (visualizar firma):

![valide_ambos2.png](/images/practica_certificadosdigitales_https/valide_ambos2.png)

Como podemos ver, usando los tres métodos usados anteriormente, se nos indica que está firmado por dos personas (Lara y yo).

### Tarea 4: Autentificación

#### Utilizando tu certificado accede a alguna página de la administración pública (cita médica, becas, puntos del carnet,…). Entrega capturas de pantalla donde se demuestre el acceso a ellas.

Para esta tarea vamos a consultar nuestros puntos del carnet a través de la página de la DGT usando nuestro certificado. Así pues, nos dirigimos a la página y le damos al siguiente botón:

![dgt1.png](/images/practica_certificadosdigitales_https/dgt1.png)

Una vez haya cargado la página, seleccionamos entrar con certificado eléctronico:

![dgt2.png](/images/practica_certificadosdigitales_https/dgt2.png)

Nos abrirá un menú en el que nos pedirá que le indiquemos el certificado con el que queremos entrar:

![dgt3.png](/images/practica_certificadosdigitales_https/dgt3.png)

Una vez seleccionado correctamente el certificado, nos redirigirá a nuestra página principal:

![dgt4.png](/images/practica_certificadosdigitales_https/dgt4.png)

Con esto hemos demostrado que podemos acceder a una página de la administración pública usando nuestro certificado electrónico.

## HTTPS / SSL

### Tarea 1: Certificado autofirmado

Esta práctica la vamos a realizar con un compañero. En un primer momento un alumno creará una Autoridad Certficadora y firmará un certificado para la página del otro alumno. Posteriormente se volverá a realizar la práctica con los roles cambiados.

Para hacer esta práctica puedes buscar información en internet, algunos enlaces interesantes:

* [Phil’s X509/SSL Guide](https://www.phildev.net/ssl/)
* [How to setup your own CA with OpenSSL](https://gist.github.com/Soarez/9688998)
* [Crear autoridad certificadora (CA) y certificados autofirmados en Linux](https://blog.guillen.io/2018/09/29/crear-autoridad-certificadora-ca-y-certificados-autofirmados-en-linux/)

El alumno que hace de Autoridad Certificadora deberá entregar una documentación donde explique los siguientes puntos:

#### Crear su autoridad certificadora (generar el certificado digital de la CA). Mostrar el fichero de configuración de la AC.

El primer paso para crear la autoridad certificadora será crear un directorio en el cual almacenaremos lo refente a la autoridad, para de esta forma tenerlo todo lo más organizado posible. Así pues, he creado el directorio padre (llamado CA) con los siguientes subdirectorios:

* certsdb: donde se almacenarán los certificados firmados.
* certreqs: donde se almacenarán los ficheros de solicitud de firma (CSR).
* crl: donde se almacenará la lista de los certificados revocados.
* private: donde se almacenará la clave privada de la autoridad certificadora.

```
mkdir -p CA/{certsdb,certreqs,crl,private}
```

Una vez generados los directorios, por seguridad, daremos los permisos 700 al subdirectorio 'clavepriv':

```
chmod 700 CA/private
```

Además, debemos crear en el directorio principal, un fichero que actuará como base de datos para los certificados existentes:

```
touch CA/index.txt
```

Ahora copiaremos el fichero de configuración de openssl para usarlo en la creación de nuestra Autoridad Certificadora:

```
cp /usr/lib/ssl/openssl.cnf .
```

Ahora lo modificaremos para configurar nuestra autoridad (a continuación incluiré solo las líneas que modifiqué):

```
nano openssl.cnf

dir             = /root/CA
certs           = $dir/certsdb 
new_certs_dir   = $certs 

countryName_default             = ES
stateOrProvinceName_default     = Sevilla
localityName_default            = Dos Hermanas
0.organizationName_default      = DanielParrales Corp 
organizationalUnitName_default  = Informatica

#challengePassword              = A challenge password

#challengePassword_min          = 4

#challengePassword_max          = 20

#unstructuredName               = An optional company name
```

Con esto, ya tenemos todo listo para generar el par de claves que usaremos y un fichero de solicitud de firma de certificado que tendremos que firmar nosotros mismos. Para ello usamos el siguiente comando:

```
openssl req -new -newkey rsa:2048 -keyout private/cakey.pem -out careq.pem -config ./openssl.cnf

Generating a RSA private key
..........................................................................................................+++++
....+++++
writing new private key to 'private/cakey.pem'
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
Country Name (2 letter code) [ES]:
State or Province Name (full name) [Sevilla]:
Locality Name (eg, city) [Dos Hermanas]:
Organization Name (eg, company) [DanielParrales Corp]:
Organizational Unit Name (eg, section) [Informatica]:
Common Name (e.g. server FQDN or YOUR name) []:daniel.debian
Email Address []:daniparrales16@gmail.com
```

En el comando anterior tenemos las siguientes opciones:

* "-new": indicamos que se genere un nuevo par de claves.
* "-newkey": aquí especificamos el tamaño y el tipo que tendrá nuestro nuevo par de claves (RSA de 2048 bits).
* "-keyout": indicamos donde se va a almacenar la clave privada y el nombre de la clave.
* "-out": indicamos el nombre y donde se va a almacenar la solicitud de firma del certificado.
* "-config": indicamos el fichero de configuración que queremos que use openssl.

Como vemos, mucha de la información que nos pregunta es la que hemos cambiado antes en el fichero de configuración, por lo que podemos dejarla como está.

Ahora tenemos que firmarnos el certificado que hemos generado, ya que es el certificado que mandaremos a nuestra compañera para que lo importe al navegador y no le salte la advertencia de https:

```
openssl ca -create_serial -out cacert.pem -days 365 -keyfile private/cakey.pem -selfsign -extensions v3_ca -config ./openssl.cnf -infiles careq.pem

Using configuration from ./openssl.cnf
Enter pass phrase for private/cakey.pem:
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number:
            29:80:5f:b4:35:bc:4c:00:aa:80:8b:6e:60:4b:2d:76:bf:c7:4c:2b
        Validity
            Not Before: Nov 30 19:19:45 2021 GMT
            Not After : Nov 30 19:19:45 2022 GMT
        Subject:
            countryName               = ES
            stateOrProvinceName       = Sevilla
            organizationName          = DanielParrales Corp
            organizationalUnitName    = Informatica
            commonName                = daniel.debian
            emailAddress              = daniparrales16@gmail.com
        X509v3 extensions:
            X509v3 Subject Key Identifier: 
                20:96:90:07:DF:CF:51:00:9F:7E:0B:F4:5C:8B:47:26:90:10:9A:16
            X509v3 Authority Key Identifier: 
                keyid:20:96:90:07:DF:CF:51:00:9F:7E:0B:F4:5C:8B:47:26:90:10:9A:16

            X509v3 Basic Constraints: critical
                CA:TRUE
Certificate is to be certified until Nov 30 19:19:45 2022 GMT (365 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated
```

En el anterior comando tenemos las siguientes opciones:

* "-create_serial": Indicamos que genere un serial de 128 bits al comenzar, para que no sobreescriba los ya existentes si volvemos a comenzar.
* "-out": Indicamos el nombre y donde se va a guardar el certificado firmado.
* "-days": Indicamos el tiempo de validez del certificado firmado.
* "-keyfile": Indicamos la clave privada que usaremos para firmar dicho certificado.
* "-selfsign": Indicamos que vamos a autofirmar el certificado.
* "-extensions": Indicamos a openssl la sección del fichero de configuración en el que se encuentran la extensiones a usar.
* "-config": Indicamos a openssl el fichero de configuración que debe usar.
* "-infiles": indicamos el fichero que queremos firmar.

Con esto ya tenemos todo listo para firmar el certificado de nuestra compañera.

#### Debe recibir el fichero CSR (Solicitud de Firmar un Certificado) de su compañero, debe firmarlo y enviar el certificado generado a su compañero.

De Lara hemos recibido el siguiente fichero y lo hemos metido en el directorio 'certreqs':

```
ls certreqs | egrep lara

lara.csr
```

Ahora ya podemos firmarlo usando el siguiente comando:

```
openssl ca -config openssl.cnf -out certsdb/lara.crt -infiles certreqs/lara.csr 
```

Una vez ejecutado el comando (las opciones usadas ya las hemos explicado anteriormente), el fichero firmado se encuentra dentro del directorio 'certsdb'. Ahora ya solo tenemos que mandárselo a lara junto con el fichero `cacert.pem` para que pueda importarlo al navegador.

Por último, podemos echar un vistazo al fichero 'index.txt' en el que podemos ver la información de los certificados que hemos firmado:

```
cat index.txt

V   221130191945Z       29805FB435BC4C00AA808B6E604B2D76BFC74C2B    unknown /C=ES/ST=Sevilla/O=DanielParrales Corp/OU=Informatica/CN=daniel.debian/emailAddress=daniparrales16@gmail.com
V   221130194608Z       29805FB435BC4C00AA808B6E604B2D76BFC74C2D    unknown /C=ES/ST=Sevilla/O=DanielParrales Corp/OU=Informatica/CN=lara.iesgn.org/emailAddress=larapruter@gmail.com
```

#### ¿Qué otra información debes aportar a tu compañero para que éste configure de forma adecuada su servidor web con el certificado generado?

El otro fichero que mandé a mi compañera es mi certificado de la autoridad firmado, para que pueda importarlo a su navegador y para que el servidor compruebe las firmas del certificado.

--------------------------------------------------------------------------------------------------

El alumno que hace de administrador del servidor web, debe entregar una documentación que describa los siguientes puntos:

#### Crea una clave privada RSA de 4096 bits para identificar el servidor.

En primer lugar debemos instalar un servidor apache. He instalado el servidor en una máquina de openstack:

```
sudo apt install apache2
```

A continuación modificaremos el virtualhost para usar el nombre de la página web que nos han idicado, en mi caso, `dparrales.iesgn.org`:

```
nano /etc/apache2/sites-available/000-default.conf

<VirtualHost *:80>

        ServerName dparrales.iesgn.org
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

</VirtualHost>
```

Tras esto, reinciamos el servicio para cargar la configuración:

```
systemctl reload apache2
```

Ahora ya podemos pasar el contenido que vamos a mostrar al directorio `/var/www/html` (en mi caso usé unas plantillas que tenía de un escenario anterior). Una vez que hemos hecho esto, ya solo tenemos que añadir la siguiente línea al fichero `/etc/hosts` de nuestro anfitrión, para poder acceder a la página:

```
172.22.200.86 dparrales.iesgn.org
```

Si intentamos entrar ahora, nos muestra lo siguiente:

![pagina_estatica_http.png](/images/practica_certificadosdigitales_https/pagina_estatica_http.png)

Con esto hemos terminado de configurar incialmente apache. Sin embargo, el acceso que tenemos ahora es por http, no por https, por lo que tendremos que corregirlo durante de realización de la tarea.

Así pues, en primer lugar, vamos a crear una clave privada de 4096 bits que usaremos posteriormente para generar una firma de solicitud de certificado (CSR) y que ahora sirve para identificar al servidor. Para ello vamos a usar el comando 'openssl':

```
openssl genrsa 4096 > /etc/ssl/private/dparrales.key
Generating RSA private key, 4096 bit long modulus (2 primes)
..........................................................................................++++
...........................++++
e is 65537 (0x010001)
```

Una vez que la hemos creado, cambiaremos sus permisos para mayor seguridad:

```
chmod 400 /etc/ssl/private/dparrales.key
```

#### Utiliza la clave anterior para generar un CSR, considerando que deseas acceder al servidor con el FQDN (tunombre.iesgn.org) y envía la solicitud de firma a la entidad certificadora (su compañero).

Una vez que ya hemos generado la clave en el apartado anterior, vamos a usarla para generar el fichero (CSR) para que lo firme la Autoridad Certificadora que está creando nuestra compañera (Lara Pruna Ternero). Para ello volvemos a hacer uso del comando 'openssl':

```
openssl req -new -key /etc/ssl/private/dparrales.key -out dparrales.csr
```

* Con '-new' indicamos que la solicitud de firma sea interactiva.
* Con '-key' indicamos la clave que vamos a asociar a dicha solicitud.
* Con '-out' indicamos el nombre y el directorio donde se almacenará la solicitud.

Al ejecutar el anterior comando, nos saldrán la siguientes preguntas que tendremos que responder (las preguntas finales que eran opcionales decidí dejarlas en blanco):

```
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:ES
State or Province Name (full name) [Some-State]:Sevilla
Locality Name (eg, city) []:Dos Hermanas
Organization Name (eg, company) [Internet Widgits Pty Ltd]:LaraPruna Corp
Organizational Unit Name (eg, section) []:Informatica
Common Name (e.g. server FQDN or YOUR name) []:dparrales.iesgn.org
Email Address []:daniparrales16@gmail.com

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
```

Este fichero CSR que hemos generado es el que tenemos que mandar a nuestra compañera. En mi caso voy a usar scp, pero podríamos usar cualquier método (seguro) a nuestra disposición.
    
#### Recibe como respuesta un certificado X.509 para el servidor firmado y el certificado de la autoridad certificadora.

De lara hemos recibido el certificado firmado y el certificado de la autoridad certificadora:

```
ls -l | egrep '(.crt|cacert)'
-rw-r--r-- 1 dparrales    dparrales          4630 nov 30 18:56 cacert.pem
-rw-r--r-- 1 dparrales    dparrales          6255 nov 30 18:00 dparrales.crt
```
    
#### Configura tu servidor web con https en el puerto 443, haciendo que las peticiones http se redireccionen a https (forzar https).

Una vez tenemos los dos certificados necesarios, vamos a configurar el virtualhost que se va a hacer cargo de las peticiones https:

```
nano /etc/apache2/sites-available/default-ssl.conf

<IfModule mod_ssl.c>
        <VirtualHost _default_:443>
                ServerAdmin webmaster@localhost
                ServerName dparrales.iesgn.org
                DocumentRoot /var/www/html

                ErrorLog ${APACHE_LOG_DIR}/error.log
                CustomLog ${APACHE_LOG_DIR}/access.log combined

                SSLEngine on

                SSLCertificateFile      /etc/ssl/certs/dparrales.crt
                SSLCertificateKeyFile /etc/ssl/private/dparrales.key
                SSLCACertificateFile /etc/ssl/certs/cacert.pem

                <FilesMatch "\.(cgi|shtml|phtml|php)$">
                                SSLOptions +StdEnvVars
                </FilesMatch>
                <Directory /usr/lib/cgi-bin>
                                SSLOptions +StdEnvVars
                </Directory>


        </VirtualHost>
</IfModule>
```

Ahora que lo hemos adaptado, pasamos a habilitar el virtualhost:

```
a2ensite default-ssl
Enabling site default-ssl.
To activate the new configuration, you need to run:
  systemctl reload apache2
```

Como modulo ssl no viene activado por defecto, tenemos activarlo nosotros:

```
a2enmod ssl
Enabling module ssl.
To activate the new configuration, you need to run:
  systemctl restart apache2
```

Ahora solo tenemos que añadir la redirección a nuestro virtualhost de http para asegurarnos que solo se puede acceder a la página mediante https:

```
nano /etc/apache2/sites-available/000-default.conf

<VirtualHost *:80>

        ServerName dparrales.iesgn.org
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

        Redirect 301 / https://dparrales.iesgn.org/
</VirtualHost>
```

Ahora que hemos terminado de tocar la configuración de apache, podemos reiniciar el servicio para aplicar los cambios:

```
systemctl reload apache2
```

Si ententamos entrar en la página ahora, obtenemos lo siguiente:

![pagina_https.png](/images/practica_certificadosdigitales_https/pagina_https.png)

Esta advertencia nos sale porque el navegador no es capaz de comprobar la firma de la CA. Para solucionarlo, vamos a importar a nuestro navegador el certificado de la CA que ha creado lara.

![certificado_lara.png](/images/practica_certificadosdigitales_https/certificado_lara.png)

Con esto, si volvemos a acceder a la página ya no nos sale la advertencia:

![pagina_certificada.png](/images/practica_certificadosdigitales_https/pagina_certificada.png)

Con esto, ya hemos terminado de configurar https en apache.

#### Instala ahora un servidor nginx, y realiza la misma configuración que anteriormente para que se sirva la página con HTTPS.

Procedamos ahora a hacer lo mismo con nginx. Para ello, primero deshabilitamos o desinstalamos apache (para que no cause conflictos). Tras ello, pasamos a configurar el virtualhost de nginx. Al contrario de lo que pasaba en apache, podemos tener las configuraciones para http y https en el mismo virtualhost, por lo que la configuración quedaría de la siguiente forma:

```
nano /etc/nginx/sites-available/default 

server {
        listen 80 default_server;
        listen [::]:80 default_server;

        server_name dparrales.iesgn.org;

        return 301 https://$host$request_uri;
}

server {
        listen 443 ssl default_server;
        listen [::]:443 ssl default_server;

        ssl    on;
        ssl_certificate    /etc/ssl/certs/dparrales.crt;
        ssl_certificate_key    /etc/ssl/private/dparrales.key;

        root /var/www/html;

        index index.html index.htm index.nginx-debian.html;

        server_name dparrales.iesgn.org;

        location / {
                try_files $uri $uri/ =404;
        }
}
```

Tras esto, reiniciamos nginx para cargar los cambios:

```
systemctl reload nginx
```

Como ya tenemos el certificado cargado en el navegador del apartado anterior, debería dejarnos entrar en la página directamente sin ninguna advertencia:

![https_nginx.png](/images/practica_certificadosdigitales_https/https_nginx.png)

Como vemos, nos carga la página perfectamente y está servida por un servidor nginx. 

Con esto hemos terminado de configurar https tanto en nginx como en apache.
