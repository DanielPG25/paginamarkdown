+++ 
draft = true
date = 2021-11-09T17:53:28+01:00
title = "Migración de aplicaciones web PHP en tu VPS"
description = "Migración de aplicaciones web PHP en tu VPS"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Aplicaciones Web"]
externalLink = ""
series = []
+++

# Instalación/migración de aplicaciones web PHP en tu VPS

Esta práctica constará de dos tareas:

Tarea 1:

Realizar la migración de la primera aplicación que tienes instalada en la práctica anterior a nuestro entorno de producción, para ello ten en cuenta lo siguiente:

* La aplicación se tendrá que migrar a un nuevo virtualhost al que se accederá con el nombre `portal.tudominio.algo`.
* Vamos a nombrar el servicio de base de datos que tenemos en producción. Como es un servicio interno no la vamos a nombrar en la zona DNS, la vamos a nombrar usando resolución estática. El nombre del servicio de base de datos se debe llamar: `bd.tudominio.algo`.
* Realiza la migración de la aplicación.
* Asegurate que las URL limpias de drupal siguen funcionando en nginx.
* La aplicación debe estar disponible en la URL: portal.tudominio.algo (Sin ningún directorio).

Tarea 2:

Instalación / migración de la aplicación Nextcloud:

* Instala la aplicación web Nextcloud en tu entorno de desarrollo.
* Realiza la migración al servidor en producción, para que la aplicación sea accesible en la URL: `www.tudominio.algo/cloud`
* Instala en un ordenador el cliente de nextcloud y realiza la configuración adecuada para acceder a “tu nube”.

-------------------------------------------------------------------------------------------------------------------------------------------------------


## Tarea 1


Para la migración vamos a usar github. He creado un repositorio privado en github, el cual tendrá toda la configuración y ficheros de mediawiki, de forma que cuando esté mi vps, solo tendré que clonar el repositorio en el DocumentRoot y hacer las configuraciones precisas. El virtualhost tendrá la siguiente información:

```
server {
        listen 80;
        listen [::]:80;

        root /var/www/www.dparrales-mediawiki.com/mediawiki-1.36.2;

        index index.html index.php index.htm index.nginx-debian.html;

        server_name portal.sysadblog.com;

        location ~ \.php$ {
               include snippets/fastcgi-php.conf;
               fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        }

        location / {
                try_files $uri $uri/ =404;
        }

}
```

Una vez que hemos configurado el virtualhost, lo habilitamos creando un enlace simbólico:

```
ln -s /etc/nginx/sites-available/dparrales-mediawiki /etc/nginx/sites-enabled/
```

Ahora tenemos que añadir las tablas de mediawiki a nuestra base de datos. Para ello vamos a utlizar la copia de seguridad que conseguimos en su momento con el siguiente comando:

```
mysqldump -v --opt --events --routines --triggers --default-character-set=utf8 -u mediawiki -p mediawiki > db_backup_mediawiki_`date +%Y%m%d_%H%M%S`.sql
```

Con el comando anterior conseguimos un fichero `.sql` que contiene toda la información de la base de datos de mediawiki. Vamos a utilizar este fichero para incorporar toda esa información a la base de datos de nuestro vps. Para ello, primero hemos tenido que crear una base de datos en mariadb y haber creado un usuario con permisos sobre esa base de datos. Una vez que hayamos cumplido estos requisitos, podemos incorporar los datos de mediawiki a nuestra base de datos:

```
mysql -u mediawiki -p mediawiki < db_backup_mediawiki_20211026_063630.sql
```

Una vez que hayamos incorporado toda la información necesaria a la base de datos, solo tenemos que cambiar la configuración de mediawiki (localizada en el fichero `LocalSettings.php`). Sin embargo, antes vamos a modificar el fichero `/etc/hosts` de nuestra vps para añadir la siguiente línea:

`
127.0.0.1 bd.sysadblog.com
`

Con esta línea, cuando configuremos mediawiki y le indiquemos la dirección de la base de datos, podremos utilizar este alias. De esta forma, si migramos la base de datos a otra máquina, no tendremos que cambiar la dirección de la base de datos en la configuración, sino que simplemente podremos añadir la línea al fichero `/etc/hosts`. Así pues, ya podemos modificar el fichero `LocalSettings.php` de mediawiki para actualizar la información de la base de datos:

