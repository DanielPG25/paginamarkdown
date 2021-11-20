+++ 
draft = true
date = 2021-11-20T15:35:40+01:00
title = "Integridad, firmas y autenticación"
description = "Integridad, firmas y autenticación"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Seguridad y Alta Disponibilidad"]
externalLink = ""
series = []
+++

# Integridad, firmas y autenticación

## Tarea 1: Firmas electrónicas

En este primer apartado vamos a trabajar con las firmas electrónicas.

### Manda un documento y la firma electrónica del mismo a un compañero. Verifica la firma que tu has recibido.

Para empezar, voy a mostrar las claves que tengo guardadas en mi "llavero" de claves de gpg:

```
gpg --list-keys

gpg: comprobando base de datos de confianza
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: nivel: 0  validez:   1  firmada:   0  confianza: 0-, 0q, 0n, 0m, 0f, 1u
gpg: siguiente comprobación de base de datos de confianza el: 2021-12-15
/home/dparrales/.gnupg/pubring.kbx
----------------------------------
pub   rsa3072 2021-11-15 [SC] [caduca: 2021-12-15]
      150B0A645D25B92F39531DBE6A6EB8CAF096A3F7
uid        [  absoluta ] Daniel Parrales Garcia <micorreofalso@gmail.com>
sub   rsa3072 2021-11-15 [E] [caduca: 2021-12-15]
```

Esta clave la subiré a un servidor de claves (en este caso usaré el mismo de la pŕactica anterior: rediris), para que de esta forma mi compañera (Lara Pruna Ternero)pueda descargársela:

```
gpg --keyserver pgp.rediris.es --send-keys 150B0A645D25B92F39531DBE6A6EB8CAF096A3F7
gpg: enviando clave 6A6EB8CAF096A3F7 a hkp://pgp.rediris.es
```

Ahora procedamos a descargar la clave pública de mi compañera del mismo servidor:

```
gpg --keyserver pgp.rediris.es --recv-keys 46173F6A 
gpg: clave 51D0DEC846173F6A: clave pública "Lara Pruna Ternero <larapruter@gmail.com>" importada
gpg: Cantidad total procesada: 1
gpg:               importadas: 1
```

Podemos ver que se importado correctamente volviendo a revisar nuestro "llavero":

```
gpg --list-keys
/home/dparrales/.gnupg/pubring.kbx
----------------------------------
pub   rsa3072 2021-11-15 [SC] [caduca: 2021-12-15]
      150B0A645D25B92F39531DBE6A6EB8CAF096A3F7
uid        [  absoluta ] Daniel Parrales Garcia <micorreofalso@gmail.com>
sub   rsa3072 2021-11-15 [E] [caduca: 2021-12-15]

pub   rsa3072 2021-11-13 [SC] [caduca: 2023-11-13]
      44589663DC53593052B6616F51D0DEC846173F6A
uid        [desconocida] Lara Pruna Ternero <larapruter@gmail.com>
sub   rsa3072 2021-11-13 [E] [caduca: 2023-11-13]
```

Una vez verificado, vamos a firmar un documento y a enviárselo junto a la firma para que pueda verificarla. En la práctica anterior hicimos uso de la opción `--sign`, que sirve para incluir tanto la firma como el documento firmado en un mismo fichero. Esta vez sin embargo, como queremos mandar el fichero firmado y la firma por separado, haremos uso de la opción `--detach-sign`. Así pues, voy a firmar un fichero que he creado de nombre `cifrado.txt`:

`gpg --detach-sign cifrado.txt`

Podemos verificar que se ha creado la firma de la siguiente forma:

```
ls -l | egrep cifrado.txt
-rw-r--r--  1 dparrales dparrales  1957 nov 13 18:59 cifrado.txt
-rw-r--r--  1 dparrales dparrales   438 nov 15 09:05 cifrado.txt.sig
```

Como vemos, nos ha generado la firma con la extensión `.sig`. Ahora procederemos a enviárselo a nuestra compañera (en mi caso haciendo uso de scp) y nosotros recibiremos su documento y su firma:

```
ls -l | egrep lara_planB
-rw-r--r--  1 dparrales dparrales   208 nov 15 09:09 lara_planB.txt
-rw-r--r--  1 dparrales dparrales   438 nov 15 09:10 lara_planB.txt.sig
```

Ahora, para verificar la firma del fichero, tenemos que hacer uso de la opción `--verify`:

```
gpg --verify lara_planB.txt.sig lara_planB.txt

gpg: Firmado el lun 15 nov 2021 09:06:06 CET
gpg:                usando RSA clave 44589663DC53593052B6616F51D0DEC846173F6A
gpg: Firma correcta de "Lara Pruna Ternero <larapruter@gmail.com>" [desconocido]
gpg: ATENCIÓN: ¡Esta clave no está certificada por una firma de confianza!
gpg:          No hay indicios de que la firma pertenezca al propietario.
Huellas dactilares de la clave primaria: 4458 9663 DC53 5930 52B6  616F 51D0 DEC8 4617 3F6A
```

Efectivamente, nos indica que la verificación ha sido un éxito. También nos indica que la clave no está certificada por una firma de confianza, lo que quiere decir que no tenemos pruebas de que la clave que hemos importado pertenezca realmente a esa persona.


### ¿Qué significa el mensaje que aparece en el momento de verificar la firma?

```
gpg: Firma correcta de "Pepe D <josedom24@gmail.com>" [desconocido]
gpg: ATENCIÓN: ¡Esta clave no está certificada por una firma de confianza!
gpg:          No hay indicios de que la firma pertenezca al propietario.
Huellas dactilares de la clave primaria: E8DD 5DA9 3B88 F08A DA1D  26BF 5141 3DDB 0C99 55FC
```

El mensaje significa que efectivamente, el fichero que hemos validado ha sido firmado por la clave de "Pepe D", pero no tenemos ninguna prueba de que esa persona sea "Pepe D". Podría pasar que el documento lo haya firmado otra persona haciéndose pasar por "Pepe D" o que nosotros nos hayamos importado una clave creyendo que era de él pero en realidad no lo sea. Es por ello, 


