+++ 
draft = true
date = 2021-11-13T19:50:18+01:00
title = "Cifrado asimétrico con gpg y openssl"
description = "Cifrado asimétrico con gpg y openssl"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Seguridad y Alta Disponibilidad"]
externalLink = ""
series = []
+++

# Cifrado asimétrico con gpg y openssl

## Tarea 1: Generación de claves (gpg)

Los algoritmos de cifrado asimétrico utilizan dos claves para el cifrado y descifrado de mensajes. Cada persona involucrada (receptor y emisor) debe disponer, por tanto, de una pareja de claves pública y privada. Para generar nuestra pareja de claves con gpg utilizamos la opción `--gen-key`:

Para esta práctica no es necesario que indiquemos frase de paso en la generación de las claves (al menos para la clave pública).

### Genera un par de claves (pública y privada). ¿En que directorio se guarda las claves de un usuario?

Para generar el par de claves, usamos el comando con la opción `--gen-key` y respondemos a las preguntas que nos indica:

```
gpg --gen-key 
gpg (GnuPG) 2.2.27; Copyright (C) 2021 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Nota: Usa "gpg --full-generate-key" para el diálogo completo de generación de clave.

GnuPG debe construir un ID de usuario para identificar su clave.

Nombre y apellidos: Daniel Parrales Garcia
Dirección de correo electrónico: micorreo@gmail.com
Ha seleccionado este ID de usuario:
    "Daniel Parrales Garcia <micorreo@gmail.com>"

¿Cambia (N)ombre, (D)irección o (V)ale/(S)alir? V
Es necesario generar muchos bytes aleatorios. Es una buena idea realizar
alguna otra tarea (trabajar en otra ventana/consola, mover el ratón, usar
la red y los discos) durante la generación de números primos. Esto da al
generador de números aleatorios mayor oportunidad de recoger suficiente
entropía.
Es necesario generar muchos bytes aleatorios. Es una buena idea realizar
alguna otra tarea (trabajar en otra ventana/consola, mover el ratón, usar
la red y los discos) durante la generación de números primos. Esto da al
generador de números aleatorios mayor oportunidad de recoger suficiente
entropía.
gpg: clave 003678CA94289486 marcada como de confianza absoluta
gpg: certificado de revocación guardado como '/home/dparrales/.gnupg/openpgp-revocs.d/5E357C9F804207FABAB0B54C003678CA94289486.rev'
claves pública y secreta creadas y firmadas.

pub   rsa3072 2021-11-13 [SC] [caduca: 2023-11-13]
      5E357C9F804207FABAB0B54C003678CA94289486
uid                      Daniel Parrales Garcia <micorreo@gmail.com>
sub   rsa3072 2021-11-13 [E] [caduca: 2023-11-13]
```

Con esto se ha generado correctamente el par de claves. Las claves se han guardado en el directorio personal del usuario que las creó, dentro de una carpeta oculta llamada `.gnupg`. En esta carpeta se ha generado un fichero llamado `pubring.kbx`, el cual contendrá todas las claves públicas que generemos o importemos, funcionando como una especie de "llavero" de nuestras claves. También se ha creado un certificado de revocación en `gnupg/openpgp-revocs.d/` que usaremos cuando queramos dejar de utilizar dicha clave, lo que a su vez notificará a otros usuarios de que no usen esa clave más.

### Lista las claves públicas que tienes en tu almacén de claves. Explica los distintos datos que nos muestra. ¿Cómo deberías haber generado las claves para indicar, por ejemplo, que tenga un 1 mes de validez?

Para listar las claves públicas de nuestro llavero usamos la opción `--list-keys` del comando gpg:

```
gpg --list-keys
/home/dparrales/.gnupg/pubring.kbx
----------------------------------
pub   rsa3072 2021-11-13 [SC] [caduca: 2023-11-13]
      5E357C9F804207FABAB0B54C003678CA94289486
uid        [  absoluta ] Daniel Parrales Garcia <micorreo@gmail.com>
sub   rsa3072 2021-11-13 [E] [caduca: 2023-11-13]
```

Los datos que nos muestra son las siguientes abreviaturas:

