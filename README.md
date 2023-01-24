# NGINX
## Caracteristicas de nginx
- Es un Web Server (para servir recursos estaticos como html,css,js) y ademas puede usarse como Reverse Proxy.
- Puede manejar 10 mil conexiones concurrentes simultaneos gracias a su arquitectura "Event Driven"  (usa Event Loop)

## Funciones de un Proxy Inverso:
- ***Anonimato de los backend servers***:  puesto que el reverse proxy es el único acceso a la red interna, es decir los clientes acceden por IP publica a nyginx y el mismo nginx es quien se conecta con la red interna privada, es decir nunca exponemos a la red publica nuestros backend server, los backend servers tienen que estar dentro de una red interna privada sin acceso via red publica.
- ***Proteccion de los backend servers***: ademas podemos nginx puede gestionar certificados ssl asi quitamos la carga de manejar los cert SSL a los servidores backend.
- ***Balanceo de carga (Load balancing)***: aumenta disponibilidad de tu app, en caso de que se caiga un backend sv redirige la carga a los server funcionales.
- ***Caching***: maneja HTTP Cache
- ***Compresion***: de data entrante y saliente (ej, gizp)

## Personalizar el comportamiento de tu server nginx
Lo hacemos en archivo de configuracion por defecto de nginx lo encontramos en el /etc/nginx/nginx.conf, dentro del mismo podemos definir directivas (una directiva es un par de clave-valor, pudiendo se un valor unico o definir un contexto entre llaves).

### Ejemplo basico de nginx.conf:  
> \# main (global) context  
> user nobody;  
> error_log /var/log/ngnix/error.log; \# Especifica donde se van a guardar los logs de error del server   
> http { \# http context puede definir 1 o mas server  
>   server {  
>      listen 80;  
>      access_log /var/log/ngnix/access.log; # Permite el keep track y loguear cada request  
>      
>      \# Para usarlo como web server para servir recursos estaticos (se especifica con la directiva root para indicarle donde estan los archivos estaticos)  
>      location / {  
>	   root /app/wwww/; # Especifica la ruta donde se encuentra el archivo index html	  
>          index  index.html;  
>      }  
>      location ~* \.(js|jpg|png|css)$ {  
>          root /app/wwww/; # Especifica la ruta donde se encuentra los archivos css, js, imagenes...  
>      }  
>      \# Para usarlo como reverse proxy (se especifica con la proxy_pass para indicarle la ip y puerto del server al que tiene que redirigir el request)  
>      location / {  
>	   proxy_pass http://192.19.23.4:3000; # Reverse proxy hacia otro server	  
>      }  
>   }  
> }  
>

## Configurando el Caching
Definendo dentro del archivo default.conf definimos una cache reutilizable (por varias locations):

> proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=custom_cache:10m inactive=60m;

Y dentro del location para configuramos la cache que va a usar dicho location:

> location / {  
>         ...  
> 	proxy_cache custom_cache;  
>		proxy_cache_valid any 10m;  
>		# proxy_cache_key $proxy_host$request_uri$cookie_jessionid; #Util para guardar response en base al usuario logueado es decir por session caso real un endpoint /shopping-cart en ese caso el cache de dicho endpoint va a hacerse por session para que a vos no te aparezca un carrito de compras de otra persona.  
		add_header X-Proxy-Cache $upstream_cache_status;  
>         ...  
> }

Si queres podes definir dos enrutamientos distintos uno que cache los response y otro que no definiendo dos locations asi:

> location / cached {  
>		# Enrutado   
>		rewrite ^/cached(.*) /$1 break;   
>		proxy_pass http://backend-server;  
>		# Seteo de cache    
>		proxy_cache custom_cache;    
>		proxy_cache_valid any 10m;  
>		# proxy_cache_key $proxy_host$request_uri$cookie_jessionid; #Util para guardar response en base al usuario logueado es decir por session caso real un >endpoint /shopping-cart en ese caso el cache de dicho endpoint va a hacerse por session para que a vos no te aparezca un carrito de compras de otra persona.  
>		add_header X-Proxy-Cache $upstream_cache_status;  
>	}  

>	location /nocached {  
>		# Enrutado  
>		rewrite ^/nocached(.*) /$1 break;   
>		proxy_pass http://backend-server;  
>	}  

### localhost/cached 
Dicha url localhost/cached va a ser enrutado al microservicio http://rest-app:8080 y va a cachear el response
Nota: para ver si el request hizo un HIT o MISS en cache, fijate en el response nginx setea un header llamado X-Proxy-Cache (Esto fue configurado en el archivo default.config).

### localhost/nocached
Dicha url localhost/nocached va a ser enrutada al microservicio http://rest-app:8080 y NO va a cachear el response

## Configurando el Balanceo de Carga (Load balancing)
Si queres agregar la capacidad de balanceo de carga entre la comunicacion del nginx con los server a el/los que se comunica simplemente tenes que agregar dentro de tu archivo llamado default.conf el upstream con las IP y puertos de los servers backend. 
Supone que levantaste 3 containers de docker-app entonces para que nginx balancee la carga entre los 3 servers tenes que poner asi:

> upstream backend-server {  
> 	server http://192.18.0.2:8080;  
> 	server http://192.18.0.3:8080;  
> 	server http://192.18.0.4:8080;  
> }

Por defecto va a aplicar round robin.

Y para utilizarlo lo especificas dentro del proxy_pass del location asi:

> location / {  
>         ...  
> 	proxy_pass http://backend-server  
>         ...  
> }

## Tambien podes ejecutar nginx sin un Dockerfile directamente usando la misma imagen nginx del registry de docker hub
Veamos las alternativas podes usar una o ambas dependiendo de tus necesidades:

### Alternativa 1: nginx como Reverse proxy (+ Load Balancing) (ubicacion del archivo default.conf: /etc/nginx/conf.d/):
Supone que almacenaste el archivo default.conf en tu ruta local D:\data\IdeaProjects\nginx entonces tu docker run:

> docker run --name myngnix --rm -d -v D:\data\IdeaProjects\nginx\default.conf:/etc/nginx/conf.d/default.conf -p 80:80 nginx

### Alternativa 2: nginx para servir recursos estaticos (ubicacion de recursos static: /usr/share/nginx/html/):

> docker run --name myngnix --rm -d -v D:\data\IdeaProjects\nginx\index.html:/usr/share/nginx/html/index.html -p 80:80 nginx