### Vamos a crear un anillo de confianza entre los miembros de nuestra clase, para ello.

* Tu clave pública debe estar en un servidor de claves
* Escribe tu fingerprint en un papel y dáselo a tu compañero, para que puede descargarse tu clave pública.
* Te debes bajar al menos tres claves públicas de compañeros. Firma estas claves.
* Tu te debes asegurar que tu clave pública es firmada por al menos tres compañeros de la clase.
* Una vez que firmes una clave se la tendrás que devolver a su dueño, para que otra persona se la firme.
* Cuando tengas las tres firmas sube la clave al servidor de claves y rellena tus datos en la tabla Claves públicas PGP 2020-2021
* Asegúrate que te vuelves a bajar las claves públicas de tus compañeros que tengan las tres firmas.
   
Para esta parte, he decidido empezar de cero, creando un nuevo para de claves y eliminando la clave de lara de mi "llavero". Así pues, mi "llavero" contiene lo siguiente:

```
gpg --list-keys
/home/dparrales/.gnupg/pubring.kbx
----------------------------------
pub   rsa3072 2021-11-15 [SC]
      C97939130FACC475D435CF070A3D7E065504F64B
uid        [  absoluta ] Daniel Parrales Garcia (Para ASIR) <daniparrales16@gmail.com>
sub   rsa3072 2021-11-15 [E]
```

Es esta la clave pública que he subido a rediris:

```
gpg --keyserver pgp.rediris.es --send-keys C97939130FACC475D435CF070A3D7E065504F64B
```

Ahora vamos a importar desde el servidor las tres claves de nuestros compañeros (Lara Pruna, Omar Elhani y Miguel Córdoba) para firmarlas:

```
gpg --keyserver pgp.rediris.es --recv-keys 46173F6A 
gpg: clave 51D0DEC846173F6A: clave pública "Lara Pruna Ternero <larapruter@gmail.com>" importada
gpg: Cantidad total procesada: 1
gpg:               importadas: 1

gpg --keyserver pgp.rediris.es --recv-keys 644AC899
gpg: clave CA261D60644AC899: clave pública "omar elhani <omar.elhani1@gmail.com>" importada
gpg: Cantidad total procesada: 1
gpg:               importadas: 1

gpg --keyserver pgp.rediris.es --recv-keys 8C74FBC0
gpg: clave 93E00F9A8C74FBC0: clave pública "Miguel Cordoba <miguelcor.rrss@gmail.com>" importada
gpg: Cantidad total procesada: 1
gpg:               importadas: 1
```

Veamos si están incorporadas a nuestro "llavero":

```
gpg --list-keys
/home/dparrales/.gnupg/pubring.kbx
----------------------------------
pub   rsa3072 2021-11-15 [SC]
      C97939130FACC475D435CF070A3D7E065504F64B
uid        [  absoluta ] Daniel Parrales Garcia (Para ASIR) <daniparrales16@gmail.com>
sub   rsa3072 2021-11-15 [E]

pub   rsa3072 2021-11-13 [SC] [caduca: 2023-11-13]
      44589663DC53593052B6616F51D0DEC846173F6A
uid        [desconocida] Lara Pruna Ternero <larapruter@gmail.com>
sub   rsa3072 2021-11-13 [E] [caduca: 2023-11-13]

pub   rsa3072 2021-11-11 [SC] [caduca: 2023-11-11]
      E152B3B11133E7BB6C1054B7CA261D60644AC899
uid        [desconocida] omar elhani <omar.elhani1@gmail.com>
sub   rsa3072 2021-11-11 [E] [caduca: 2023-11-11]

pub   rsa3072 2021-11-11 [SC] [caduca: 2021-12-11]
      0F99E1755360586A9B7C1F9C93E00F9A8C74FBC0
uid        [desconocida] Miguel Cordoba <miguelcor.rrss@gmail.com>
sub   rsa3072 2021-11-11 [E] [caduca: 2023-11-11]
```

Actualmente, si nos fijamos, la validez de las claves es desconocida. Este parámetro cambiará una vez que hayamos firmado las claves. Para firma las claves haremos uso de la opción `--sign-key` seguido del identificador de la clave:

```
gpg --sign-key 44589663DC53593052B6616F51D0DEC846173F6A

pub  rsa3072/51D0DEC846173F6A
     creado: 2021-11-13  caduca: 2023-11-13  uso: SC  
     confianza: desconocido   validez: desconocido
sub  rsa3072/99912020704046AB
     creado: 2021-11-13  caduca: 2023-11-13  uso: E   
[desconocida] (1). Lara Pruna Ternero <larapruter@gmail.com>


pub  rsa3072/51D0DEC846173F6A
     creado: 2021-11-13  caduca: 2023-11-13  uso: SC  
     confianza: desconocido   validez: desconocido
 Huella clave primaria: 4458 9663 DC53 5930 52B6  616F 51D0 DEC8 4617 3F6A

     Lara Pruna Ternero <larapruter@gmail.com>

Esta clave expirará el 2023-11-13.
¿Está realmente seguro de querer firmar esta clave
con su clave: "Daniel Parrales Garcia (Para ASIR) <daniparrales16@gmail.com>" (0A3D7E065504F64B)?

¿Firmar de verdad? (s/N) s
```