* pub: clave pública primaria
* uid: identificador único
* sub: clave pública secundaria

Al crear el par de claves con gpg, no solo ha creado la pareja de publica-privada, sino que también ha creado un par de claves secundarias relacionadas con las principales. De esta forma, el par de claves primario se usa para firmar/comprobar firmas, mientras que el secundario se usa para encriptar/desencriptar. 

También aparece información con respecto al algoritmo usado por la clave (rsa3072), la fecha de creación (2021-11-13) y de caducidad de la validez de las claves (2023-11-13), y unas letras entre corchetes que corresponden a unos flags:

* SC: nos indica que sirve para firmar archivos (S) y certificar llaves (C).
* E: encriptar información. 

Para indicar que las claves tengan una determinada validez, tenemos que haber usado la opción `--full-gen-key` en lugar de la opción `--key-gen`. Si lo hubieramos hecho así nos habría aparecido la siguiente información (además de otras opciones como el tamaño de la clave, tipo de clave, etc):

```
Por favor, especifique el período de validez de la clave.
         0 = la clave nunca caduca
      <n>  = la clave caduca en n días
      <n>w = la clave caduca en n semanas
      <n>m = la clave caduca en n meses
      <n>y = la clave caduca en n años
¿Validez de la clave (0)?
```

Así pues, en esta pregunta responderíamos '1m' para que su validez fuera de un mes.


### Lista las claves privadas de tu almacén de claves.

Para listar las claves privadas de nuestro "llavero" usamos la opción `--list-secret-keys`:

```
gpg --list-secret-keys
/home/dparrales/.gnupg/pubring.kbx
----------------------------------
sec   rsa3072 2021-11-13 [SC] [caduca: 2023-11-13]
      5E357C9F804207FABAB0B54C003678CA94289486
uid        [  absoluta ] Daniel Parrales Garcia <micorreo@gmail.com>
ssb   rsa3072 2021-11-13 [E] [caduca: 2023-11-13]
```


## Tarea 2: Importar / exportar clave pública (gpg)

Para enviar archivos cifrados a otras personas, necesitamos disponer de sus claves públicas. De la misma manera, si queremos que cierta persona pueda enviarnos datos cifrados, ésta necesita conocer nuestra clave pública. Para ello, podemos hacérsela llegar por email por ejemplo. Cuando recibamos una clave pública de otra persona, ésta deberemos incluirla en nuestro keyring o anillo de claves, que es el lugar donde se almacenan todas las claves públicas de las que disponemos.

### Exporta tu clave pública en formato ASCII y guárdalo en un archivo nombre_apellido.asc y envíalo al compañero con el que vas a hacer esta práctica.

Para exportar la clave pública en formato ASCII debemos usar dos opciones: `--export` y `-a`. Tras la opción export incluimos el uid de la clave que queramos exportar. Esto generará una cadena de texto con la clave publica, por lo que tendremos que redirigir la salida del comando a un fichero, al que he llamado 'dparrales.asc':

```
gpg -a --export 5E357C9F804207FABAB0B54C003678CA94289486 >> dparrales.asc
```

Este fichero es el que enviaremos a nuestro compañero. En mi caso, voy a enviar mi clave a mi compañera "Lara Pruna Ternero", y yo recibiré la suya.

### Importa las claves públicas recibidas de vuestro compañero.

La clave pública que he recibido se encuentra en un fichero llamado `lara_pruna.asc`. Para importarla usamos la opción `--import`:

```
gpg --import lara_pruna.asc 
gpg: clave 51D0DEC846173F6A: clave pública "Lara Pruna Ternero <larapruter@gmail.com>" importada
gpg: Cantidad total procesada: 1
gpg:               importadas: 1
```

Como vemos, nos indica que ha importado correctamente la clave.

### Comprueba que las claves se han incluido correctamente en vuestro keyring.

Podemos comprobar si se ha añadido de forma correcta usando el comando que usamos anteriormente para listar las claves públicas:

![clave_publica_lara.png](/images/cifrado_asimetrico_gpg_openssl/clave_publica_lara.png)

