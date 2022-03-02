+++ 
draft = true
date = 2022-03-02T14:04:16+01:00
title = "Práctica: IC/DC con Jenkins"
description = "Práctica: IC/DC con Jenkins"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Aplicaciones Web"]
externalLink = ""
series = []
+++

El objetivo de esta práctica es el desarrollo gradual de un Pipeline que vaya realizando tareas sobre el repositorio de una aplicación.

La aplicación con la que vamos a trabajar será tu fork de la aplicación django Polls. Como hemos visto esta aplicación que implementa el tutorial de Django tiene implementado un módulo de pruebas.

Vamos a construir el Pipeline en varias fases:

## Ejercicio 1: Testeo de la aplicación

Vamos a comenzar a crear un pipeline, que realice las siguientes tareas:

1. Clone el repositorio.
2. Instale los requerimientos python.
3. Realice los tests al programa.

Este pipeline se tiene que ejecutar sobre la imagen `python:3`. Otras consideraciones:

* Este pipeline se disparará cuando observe un cambio en el repositorio. Esta comprobación se hará cada minuto.

----------------------------------------------------------------

Para ello creamos en Jenkins el siguiente pipeline:

```
pipeline {
    agent {
        docker { image 'python:3'
        args '-u root:root'
        }
    }
    stages {
        stage('Clone') {
            steps {
                git branch:'master',url:'https://github.com/DanielPG25/django_tutorial.git'
            }
        }
        stage('Install') {
            steps {
                sh 'pip install -r requirements.txt'
            }
        }
        stage('Test')
        {
            steps {
                sh 'python3 manage.py test'
            }
        }
    }
}
```

Para que se ejecute cada minuto, en el programador de triggers escribimos lo siguiente:

![img_1.png](/images/practica_jenkins/img_1.png)

Una vez hecho esto, se iniciará el pipeline. Como acabamos de hacer un fork del repositorio, no debe haber ningún error, por lo que el tests del programa serán exitosos:

![img_2.png](/images/practica_jenkins/img_2.png)

Una vez que hemos comprobado que los tests funcionan, vamos a cambiar el código de la aplicación para crear algunos errores. Para ello, en el fichero `polls/templates/polls/index.html` cambiamos el mensaje de "No polls are available" por "No hay encuestas disponibles". Si subimos los cambios al repositorio, debería salir un error al hacer los tests, ya que hay uno en concreto que busca ese mensaje:

![img_3.png](/images/practica_jenkins/img_3.png)

Si vemos los logs, nos indica que ha podido encontrar el mensaje que hemos cambiado:

![img_4.png](/images/practica_jenkins/img_4.png)

Como vemos, los tests que están programados funcionan bien.

----------------------

## Ejercicio 2: Construcción de una imagen docker

Modifica el pipeline para que después de hacer el test sobre la aplicación, genere una imagen docker. tienes que tener en cuenta que los pasos para generar la imagen lo tienes que realizar en la máquina donde está instalado Jenkins. Tendrás que añadir las siguientes acciones:

1. Construir la imagen con el `Dockerfile` que tengas en el repositorio.
2. Subir la imagen a tu cuenta de Docker Hub.
3. Borrar la imagen que se ha creado.