```
dparrales@debian:~$ gpg --sign-key E152B3B11133E7BB6C1054B7CA261D60644AC899

gpg: comprobando base de datos de confianza
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: nivel: 0  validez:   1  firmada:   1  confianza: 0-, 0q, 0n, 0m, 0f, 1u
gpg: nivel: 1  validez:   1  firmada:   0  confianza: 1-, 0q, 0n, 0m, 0f, 0u
gpg: siguiente comprobación de base de datos de confianza el: 2023-11-13
pub  rsa3072/CA261D60644AC899
     creado: 2021-11-11  caduca: 2023-11-11  uso: SC  
     confianza: desconocido   validez: desconocido
sub  rsa3072/2167621B8A191E79
     creado: 2021-11-11  caduca: 2023-11-11  uso: E   
[desconocida] (1). omar elhani <omar.elhani1@gmail.com>


pub  rsa3072/CA261D60644AC899
     creado: 2021-11-11  caduca: 2023-11-11  uso: SC  
     confianza: desconocido   validez: desconocido
 Huella clave primaria: E152 B3B1 1133 E7BB 6C10  54B7 CA26 1D60 644A C899

     omar elhani <omar.elhani1@gmail.com>

Esta clave expirará el 2023-11-11.
¿Está realmente seguro de querer firmar esta clave
con su clave: "Daniel Parrales Garcia (Para ASIR) <daniparrales16@gmail.com>" (0A3D7E065504F64B)?

¿Firmar de verdad? (s/N) s
```

```
dparrales@debian:~$ gpg --sign-key 0F99E1755360586A9B7C1F9C93E00F9A8C74FBC0

gpg: comprobando base de datos de confianza
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: nivel: 0  validez:   1  firmada:   2  confianza: 0-, 0q, 0n, 0m, 0f, 1u
gpg: nivel: 1  validez:   2  firmada:   0  confianza: 2-, 0q, 0n, 0m, 0f, 0u
gpg: siguiente comprobación de base de datos de confianza el: 2023-11-11
pub  rsa3072/93E00F9A8C74FBC0
     creado: 2021-11-11  caduca: 2021-12-11  uso: SC  
     confianza: desconocido   validez: desconocido
sub  rsa3072/264D8A7CC114656B
     creado: 2021-11-11  caduca: 2023-11-11  uso: E   
[desconocida] (1). Miguel Cordoba <miguelcor.rrss@gmail.com>


pub  rsa3072/93E00F9A8C74FBC0
     creado: 2021-11-11  caduca: 2021-12-11  uso: SC  
     confianza: desconocido   validez: desconocido
 Huella clave primaria: 0F99 E175 5360 586A 9B7C  1F9C 93E0 0F9A 8C74 FBC0

     Miguel Cordoba <miguelcor.rrss@gmail.com>

Esta clave expirará el 2021-12-11.
¿Está realmente seguro de querer firmar esta clave
con su clave: "Daniel Parrales Garcia (Para ASIR) <daniparrales16@gmail.com>" (0A3D7E065504F64B)?

¿Firmar de verdad? (s/N) s
```

Una vez firmadas, podemos observar como ha cambiado el parámetro de validez de la clave de "desconocida" a "total":

```
gpg --list-keys
gpg: comprobando base de datos de confianza
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: nivel: 0  validez:   1  firmada:   3  confianza: 0-, 0q, 0n, 0m, 0f, 1u
gpg: nivel: 1  validez:   3  firmada:   0  confianza: 3-, 0q, 0n, 0m, 0f, 0u
gpg: siguiente comprobación de base de datos de confianza el: 2021-12-11
/home/dparrales/.gnupg/pubring.kbx
----------------------------------
pub   rsa3072 2021-11-15 [SC]
      C97939130FACC475D435CF070A3D7E065504F64B
uid        [  absoluta ] Daniel Parrales Garcia (Para ASIR) <daniparrales16@gmail.com>
sub   rsa3072 2021-11-15 [E]

pub   rsa3072 2021-11-13 [SC] [caduca: 2023-11-13]
      44589663DC53593052B6616F51D0DEC846173F6A
uid        [   total   ] Lara Pruna Ternero <larapruter@gmail.com>
sub   rsa3072 2021-11-13 [E] [caduca: 2023-11-13]

pub   rsa3072 2021-11-11 [SC] [caduca: 2023-11-11]
      E152B3B11133E7BB6C1054B7CA261D60644AC899
uid        [   total   ] omar elhani <omar.elhani1@gmail.com>
sub   rsa3072 2021-11-11 [E] [caduca: 2023-11-11]

pub   rsa3072 2021-11-11 [SC] [caduca: 2021-12-11]
      0F99E1755360586A9B7C1F9C93E00F9A8C74FBC0
uid        [   total   ] Miguel Cordoba <miguelcor.rrss@gmail.com>
sub   rsa3072 2021-11-11 [E] [caduca: 2023-11-11]
```

Ahora vamos a tener que exportar dichas claves manualmente, para devolvérsela a nuestros compañeros. Para ello he usado el siguiente comando:

```
gpg --export -a 44589663DC53593052B6616F51D0DEC846173F6A > clave-lara.asc
gpg --export -a E152B3B11133E7BB6C1054B7CA261D60644AC899 > clave-omar.asc
gpg --export -a 0F99E1755360586A9B7C1F9C93E00F9A8C74FBC0 > clave-miguel.asc
```

### Muestra las firmas que tiene tu clave pública.

Una vez que hayamos recibido nuestras claves firmadas, las importamos. Podemos ver las firmas de nuestra clave usando el siguiente comando:

```
gpg --list-sig
/home/dparrales/.gnupg/pubring.kbx
----------------------------------
pub   rsa3072 2021-11-15 [SC]
      C97939130FACC475D435CF070A3D7E065504F64B
uid        [  absoluta ] Daniel Parrales Garcia (Para ASIR) <daniparrales16@gmail.com>
sig 3        0A3D7E065504F64B 2021-11-15  Daniel Parrales Garcia (Para ASIR) <daniparrales16@gmail.com>
sig          51D0DEC846173F6A 2021-11-15  Lara Pruna Ternero <larapruter@gmail.com>
sig          CA261D60644AC899 2021-11-15  omar elhani <omar.elhani1@gmail.com>
sig          EEDED9FCCE3CFC9A 2021-11-15  [ID de usuario no encontrado]
sub   rsa3072 2021-11-15 [E]
sig          0A3D7E065504F64B 2021-11-15  Daniel Parrales Garcia (Para ASIR) <daniparrales16@gmail.com>
```    