![nueva_config.png](/images/practicamigracion_php_vps/nueva_config.png)

También debemos cambiar la configuración en este fichero que indica el dominio de la página, ya que lo hemos cambiado:

![config_dos.png](/images/practicamigracion_php_vps/config_dos.png)

Ahora reiniciamos nginx para que lea la nueva configuración:

```
systemctl restart nginx
```

Para acceder a nuestra aplicación, tenemos que crear un nuevo registro en nuestro DNS de time cname que apunte a la url `portal.sysadblog.com`:

![dns_nuevaentrada.png](/images/practicamigracion_php_vps/dns_nuevaentrada.png)

Con esto ya deberíamos poder acceder a nuestra aplicación:

![mediawiki.png](/images/practicamigracion_php_vps/mediawiki.png)

Como vemos podemos acceder, pero nos indica que nos faltan algunas librerías de php. Las instalamos y probamos otra vez:

```
apt install php-mbstring php-xml php-intl php-mysql
```

![mediawiki2.png](/images/practicamigracion_php_vps/mediawiki2.png)

Podemos acceder perfectamente, por lo que podemos decir que la migración ha sido un éxito.


------------------------------------------------------------------------------------------------

## Tarea 2

## Instala la aplicación web Nextcloud en tu entorno de desarrollo.

Para facilitar la migración después, he instalado nginx y php-fpm en mi entorno de desarrollo. De esta forma, la migración será más limpia y tendremos que cambiar menos ficheros. 

Para empezar vamos a descargar el fichero `.zip` en el directorio `/var/www` de forma que cuando lo descomprimamos, nos creará una carpeta llamada `nextcloud`, la cual nos servirá como DocumentRoot:

```
wget https://download.nextcloud.com/server/releases/nextcloud-22.2.0.zip

unzip nextcloud-22.2.0.zip
```

Una vez hecho esto, vamos a crear el virtualhost de nextcloud. Afortunadamente, la documentación de nextcloud nos ofrece una plantilla completa del virtualhost, por lo que podemos copiarla y ajustarla a nuestras necesidades. Mi configuración del virtualhost ha quedado así:

```
upstream php-handler {
    #server 127.0.0.1:9000;
    server unix:/run/php/php7.4-fpm.sock;
}

server {
    listen 80;
    listen [::]:80;

    server_name cloud.example.com;

    client_max_body_size 512M;
    client_body_timeout 300s;
    fastcgi_buffers 64 4K;

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    }

    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 256;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

    add_header Referrer-Policy                      "no-referrer"   always;
    add_header X-Content-Type-Options               "nosniff"       always;
    add_header X-Download-Options                   "noopen"        always;
    add_header X-Frame-Options                      "SAMEORIGIN"    always;
    add_header X-Permitted-Cross-Domain-Policies    "none"          always;
    add_header X-Robots-Tag                         "none"          always;
    add_header X-XSS-Protection                     "1; mode=block" always;

    fastcgi_hide_header X-Powered-By;

    root /var/www/nextcloud;

    index index.php index.html /index.php$request_uri;

    location = / {
        if ( $http_user_agent ~ ^DavClnt ) {
            return 302 /remote.php/webdav/$is_args$args;
        }
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location ^~ /.well-known {

        location = /.well-known/carddav { return 301 /remote.php/dav/; }
        location = /.well-known/caldav  { return 301 /remote.php/dav/; }

        location /.well-known/acme-challenge    { try_files $uri $uri/ =404; }
        location /.well-known/pki-validation    { try_files $uri $uri/ =404; }

        return 301 /index.php$request_uri;
    }

    location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)(?:$|/)  { return 404; }
    location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console)                { return 404; }

    location ~ \.php(?:$|/) {
        rewrite ^/(?!index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+|.+\/richdocumentscode\/proxy) /index.php$request_uri;

        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        set $path_info $fastcgi_path_info;

        try_files $fastcgi_script_name =404;

        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $path_info;

        fastcgi_param modHeadersAvailable true;         # Avoid sending the security headers twice
        fastcgi_param front_controller_active true;     # Enable pretty urls
        fastcgi_pass php-handler;

        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;
    }

    location ~ \.(?:css|js|svg|gif|png|jpg|ico)$ {
        try_files $uri /index.php$request_uri;
        expires 6M;         # Cache-Control policy borrowed from `.htaccess`
        access_log off;     # Optional: Don't log access to assets
    }

    location ~ \.woff2?$ {
        try_files $uri /index.php$request_uri;
        expires 7d;         # Cache-Control policy borrowed from `.htaccess`
        access_log off;     # Optional: Don't log access to assets
    }

    location /remote {
        return 301 /remote.php$request_uri;
    }

    location / {
        try_files $uri $uri/ /index.php$request_uri;
    }
}
```

