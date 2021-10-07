+++ 
draft = true
date = 2021-10-07T09:16:53+02:00
title = "Hugo"
description = "Generador de Web Estática Hugo"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = []
externalLink = ""
series = []
+++

# Generador de páginas estáticas: Hugo

## Sobre Hugo

Hugo es un generador de páginas estáticas rápido y moderno escrito en Go. Utiliza las librerías de Go *html/template* y *text/template* como base para las plantillas que utiliza. Permite escribir en *Markdown*, el cual lee al realizar un despliegue, transformándolo en *html*, lo que nos permite generar páginas estáticas de forma muy sencilla. Instalarlo en Debian es de lo más sencillo, solo hay que usar el siguiente comando:

`sudo apt-get install hugo`

## Modificación de la configuración

El archivo de configuración de hugo se llama "config.toml" y en el podemos cambiar varias cosas para modificar nuestra web a nuestro gusto.

Lo primero que querremos cambiar será nuestro tema. En la página oficial de [Hugo](https://gohugo.io/) podemos encontrar bastantes temas de los que elegir. En mi caso, elegí **Coder**. Cada tema se instala de forma diferente, pero solo hay que seguir la guía que existe en la página oficial del tema. En mi caso, lo primero fue añadir el submódulo con el tema en mi directorio principal de la página:

`git submodule add https://github.com/luizdepra/hugo-coder.git themes/hugo-coder`.

A continuación, si seguimos la documentación de la página, encontraremos que hay que modificar nuestro "config.toml", y para ello nos ponen uno de ejemplo que podremos copiar y modfificar:

```
baseurl = "http://www.example.com"
title = "johndoe"
theme = "hugo-coder"
languagecode = "en"
defaultcontentlanguage = "en"

paginate = 20

pygmentsstyle = "bw"
pygmentscodefences = true
pygmentscodefencesguesssyntax = true

disqusShortname = "yourdiscussshortname"

[params]
  author = "John Doe"
  info = "Full Stack DevOps and Magician"
  description = "John Doe's personal website"
  keywords = "blog,developer,personal"
  avatarurl = "images/avatar.jpg"
  #gravatar = "john.doe@example.com"

  favicon_32 = "/img/favicon-32x32.png"
  favicon_16 = "/img/favicon-16x16.png"

  footercontent = "Enter a text here."
  hideFooter = false
  hideCredits = false
  hideCopyright = false
  since = 2019

  enableTwemoji = true

  colorScheme = "auto"
  hidecolorschemetoggle = false

  customCSS = ["css/custom.css"]
  customSCSS = ["scss/custom.scss"]
  customJS = ["js/custom.js"]

[taxonomies]
  category = "categories"
  series = "series"
  tag = "tags"
  author = "authors"

# Social links
[[params.social]]
  name = "Github"
  icon = "fa fa-github fa-2x"
  weight = 1
  url = "https://github.com/johndoe/"
[[params.social]]
  name = "Gitlab"
  icon = "fa fa-gitlab fa-2x"
  weight = 2
  url = "https://gitlab.com/johndoe/"
[[params.social]]
  name = "Twitter"
  icon = "fa fa-twitter fa-2x"
  weight = 3
  url = "https://twitter.com/johndoe/"

# Menu links
[[menu.main]]
  name = "Blog"
  weight = 1
  url  = "posts/"
[[menu.main]]
  name = "About"
  weight = 2
  url = "about/"
```

Como se puede ver en la siguiente imagen, he modificado las línes referentes a la url base, el título y el tema. También he añadido alguna información personal sobre mí y he cambiado el avatar.

![configuracion.png](/images/configuracion.png)

También podemos modificar la información referente a las redes sociales para que redireccionen a las nuestras o suprimir esa información por completo.


## Despliegue

Podemos ver como quedaría la página que hemos y el tema que hemos elegido usando el siguiente comando, que despliega la página de forma local:

`hugo server -D`

![local.png](/images/local.png)

Una vez que hemos comprobado que el tema es de nuestro gusto, podemos empezar a escribir posts. Para ello, hugo nos lo pone fácil:

`hugo new posts/nombre_del_post.md`

Con este comando, hugo nos crea un nuevo fichero *markdown* dentro de **content/posts**. El directorio "content", es donde guardaremos todos nuestros posts, ya que por defecto, el tema que elegí los busca ahí al hacer el despliegue. El comando anterior, al crear los markdown, también añade algunos campos que podemos rellenar para personalizar aún más nuestros posts:

![extramark.png](/images/extramark.png)


Ahora ya solo queda publicar nuestra web estática en Internet, para lo cual hay muchos servicios de hosting disponibles. En mi caso elegí **Render**.

**Render** es gratuito para las páginas estáticas, ofrece un gran mantenimiento y permite un despliegue rápido y autómatico desde un repositorio de *Github*. El proceso de despliegue es sencillo:

* En primer lugar debemos tener nuestro esquema de directorios creados por hugo subido en *Github*.
* A continuación nos creamos una cuenta en _Render_, y le damos permiso para acceder al repositorio de la paǵina en _Github_.
* Seleccionamos el nombre que tendrá nuestra web y la rama del repositorio que queremos deplegar.
* Cuando nos aparezca "Build Command" lo rellenamos con lo siguiente:

`hugo -D`

* El comando anterior permitirá que cada vez que se produzca un despliegue, se genere el html a partir de los ficheros que se encuentran en nuestro *Github*, por lo que de esa forma, nos ahorramos tener que generarlo nosotros cada vez que subamos un cambio a *Github*.
* En "Publish directory", escribimos "*public*", ya que ese el directorio por defecto en el que se guarda el *html* generado por el comando anterior. 
* Guardamos los cambios y desplegamos.

Con esto, ya tenemos lista lo configuración para el despliegue de nuestra página web. Cada vez que hagamos un cambio en nuestro *github*, *Render* lo notará y volverá a deplegar la página de forma automática si no hemos cambiado esa configuración.

Esto método es el más sencillo y directo para la creación y despliegue de nuestra web. Sin embargo, por motivos de una práctica que estoy realizando, el despliegue de esta web será diferente. 

En mi caso, ejecuto en mi máquina el comando anterior:

`hugo -D`

Esto generará en mi directorio *"public"* el html de mi web (ese directorio de encuentra añadido a mi fichero *.gitignore* para que no lo suba a github cada vez que lo actualice). 

El contenido del directorio *"public"*, es copiado después a otro repositorio de *Github*, que es el que tengo asignado a mi web estática en *Render*. En este caso, no es necesario rellenar los campos de "Build Command" y "Publish directory", ya que es todo el repositorio el que tiene que desplegar, y no hace falta un comando para eso.


## Automatización del despliegue

Para la automatización del despliegue, he creado un script bastante sencillo que ejecuta los pasos que he descrito anteriormente:

```
#!/bin/sh


# Primero generamos el html

hugo -D

#Primero subimos los cambios hechos a nuestro repositorio principal (el contenido de public está añadido a .gitignore):

git add .
git commit -am "Cambios"
git push

#Una vez subido, copiamos los archivos generados de public a nuestro repositorio secundario:

cp -R public/* ../mipaginahtml

#Ahora nos movemos a ese directorio y subimos los cambios a nuestro github

cd ../mipaginahtml
git add .
git commit -am "Cambios"
git push

```

Este script lo ejecutaremos cada vez que realicemos algún cambio en nuestra web o añadamos algún artículo. A continuación la ejecución del script:

![ejecucionscript.png](/images/ejecucionscript.png)