Podemos ver que tenemos tres firmas en nuestra clave pública que corresponden a los tres compañeros con los que intercambié claves (en la que pone ID de usuario no encontrado corresponde a Miguel Córdoba). Tras esto la volvemos a subir al servidor de claves:

```
gpg --keyserver pgp.rediris.es --send-keys C97939130FACC475D435CF070A3D7E065504F64B
```

Podemos ver que se ha actualizado la información en la web del servidor:

![rediris_actualizado.png](/images/integridad_firmas_autentificacion/rediris_actualizado.png)

### Comprueba que ya puedes verificar sin “problemas” una firma recibida por una persona en la que confías.

Vamos a volver a verificar el fichero que nos mandó antes lara, para ver si ahora no aparece el mensaje de advertencia:

```
gpg --verify lara_planB.txt.sig lara_planB.txt

gpg: Firmado el lun 15 nov 2021 09:06:06 CET
gpg:                usando RSA clave 44589663DC53593052B6616F51D0DEC846173F6A
gpg: Firma correcta de "Lara Pruna Ternero <larapruter@gmail.com>" [total]
```

Como podemos observar, ahora nos indica que se ha podido verificar sin problemas que el archivo está firmado por Lara.
    
### Comprueba que puedes verificar con confianza una firma de una persona en las que no confías, pero sin embargo si confía otra persona en la que tu tienes confianza total.

Para ello he recibido un archivo cifrado y una clave pública de mi compañera Lara, la cual se creo una máquina virtual para generar una nueva clave. Firmo dicha clave con su clave principal y me la pasó. Tras esto, importé dicha clave a mi sistema. Una vez hecho todo esto, tenemos en nuestro sistema una clave que no hemos firmado nosotros (por lo que no confiamos en ella), pero que se encuentra firmada por Lara, una persona en la que confío. Si intento verificar entonces la firma de ese nuevo ocurre lo siguiente:

```
gpg --verify firmado.txt.sig 
gpg: asumiendo que los datos firmados están en 'firmado.txt'
gpg: Firmado el jue 18 nov 2021 13:43:58 CET
gpg:                usando RSA clave 2023DF17B145770C56ACCDF37D7B1AA8213EEB7B
gpg: Firma correcta de "Lari Pruna Ternero <correofalso12@gmail.com>" [no definido]
gpg: ATENCIÓN: ¡Esta clave no está certificada por una firma de confianza!
gpg:          No hay indicios de que la firma pertenezca al propietario.
Huellas dactilares de la clave primaria: 2023 DF17 B145 770C 56AC  CDF3 7D7B 1AA8 213E EB7B
```

Como vemos, nos indica que no es una firma de confianza. Esto se debe a que aunque hemos firmado la clave pública de Lara y ella ha firmado la nuestra, la confianza que el sistema deposita en ella por defecto no es suficiente para que nuestro sistema confíe en las personas en las que Lara confía. Por ello tenemos que cambiar la confianza que tenemos en ella a "Total". Así pues, empecemos:

```
gpg --edit-key 44589663DC53593052B6616F51D0DEC846173F6A
gpg (GnuPG) 2.2.27; Copyright (C) 2021 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.


pub  rsa3072/51D0DEC846173F6A
     creado: 2021-11-13  caduca: 2023-11-13  uso: SC  
     confianza: desconocido   validez: total
sub  rsa3072/99912020704046AB
     creado: 2021-11-13  caduca: 2023-11-13  uso: E   
[   total   ] (1). Lara Pruna Ternero <larapruter@gmail.com>

gpg>
```

Una vez en este menú ejecutamos lo siguiente para cambiar el nivel de confianza:

```
gpg> trust
pub  rsa3072/51D0DEC846173F6A
     creado: 2021-11-13  caduca: 2023-11-13  uso: SC  
     confianza: desconocido   validez: total
sub  rsa3072/99912020704046AB
     creado: 2021-11-13  caduca: 2023-11-13  uso: E   
[   total   ] (1). Lara Pruna Ternero <larapruter@gmail.com>

Por favor, decida su nivel de confianza en que este usuario
verifique correctamente las claves de otros usuarios (mirando
pasaportes, comprobando huellas dactilares en diferentes fuentes...)


  1 = No lo sé o prefiero no decirlo
  2 = NO tengo confianza
  3 = Confío un poco
  4 = Confío totalmente
  5 = confío absolutamente
  m = volver al menú principal

¿Su decisión? 4

pub  rsa3072/51D0DEC846173F6A
     creado: 2021-11-13  caduca: 2023-11-13  uso: SC  
     confianza: absoluta      validez: total
sub  rsa3072/99912020704046AB
     creado: 2021-11-13  caduca: 2023-11-13  uso: E   
[   total   ] (1). Lara Pruna Ternero <larapruter@gmail.com>
Ten en cuenta que la validez de clave mostrada no es necesariamente
correcta a menos de que reinicies el programa.

gpg> quit
```

Hemos asignado confianza total a Lara, por lo que nos fiaremos de cualquier cosa que haya firmado ella. Así pues, antes de verificar la firma otra vez, aseguremonos de que la clave pública del falso usuario que me pasó Lara está firmada por ella:

```
pub   rsa3072 2021-11-18 [SC] [caduca: 2023-11-18]
      2023DF17B145770C56ACCDF37D7B1AA8213EEB7B
uid        [   total   ] Lari Pruna Ternero <correofalso12@gmail.com>
sig 3        7D7B1AA8213EEB7B 2021-11-18  Lari Pruna Ternero <correofalso12@gmail.com>
sig          51D0DEC846173F6A 2021-11-18  Lara Pruna Ternero <larapruter@gmail.com>
sub   rsa3072 2021-11-18 [E] [caduca: 2023-11-18]
sig          7D7B1AA8213EEB7B 2021-11-18  Lari Pruna Ternero <correofalso12@gmail.com>
```

