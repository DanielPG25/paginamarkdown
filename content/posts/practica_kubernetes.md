+++ 
draft = true
date = 2022-02-23T13:37:12+01:00
title = "Despliegue de Bookmedik en Kubernetes"
description = "Despliegue de Bookmedik en Kubernetes"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Cloud Computing"]
externalLink = ""
series = []
+++

En IAW has creado dos imágenes de dos aplicaciones: bookmedik (php) y polls (python django). Elige una de ellas y despliégala en kuberenetes. Para ello vamos a hacer dos ejercicios:

## Ejercicio1: Despliegue en Minikube

Escribe los ficheros yaml que te posibilitan desplegar la aplicación en minikube. Recuerda que la base de datos debe tener un volumen para hacerla persistente. Debes crear ficheros para los deployments, services, ingress, volúmenes, etc. Despliega la aplicación en minikube.

---------------------------------------------------

Para este ejercicio he decidido desplegar la aplicación bookmedik, la cual usará una base de datos mariadb para guardar la información. Así pues, hay que definir los siguientes recursos: el despliegue de bookmedik, el despliegue de mariadb, el servicio NodePort para acceder a bookmedik, el servicio ClusterIP para conectar la base de datos con bookmedik, el servicio Ingress y el volumen en el que guardaremos la información de la base de datos para hacerla persistente.

También crearemos un "ConfigMap" y un "Secret" para guardar algunas variables de entorno:

```
kubectl create cm cm-mariadb --from-literal=mysql_usuario=bookmedik     \
                             --from-literal=basededatos=bookmedik
```

```
kubectl create secret generic secret-mariadb --from-literal=password=bookmedik   \
                                             --from-literal=rootpass=root
```

Así pues, los ficheros `.yaml` quedarían de la siguiente forma:

* Volumen de mariadb:

```
nano pvc-bookmedik.yaml

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: pvc-bookmedik
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
```

* Despliegue de mariadb:

```
nano mariadb-despliegue.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
  labels:
    app: mariadb
    tier: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
      tier: backend
  template:
    metadata:
      labels:
        app: mariadb
        tier: backend
    spec:
      volumes:
        - name: volumen-mariadb
          persistentVolumeClaim:
            claimName: pvc-bookmedik
      containers:
        - name: contenedor-mariadb
          image: mariadb
          env:
            - name: MARIADB_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: secret-mariadb
                  key: rootpass
            - name: MARIADB_DATABASE
              valueFrom:
                configMapKeyRef:
                  name: cm-mariadb
                  key: basededatos
            - name: MARIADB_USER
              valueFrom:
                configMapKeyRef:
                  name: cm-mariadb
                  key: mysql_usuario
            - name: MARIADB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: secret-mariadb
                  key: password
          ports:
            - name: mariadb-server
              containerPort: 3306
          volumeMounts:
            - mountPath: "/var/lib/mysql"
              name: volumen-mariadb
```

* Servicio mariadb:

```
nano mariadb-srv.yaml

apiVersion: v1
kind: Service
metadata:
  name: mariadb
  labels:
    app: mariadb
    tier: backend
spec:
  type: ClusterIP
  ports:
  - port: 3306
    targetPort: mariadb-server
  selector:
    app: mariadb
    tier: backend
```

* Despliegue bookmedik:

```
nano bookmedik-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: bookmedik
  labels:
    app: bookmedik
    tier: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: bookmedik
      tier: frontend
  template:
    metadata:
      labels:
        app: bookmedik
        tier: frontend
    spec:
      containers:
      - name: contenedor-bookmedik
        image: dparrales/bookmedik:v1
        env:
          - name: USUARIO_BOOKMEDIK
            valueFrom:
              configMapKeyRef:
                name: cm-mariadb
                key: mysql_usuario
          - name: CONTRA_BOOKMEDIK
            valueFrom:
              secretKeyRef:
                name: secret-mariadb
                key: password
          - name: DATABASE_HOST
            value: mariadb
          - name: NOMBRE_DB
            valueFrom:
              configMapKeyRef:
                name: cm-mariadb
                key: basededatos
        ports:
          - name: http-server
            containerPort: 80
```