Ahora debemos habilitar el virtualhost creando el enlace simbólico:

```
ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/nextcloud
```

Y reiniciamos el servicio:

```
systemctl restart nginx
```

Con esto, ya podemos añadir la línea en el fichero `/etc/hosts` para que resuelva el nombre:

```
192.168.121.20 cloud.example.com
```

Ahora intentamos acceder a la url:

![modulosPHP_nextcloud.png](/images/practicamigracion_php_vps/modulosPHP_nextcloud.png)

Como vemos, nos indica que tenemos que instalar esos módulos para que funcione la aplicación. Así pues los instalamos:

```
apt install php-zip php-dom php-xmlwriter php-xmlreader php-xml php-mbstring php-gd php-simplexml php-curl php-mysql
```

Una vez instalados volvemos a entrar en la url:

![nextcloud_entrada.png](/images/practicamigracion_php_vps/nextcloud_entrada.png)

Ya podemos registrarnos. Así pues, lo rellenamos con la información del usuario y la base de datos que hemos creado anteriormente para nextcloud:

![nextcloud_registro.png](/images/practicamigracion_php_vps/nextcloud_registro.png)

Una vez hecho esto, ya podemos dejar que se instale. Cuando acabe, ya podremos acceder a nuestra cuenta cuando entremos en la web:

![nextcloud_instalado.png](/images/practicamigracion_php_vps/nextcloud_instalado.png)


## Realiza la migración al servidor en producción, para que la aplicación sea accesible en la URL: `www.tudominio.algo/cloud`

Para realizar la migración vamos a usar el mismo método que usamos anteriormente. Esto es, crear un repositorio en github donde se encuentre la configuración y los ficheros de nextcloud, el cual usaremos para clonar su contenido en nuestra vps, y hacer una copia de seguridad de la base de datos, la cual incorporaremos a la base de datos que hemos creado en nuestra vps. Así pues, vamos a realizar en primer lugar la copia de seguridad:

```
mysqldump -v --opt --events --routines --triggers --default-character-set=utf8 -u nextcloud -p nextcloud > db_backup_nextcloud_`date +%Y%m%d_%H%M%S`.sql
```

Una vez que la hallamos transferido a nuestra vps (mediante github, scp, etc), pasamos a incorporarla a nuestra base de datos:

```
mysql -u nextcloud -p nextcloud < db_backup_nextcloud_20211106_103948.sql
```

Ya hemos añadido la base de datos, así que ahora podemos clonar el directorio donde hemos subido los archivos de nextcloud en el DocumentRoot que elijamos. Una vez clonado, podemos añadir la siguiente configuración a nuestro virtualhost principal (donde tenemos la página principal del dominio):