Como podemos ver, la clave se ha añadido correctamente.

## Tarea 3: Cifrado asimétrico con claves públicas (gpg)

Tras realizar el ejercicio anterior, podemos enviar ya documentos cifrados utilizando la clave pública de los destinatarios del mensaje.

### Cifraremos un archivo cualquiera y lo remitiremos por email a uno de nuestros compañeros que nos proporcionó su clave pública.

Vamos a cifrar un fichero que acabo de crear con el contenido "fichero a cifrar":

```
echo "fichero a cifrar" > cifrar.txt
```

Para cifrar el fichero debemos usar las siguientes opciones del comando gpg:

* -e: para indicar que vamos a cifrar el fichero
* -u: para indicar el remitente (en este caso sería yo)
* -r: para indicar el destinatario (en este caso Lara)

```
gpg -e -u "Daniel Parrales Garcia" -r "Lara Pruna Ternero" cifrar.txt 
gpg: 99912020704046AB: No hay seguridad de que esta clave pertenezca realmente
al usuario que se nombra

sub  rsa3072/99912020704046AB 2021-11-13 Lara Pruna Ternero <larapruter@gmail.com>
 Huella clave primaria: 4458 9663 DC53 5930 52B6  616F 51D0 DEC8 4617 3F6A
      Huella de subclave: B5CD 5CED A347 462B 2A8B  E614 9991 2020 7040 46AB

No es seguro que la clave pertenezca a la persona que se nombra en el
identificador de usuario. Si *realmente* sabe lo que está haciendo,
puede contestar sí a la siguiente pregunta.

¿Usar esta clave de todas formas? (s/N) s
```

Una vez hecho esto podemos comprobar que se nos ha creado el fichero cifrado:

```
ls -l | egrep cifrar
-rw-r--r--  1 dparrales dparrales    17 nov 13 16:48 cifrar.txt
-rw-r--r--  1 dparrales dparrales   483 nov 13 16:53 cifrar.txt.gpg
```

Vemos que nos ha generado un fichero .gpg, que es el fichero cifrado. Podemos ver la información del fichero con el comando `file`:

```
file cifrar.txt.gpg 
cifrar.txt.gpg: PGP RSA encrypted session key - keyid: 99912020 704046AB RSA (Encrypt or Sign) 3072b .
```

Este fichero se lo enviamos a nuestro compañero (en mi caso he usado ssh).
  
### Nuestro compañero, a su vez, nos remitirá un archivo cifrado para que nosotros lo descifremos.

He recibido de Lara el siguiente fichero:

![documento_lara.png](/images/cifrado_asimetrico_gpg_openssl/documento_lara.png)
    
### Tanto nosotros como nuestro compañero comprobaremos que hemos podido descifrar los mensajes recibidos respectivamente.

Para descifrarlo usaremos la opción `-d`, que indica que queremos descifrar un fichero:

```
gpg -d prueba_lara.txt.gpg 
gpg: cifrado con clave de 3072 bits RSA, ID 3A4CA0B54B19B8DD, creada el 2021-11-13
      "Daniel Parrales Garcia <micorreo@gmail.com>"
Hola, Dani, te envío los planes secretos para acabar con ASIR:

   ^ ^
^\(`v´)/^
  I___I	   GUAJAJAJAJAJAJA
 _/   \_


Fd: Lara
```

Como podemos ver, el archivo de ha descifrado con éxito.
    
### Por último, enviaremos el documento cifrado a alguien que no estaba en la lista de destinatarios y comprobaremos que este usuario no podrá descifrar este archivo.

Para probar esta parte, he mandado el fichero a un usuario en una máquina virtual que he creado, de forma que no posee ninguna clave pública ni privada.

```
gpg -d cifrar.txt.gpg 
gpg: encrypted with RSA key, ID 99912020704046AB
gpg: decryption failed: No secret key
```

Al no disponer de la clave privada indicada en el destinatario, no he podido descifrar el documento.

### Para terminar, indica los comandos necesarios para borrar las claves públicas y privadas que posees.

Para borrar las claves públicas y privadas de que dispongo, hay que usar las opciones `--delete-keys` y `--delete-secret-keys` respectivamente, ambas seguidas de el uid de la clave que queramos borrar. Sin embargo, para poder borrarlas hay que seguir un orden: primero hay que borrar la privada, y después la pública. Para probar estos comando he creado otro par de claves que voy a borrar:

```
gpg --delete-secret-keys A6434BBD80D7F096592F4B17A934842CFBDB96CF 
gpg (GnuPG) 2.2.27; Copyright (C) 2021 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.


