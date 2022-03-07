+++ 
draft = true
date = 2022-01-27T18:59:42+01:00
title = "Ejercicios con Kubernetes"
description = "Ejercicios con Kubernetes"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Cloud Computing"]
externalLink = ""
series = []
+++

# Ejercicios con Kubernetes

Vamos a realizar los ejercicios que se encuentran en [este](https://github.com/iesgn/curso_kubernetes_cep) curso de Kubernetes.

## Contenedores en Kubernetes: Pods

### Actividad: Trabajando con Pods

Vamos a crear nuestro primer Pod, y para ellos vamos a desplegar una imagen que nos ofrece un servidor web con una página estática. Para ello realiza los siguientes pasos:

1. Crea un fichero yaml con la descripción del recurso Pod, teniendo en cuenta los siguientes aspectos:
    - Indica nombres distintos para el Pod y para el contenedor.
    - La imagen que debes desplegar es `iesgn/test_web:latest`.
    - Indica una etiqueta en la descripción del Pod.
2. Crea el Pod.
3. Comprueba que el Pod se ha creado y está corriendo.
4. Obtén información detallada del Pod creado.
5. Accede de forma interactiva al Pod y comprueba los ficheros que están en el DocumentRoot (`usr/local/apache2/htdocs/`).
6. Crea una redirección con `kubectl port-forward` utilizando el puerto de localhost 8888 y sabiendo que el Pod ofrece el servicio en el puerto 80. Accede a la aplicación desde un navegador.
7. Muestra los logs del Pod y comprueba que se visualizan los logs de los accesos que hemos realizado en el punto anterior.
8. Elimina el Pod, y comprueba que ha sido eliminado.

-----------------------------------------------------

Para creamos un fichero `.yaml` con la siguiente información:

```
apiVersion: v1
kind: Pod
metadata:
 name: pod-test-web
 labels:
   service: web
spec:
 containers:
   - image: iesgn/test_web:latest
     name: contenedor-test-web
```

![img_1.png](/images/ejercicios_kubernetes/img_1.png)

A continuación creamos el pod:

```
kubectl apply -f test_web.yaml
```

Podemos ver que se ha creado con el siguiente comando:

```
kubectl get pods
```

![img_2.png](/images/ejercicios_kubernetes/img_2.png)

Si lo queremos ver más detallado, podemos usar el siguiente comando:

```
kubectl get pod -o wide
```

![img_3.png](/images/ejercicios_kubernetes/img_3.png)

Como vemos, el pod esta encendido y funcionando de forma correcta. No es lo habitual, pero podemos acceder al pod (en este caso tiene un solo contenedor) con el siguiente comando:

```
kubectl exec -it pod-test-web -- /bin/bash
```

![img_4.png](/images/ejercicios_kubernetes/img_4.png)

Otra cosa que podemos hacer con el pod es crear una redirección de los puertos, de forma que al acceder a uno de los puertos en el anfitrión podremos ver la página web servida por el pod que hemos creado:

```
kubectl port-forward pod-test-web 8888:80

Forwarding from 127.0.0.1:8888 -> 80
Forwarding from [::1]:8888 -> 80
```

![img_5.png](/images/ejercicios_kubernetes/img_5.png)

También podemos ver los logs de los pods, por si hubiera algún problema. Para ello usamos el siguiente comando:

```
kubectl logs pod-test-web
```

![img_6.png](/images/ejercicios_kubernetes/img_6.png)

Por último, si ya no nos hiciera falta el pod, lo eliminaríamos con el siguiente comando:

```
kubectl delete pod pod-test-web
```

![img_7.png](/images/ejercicios_kubernetes/img_7.png)

Con esto último damos por finalizado el ejercicio de introducción a los pods.

## Tolerancia y escalabilidad: ReplicaSets

### Actividad: Trabajando con ReplicaSet

Como indicamos en el contenido de este módulo, no se va a trabajar directamente con los Pods (realmente tampoco vamos a trabajar directamente con los ReplicaSet, en el siguiente módulo explicaremos los Deployments que serán el recurso con el que trabajaremos). En este ejercicio vamos a crear un ReplicaSet que va a controlar un conjunto de Pods. Para ello, realiza los siguientes pasos:

1. Crea un fichero yaml con la descripción del recurso ReplicaSet, teniendo en cuenta los siguientes aspectos:
    - Indica nombres distintos para el ReplicaSet y para el contenedor de los Pods que va a controlar.
    - El ReplicaSet va a crear 3 réplicas.
    - La imagen que debes desplegar es `iesgn/test_web:latest`.
    - Indica de manera adecuada una etiqueta en la especificación del Pod que vas a definir que coincida con el selector del ReplicaSet.
2. Crea el ReplicaSet.
3. Comprueba que se ha creado el ReplicaSet y los 3 Pods.
4. Obtén información detallada del ReplicaSet creado.
5. Vamos a probar la tolerancia a fallos: Elimina uno de los 3 Pods, y comprueba que inmediatamente se ha vuelto a crear un nuevo Pod.
6. Vamos a comprobar la escalabilidad: escala el ReplicaSet para tener 6 Pods de la aplicación.
7. Elimina el ReplicaSet y comprueba que se han borrado todos los Pods.

-------------------------------------------------

Así pues, en primer lugar creamos un fichero `.yaml` en el cual definiremos el ReplicaSet y los contenedores que manejará:

```
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: replica-test-web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-prueba
  template:
    metadata:
      labels:
        app: web-prueba
    spec:
      containers:
        - image: iesgn/test_web:latest
          name: contenedor-test-web
```

![img_8.png](/images/ejercicios_kubernetes/img_8.png)

Para crear el ReplicaSet usamos la siguiente orden:

```
kubectl apply -f test-web.yaml
```

Podemos ver que se ha creado el ReplicaSet y los pods que hemos definido:

```
kubectl get rs,pods
```

![img_9.png](/images/ejercicios_kubernetes/img_9.png)

Al igual que hicimos con los pods en el ejercicio anterior, podemos obtener información más detallada del ReplicaSet. Para ello ejecutamos lo siguiente:

```
kubectl describe rs replica-test-web
```

![img_10.png](/images/ejercicios_kubernetes/img_10.png)

Una de las ventajas que ofrecen los ReplicaSets es la tolerancia a fallos, de forma que si eliminamos uno de los pods de forma accidental o por algún error, se volverá a crear. Veámoslo:

![img_11.png](/images/ejercicios_kubernetes/img_11.png)

Como vemos, al eliminar un pod, se ha creado otro inmediatamente, de forma que Kubernetes va a tratar de que siempre tengamos activos el número de pods que le hemos indicado. 

Otra de las ventajas que ofrece Kubernetes es la escalabilidad, de forma que si en algún momento necesitamos más o menos pods, simplemente tendremos que indicárselo y Kubernetes se encargará del resto. Para probarlo, le indicaremos a Kubernetes que a partir de ahora queremos tener 6 pods en lugar de los 3 que le indicamos en fichero de definición del ReplicaSet:

```
kubectl scale rs replica-test-web --replicas=6
```

![img_12.png](/images/ejercicios_kubernetes/img_12.png)

Como vemos, ha creado otros 3 pods. Ya solo nos queda eliminar el ReplicaSet, para lo cual ejecutamos lo siguiente:

```
kubectl delete rs replica-test-web 
```

![img_13.png](/images/ejercicios_kubernetes/img_13.png)

Con la eliminación del ReplicaSet, damos por finalizado este ejercicio.

## Despliegues

### Trabajando con Deployments

En esta actividad vamos a crear un Deployment de una aplicación web. Sigamos los siguientes pasos:

1. Crea un fichero yaml con la descripción del recurso Deployment, teniendo en cuenta los siguientes aspectos:
    * Indica nombres distintos para el Deployment y para el contenedor de los Pods que va a controlar.
    * El Deployment va a crear 2 réplicas.
    * La imagen que debes desplegar es `iesgn/test_web:latest`.
    * Indica de manera adecuada una etiqueta en la especificación del Pod que vas a definir que coincida con el selector del Deployment.
2. Crea el Deployment.
3. Comprueba los recursos que se han creado: Deployment, ReplicaSet y Pods.
4. Obtén información detallada del Deployment creado.
5. Crea un una redirección utilizando el port-forward para acceder a la aplicación, sabiendo que la aplicación ofrece el servicio en el puerto 80, y accede a la aplicación con un navegador web.
6. Accede a los logs del despliegue para comprobar el acceso que has hecho en el punto anterior.
7. Elimina el Deployment y comprueba que se han borrado todos los recursos creados.

----------------------------------------------------------

Vamos a empezar creando el fichero yaml:

```
nano deployment-test-web.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-testweb
  labels:
    app: web
spec:
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - image: iesgn/test_web:latest
        name: contendor-testweb
        ports:
        - name: http
          containerPort: 80
```

![img_14.png](/images/ejercicios_kubernetes/img_14.png)

Lanzamos el deployment:

```
kubectl apply -f deployment-test-web.yaml
```

Podemos ver los recursos que se han creado:

```
kubectl get all
```

![img_15.png](/images/ejercicios_kubernetes/img_15.png)

Si queremos ver información más detallada del deployment, ejecutamos lo siguiente:

```
kubectl describe deployment.apps/deployment-testweb
```

![img_16.png](/images/ejercicios_kubernetes/img_16.png)

Si queremos comprobar que la aplicación se está sirviendo, podemos crear momentáneamente una redirección para acceder a través del navegador:

```
kubectl port-forward deployment.apps/deployment-testweb 8080:80
```

![img_17.png](/images/ejercicios_kubernetes/img_17.png)

También podemos acceder a los logs del deployment para ver el acceso que hemos hecho a través del navegador web:

```
kubectl logs deployment.apps/deployment-testweb
```

![img_18.png](/images/ejercicios_kubernetes/img_18.png)

Por último, podemos eliminar el deployment con la siguiente orden:

```
kubectl delete deployments.apps deployment-testweb
```

![img_19.png](/images/ejercicios_kubernetes/img_19.png)

Con esto, damos por finalizado este ejercicio.

### Actualización y desactualización de nuestra aplicación

El equipo de desarrollo ha creado una primera versión preliminar de una aplicación web y ha creado una imagen de contenedor con el siguiente nombre: `iesgn/test_web:version1`.

Vamos a desplegar esta primera versión de la aplicación, para ello:

1. Crea un fichero yaml (puedes usar el de la actividad anterior) para desplegar la imagen: `iesgn/test_web:version1`.
2. Crea el Deployment, recuerda la opción que nos permite registrar los comandos que vamos a ejecutar a continuación para ir actualizando el despliegue.
3. Crea una redirección utilizando el `port-forward` para acceder a la aplicación, sabiendo que la aplicación ofrece el servicio en el puerto 80, y accede a la aplicación con un navegador web.

-------------------------------------------------

En primer lugar, crearemos el fichero yaml correspondiente a este despliegue:

```
nano deployment-test-web2.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-testweb
  labels:
    app: web
spec:
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - image: iesgn/test_web:version1
        name: contendor-testweb
        ports:
        - name: http
          containerPort: 80
```

Ahora lanzamos el despliegue:

```
kubectl apply -f deployment-test-web2.yaml
```

Y anotamos el despliegue para tener un registro:

```
kubectl annotate deployment/deployment-testweb kubernetes.io/change-cause="Lanzamos la primera versión de la aplicación"
```

Podemos acceder a través del navegador usando el `port-forwarding`:

```
kubectl port-forward deployment.apps/deployment-testweb 8080:80
```

![img_20.png](/images/ejercicios_kubernetes/img_20.png)

-------------------------------------------------

Nuestro equipo de desarrollo ha seguido trabajando y ya tiene lista la versión 2 de nuestra aplicación, han creado una imagen que se llama: `iesgn/test_web:version2`. Vamos a actualizar nuestro despliegue con la nueva versión, para ello:

1. Realiza la actualización del despliegue utilizando la nueva imagen.
2. Comprueba los recursos que se han creado: Deployment, ReplicaSet y Pods.
3. Visualiza el historial de actualizaciones.
4. Crea una redirección utilizando el `port-forward` para acceder a la aplicación, sabiendo que la aplicación ofrece el servicio en el puerto 80, y accede a la aplicación con un navegador web.

-----------------------------------

Para ello ejecutamos lo siguiente:

```
kubectl set image deployment.apps/deployment-testweb contendor-testweb=iesgn/test_web:version2
```

Y creamos la anotación:

```
kubectl annotate deployment/deployment-testweb kubernetes.io/change-cause="Lanzamos la segunda versión de la aplicación"
```

Podemos ver que se han creado los nuevos recursos:

```
kubectl get all
```

![img_21.png](/images/ejercicios_kubernetes/img_21.png)

Si vemos el historial de actualizaciones, nos saldrán los dos deployments que hemos hecho junto con las anotaciones:

```
kubectl rollout history deployment deployment-testweb
```

![img_22.png](/images/ejercicios_kubernetes/img_22.png)

Ahora podemos acceder a la web usando el `port-forwarding` y ver si se han producido los cambios:

```
kubectl port-forward deployment.apps/deployment-testweb 8080:80
```

![img_23.png](/images/ejercicios_kubernetes/img_23.png)

----------------------------------

Finalmente después de un trabajo muy duro, el equipo de desarrollo ha creado la imagen iesgn/test_web:version3 con la última versión de nuestra aplicación y la vamos a poner en producción, para ello:

1. Realiza la actualización del despliegue utilizando la nueva imagen.
2. Comprueba los recursos que se han creado: Deployment, ReplicaSet y Pods.
3. Visualiza el historial de actualizaciones.
4. Crea una redirección utilizando el port-forward para acceder a la aplicación, sabiendo que la aplicación ofrece el servicio en el puerto 80, y accede a la aplicación con un navegador web.

--------------------------------------------

Para ello ejecutamos lo siguiente:

```
kubectl set image deployment.apps/deployment-testweb contendor-testweb=iesgn/test_web:version3
```

Y creamos la anotación:

```
kubectl annotate deployment/deployment-testweb kubernetes.io/change-cause="Lanzamos la tercera versión de la aplicación"
```

Podemos ver que se han creado los nuevos recursos:

```
kubectl get all
```

![img_24.png](/images/ejercicios_kubernetes/img_24.png)

Si vemos el historial de actualizaciones, nos saldrán los dos deployments que hemos hecho junto con las anotaciones:

```
kubectl rollout history deployment deployment-testweb
```

![img_25.png](/images/ejercicios_kubernetes/img_25.png)

Ahora podemos acceder a la web usando el `port-forwarding` y ver si se han producido los cambios:

```
kubectl port-forward deployment.apps/deployment-testweb 8080:80
```

![img_26.png](/images/ejercicios_kubernetes/img_26.png)

-------------------------------------

¡Vaya!, parece que esta versión tiene un fallo, y no se ve de forma adecuada la hoja de estilos, tenemos que volver a la versión anterior:

1. Ejecuta la instrucción que nos permite hacer un rollback de nuestro despliegue.
2. Comprueba los recursos que se han creado: Deployment, ReplicaSet y Pods.
3. Visualiza el historial de actualizaciones.
4. Crea una redirección utilizando el `port-forward` para acceder a la aplicación, sabiendo que la aplicación ofrece el servicio en el puerto 80, y accede a la aplicación con un navegador web.

-------------------------------------------------------------

Para volver a la versión anterior ejecutamos lo siguiente:

```
kubectl rollout undo deployment.apps/deployment-testweb
```

Y lo anotamos:

```
kubectl annotate deployment/deployment-testweb kubernetes.io/change-cause="Volvemos a la segunda versión de la aplicación"
```

Vemos los recursos que se han creado:

![img_27.png](/images/ejercicios_kubernetes/img_27.png)

Si visualizamos el historial de actualizaciones, veremos que los números han cambiado, y hemos vuelto a la versión dos (ha desaparecido el número dos y se ha cambiado por el cuatro):

```
kubectl rollout history deployment deployment-testweb
```

![img_28.png](/images/ejercicios_kubernetes/img_28.png)

Si ahora vemos la página web a través del `port-forward`, veremos que, efectivamente, hemos vuelto a la versión dos:

```
kubectl port-forward deployment.apps/deployment-testweb 8080:80
```

![img_29.png](/images/ejercicios_kubernetes/img_29.png)

Con esto, terminamos este ejercicio.

### Despliegue de la aplicación GuestBook

En esta tarea vamos a desplegar una aplicación web que requiere de dos servicios para su ejecución. La aplicación se llama GuestBook y necesita los siguientes servicios:

* La aplicación Guestbook es una aplicación web desarrollada en python que es servida en el puerto 5000/tcp. Utilizaremos la imagen `iesgn/guestbook`.
* Esta aplicación guarda la información en una base de datos no relacional redis, que utiliza el puerto 6379/tcp para recibir las conexiones. Usaremos la imagen `redis`.

Por lo tanto si tenemos dos servicios distintos, tendremos dos ficheros yaml para crear dos recursos Deployment, uno para cada servicio. Con esta manera de trabajar podemos obtener las siguientes características:

* Cada conjunto de Pods creado en cada despliegue ejecutarán un solo proceso para ofrecer el servicio.
* Cada conjunto de Pods se puede escalar de manera independiente. Esto es importante, si identificamos que al acceder a alguno de los servicios se crea un cuello de botella, podemos escalarlo para tener más Pods ejecutando el servicio.
* Las actualizaciones de los distintos servicios no interfieren en el resto.
* Lo estudiaremos en un módulo posterior, pero podremos gestionar el almacenamiento de cada servicio de forma independiente.

Por lo tanto para desplegar la aplicaciones tendremos dos ficheros.yaml:

* [guestbook-deployment.yaml](https://github.com/iesgn/curso_kubernetes_cep/blob/main/modulo6/files/guestbook/guestbook-deployment.yaml)
* [redis-deployment.yaml](https://github.com/iesgn/curso_kubernetes_cep/blob/main/modulo6/files/guestbook/redis-deployment.yaml)

Para realizar el despliegue realiza los siguientes pasos:

* Usando los ficheros anteriores crea los dos Deployments.
* Comprueba que los recursos que se han creado: Deployment, ReplicaSet y Pods.
* Crea una redirección utilizando el port-forward para acceder a la aplicación, sabiendo que la aplicación ofrece el servicio en el puerto 5000, y accede a la aplicación con un navegador web.

---------------------------------------------------------------------------

Así pues, creamos los dos ficheros para los deployments:

```
nano guestbook-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: guestbook
  labels:
    app: guestbook
    tier: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: guestbook
      tier: frontend
  template:
    metadata:
      labels:
        app: guestbook
        tier: frontend
    spec:
      containers:
      - name: contenedor-guestbook
        image: iesgn/guestbook
        ports:
          - name: http-server
            containerPort: 5000
```

```
nano redis-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  labels:
    app: redis
    tier: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
      tier: backend
  template:
    metadata:
      labels:
        app: redis
        tier: backend
    spec:
      containers:
        - name: contenedor-redis
          image: redis
          ports:
            - name: redis-server
              containerPort: 6379
```

Una vez hemos terminado con los ficheros, creamos los dos deployments:

```
kubectl apply -f guestbook-deployment.yaml

kubectl apply -f redis-deployment.yaml
```

Podemos ver lo servicios que se han creado:

![img_30.png](/images/ejercicios_kubernetes/img_30.png)

Si hacemos un `port-forward` podemos acceder a la página de guestbook, pero nos indica el siguiente mensaje:

```
kubectl port-forward deployment.apps/guestbook 5000:5000
```

![img_31.png](/images/ejercicios_kubernetes/img_31.png)

Este mensaje nos sale porque los contenedores de guestbook no pueden acceder a la base de datos redis. En el siguiente apartado veremos como conectar los contenedores en kubernetes.

## Acceso a las aplicaciones: Servicios

### Despliegue y acceso de la aplicación GuestBook

Una vez que tenemos creado el despliegue de la aplicación, que realizamos en la actividad anterior, vamos a crear los Services correspondientes para acceder a ella:

* Service para acceder a la aplicación:

El Servicio para acceder a la aplicación será del tipo "NodePort", y será definido con el siguiente yaml:

```
nano servicio_guestbook.yaml

apiVersion: v1
kind: Service
metadata:
  name: guestbook
  labels:
    app: guestbook
    tier: frontend
spec:
  type: NodePort
  ports:
  - port: 80 
    targetPort: http-server
  selector:
    app: guestbook
    tier: frontend
```

Una vez que hemos definido el servicio, lo lanzamos:

```
kubectl apply -f servicio_guestbook.yaml
```

Podemos ver el puerto que nos ha asignado viendo la lista de recursos que se han creado:

```
kubectl get all
```

![img_32.png](/images/ejercicios_kubernetes/img_32.png)

Como vemos, se ha asignado el puerto 32127 para poder acceder al servicio desde el exterior. Podemos usar el navegador para acceder al servicio si usamos ese puerto:

![img_33.png](/images/ejercicios_kubernetes/img_33.png)

Nos sigue apareciendo el mensaje de "Waiting for database connection...". Esto es así porque el servicio que hemos creado sirve para conectar el exterior con las máquinas del "frontend", sin embargo, no hemos creado aún el servicio que permita al "frontend" y el "backend" conectarse. 

* Service para que la aplicación se conecte a la base de datos:

El servicio que conectará el "frontend" y el "backend" será de tipo ClusterIP, y estará definido en el siguiente yaml:

```
nano servicio_redis.yaml

apiVersion: v1
kind: Service
metadata:
  name: redis
  labels:
    app: redis
    tier: backend
spec:
  type: ClusterIP
  ports:
  - port: 6379
    targetPort: redis-server
  selector:
    app: redis
    tier: backend
```

Una vez que hemos terminado con el fichero yaml, lanzamos el servicio:

```
kubectl apply -f servicio_redis.yaml
```

Podemos ver que se ha creado el servicio:

```
kubectl get all
```

![img_34.png](/images/ejercicios_kubernetes/img_34.png)

Ahora que hemos creado este servicio, la aplicación debería poder conectarse perfectamente con la base de datos, por lo que el mensaje anterior de "Waiting for database connection..." debería haber desaparecido:

![img_35.png](/images/ejercicios_kubernetes/img_35.png)

A continuación, vamos a crear un recurso de tipo "Ingress", que nos permita acceder a la aplicación usando un nombre en lugar de la ip (básicamente actuará de proxy). Sin embargo, como estamos usando "minikube", debemos habilitar primero ese tipo de recursos:

```
minikube addons enable ingress
```

Una vez habilitado, podemos crear el fichero yaml en el cual definiremos el nuevo recurso:

```
nano ingress_guestbook.yaml

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: guestbook
spec:
  rules:
  - host: www.dparrales.org
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: guestbook
            port:
              number: 80
```

Una vez finalizado con el fichero, creamos el nuevo recurso:

```
kubectl apply -f ingress_guestbook.yaml
```

Podemos ver el recurso creado:

```
kubectl get ingress
```

![img_36.png](/images/ejercicios_kubernetes/img_36.png)

Para que podemos acceder a la web usando el nombre que le hemos asignado, debemos modificar el fichero `/etc/hosts` y añadir la siguiente línea:

```
192.168.39.80 www.dparrales.org
```

Ahora podemos acceder a la aplicación "guestbook" usando el nombre que le hemos asignado:

![img_37.png](/images/ejercicios_kubernetes/img_37.png)

Con esto, damos por finalizado este ejercicio.

## Despliegues parametrizados

### Configurando nuestra aplicación "Temperaturas"

En un ejemplo del módulo anterior: [Ejemplo completo: Desplegando y accediendo a la aplicación Temperaturas](https://github.com/iesgn/curso_kubernetes_cep/blob/main/modulo6/temperaturas.md) habíamos desplegado una aplicación formada por dos microservicios que nos permitía visualizar las temperaturas de municipios.

Recordamos que el componente `frontend` hace peticiones al componente `backend` utilizando el nombre `temperaturas-backend`, que es el nombre que asignamos al Service ClusterIP para el acceso al `backend`.

Vamos a cambiar la configuración de la aplicación para indicar otro nombre.

Podemos configurar el nombre del servidor `backend` al que vamos acceder desde el `frontend` modificando la variable de entorno *TEMP_SERVER* a la hora de crear el despliegue del `frontend`.

Por defecto el valor de esa variable es:

```
TEMP_SERVER temperaturas-backend:5000
```

Vamos a modificar esta variable en el despliegue del `frontend` y cambiaremos el nombre del Service del `backend` para que coincidan, para ello realiza los siguientes pasos:

1. Crea un recurso `ConfigMap` con un dato que tenga como clave **SERVIDOR_TEMPERATURAS** y como contenido **servidor-temperaturas:5000**.
2. Modifica el fichero de despliegue del `frontend`: [frontend-deployment.yaml](https://github.com/iesgn/curso_kubernetes_cep/blob/main/modulo6/files/temperaturas/frontend-deployment.yaml) para añadir la modificación de la variable **TEMP_SERVER** con el valor que hemos guardado en el `ConfigMap`.
3. Realiza el despliegue y crea el Service para acceder al `frontend`.
4. Despliega el microservicio `backend`.
5. Modifica el fichero [backend-srv.yaml](https://github.com/iesgn/curso_kubernetes_cep/blob/main/modulo6/files/temperaturas/backend-srv.yaml) para cambiar el nombre del Service por `servidor-temperaturas` y crea el Service.
6. Accede a la aplicación usando el puerto asignado al Service NodePort del `frontend` o creando el recurso `Ingress`.

------------------------------------------------------------------------------------------------------------------

En primer lugar, vamos a crear el recurso "ConfigMap" con los valores indicados:

```
kubectl create cm temperaturas --from-literal=SERVIDOR_TEMPERATURAS=servidor-temperaturas:5000
```

Podemos ver la definición del recurso con el siguiente comando:

```
kubectl describe cm temperaturas
```

![img_38.png](/images/ejercicios_kubernetes/img_38.png)

A continuación crearemos los cuatro ficheros yaml que usaremos para desplegar la aplicación:

```
nano frontend-deployment.yaml


apiVersion: apps/v1
kind: Deployment
metadata:
  name: temperaturas-frontend
  labels:
    app: temperaturas
    tier: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: temperaturas
      tier: frontend
  template:
    metadata:
      labels:
        app: temperaturas
        tier: frontend
    spec:
      containers:
      - name: contenedor-temperaturas
        image: iesgn/temperaturas_frontend
        ports:
          - name: http-server
            containerPort: 3000
        env:
          - name: TEMP_SERVER
            valueFrom:
              configMapKeyRef:
                name: temperaturas
                key: SERVIDOR_TEMPERATURAS
```

![img_39.png](/images/ejercicios_kubernetes/img_39.png)

```
nano frontend-srv.yaml

apiVersion: v1
kind: Service
metadata:
  name: temperaturas-frontend
  labels:
    app: temperaturas
    tier: frontend
spec:
  type: NodePort
  ports:
  - port: 3000
    targetPort: http-server
  selector:
    app: temperaturas
    tier: frontend
```

```
nano backend-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: temperaturas-backend
  labels:
    app: temperaturas
    tier: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: temperaturas
      tier: backend
  template:
    metadata:
      labels:
        app: temperaturas
        tier: backend
    spec:
      containers:
        - name: contendor-servidor-temperaturas
          image: iesgn/temperaturas_backend
          ports:
            - name: api-server
              containerPort: 5000
```

```
nano backend-srv.yaml

apiVersion: v1
kind: Service
metadata:
  name: servidor-temperaturas
  labels:
    app: temperaturas
    tier: backend
spec:
  type: ClusterIP
  ports:
  - port: 5000
    targetPort: api-server
  selector:
    app: temperaturas
    tier: backend
```

![img_40.png](/images/ejercicios_kubernetes/img_40.png)

Ahora podemos crear todos los recursos que hemos definido en este directorio con el siguiente comando:

```
kubectl apply -f .
```

Podemos ver todos los recursos que se han creado:

![img_41.png](/images/ejercicios_kubernetes/img_41.png)

Ahora intentemos acceder a la aplicación a través del navegador, usando el servicio `NodePort` que hemos creado:

![img_42.png](/images/ejercicios_kubernetes/img_42.png)

Como vemos, no nos indica ningún error, por lo que podemos dar por concluido este ejercicio.

## Almacenamiento en Kubernetes

### Desplegando un servidor web persistente

Siguiendo la guía explicada en el [Ejemplo 2: Gestión dinámica de volúmenes](https://github.com/iesgn/curso_kubernetes_cep/blob/main/modulo8/ejemplo2.md), vamos a crear un servidor web que permita la ejecución de scripts PHP con almacenamiento persistente.

Para realizar esta actividad vamos a usar asignación dinámica de volúmenes y puedes usar, como modelos, los ficheros del ejemplo 2.

Realiza los siguientes pasos:

1. Crea un fichero yaml para definir un recurso PersistentVolumenClaim que se llame `pvc-webserver` y para solicitar un volumen de 2Gb.
2. Crea el recurso y comprueba que se ha asociado un volumen de forma dinámica a la solicitud.
3. Crea un fichero yaml para desplegar un servidor web desde la imagen `php:7.4-apache`, asocia el volumen al Pod que se va a crear e indica el punto de montaje en el DocumentRoot del servidor: `/var/www/html`.
4. Despliega el servidor y crea un fichero `info.php` en `/var/www/html`, con el siguiente contenido: `<?php phpinfo(); ?>`.
5. Define y crea un Service NodePort, accede desde un navegador al fichero `info.php` y comprueba que se visualiza de forma correcta.
6. Comprobemos la persistencia: elimina el Deployment, vuelve a crearlo y vuelve a acceder desde el navegador al fichero `info.php`. ¿Se sigue visualizando?

-------------------------------------------------------------

Creamos el fichero yaml que definirá el recurso PersistentVolumenClaim:

```
nano pvc-webserver.yaml

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: pvc-webserver
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
```

![img_43.png](/images/ejercicios_kubernetes/img_43.png)

Ahora creamos el recurso:

```
kubectl apply -f pvc-webserver.yaml
```

Podemos ver que se ha creado ejecutando lo siguiente:

```
kubectl get pc, pvc
```

![img_44.png](/images/ejercicios_kubernetes/img_44.png)

Ahora crearemos el fichero que definirá el despliegue del servidor web:

```
nano servidorweb-php.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: servidorweb
  labels:
    app: apache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apache
  template:
    metadata:
      labels:
        app: apache
    spec:
      volumes:
        - name: volumen-servidorweb
          persistentVolumeClaim:
            claimName: pvc-webserver
      containers:
        - name: contenedor-apache-php
          image: php:7.4-apache
          ports:
            - name: http-server
              containerPort: 80
          volumeMounts:
            - mountPath: "/var/www/html"
              name: volumen-servidorweb
```

![img_45.png](/images/ejercicios_kubernetes/img_45.png)

Y creamos el despliegue:

```
kubectl apply -f servidorweb-php.yaml
```

A continuación, creamos el fichero `.yaml` que definirá el servicio 'NodePort' con el que accederemos al servidor web a través del navegador:

```
nano servicioweb.yaml

apiVersion: v1
kind: Service
metadata:
  name: servicio-servidorweb
spec:
  type: NodePort
  ports:
  - name: service-http
    port: 80
    targetPort: http-server
  selector:
    app: apache
```

Y lo creamos:

```
kubectl apply -f servidorweb-php.yaml
```

Ahora creamos el fichero `info.php` en la ruta que nos han indicado. Para ello, primero debemos averiguar cual es el identificador del pod:

![img_46.png](/images/ejercicios_kubernetes/img_46.png)

Sabiendo esto, ejecutamos lo siguiente:

```
kubectl exec pod/servidorweb-745bc67f58-dmlbn -- bash -c "echo '<?php phpinfo(); ?>' > /var/www/html/info.php"
```

Ahora accedemos a la ip de minikube, al puerto que nos indica el servicio (31757):

![img_47.png](/images/ejercicios_kubernetes/img_47.png)

Como vemos, se muestra correctamente el php. Ahora veremos la persistencia. Para ello eliminamos el despliegue y lo volvemos a crear:

```
kubectl delete deployment.apps/servidorweb

kubectl apply -f servidorweb-php.yaml
```

![img_48.png](/images/ejercicios_kubernetes/img_48.png)

Y si volvemos a acceder:

![img_49.png](/images/ejercicios_kubernetes/img_49.png)

Podemos seguir accediendo a la información tras haber destruido y creado el despliegue, por lo que confirmamos que el almacenamiento es persistente.

### Haciendo persistente la aplicación GuestBook

En este ejercicio vamos a volver a desplegar nuestra aplicación GuestBook, que realizamos en [Actividad 5.3: Despliegue de la aplicación GuestBook](https://github.com/iesgn/curso_kubernetes_cep/blob/main/modulo5/actividad3.md) y en la [Actividad 6.1: Acceso de la aplicación GuestBook](https://github.com/iesgn/curso_kubernetes_cep/blob/main/modulo6/actividad1.md) para añadirle persistencia a la base de datos redis. Por lo tanto necesitaremos solicitar un volumen, que se asociará de forma dinámica.

Realiza los siguientes pasos:

1. Crea un fichero yaml para definir un recurso PersistentVolumenClaim que se llame `pvc-redis` y para solicitar un volumen de 3Gb.
2. Crea el recurso y comprueba que se ha asociado un volumen de forma dinámica a la solicitud.
3. Modifica el fichero del despliegue de redis, modificando las `xxxxxxxxxxxx` por los valores correctos: el nombre del PersistentVolumenClaim y el directorio de montaje en el contenedor (como hemos visto anteriormente es `/data`).
4. Crea el despliegue de redis. El despliegue de la aplicación `guestbook` y la creación de los Services de acceso se hace con los ficheros que ya utilizamos anteriormente: [guestbook-deployment.yaml](https://github.com/iesgn/curso_kubernetes_cep/blob/main/modulo8/files/guestbook/guestbook-deployment.yaml), [guestbook-srv.yaml](https://github.com/iesgn/curso_kubernetes_cep/blob/main/modulo8/files/guestbook/guestbook-srv.yaml) y [redis-srv.yaml](https://github.com/iesgn/curso_kubernetes_cep/blob/main/modulo8/files/guestbook/redis-srv.yaml).
5. Accede a la aplicación y escribe algunos mensajes.
6. Comprobemos la persistencia: elimina el despliegue de redis, vuelve a crearlo, vuelve a acceder desde el navegador y comprueba que los mensajes no se han perdido.

-----------------------------------------------------------------

En primer lugar creamos el fichero `.yaml` para definir el recurso "PersistentVolumenClaim":

```
nano pvc-redis.yaml

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: pvc-redis
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
```

![img_50.png](/images/ejercicios_kubernetes/img_50.png)

Y lo creamos:

```
kubectl apply -f pvc-redis.yaml
```

Vemos que se ha creado la solicitud y se ha asignado el volumen:

![img_51.png](/images/ejercicios_kubernetes/img_51.png)

Creamos el fichero `.yaml` que define el despliegue de redis usando el volumen que hemos definido anteriormente:

```
nano redis-despliegue.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  labels:
    app: redis
    tier: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
      tier: backend
  template:
    metadata:
      labels:
        app: redis
        tier: backend
    spec:
      volumes:
        - name: volumen-redis
          persistentVolumeClaim:
            claimName: pvc-redis
      containers:
        - name: contenedor-redis
          image: redis
          command: ["redis-server"]
          args: ["--appendonly", "yes"]
          ports:
            - name: redis-server
              containerPort: 6379
          volumeMounts:
            - mountPath: "/data"
              name: volumen-redis
```

![img_52.png](/images/ejercicios_kubernetes/img_52.png)

Y el resto de recursos que necesitaremos:

```
nano guestbook-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: guestbook
  labels:
    app: guestbook
    tier: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: guestbook
      tier: frontend
  template:
    metadata:
      labels:
        app: guestbook
        tier: frontend
    spec:
      containers:
      - name: contenedor-guestbook
        image: iesgn/guestbook
        ports:
          - name: http-server
            containerPort: 5000
```

```
nano guestbook-srv.yaml

apiVersion: v1
kind: Service
metadata:
  name: guestbook
  labels:
    app: guestbook
    tier: frontend
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: http-server
  selector:
    app: guestbook
    tier: frontend
```

```
nano redis-srv.yaml

apiVersion: v1
kind: Service
metadata:
  name: redis
  labels:
    app: redis
    tier: backend
spec:
  type: ClusterIP
  ports:
  - port: 6379
    targetPort: redis-server
  selector:
    app: redis
    tier: backend
```

Y los creamos todos:

```
kubectl apply -f .
```

Vemos que se han creado todos los recursos:

![img_53.png](/images/ejercicios_kubernetes/img_53.png)

Ya podemos acceder a la aplicación de guestbook desde el navegador y crear algunos mensajes de prueba:

![img_54.png](/images/ejercicios_kubernetes/img_54.png)

Ahora eliminamos el despliegue de redis y lo volvemos a crear, para comprobar si el almacenamiento es persistente:

![img_55.png](/images/ejercicios_kubernetes/img_55.png)

Y entramos en la url para ver si los mensajes se han guardado:

![img_56.png](/images/ejercicios_kubernetes/img_56.png)

Como vemos, se han guardado los mensajes, por lo que podemos dar por concluido el ejercicio.

## Instalación de aplicaciones en Kubernetes con Helm

### Instalación de un CMS con Helm

Vamos a instalar el CMS Wordpress usando Helm. Para ello, realiza los siguientes pasos:

1. Instala la última versión de Helm.
2. Añade el repositorio de bitnami
3. Busca el chart de bitnami para la instalación de Wordpress.
4. Busca la documentación del chart y comprueba los parámetros para cambiar el tipo de Service y el nombre del blog.
5. Instala el chart definiendo el tipo del Service como NodePort y poniendo tu nombre como nombre del blog.
6. Comprueba los Pods, ReplicaSet, Deployment y Services que se han creado.
7. Accede a la aplicación.

---------------------------------------------------

Así pues, tal y como nos indican, vamos a instalar la última versión de Helm:

```
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

Podemos comprobar la versión de helm que ha instalado:

```
helm version

version.BuildInfo{Version:"v3.8.0", GitCommit:"d14138609b01886f544b2025f5000351c9eb092e", GitTreeState:"clean", GoVersion:"go1.17.5"}
```

A continuación instalamos el repositorio de bitnami:

```
helm repo add bitnami https://charts.bitnami.com/bitnami

"bitnami" has been added to your repositories
```

Y comprobamos que se ha instalado correctamente:

```
helm repo list

NAME    URL                               
bitnami https://charts.bitnami.com/bitnami
```

Actualizamos los repositorios:

```
helm repo update

Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈Happy Helming!⎈
```

Ahora buscaremos el chart de bitnami para Wordpress:

```
helm search repo wordpress

NAME                    CHART VERSION APP VERSION DESCRIPTION                                       
bitnami/wordpress       13.0.22       5.9.1       WordPress is the world's most popular blogging ...
bitnami/wordpress-intel 0.1.13        5.9.1       WordPress for Intel is the most popular bloggin...
```

Instalamos wordpress usando los parámetros que nos han indicado:

```
helm install serverweb bitnami/wordpress --set service.type=NodePort --set wordpressBlogName=Dparrales

NAME: serverweb
LAST DEPLOYED: Mon Mar  7 09:47:42 2022
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: wordpress
CHART VERSION: 13.0.22
APP VERSION: 5.9.1

** Please be patient while the chart is being deployed **

Your WordPress site can be accessed through the following DNS name from within your cluster:

    serverweb-wordpress.default.svc.cluster.local (port 80)

To access your WordPress site from outside the cluster follow the steps below:

1. Get the WordPress URL by running these commands:

   export NODE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services serverweb-wordpress)
   export NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
   echo "WordPress URL: http://$NODE_IP:$NODE_PORT/"
   echo "WordPress Admin URL: http://$NODE_IP:$NODE_PORT/admin"

2. Open a browser and access WordPress using the obtained URL.

3. Login with the following credentials below to see your blog:

  echo Username: user
  echo Password: $(kubectl get secret --namespace default serverweb-wordpress -o jsonpath="{.data.wordpress-password}" | base64 --decode)
```

Comprobamos los servicios que se han creado:

```
kubectl get all

NAME                                      READY   STATUS    RESTARTS   AGE
pod/serverweb-mariadb-0                   1/1     Running   0          78s
pod/serverweb-wordpress-f4c6d594b-x552h   1/1     Running   0          78s

NAME                          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/kubernetes            ClusterIP   10.96.0.1        <none>        443/TCP                      38d
service/serverweb-mariadb     ClusterIP   10.104.148.170   <none>        3306/TCP                     78s
service/serverweb-wordpress   NodePort    10.101.173.60    <none>        80:30788/TCP,443:31936/TCP   78s

NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/serverweb-wordpress   1/1     1            1           78s

NAME                                            DESIRED   CURRENT   READY   AGE
replicaset.apps/serverweb-wordpress-f4c6d594b   1         1         1       78s

NAME                                 READY   AGE
statefulset.apps/serverweb-mariadb   1/1     78s
```

Comprobamos la url de la aplicación ejecutando el comando que nos ha dado:

```
export NODE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services serverweb-wordpress)
export NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
echo "WordPress URL: http://$NODE_IP:$NODE_PORT/"

WordPress URL: http://192.168.39.80:30788/
```

Y accedemos al la url:

![img_57.png](/images/ejercicios_kubernetes/img_57.png)
