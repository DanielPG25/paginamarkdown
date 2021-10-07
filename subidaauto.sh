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

