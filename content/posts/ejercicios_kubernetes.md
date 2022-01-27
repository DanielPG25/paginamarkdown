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
