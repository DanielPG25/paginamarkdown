+++ 
draft = true
date = 2022-01-19T08:50:08+01:00
title = "Ejercicios con Postfix"
description = "Ejercicios con el servidor de correo Postfix"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Servicios de Red"]
externalLink = ""
series = []
+++
# Ejercicios con el Servidor de Correos (Postfix)

## Ejercicio 1: Envío local, entre usuarios del mismo servidor

Instala y configura un servidor de correo en apolo. El nombre del sistema de correo será tu nombre de dominio `tudominio.gonzalonazareno.org`.

Utilizando la utilidad mail manda un correo desde un usuario del servidor a otro usuario del servidor. El usuario destinatario debe leer el correo con el mismo programa.

--------------------------------------------------------------

Para empezar, en apolo vamos a tener que instalar los dos paquetes que vamos a necesitar para este y los próximos ejercicios:

```
apt install postfix bsd-mailx
```

Al instalar postfix nos saldrá el siguiente menú:

![img_1.png](/images/ejercicios_servidor_correos/img_1.png)

![img_2.png](/images/ejercicios_servidor_correos/img_2.png)

Seleccionamos "Internet Site". A continuación nos aparece el siguiente menú:

![img_3.png](/images/ejercicios_servidor_correos/img_3.png)

En este momento nos está preguntando por el nombre del dominio en el que estará en el servidor de correos, por lo que he puesto el dominio que he configurado en mi escenario: `dparrales.gonzalonazareno.org`. Con esto ya habríamos terminado de instalar postfix y podríamos empezar a mandar correos dentro del mismo servidor usando la herramienta `mail`.

Más adelante, en otros ejercicios, entraremos en más profundidad con la configuración de postfix, pero por ahora nos vale lo que hemos hecho para completar el ejercicio. Así pues, mandamos un correo a otro usuario del servidor usando la siguiente sintaxis:

```
mail nombre_usuario@dominio
```

![img_4.png](/images/ejercicios_servidor_correos/img_4.png)

Como vemos he mandado un correo al usuario impmon (creado para otras prácticas). Una vez terminado el cuerpo del mensaje salimos con Control+D.

Ahora entremos como dicho usuario y comprobemos si ha llegado el correo:

![img_5.png](/images/ejercicios_servidor_correos/img_5.png)

Para ver el correo usamos el comando `mail` sin ningún parámetro. Podemos ver que el correo ha llegado, y tiene el número 1 asignado, por lo que para leer dicho correo simplemente introducimos dicho número:

![img_6.png](/images/ejercicios_servidor_correos/img_6.png)

El correo ha llegado de forma satisfactoria, así que podemos dar por concluido este ejercicio.


## Ejercicio 2: Envío de correo desde usuarios del servidor a correos de Internet

Configura tu servidor de correo para que use como relay el servidor de correo de nuestra red babuino-smtp. Con la utilidad mail envía un correo a tu cuenta personal de gmail, hotmail, etc.

Muestra el log del sistema donde se comprueba que el correo se ha enviado con éxito.

Comprueba las cabeceras del correo que has recibido e indica donde vemos los servidores por los que ha pasado el correo.

---------------------------------------------------

En este ejercicio seguiremos usando las mismas máquinas que en el anterior. Así pues, para configurar a `babuino-smtp` como relay, debemos añadir la siguiente línea en el fichero de configuración de postfix (`/etc/postfix/main.cf`):

```
nano /etc/postfix/main.cf

relayhost = babuino-smtp.gonzalonazareno.org
```

Ahora probamos a mandar un correo a mi cuenta de gmail (para que funcione, el relay debe estar configurado para aceptar correo desde nuestra red):

![img_7.png](/images/ejercicios_servidor_correos/img_7.png)

Veamos el log de postfix (`/var/log/mail.log`) para ver si se ha mandado:

![img_8.png](/images/ejercicios_servidor_correos/img_8.png)

Como vemos, el log nos indica que se ha enviado. Comprobemos ahora si lo hemos recibido en nuestro cliente:

![img_9.png](/images/ejercicios_servidor_correos/img_9.png)

Lo hemos recibido de forma satisfactoria. Miremos las cabeceras del correo y comprobemos los saltos que ha dado hasta llegar a mi cliente:

![img_10.png](/images/ejercicios_servidor_correos/img_10.png)

En las cabeceras se nos indica que ha pasado tanto por apolo como por babuino, por lo que podemos concluir que este ejercicio ha sido un éxito.

## Ejercicio 3: Recibir correos desde Internet a usuarios del servidor

En este ejercicio debes responder desde tu cuenta de correo personal al correo que recibiste en el ejercicio anterior. Recuerda que para que todo funcione debes indicarle al profesor el nombre de tu dominio para que configure de manera adecuada el parámetro relay_domains en babuino-smtp. Además debes configurar de manera adecuada el registro MX de tu servidor DNS.

Muestra el log del sistema donde se comprueba que el correo se ha recibido con éxito.

-----------------------------------------------------

Para empezar, debemos añadir a nuestro servidor dns un registro MX que indique a que máquina enviar el correo de nuestro dominio. Debido a que en Apolo tengo creada tres zonas (una para cada red), añadiríamos el registro MX a la zona externa, indicando que los correos que lleguen a nuestro dominio sean enviados a la máquina Zeus. En dicha máquina crearemos una regla DNAT, para que todos los correos sean transferidos a Apolo. Así pues, empecemos por el registro MX:

```
nano /var/cache/bind/db.externa.dparrales.gonzalonazareno.org

$TTL    86400
@   IN  SOA zeus.dparrales.gonzalonazareno.org. dparrales.example.org. (
                  1     ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
              86400 )   ; Negative Cache TTL
;
@       IN       NS     zeus.dparrales.gonzalonazareno.org.
@       IN       MX     10 zeus.dparrales.gonzalonazareno.org.

$ORIGIN dparrales.gonzalonazareno.org.

zeus    IN      A       172.22.9.170
www     IN      CNAME   zeus
python  IN      CNAME   zeus
```

Y reiniciamos el servicio:

```
systemctl restart bind9
```

Ahora, en Zeus, vamos a crear la regla DNAT necesaria para transferir los correos que le lleguen a apolo. Para hacerla persistente, la añadimos al fichero `/etc/network/interfaces`:

```
post-up iptables -t nat -A PREROUTING -p tcp -i enp0s8 --dport 25 -j DNAT --to 10.0.1.102
```

Como estamos en una red interna dentro del instituto, debemos asegurarnos de que la puerta de enlace del mismo esté bien configurada y aceptando paquetes del puerto 25. Una vez confirmado esto, podemos ir a nuestro cliente de correos que usamos en el ejercicio anterior y responder al correo que nos llegó desde apolo:

![img_11.png](/images/ejercicios_servidor_correos/img_11.png)

Al cabo de unos segundos, y si todo ha ido bien, nos aparece en el log de apolo que le ha llegado un correo:

![img_12.png](/images/ejercicios_servidor_correos/img_12.png)

Veamos el correo usando la utilidad `mail`:

![img_13.png](/images/ejercicios_servidor_correos/img_13.png)

Como vemos, el correo ha llegado correctamente, incluyendo todas las respuestas que estaban en cola por anteriores pruebas.