Una vez que nos hemos asegurados de que está firmada por ella, comprobemos lo que ocurre al verificar la firma del documento anterior:

```
gpg --verify firmado.txt.sig 
gpg: asumiendo que los datos firmados están en 'firmado.txt'
gpg: Firmado el jue 18 nov 2021 13:43:58 CET
gpg:                usando RSA clave 2023DF17B145770C56ACCDF37D7B1AA8213EEB7B
gpg: comprobando base de datos de confianza
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: nivel: 0  validez:   1  firmada:   3  confianza: 0-, 0q, 0n, 0m, 0f, 1u
gpg: nivel: 1  validez:   3  firmada:   1  confianza: 2-, 0q, 0n, 0m, 1f, 0u
gpg: nivel: 2  validez:   1  firmada:   0  confianza: 1-, 0q, 0n, 0m, 0f, 0u
gpg: siguiente comprobación de base de datos de confianza el: 2021-12-11
gpg: Firma correcta de "Lari Pruna Ternero <correofalso12@gmail.com>" [total]
```

Como vemos, al estar firmada la clave pública por Lara, en quien confiamos plenamente, nos verifica correctamente la firma del fichero.


## Tarea 2: Correo seguro con evolution/thunderbird

Ahora vamos a configurar nuestro cliente de correo electrónico para poder mandar correos cifrados, para ello:

### Configura el cliente de correo evolution con tu cuenta de correo habitual

Para ello simplemente inciamos el cliente de correo y añadimos nuestro correo tal y como nos indica el asistente. Una vez acabado, debería salirnos lo siguiente:

![evolution.png](/images/integridad_firmas_autentificacion/evolution.png)

### Añade a la cuenta las opciones de seguridad para poder enviar correos firmados con tu clave privada o cifrar los mensajes para otros destinatarios

Para ello, modificamos las opciones de seguridad de nuestra cuenta de correo en Evolution, cambiando la siguiente configuración:

![evolution_cifrado.png](/images/integridad_firmas_autentificacion/evolution_cifrado.png)

### Envía y recibe varios mensajes con tus compañeros y comprueba el funcionamiento adecuado de GPG

Ahora al enviar correos, seleccionamos lo siguiente:

![evolution_cifrar.png](/images/integridad_firmas_autentificacion/evolution_cifrar.png)

Con esos dos botones marcados, al enviar el correo nos preguntará por nuestra clave de paso para cifrarlo y firmalo. Si el destinatario dispone de nuestra clave pública podrá verificarlo y descifrarlo. Cuando recibimos un correo firmado y cifrado por nuestro compañero, nos preguntará por la clave de paso de nuestra clave gpg, y si la introducimos correctamente nos indica esto en el correo:

![lara_evolution.png](/images/integridad_firmas_autentificacion/lara_evolution.png)

Esto nos indica que era un mensaje cifrado y firmado por ella, y que lo hemos verificado y descifrado con éxito.

## Tarea 3: Integridad de ficheros

Vamos a descargarnos la ISO de debian, y posteriormente vamos a comprobar su integridad. Puedes encontrar la ISO en la dirección: `https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/`.

### Para validar el contenido de la imagen CD, solo asegúrese de usar la herramienta apropiada para sumas de verificación. Para cada versión publicada existen archivos de suma de comprobación con algoritmos fuertes (SHA256 y SHA512); debería usar las herramientas sha256sum o sha512sum para trabajar con ellos.

En primer lugar, tenemos que descargarnos los ficheros que vamos a usar del enlace anterior:

* debian-10.6.0-amd64-netinst.iso: La imagen ISO cuya integridad comprobaremos.
* SHA256SUMS: El fichero con el hash de la imagen, tras aplicar el algoritmo SHA256.
* SHA256SUMS.sign: La firma haciendo uso de la clave privada de Debian sobre el hash del fichero SHA256SUMS.
* SHA512SUMS: El fichero con el hash de la imagen, tras aplicar el algoritmo SHA512.
* SHA512SUMS.sign: La firma haciendo uso de la clave privada de Debian sobre el hash del fichero SHA512SUMS.

```
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/SHA256SUMS
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/SHA256SUMS.sign
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/SHA512SUMS
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/SHA512SUMS.sign
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-11.1.0-amd64-netinst.iso
```
    