```
        location = /robots.txt {
            allow all;
            log_not_found off;
            access_log off;
        }

        location /.well-known {

            location = /.well-known/carddav   { return 301 /cloud/remote.php/dav/; }
            location = /.well-known/caldav    { return 301 /cloud/remote.php/dav/; }

            location /.well-known/acme-challenge    { try_files $uri $uri/ =404; }
            location /.well-known/pki-validation    { try_files $uri $uri/ =404; }

            try_files $uri $uri/ =404;
        }

        location ^~ /cloud {
            client_max_body_size 512M;
            fastcgi_buffers 64 4K;

            gzip on;
            gzip_vary on;
            gzip_comp_level 4;
            gzip_min_length 256;
            gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
            gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

            add_header Referrer-Policy                      "no-referrer"   always;
            add_header X-Content-Type-Options               "nosniff"       always;
            add_header X-Download-Options                   "noopen"        always;
            add_header X-Frame-Options                      "SAMEORIGIN"    always;
            add_header X-Permitted-Cross-Domain-Policies    "none"          always;
            add_header X-Robots-Tag                         "none"          always;
            add_header X-XSS-Protection                     "1; mode=block" always;

            fastcgi_hide_header X-Powered-By;

            index index.php index.html /cloud/index.php$request_uri;

            expires 1m;

            location = /cloud {
                if ( $http_user_agent ~ ^DavClnt ) {
                    return 302 /cloud/remote.php/webdav/$is_args$args;
                }
            }

            location ~ ^/cloud/(?:build|tests|config|lib|3rdparty|templates|data)(?:$|/)    { return 404; }
            location ~ ^/cloud/(?:\.|autotest|occ|issue|indie|db_|console)                { return 404; }

            location ~ \.php(?:$|/) {
                fastcgi_split_path_info ^(.+?\.php)(/.*)$;
                set $path_info $fastcgi_path_info;

                try_files $fastcgi_script_name =404;

                include fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_param PATH_INFO $path_info;

                fastcgi_param modHeadersAvailable true;
                fastcgi_param front_controller_active true;
                fastcgi_pass unix:/run/php/php7.4-fpm.sock;

                fastcgi_intercept_errors on;
                fastcgi_request_buffering off;
            }

            location ~ \.(?:css|js|svg|gif)$ {
                try_files $uri /cloud/index.php$request_uri;
                expires 6M;
                access_log off;
            }

            location ~ \.woff2?$ {
                try_files $uri /cloud/index.php$request_uri;
                expires 7d;
                access_log off;
            }

            location /cloud {
                try_files $uri $uri/ /cloud/index.php$request_uri;
            }
        }
```

* Nota: la configuración se encuentra disponible en la página oficial de Nextcloud, en la documentación de nginx. Yo solo la he modificado para adaptarla a nuestro escenario.

Ahora, para aplicar los cambios, debemos reiniciar el servicio de nginx:

```
systemctl reload nginx
```

Por supuesto, debemos recordar que ya que hemos migrado la aplicación, debemos cambiar el fichero de configuración de la misma para que se adapte al nuevo entorno:

![nextcloud_config.png](/images/practicamigracion_php_vps/nextcloud_config.png)

Con esto, intentamos acceder a nuestra página de nextcloud:

![nextcloud_acceso_vps.png](/images/practicamigracion_php_vps/nextcloud_acceso_vps.png)

Si introducimos el usuario y la contraseña que pusimos durante la instalación debería dejarnos entrar, lo que significaría que la migración ha sido un éxito:

![nextcloud_vps_dashboard.png](/images/practicamigracion_php_vps/nextcloud_vps_dashboard.png)

Como podemos ver, tenemos acceso con ese usuario y contraseña, por lo que podemos considerar la migración un éxito.

## Instala en un ordenador el cliente de nextcloud y realiza la configuración adecuada para acceder a “tu nube”.

El cliente de nextcloud se encuentra dentro de la paquetería de debian, por lo que para instalarlo simplemente debemos ejecutar lo siguiente:

```
apt install nextcloud-desktop
```

Una vez instalado, para ejecutarlo usamos el siguiente comando:

```
nextcloud
```

Al ejecutarlo nos abre la siguiente ventana:

![cliente.png](/images/practicamigracion_php_vps/cliente.png)

En esta ventana le damos al botón "Entrar", tras lo cual nos preguntará por el host de nuestro servidor. Introducimos entonces la url de nuestro servidor de nextcloud y no autentificamos para darle permiso. Tras ello elegimos que carpeta queremos sincronizar y la damos a conectar. Con esto ya hemos conectado el servidor y el cliente.

Vamos a comprobar que están sincronizados. Voy a crear un fichero en la carpeta compartida de mi anfitrión, y si están sincronizados, debería aparecernos en el navegador, y por tanto, en el servidor:

![fichero_prueba.png](/images/practicamigracion_php_vps/fichero_prueba.png)

![confirmacion.png](/images/practicamigracion_php_vps/confirmacion.png)