sec  rsa3072/A934842CFBDB96CF 2021-11-08 Daniel Parrales <algo@gmail.com>

¿Eliminar esta clave del anillo? (s/N) s
¡Es una clave secreta! ¿Eliminar realmente? (s/N) s
```

```
gpg --delete-keys A6434BBD80D7F096592F4B17A934842CFBDB96CF 
gpg (GnuPG) 2.2.27; Copyright (C) 2021 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.


pub  rsa3072/A934842CFBDB96CF 2021-11-08 Daniel Parrales <algo@gmail.com>

¿Eliminar esta clave del anillo? (s/N) 
```

De esta forma podemos eliminar las claves que queramos.

## Tarea 4: Exportar clave a un servidor público de claves PGP (gpg)

Para distribuir las claves públicas es mucho más habitual utilizar un servidor específico para distribuirlas, que permite a los clientes añadir las claves públicas a sus anillos de forma mucho más sencilla.

### Genera la clave de revocación de tu clave pública para utilizarla en caso de que haya problemas.

Para generar la clave de revocación tenemos que hacer uso de la opción `--gen-revoke` seguido del uid de la clave de la que queramos crear la clave de revocación:

```
gpg --gen-revoke 5E357C9F804207FABAB0B54C003678CA94289486

sec  rsa3072/003678CA94289486 2021-11-13 Daniel Parrales Garcia <micorreo@gmail.com>

¿Crear un certificado de revocación para esta clave? (s/N) s
Por favor elija una razón para la revocación:
  0 = No se dio ninguna razón
  1 = La clave ha sido comprometida
  2 = La clave ha sido reemplazada
  3 = La clave ya no está en uso
  Q = Cancelar
(Probablemente quería seleccionar 1 aquí)
¿Su decisión? 0
Introduzca una descripción opcional; acábela con una línea vacía:
> 
Razón para la revocación: No se dio ninguna razón
(No se dió descripción)
¿Es correcto? (s/N) s
```

Tras confirmar que queremos crear la clave de revocación (también nos pide que digamos la razón) nos aparece la clave:

```
se fuerza salida con armadura ASCII.
-----BEGIN PGP PUBLIC KEY BLOCK-----
Comment: This is a revocation certificate

iQG2BCABCgAgFiEEXjV8n4BCB/q6sLVMADZ4ypQolIYFAmGP67ECHQAACgkQADZ4
ypQolIZPDQv/XTrwz1CO7PGNQL4rXLuEqU8gxycm4cKtq9TMHlkowPXr61O1C+43
igKttyRhEq0iZNdIKbRhicnO2Mjj5jyIcNa2IDVN8438gd1o6Q561wU/4id2U0Sp
5cH6qc+TPZlKJc1R83AyKhGp4IDZjSJMM/EarMuUvWF3pkatsnMtJNjp+uW+RnMC
Uj5UqzQojktlxLEOgNK/FPaHzMEcQzMAgksTwDP6F+UtssOisoh7UfYmFCZChM86
14zHC/fElXmYb/RNfE6Bx0UHB51vbdyIIq8iaN7KiNk+kbHL2pg8JismOhYlz6pp
s69Bvuyzb3aHyaT13gfglPZJ0L/0FzzAJkhZ864Fx11DJLPPN7mP++vOkmyv9FOB
Ff+bSRE3Ly1Q/7CkYzqwQ6+4kJQQ9SKC0/AViBPpa/CquEXrf3uzirpdT6EfOMQs
BW4+YmEb9vUfD+m/eJB9dc8DyMfq5kq6o5o4cbYOd+NIpGiwYuuysgiICgGBKvje
IXex6QfAdJGB
=BfEo
-----END PGP PUBLIC KEY BLOCK-----
Certificado de revocación creado.