Por lo tanto tienes que estudiar el apartado [Ejecución de un pipeline](https://fp.josedomingo.org/iaw2122/u06/runner.html) en varios runner para ejecutar el pipeline en dos runner:

* En el contenedor docker a partir de la imagen `python:3` los pasos del ejercicio1.
* En la máquina de Jenkins los pasos de este ejercicio.

Otras consideraciones:

* Cuando termine de ejecutar el pipeline te mandará un correo de notificación.
* El pipeline se guardará en un fichero Jenkinsfile en tu repositorio, y la configuración del pipeline hará referencia a él.

-------------------------------------------------------------------------

El Dockerfile queda de la siguiente forma (esta basado en el que creamos en la práctica de Docker con python):

```
FROM python:3
WORKDIR /usr/src/app
MAINTAINER Daniel Parrales García "daniparrales16@gmail.com"
RUN pip install django mysqlclient
ADD django_tutorial/ /usr/src/app
ADD django_polls.sh /opt
RUN mkdir static && chmod +x /opt/django_polls.sh
ENV ALLOWED_HOSTS=*
ENV HOST=mariadb
ENV USUARIO=django
ENV CONTRA=django
ENV BASE_DATOS=django
ENV DJANGO_SUPERUSER_PASSWORD=admin
ENV DJANGO_SUPERUSER_USERNAME=admin
ENV DJANGO_SUPERUSER_EMAIL=admin@example.org
CMD ["/opt/django_polls.sh"]
```

Ahora debemos modificar el pipeline que hemos creado antes, para que cuando pase los tests, cree la imagen y la suba a Docker Hub:

```
pipeline {
    environment {
        IMAGEN = "dparrales/django_python"
        LOGIN = 'USER_DOCKERHUB'
    }
    agent none
    stages {
        stage("Desarrollo") {
            agent {
                docker { image "python:3"
                args '-u root:root'
                }
            }
            stages {
                stage('Clone') {
                    steps {
                        git branch:'master',url:'https://github.com/DanielPG25/django_tutorial.git'
                    }
                }
                stage('Install') {
                    steps {
                        sh 'pip install -r requirements.txt'
                    }
                }
                stage('Test')
                {
                    steps {
                        sh 'python3 manage.py test'
                    }
                }

            }
        }
        stage("Construccion") {
            agent any
            stages {
                stage('CloneAnfitrion') {
                    steps {
                        git branch:'main',url:'https://github.com/DanielPG25/docker_python.git'
                    }
                }
                stage('BuildImage') {
                    steps {
                        script {
                            newApp = docker.build "$IMAGEN:latest"
                        }
                    }
                }
                stage('UploadImage') {
                    steps {
                        script {
                            docker.withRegistry( '', LOGIN ) {
                                newApp.push()
                            }
                        }
                    }
                }
                stage('RemoveImage') {
                    steps {
                        sh "docker rmi $IMAGEN:latest"
                    }
                }
            }
        }           
    }
    post {
        always {
            mail to: 'daniparrales16@gmail.com',
            subject: "Status of pipeline: ${currentBuild.fullDisplayName}",
            body: "${env.BUILD_URL} has result ${currentBuild.result}"
        }
    }
}
```

Podemos ver ahora que todos los pasos del pipeline se han ejecutado con éxito:

![img_5.png](/images/practica_jenkins/img_5.png)

También podemos observar que la imagen se ha subido con éxito a Docker Hub:

![img_6.png](/images/practica_jenkins/img_6.png)

Y tal como le indicamos, nos ha mandado un correo con la información de la ejecución del pipeline:

![img_7.png](/images/practica_jenkins/img_7.png)

Por último, si cambiamos el `Dockerfile`, y le indicamos un archivo que no exista, falla la ejecución y no se crea la imagen:

![img_8.png](/images/practica_jenkins/img_8.png)

Podemos ver los ficheros que he usado en este pipeline en mi [repositorio](https://github.com/DanielPG25/docker_python) de Github.

----------------------------------------------------

## Ejercicio 3: Despliegue de la aplicación

Amplía el pipeline anterior para que tenga una última etapa donde se haga el despliegue de la imagen que se ha subido a Docker Hub en tu entorno de producción (VPS). Algunas pistas:

* Busca información de cómo hacer el despliegue a un servidor remoto (ssh, buscando algún plugin con esa funcionalidad,…)
* Si vas a hacer conexiones por ssh, tendrás que guardar una credencial en tu Jenkins con el nombre de usuario y contraseña.
* Para el despliegue deberá usar el fichero `docker-compose.yaml` que has generado en otras prácticas.
* Se deberá borrar el contenedor con la versión anterior, descargar la nueva imagen y crear un nuevo contenedor.

Otras consideraciones:

* Cambia el disparador del pipeline. Configúralo con un webhook de github, para que cada vez que se produce un push se ejecute el pipeline. Para que el webhook pueda acceder a tu Jenkins puedes usar [ngrok](https://ngrok.com/).

-------------------------------------------------------------

En primer lugar, debemos instalar los plugins necesarios para que jenkins pueda usar SSH para acceder a nuestra VPS y ejecutar los comandos necesarios:

![img_9.png](/images/practica_jenkins/img_9.png)

También creamos las credenciales:

![img_10.png](/images/practica_jenkins/img_10.png)

Una vez hecho eso, modificamos el pipeline anterior y añadimos lo siguiente después del borrado de la imagen:

```
stage ('SSH') {
    steps{
        sshagent(credentials : ['SSH_ROOT']) {
            sh 'ssh -o StrictHostKeyChecking=no root@blackstar.sysadblog.com wget https://raw.githubusercontent.com/DanielPG25/docker_python/main/docker-compose.yaml -O docker-compose.yaml'
            sh 'ssh -o StrictHostKeyChecking=no root@blackstar.sysadblog.com docker-compose up -d --force-recreate'
        }
    }
}
```

El docker-compose que introducimos mediante scp es el siguiente:

```
version: '3.1'
services:
  django-tutorial:
    container_name: django-tutorial2
    image: dparrales/django_python  
    restart: always
    environment:
      ALLOWED_HOSTS: "*"
      HOST: db_mariadb
      USUARIO: django
      CONTRA: django
      BASE_DATOS: django
      DJANGO_SUPERUSER_PASSWORD: admin
      DJANGO_SUPERUSER_USERNAME: admin
      DJANGO_SUPERUSER_EMAIL: admin@example.org
    ports:
      - 8086:8006
    depends_on:
      - db
  db:
    container_name: db_mariadb
    image: mariadb
    restart: always
    environment:
      MARIADB_ROOT_PASSWORD: root
      MARIADB_DATABASE: django
      MARIADB_USER: django
      MARIADB_PASSWORD: django
    volumes:
      - mariadb_data_django2:/var/lib/mysql
volumes:
    mariadb_data_django2:
```

Si ejecutamos el pipeline a mano, nos funciona:

![img_11.png](/images/practica_jenkins/img_11.png)

Sin embargo, lo que queremos es que cada vez que actualicemos la aplicación, se despliegue automáticamente. Para ello, vamos a utilizar un webhook de Github, para que cada vez que actualice el repositorio, mande una notificación a Jenkins y se ejecute el pipeline que hemos definido en el Jenkinsfile. No obstante, al tener Jenkins en una red interna, vamos a usar la herramienta `ngrok` para permitir que Jenkins reciba la notificación del "push". Así pues, lo primero es cambiar la configuración de la seguridad de Jenkins, activando la siguiente opción:

![img_12.png](/images/practica_jenkins/img_12.png)

A continuación descargamos `ngrok` de su [página oficial](https://ngrok.com/). Lo que he descargado, al menos en mi caso, es un ejecutable, por lo que para hacer uso de él, deberemos indicar la ruta del mismo en el comando. Así pues, siguiendo la documentación, lo primero que haremos será generar un fichero con nuestro "Token". Para ello ejecutamos el siguiente comando con el token que encontraremos en la web, en la sección de "Your Authtoken":

```
./ngrok authtoken tu-authtoken
```

Tras esto, debemos ejecutar el siguiente comando para exponer el servidor de Jenkins al exterior (por defecto escucha en el puerto 8080):

```
./ngrok http 8080
```

Esto nos generará una URL que será la que pondremos en el webhook de Github (no hay que cortar el servicio, o la url cambiará):

![img_13.png](/images/practica_jenkins/img_13.png)

Una vez hecho esto, debemos instalar en Jenkins los plugins que harán que podamos trabajar con Github:

![img_14.png](/images/practica_jenkins/img_14.png)

Esto nos posibilitará editar el "trigger" del pipeline a un "webhook" de Github. Para ello, nos dirigimos a la configuración del pipeline y seleccionamos la siguiente opción:

![img_15.png](/images/practica_jenkins/img_15.png)

Al seleccionar esta opción, deberemos indicar al pipeline el repositorio de Github del que debe recibir notificaciones:

![img_16.png](/images/practica_jenkins/img_16.png)

Como vemos, al ejecutar un pipeline de esta forma, debemos tener un fichero en el repositorio llamado "Jenkinsfile" (por defecto), en el cual se encontrarán todos los pasos que realizará dicho pipeline. Con esto, Jenkins ya estaría esperando a recibir las notificaciones de Github, pero aún no hemos introducido en Github la configuración necesaria para que mande dichas notificaciones. Para ello, nos dirigimos al apartado de configuración de nuestro repositorio y creamos un nuevo "webhook":

![img_17.png](/images/practica_jenkins/img_17.png)

El "webhook" hay que configurarlo de la siguiente forma para que no de errores a la hora de conectarse con Jenkins:

![img_18.png](/images/practica_jenkins/img_18.png)

* En el apartado de "Payload URL", debemos poner la URL que nos indica `ngrok` seguida de `/github-webhook/`.
* En el apartado de "Secret", debemos añadir el Token que hemos generado para nuestro usuario en Jenkins (lo explicamos a continuación).

Para generar el Token de Jenkins y poder añadirlo al "Webhook" de Github hay que irnos a la zona de administración de Jenkins, y en la configuración del usuario, darle a generar Token:

![img_19.png](/images/practica_jenkins/img_19.png)

Ahora, cada vez que hagamos un "push" al repositorio que hemos indicado, se disparará el trigger y se ejecutará el pipeline, haciendo que nuestra aplicación se despliegue continuamente.

![img_20.png](/images/practica_jenkins/img_20.png)

Con esto podemos dar por concluida la práctica con éxito.