Tras esto hemos de importar las claves públicas de debian, para que podamos verificar los ficheros firmados. Podemos encontrar las claves en el siguiente [enlace](https://www.debian.org/CD/verify).

```
gpg --keyserver keyring.debian.org --recv-keys 6294BE9B
gpg: clave DA87E80D6294BE9B: clave pública "Debian CD signing key <debian-cd@lists.debian.org>" importada
gpg: Cantidad total procesada: 1
gpg:               importadas: 1
```

Una vez importada la clave pública de debian, podemos comprobar la integridad de los ficheros. Dicha integridad la comprobaremos empleando los archivos 'SHA256SUMS' y 'SHA512SUMS' junto con los comandos apropiados, que nos indicará si la integridad del fichero se ha visto vulnerada desde que se creó el fichero, ya que compararemos el hash que calculamos nosotros con el hash que nos proporciona debian en esos ficheros. Si coinciden, es que la integridad del fichero se ha mantenido, pero si falla, nos indicará que la integridad se ha visto vulnerada. Así pues, usaremos los comandos `sha256sum` y `sha512sum` para los respectivos ficheros:

```
sha256sum -c SHA256SUMS

debian-11.1.0-amd64-netinst.iso: La suma coincide
sha256sum: debian-edu-11.1.0-amd64-netinst.iso: No existe el fichero o el directorio
debian-edu-11.1.0-amd64-netinst.iso: FAILED open or read
sha256sum: debian-mac-11.1.0-amd64-netinst.iso: No existe el fichero o el directorio
debian-mac-11.1.0-amd64-netinst.iso: FAILED open or read
sha256sum: ATENCIÓN: no se pudieron leer 2 ficheros listados
```

```
sha512sum -c SHA512SUMS
debian-11.1.0-amd64-netinst.iso: La suma coincide
sha512sum: debian-edu-11.1.0-amd64-netinst.iso: No existe el fichero o el directorio
debian-edu-11.1.0-amd64-netinst.iso: FAILED open or read
sha512sum: debian-mac-11.1.0-amd64-netinst.iso: No existe el fichero o el directorio
debian-mac-11.1.0-amd64-netinst.iso: FAILED open or read
sha512sum: ATENCIÓN: no se pudieron leer 2 ficheros listados
```

Como vemos, nos aparecen algunos errores, pero dichos errores son porque no he descargado los otros 3 ficheros que había en la página. Si nos fijamos en la primera línea, nos indica que la suma coincide para el fichero que hemos descargado, por lo que podemos estar seguros de su integridad.

### Verifica que el contenido del hash que has utilizado no ha sido manipulado, usando la firma digital que encontrarás en el repositorio. Puedes encontrar una guía para realizarlo en este artículo: [How to verify an authenticity of downloaded Debian ISO images](https://linuxconfig.org/how-to-verify-an-authenticity-of-downloaded-debian-iso-images)

Para verificar que el contenido del hash que hemos utilizado no ha sido manipulado, tendremos que verificar la firma existente usando la clave pública de debian que nos descargamos anteriormente. Para ello utlizamos un comando que ya hemos utilizado anteriormente: `gpg --verify`.

```
gpg --verify SHA256SUMS.sign SHA256SUMS
gpg: Firmado el sáb 09 oct 2021 22:53:47 CEST
gpg:                usando RSA clave DF9B9C49EAA9298432589D76DA87E80D6294BE9B
gpg: Firma correcta de "Debian CD signing key <debian-cd@lists.debian.org>" [desconocido]
gpg: ATENCIÓN: ¡Esta clave no está certificada por una firma de confianza!
gpg:          No hay indicios de que la firma pertenezca al propietario.
Huellas dactilares de la clave primaria: DF9B 9C49 EAA9 2984 3258  9D76 DA87 E80D 6294 BE9B
```

```
gpg --verify SHA512SUMS.sign SHA512SUMS
gpg: Firmado el sáb 09 oct 2021 22:53:48 CEST
gpg:                usando RSA clave DF9B9C49EAA9298432589D76DA87E80D6294BE9B
gpg: Firma correcta de "Debian CD signing key <debian-cd@lists.debian.org>" [desconocido]
gpg: ATENCIÓN: ¡Esta clave no está certificada por una firma de confianza!
gpg:          No hay indicios de que la firma pertenezca al propietario.
Huellas dactilares de la clave primaria: DF9B 9C49 EAA9 2984 3258  9D76 DA87 E80D 6294 BE9B
```

Tal y como se nos indica en la salida del comando, hemos verificado con éxito la firma, por lo que podemos concluir que no ha habido ninguna manipulación en la imagen que hemos descargado.

## Tarea 4: Integridad y autenticidad (apt secure)

Cuando nos instalamos un paquete en nuestra distribución linux tenemos que asegurarnos que ese paquete es legítimo. Para conseguir este objetivo se utiliza criptografía asimétrica, y en el caso de Debian a este sistema se llama apt secure. Esto lo debemos tener en cuenta al utilizar los repositorios oficiales. Cuando añadamos nuevos repositorios tendremos que añadir las firmas necesarias para confiar en que los paquetes son legítimos y no han sido modificados.

Busca información sobre apt secure y responde las siguientes preguntas:

### ¿Qué software utiliza apt secure para realizar la criptografía asimétrica?

El software que utiliza apt secure para realizar la criptografía asimétrica es GPG (GNU Privacy Guard).
    
### ¿Para que sirve el comando apt-key? ¿Qué muestra el comando apt-key list?

El comando apt-key se utiliza para gestionar la lista de claves que usa apt para autentificar los paquetes. Los paquetes que hayan sido autentificados usando estas claves son considerados de fiar. El comando `apt-key list` muestra una lista de las claves que nuestro sistema tiene almacenado:

```
apt-key list
Warning: apt-key is deprecated. Manage keyring files in trusted.gpg.d instead (see apt-key(8)).
/etc/apt/trusted.gpg
--------------------
pub   rsa4096 2017-05-08 [SCEA]
      1EDD E2CD FC02 5D17 F6DA  9EC0 ADAE 6AD2 8A8F 901A
uid        [desconocida] Sublime HQ Pty Ltd <support@sublimetext.com>
sub   rsa4096 2017-05-08 [S]

/etc/apt/trusted.gpg.d/debian-archive-bullseye-automatic.gpg
------------------------------------------------------------
pub   rsa4096 2021-01-17 [SC] [caduca: 2029-01-15]
      1F89 983E 0081 FDE0 18F3  CC96 73A4 F27B 8DD4 7936
uid        [desconocida] Debian Archive Automatic Signing Key (11/bullseye) <ftpmaster@debian.org>
sub   rsa4096 2021-01-17 [S] [caduca: 2029-01-15]

/etc/apt/trusted.gpg.d/debian-archive-bullseye-security-automatic.gpg
---------------------------------------------------------------------
pub   rsa4096 2021-01-17 [SC] [caduca: 2029-01-15]
      AC53 0D52 0F2F 3269 F5E9  8313 A484 4904 4AAD 5C5D
uid        [desconocida] Debian Security Archive Automatic Signing Key (11/bullseye) <ftpmaster@debian.org>
sub   rsa4096 2021-01-17 [S] [caduca: 2029-01-15]

/etc/apt/trusted.gpg.d/debian-archive-bullseye-stable.gpg
---------------------------------------------------------
pub   rsa4096 2021-02-13 [SC] [caduca: 2029-02-11]
      A428 5295 FC7B 1A81 6000  62A9 605C 66F0 0D6C 9793
uid        [desconocida] Debian Stable Release Key (11/bullseye) <debian-release@lists.debian.org>

/etc/apt/trusted.gpg.d/debian-archive-buster-automatic.gpg
----------------------------------------------------------
pub   rsa4096 2019-04-14 [SC] [caduca: 2027-04-12]
      80D1 5823 B7FD 1561 F9F7  BCDD DC30 D7C2 3CBB ABEE
uid        [desconocida] Debian Archive Automatic Signing Key (10/buster) <ftpmaster@debian.org>
sub   rsa4096 2019-04-14 [S] [caduca: 2027-04-12]

/etc/apt/trusted.gpg.d/debian-archive-buster-security-automatic.gpg
-------------------------------------------------------------------
pub   rsa4096 2019-04-14 [SC] [caduca: 2027-04-12]
      5E61 B217 265D A980 7A23  C5FF 4DFA B270 CAA9 6DFA
uid        [desconocida] Debian Security Archive Automatic Signing Key (10/buster) <ftpmaster@debian.org>
sub   rsa4096 2019-04-14 [S] [caduca: 2027-04-12]

/etc/apt/trusted.gpg.d/debian-archive-buster-stable.gpg
-------------------------------------------------------
pub   rsa4096 2019-02-05 [SC] [caduca: 2027-02-03]
      6D33 866E DD8F FA41 C014  3AED DCC9 EFBF 77E1 1517
uid        [desconocida] Debian Stable Release Key (10/buster) <debian-release@lists.debian.org>

/etc/apt/trusted.gpg.d/debian-archive-stretch-automatic.gpg
-----------------------------------------------------------
pub   rsa4096 2017-05-22 [SC] [caduca: 2025-05-20]
      E1CF 20DD FFE4 B89E 8026  58F1 E0B1 1894 F66A EC98
uid        [desconocida] Debian Archive Automatic Signing Key (9/stretch) <ftpmaster@debian.org>
sub   rsa4096 2017-05-22 [S] [caduca: 2025-05-20]

/etc/apt/trusted.gpg.d/debian-archive-stretch-security-automatic.gpg
--------------------------------------------------------------------
pub   rsa4096 2017-05-22 [SC] [caduca: 2025-05-20]
      6ED6 F5CB 5FA6 FB2F 460A  E88E EDA0 D238 8AE2 2BA9
uid        [desconocida] Debian Security Archive Automatic Signing Key (9/stretch) <ftpmaster@debian.org>
sub   rsa4096 2017-05-22 [S] [caduca: 2025-05-20]

/etc/apt/trusted.gpg.d/debian-archive-stretch-stable.gpg
--------------------------------------------------------
pub   rsa4096 2017-05-20 [SC] [caduca: 2025-05-18]
      067E 3C45 6BAE 240A CEE8  8F6F EF0F 382A 1A7B 6500
uid        [desconocida] Debian Stable Release Key (9/stretch) <debian-release@lists.debian.org>
```
    
### En que fichero se guarda el anillo de claves que guarda la herramienta apt-key?

El anillo de claves se encuentra en el fichero `/etc/apt/trusted.gpg`. También hay más claves de confianza en el directorio `/etc/apt/trusted.gpg.d/`.
    
### ¿Qué contiene el archivo Release de un repositorio de paquetes?. ¿Y el archivo Release.gpg?. Puedes ver estos archivos en el repositorio `http://ftp.debian.org/debian/dists/Debian11.1/`. Estos archivos se descargan cuando hacemos un apt update.

El archivo Release contiene una lista de los paquetes junto con sus hashes MD5 y SHA256. Esto los usa el sistema para verificar que los paquetes que descargamos con apt no han sido manipulados, tal como hicimos nosotros en el ejercicio anterior, comparando los hashes del fichero Release y los hashes que calcula el sistema.

Por otro lado el fichero Release.gpg contiene las firmas correspondientes al fichero Release, por lo que al comprobar dichas firmas con las claves públicas de `/etc/apt/trusted.gpg`, el sistema puede comprobar que el remitente de esos paquetes es de confianza.
    
### Explica el proceso por el cual el sistema nos asegura que los ficheros que estamos descargando son legítimos.

Cuando se ejecuta un `apt update`, se descargan los ficheros `Release` y `Release.gpg`, junto con el fichero `Packages.gz`. De esta forma, primero se comprueba que el hash del paquete `.deb` coincide con los hashes que aparecen en los ficheros `Packages.gz` y `Release`, comprobando en último lugar que la firma del fichero `Release` a través del fichero `Release.gpg`.

    
### Añade de forma correcta el repositorio de virtualbox añadiendo la clave pública de virtualbox como se indica en la documentación.

Tal y como se nos indica en la documentación proporcionada por VirtualBox, lo primero es añadir el repositorio de virtualbox:

```
echo "deb https://download.virtualbox.org/virtualbox/debian bullseye contrib" >> /etc/apt/sources.list
```

Ahora añadimos las claves públicas de virtualbox:

```
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -

wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
```

Ahora que están añadidas, podemos ejecutar un `apt update`:

```
apt update
Get:1 http://security.debian.org/debian-security bullseye-security InRelease [44.1 kB]
Hit:2 http://deb.debian.org/debian bullseye InRelease                          
Get:3 http://deb.debian.org/debian bullseye-updates InRelease [39.4 kB]        
Get:4 http://deb.debian.org/debian bullseye-backports InRelease [43.7 kB]
Get:5 https://download.virtualbox.org/virtualbox/debian bullseye InRelease [7735 B]
Get:6 http://security.debian.org/debian-security bullseye-security/main Sources [67.8 kB]
Get:7 http://security.debian.org/debian-security bullseye-security/main amd64 Packages [94.0 kB]
Get:8 http://security.debian.org/debian-security bullseye-security/main Translation-en [59.6 kB]
Get:9 http://deb.debian.org/debian bullseye-backports/main Sources.diff/Index [63.3 kB]
Get:10 http://deb.debian.org/debian bullseye-backports/main amd64 Packages.diff/Index [63.3 kB]
Get:11 http://deb.debian.org/debian bullseye-backports/main Translation-en.diff/Index [26.3 kB]
Get:12 http://deb.debian.org/debian bullseye-backports/main Sources T-2021-11-18-2005.23-F-2021-11-13-2001.35.pdiff [13.9 kB]
Get:12 http://deb.debian.org/debian bullseye-backports/main Sources T-2021-11-18-2005.23-F-2021-11-13-2001.35.pdiff [13.9 kB]
Get:13 http://deb.debian.org/debian bullseye-backports/main amd64 Packages T-2021-11-18-2005.23-F-2021-11-13-2001.35.pdiff [16.6 kB]
Get:13 http://deb.debian.org/debian bullseye-backports/main amd64 Packages T-2021-11-18-2005.23-F-2021-11-13-2001.35.pdiff [16.6 kB]
Get:14 https://download.virtualbox.org/virtualbox/debian bullseye/contrib amd64 Packages [1088 B]
Get:15 http://deb.debian.org/debian bullseye-backports/main Translation-en T-2021-11-14-0803.33-F-2021-11-13-2001.35.pdiff [9932 B]
Get:15 http://deb.debian.org/debian bullseye-backports/main Translation-en T-2021-11-14-0803.33-F-2021-11-13-2001.35.pdiff [9932 B]
Fetched 551 kB in 2s (301 kB/s)     
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
5 packages can be upgraded. Run 'apt list --upgradable' to see them.
```

Con esto ya podríamos instalar virtualbox de forma normal.

## Tarea 5: Autentificación: ejemplo SSH

Vamos a estudiar como la criptografía nos ayuda a cifrar las comunicaciones que hacemos utilizando el protocolo ssh, y cómo nos puede servir también para conseguir que un cliente se autentifique contra el servidor. Responde las siguientes cuestiones:

### Explica los pasos que se producen entre el cliente y el servidor para que el protocolo cifre la información que se transmite? ¿Para qué se utiliza la criptografía simétrica? ¿Y la asimétrica?

Cuando un cliente intenta conectarse al servidor ssh a través de TCP , el servidor le indica los protocolos de cifrado de que dispone y las versiones que soporta. Si el cliente cumple con estas dos condiciones (protocolo y versión), se inicia la conexión con el protocolo que hayan elegido. En este momento, servidor y cliente crean claves públicas temporales y se las intercambian, haciendo uso en este momento de la criptografía asimétrica.

Una vez establecida la conexión, ambas partes usan el Algoritmo de Intercambio de Claves Diffie-Hellman para generar una clave simétrica. Será esta clave simétrca la que utilizará en adelante durante la conexión. 

En último lugar, una vez establecido todo lo anterior, el cliente debe autentificarse.

### Explica los dos métodos principales de autentificación: por contraseña y utilizando un par de claves públicas y privadas.

* Contraseña: El usuario usa la contraseña del usuario con el que está tratando de acceder a la máquina. Debido a que está cifrado de forma simétrica, es muy difícil que un atacante se haga con la misma.

* Par de claves: El servidor tiene almacenada la clave pública del cliente, por lo que cuando el cliente intenta conectarse, el servidor le pide que cifre algo usando la clave privada. Si el servidor es capaz de descifrarlo, se confirma la identidad del cliente y se le permite el acceso.

### En el cliente, ¿para qué sirve el contenido que se guarda en el fichero `~/.ssh/known_hosts`?

El contenido de dicho fichero lo usa el cliente para almacenar los equipos con los que ha realizado una conexión en el pasado.

### ¿Qué significa este mensaje que aparece la primera vez que nos conectamos a un servidor?

```
            $ ssh debian@172.22.200.74
            The authenticity of host '172.22.200.74 (172.22.200.74)' can't be established.
            ECDSA key fingerprint is SHA256:7ZoNZPCbQTnDso1meVSNoKszn38ZwUI4i6saebbfL4M.
            Are you sure you want to continue connecting (yes/no)? 
```

Significa que el cliente no puede garantizar que el servidor es quien dice ser (ya que no ha habido conexión anterior y la máquina no se encuentra en el fichero `~/.ssh/known_hosts`. En este momento el usuario puede decidir si seguir adelante con la comunicación o rechazarla. 

### En ocasiones cuando estamos trabajando en el cloud, y reutilizamos una ip flotante nos aparece este mensaje:

```
 $ ssh debian@172.22.200.74
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
 Someone could be eavesdropping on you right now (man-in-the-middle attack)!
 It is also possible that a host key has just been changed.
 The fingerprint for the ECDSA key sent by the remote host is
 SHA256:W05RrybmcnJxD3fbwJOgSNNWATkVftsQl7EzfeKJgNc.
 Please contact your system administrator.
 Add correct host key in /home/jose/.ssh/known_hosts to get rid of this message.
 Offending ECDSA key in /home/jose/.ssh/known_hosts:103
   remove with:
   ssh-keygen -f "/home/jose/.ssh/known_hosts" -R "172.22.200.74"
 ECDSA host key for 172.22.200.74 has changed and you have requested strict checking.
```

Este mensaje significa que el cliente tiene su fichero `~/.ssh/known_hosts` que se ha conectado antes con dicho servidor, pero que por alguna razón, el servidor a cambiado. Normalmente, en el escenario de las ip flotantes de openstack, esto se debe a que hemos reutilizado una ip flotante, por lo que el cliente recuerda haberse conectado con esa ip antes, pero como la máquina ha cambiado, nos avisa de ello.

Sin embargo, otra razón por la que pueda pasar esto, es porque alguien este suplantando la identidad del servidor (man-in-the-middle), por lo que si no estamos seguros de lo que está pasando, es mejor no arriesgarse.

### ¿Qué guardamos y para qué sirve el fichero en el servidor `~/.ssh/authorized_keys`?

En el fichero `~/.ssh/authorized_keys` se guardan las claves públicas de los usuarios que se han conectado por ssh con el servidor. De esta forma, el servidor puede asegurarse de que el cliente es quien dice ser, sin necesidad de preguntar por contraseñas.