Por favor consérvelo en un medio que pueda esconder; si alguien consigue
acceso a este certificado puede usarlo para inutilizar su clave.
Es inteligente imprimir este certificado y guardarlo en otro lugar, por
si acaso su medio resulta imposible de leer. Pero precaución: ¡el sistema
de impresión de su máquina podría almacenar los datos y hacerlos accesibles
a otras personas!
```
    
El certificado de revocación se encuentra entre las líneas 'BEGIN PGP PUBLIC KEY BLOCK' y 'END PGP PUBLIC KEY BLOCK'.

### Exporta tu clave pública al servidor `pgp.rediris.es`

Para exportar la clave pública al servidor `pgp.rediris.es` tenemos que usar la opción `--keyserver` y el nombre del servidor, y la opción `--send-key` junto con el uid de la clave que queramos subir. 

```
gpg --keyserver pgp.rediris.es --send-keys 5E357C9F804207FABAB0B54C003678CA94289486
gpg: enviando clave 003678CA94289486 a hkp://pgp.rediris.es
```

Una vez enviada, podemos burcarla desde el navegador de la página:

![red_iris1.png](/images/cifrado_asimetrico_gpg_openssl/red_iris1.png)

![red_iris2.png](/images/cifrado_asimetrico_gpg_openssl/red_iris2.png)
    
### Borra la clave pública de alguno de tus compañeros de clase e impórtala ahora del servidor público de rediris.

Vamos a borrar la clave que importamos anteriormente de Lara, usando el comando que vimos antes:

```
gpg --delete-keys 44589663DC53593052B6616F51D0DEC846173F6A
gpg (GnuPG) 2.2.27; Copyright (C) 2021 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.


pub  rsa3072/51D0DEC846173F6A 2021-11-13 Lara Pruna Ternero <larapruter@gmail.com>

¿Eliminar esta clave del anillo? (s/N) s
```

Una vez eliminada, vamos a importarla del servidor rediris. Para ello haremos uso de la opción `--keyserver` y el nombre del servidor, y la opción `--recv-keys` junto con el uid de la clave que queramos subir (tambien sirve los últimos ocho dígitos del uid):

```
gpg --keyserver pgp.rediris.es --recv-keys 46173F6A
gpg: clave 51D0DEC846173F6A: clave pública "Lara Pruna Ternero <larapruter@gmail.com>" importada
gpg: Cantidad total procesada: 1
gpg:               importadas: 1
```

Ahora podemos comprobar, que efectivamente, la clave se importado correctamente:

```
gpg --list-keys
/home/dparrales/.gnupg/pubring.kbx
----------------------------------
pub   rsa3072 2021-11-13 [SC] [caduca: 2023-11-13]
      5E357C9F804207FABAB0B54C003678CA94289486
uid        [  absoluta ] Daniel Parrales Garcia <micorreo@gmail.com>
sub   rsa3072 2021-11-13 [E] [caduca: 2023-11-13]

pub   rsa3072 2021-11-13 [SC] [caduca: 2023-11-13]
      44589663DC53593052B6616F51D0DEC846173F6A