* Servicio de bookmedik:

```
nano bookmedik-srv.yaml

apiVersion: v1
kind: Service
metadata:
  name: bookmedik
  labels:
    app: bookmedik
    tier: frontend
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: http-server
  selector:
    app: bookmedik
    tier: frontend
```

Los creamos todos:

```
kubectl apply -f .
```

Y apuntamos el lanzamiento de la primera versión de bookmedik:

```
kubectl annotate deployment.apps/bookmedik kubernetes.io/change-cause="Lanzamos la primera versión de bookmedik"
```

Podemos observar como se han creado todos los recursos que hemos definido:

![img_1.png](/images/practica_kubernetes/img_1.png)

Ahora intentemos acceder a la aplicación a través del navegador usando el servicio que hemos creado:

![img_2.png](/images/practica_kubernetes/img_2.png)

![img_3.png](/images/practica_kubernetes/img_3.png)

Como vemos podemos acceder perfectamente a la aplicación, por lo que podemos concluir que tiene conexión con la base de datos. A continuación crearemos un recurso de Ingress para poder acceder más fácilmente a la aplicación. Para ello, primero tenemos que definir el recurso:

```
nano bookmedik-ingress.yaml

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: bookmedik-ing
spec:
  rules:
  - host: www.bookmedik.org
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: bookmedik
            port:
              number: 80
```

Y lo creamos:

```
kubectl apply -f bookmedik-ingress.yaml
```

Ahora, modificamos la resolución estática del anfitrión para acceder a la aplicación usando el nombre que hemos proporcionado al Ingress Controller:

```
nano /etc/hosts

192.168.39.80 www.bookmedik.org
```

E intentamos acceder usando ese nombre:

![img_4.png](/images/practica_kubernetes/img_4.png)

Crearemos algún contenido para comprobar la persistencia de los datos cuando borremos el despliegue de mariadb:

![img_5.png](/images/practica_kubernetes/img_5.png)

A continuación, eliminamos el despliegue de mariadb y volvemos a crearlo:

![img_6.png](/images/practica_kubernetes/img_6.png)

Si volvemos a acceder, nos debería aparecer la misma información:

![img_7.png](/images/practica_kubernetes/img_7.png)

Para escalar el despliegue de bookmedik a tres pods hay dos opciones: o lo hacemos a través de la terminal y el cambio sería temporal o modificamos el fichero `.yaml` del despliegue y alteramos el número de pods. Yo he optado por la primera opción:

```
kubectl scale deployment/bookmedik --replicas=3
```

Vemos que se han creado los nuevos pods:

![img_8.png](/images/practica_kubernetes/img_8.png)

A continuación crearemos una nueva imagen de bookmedik con alguna modificación. En mi caso he modificado el login de la aplicación para que ponga mi nombre. Una vez hecho eso, construimos otra imagen con la modificación:

```
docker build -t dparrales/bookmedik:v1_1 .

docker login

docker push dparrales/bookmedik:v1_1
```

Y modificamos el fichero del despliegue para indicar la nueva versión:

```
image: dparrales/bookmedik:v1_1
```

Ahora volvemos a lanzar al despliegue y lo anotamos:

```
kubectl apply -f bookmedik-deployment.yaml

kubectl annotate deployment.apps/bookmedik kubernetes.io/change-cause="Lanzamos la versión 1.1 de bookmedik"
```

![img_9.png](/images/practica_kubernetes/img_9.png)

Podemos ver el histórico de despliegues:

![img_10.png](/images/practica_kubernetes/img_10.png)

Y la modificación de la pantalla de inicio:

![img_11.png](/images/practica_kubernetes/img_11.png)