uid        [desconocida] Lara Pruna Ternero <larapruter@gmail.com>
sub   rsa3072 2021-11-13 [E] [caduca: 2023-11-13]
```

## Tarea 5: Cifrado asimétrico con openssl

En esta ocasión vamos a cifrar nuestros ficheros de forma asimétrica utilizando la herramienta openssl

### Genera un par de claves (pública y privada).

Para generar el par de claves haremos uso del comando openssl con las siguientes opciones:

* genrsa: para indicar que queremos usar el algoritmo RSA.
* -aes128: para indicar que usaremos una clave de paso para desbloquearla que utilizará el algoritmo AES128 (podríamos haber usado otros).
* -out: Para indicar el nombre del fichero que tendrá el par de claves que creemos.

Al final del comando especificaremos el tamaño de la clave. En mi caso usaré 4096 bits.

```
openssl genrsa -aes128 -out clave.pem 2048
[sudo] password for dparrales: 
Generating RSA private key, 2048 bit long modulus (2 primes)
.............+++++
....................................+++++
e is 65537 (0x010001)
Enter pass phrase for clave.pem:
Verifying - Enter pass phrase for clave.pem:
```

Con esto hemos generado el par de claves en un único fichero llamado `clave.pem`.

### Envía tu clave pública a un compañero.

Como hemos mencionado antes, openssl genera tanto la clave pública como la privada en un mismo fichero, lo que quiere decir que tendremos que extraer la pública en primer lugar, ya que sería un gran riesgo el enviar el fichero completo. 

Para extraer la clave pública usaremos el comando `openssl` con las siguientes opciones:

* -in: para indicar el fichero del que queremos extraer las claves.
* -pubout: para indicar que lo que queremos es extraer la clave pública.
* -out: para indicar el nombre del fichero en el que queremos extraer la clave pública.
* rsa: indica que queremos usar el algoritmo RSA.

```
openssl rsa -in clave.pem -pubout -out clavepublica_dparrales.pem
Enter pass phrase for clave.pem:
writing RSA key
```

Podemos ver el contenido del fichero con el comando `cat`:

```
cat clavepublica_dparrales.pem 
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAug90m2FqE4wMxe8wBI1Y
Whmma0M/uom3xv2O9ugFtbi8Qyo/bBuge+yLe4yI7sNoBPvtSmu4SD3JAU7G3POy
+3D0zgH5zjqE6WoKjc9D2JdUuRT+AYgCMkjvSCvM9TiW+iL3ksASu6bTXckHia/k
XLUVx7UTrU2sEKmQziZGxiyeOQmx2rpultDyethMXD8F/gFvnVWrBGhab6efFHHg
kCRJmAgjHQth/pKOLWgxHNNIX+C5z2q17f3OckgbDIVGnZGHpflawPh8Pcuksk12
yqDEqnoen9v5D2gCjnbjw97bSjA53T/V8NkXctTMvYR3fjxIU2gKPUdDXT7yLAzd
XQIDAQAB
-----END PUBLIC KEY-----
```

Ahora podemos enviar la clave a nuestro compañero (en mi caso he usado ssh).

### Utilizando la clave pública cifra un fichero de texto y envíalo a tu compañero.

He creado un nuevo fichero al que he llamado `1.txt`. Para cifrarlo con nuestra clave, debemos usar el comando openssl con las siguientes opciones:

* -encrypt: indicamos que vamos a cifrar un fichero.
* -in: indicamos el fichero que vamos a cifrar.
* -out: para indicar el nombre del fichero una vez lo cifremos.
* -inkey: para indicar la clave con la que cifraremos el fichero.
* -pubin: para indicar que vamos a cifrar el fichero con una clave pública.
* rsautl: para indicar que vamos usar el algoritmo RSA.

```
openssl rsautl -encrypt -in 1.txt -out cifrado2.enc -inkey lara.pub.pem -pubin
```

Como podemos ver, he usado la clave pública que me ha pasado lara para encriptar el ficher, tras lo cual enviamos el fichero a nuestro compañero.
    
### Tu compañero te ha mandado un fichero cifrado, muestra el proceso para el descifrado.

Mi compañero me ha mandado un fichero cifrado llamado `prueba_lara.enc`:

![openssl_lara.png](/images/cifrado_asimetrico_gpg_openssl/openssl_lara.png)

Para desencriptarlo haremos uso del comando openssl con las siguientes opciones:

* -decrypt: para indicar que queremos descifrar el fichero.
* -in: para indicar el fichero que queremos descifrar.
* -out: para indicar el fichero que generaremos al descifrar el fichero.
* -inkey: para indicar la clave pública que usaremos para descifrar el fichero.
* rsautl: para indicar que vamos a usar RSA.

```
sudo openssl rsautl -decrypt -in prueba_lara.enc -out prueba.desc -inkey clave.pem 
```

Nos ha generado un fichero llamado `prueba.desc` con el siguiente contenido:

![desc_lara.png](/images/cifrado_asimetrico_gpg_openssl/desc_lara.png)