Como vemos se ha modificado la pantalla de inicio, por lo que podemos dar por concluido este ejercicio. Todos los ficheros que he usado están en mi [repositorio](https://github.com/DanielPG25/practica_kubernetes_bookmedik) de Github.


## Ejercicio2: Despliegue en otra distribución de Kubernetes

Instala un cluster de kubernetes (más de un nodo). Tienes distintas opciones para construir un cluster de kubernetes: [Alternativas para instalación simple de k8s](https://github.com/iesgn/curso_kubernetes_cep/blob/main/modulo2/alternativas.md).

Realiza el despliegue de la aplicación en el nuevo cluster. Es posible que no tenga instalado un ingress controller, por lo que no va a funcionar el ingress (puedes buscar como hacer la instalación: por ejemplo el [nginx controller](https://kubernetes.github.io/ingress-nginx/)).

Escala la aplicación y ejecuta kubectl get pods -o wide para ver cómo se ejecutan en los distintos nodos del cluster.

------------------------------------------

He decidido usar k3s. Para ello he creado tres máquinas, una que funcionará como maestro y dos workers. En el nodo maestro ejecutamos lo siguiente para instalar k3s:

```
curl -sfL https://get.k3s.io | sh -
```

En los dos nodos workers, tenemos que ejecutar lo siguiente:

```
curl -sfL https://get.k3s.io | K3S_URL=https://myserver:6443 K3S_TOKEN=mynodetoken sh -
```

Donde:

* **myserver:** Indicamos la ip del nodo maestro.
* **mynodetoken:** Indicamos el token que se guarda en `/var/lib/rancher/k3s/server/node-token`.

Así pues, mi comando quedaría de la siguiente forma:

```
curl -sfL https://get.k3s.io | K3S_URL=https://172.22.6.37:6443 K3S_TOKEN=K10d57eaa452113b16c90a2f4760f2f8361c6d329c6213e8170690da37793e37c22::server:ae31bf8fe488713487032a73711b8d1a sh -
```

Podemos ver los nodos que tenemos ejecutando en el master lo siguiente:

```
kubectl get nodes
```

![img_12.png](/images/practica_kubernetes/img_12.png)

Ahora clonamos en el nodo maestro el repositorio de Github que contiene los ficheros `.yaml` que hemos usado anteriormente:

```
git clone https://github.com/DanielPG25/practica_kubernetes_bookmedik.git
```

También hemos de recordar que tenemos que volver a crear el "ConfigMap" y el "Secret":

```
kubectl create cm cm-mariadb --from-literal=mysql_usuario=bookmedik     \
                             --from-literal=basededatos=bookmedik
```

```
kubectl create secret generic secret-mariadb --from-literal=password=bookmedik   \
                                             --from-literal=rootpass=root
```

Ahora volvemos a crear los recursos, asegurándonos de crear primero el despliegue de mariadb y el volumen, para que no haya problemas de acceso a la información:

```
kubectl apply -f pvc-bookmedik.yaml

kubectl apply -f mariadb-despliegue.yaml

kubectl apply -f mariadb-srv.yaml

kubectl apply -f bookmedik-deployment.yaml  

kubectl apply -f bookmedik-srv.yaml

kubectl apply -f bookmedik-ingress.yaml  
```

Vemos que se ha creado todo correctamente:

![img_13.png](/images/practica_kubernetes/img_13.png)

![img_14.png](/images/practica_kubernetes/img_14.png)

Y probamos a acceder:

![img_15.png](/images/practica_kubernetes/img_15.png)

![img_16.png](/images/practica_kubernetes/img_16.png)

Ahora probamos a escalar el despliegue de bookmedik:

```
kubectl scale deployment/bookmedik --replicas=3
```

Y vemos como se han repartido entre los diferentes nodos:

```
kubectl get pods -o wide
```

![img_17.png](/images/practica_kubernetes/img_17.png)

Como vemos se han repartido los nodos entre los workers y el master, por lo que podemos dar por concluida la práctica.
