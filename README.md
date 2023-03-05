# NGINX
## Caracteristicas de nginx
- Es un ***Web Server*** (para servir recursos estaticos como html,css,js) y ademas puede usarse como ***Reverse Proxy***.
- Puede manejar 10 mil conexiones concurrentes simultaneos gracias a su arquitectura "Event Driven"  (usa Event Loop) por esto es muy popular para sitios web con alto trafico.

## Funciones de un Proxy Inverso:
- ***Enturamiento de request de clientes***: En base a datos del request, como:  
	- el ***DOMAIN_NAME*** definido en el header Host del request (server_name guru.com en nginx)  
	- el ***PATH*** definida en la URL (location /pagos-service en nginx)  
el mismo nginx sabe a que server necesita enrutar el request. Ya que el cliente por ej contactandose por el puerto 80 de nginx que es el puerto implicito por defecto, el mismo nginx se encarga de mapearle segun el ***DOMAIN_NAME*** o ***PATH*** solicitado la IP:puerto del server destino privado. (con esto les facilitas la vida a los clientes de no hacerles memoriazar los puertos de las aplicaciones que necesitan consultar)  
- ***Anonimato de los backend servers***: sin nginx funcionando como reverse proxy, no te queda otra que el cliente tenga que acordarse los puertos de cada app que necesita usar, en cambio con nginx simplemente el cliente con un nombre de dominio especifico para una app que necesita y conectandose para todas las app's al puerto 80 (Http Insecured) o el 433 (HTTPS con certificado SSL) de nginx ya con eso nginx es capaz de redirigir el trafico segun el el nombre de dominio al server/app correcta. (Ya que recorda que el router solo tiene la capacidad de analizar puertos para redirigir el trafico al server correcto (no entiende ni mira los nombres de dominio), en cambio nginx si mira y entiende los nombres de dominio para poder redirigir el trafico.
- ***Proteccion de los backend servers***: ademas podemos nginx puede gestionar certificados ssl asi quitamos la carga de manejar los cert SSL a los servidores backend. Y con el certificado cifrar y segurizar la comunicacion entre el cliente y nginx.
- ***Balanceo de carga (Load balancing)***: aumenta disponibilidad de tu app, en caso de que se caiga un backend sv redirige la carga a los server funcionales.
- ***Caching***: maneja HTTP Cache
- ***Compresion***: de data entrante y saliente (ej, gizp)

## Personalizar el comportamiento de tu server nginx
Lo hacemos en archivo de configuracion por defecto de nginx lo encontramos en el /etc/nginx/nginx.conf, dentro del mismo podemos definir directivas (una directiva es un par de clave-valor, pudiendo se un valor unico o definir un contexto entre llaves).

### Ejemplo basico de nginx.conf:
```
# main (global) context  
user nobody;  
error_log /var/log/ngnix/error.log; # Especifica donde se van a guardar los logs de error del server   
http { # http context puede definir 1 o mas server  
   server {  
      listen 80;  
      access_log /var/log/ngnix/access.log; # Permite el keep track y loguear cada request  
      
      # Para usarlo como web server para servir recursos estaticos (se especifica con la directiva root para indicarle donde estan los archivos estaticos html,css,js)  
      location / {  
	  root /app/static; # Especifica la ruta de la carpeta 'static' la cual tiene dentro los archivos estaticos (html,js,css, img)	  
          index  index.html;  
	  try_files $uri $uri/ /index.html =404; # Le indica a nginx que trate de matchear los archivos solicitados en la URL (URI) con los archivos disponibles dentro de la ruta especificada en la directiva root de este location. Por ej, si en la URL viene /main.bundle.js entonces va a matchear con el archivo main.bundle.js y lo va a retornar al cliente a dicho archivo js. Pero si no encuentra ningun match, it will default to index.html.
      }  
      # Para usarlo como reverse proxy (se especifica con la proxy_pass para indicarle la ip y puerto del server al que tiene que redirigir el request)  
      location /api {  
	   proxy_pass http://192.19.23.4:3000; # Reverse proxy hacia otro server	  
      }  
   }  
}  
```

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

## Como acceder desde internet a mi NGINX funcionaodo como un Reverse Proxy de mis servers privados.
![alt text](https://github.com/estebanbri/nginx/blob/master/Access-NGINX-via-Internet2.png)

### Explicacion:
1. Cliente ingresa en browser el domain name (ej: www.guru.com)
2. Se trata de resolver la "IP Publica" destino que se le corresponde a dicho domain name ingresado por cliente.
- Si el mapping domain-name con IP destino se encuentra en la cache DNS del browser se retorna la IP destino al cliente.
- Si el mapping domain-name con IP destino se encuentra en la cache DNS del router se retorna la IP destino al cliente.
- Si no se encuentra en los dos pasos anteriores, se hace un request con destino a los Public DNS servers que se encuentran en internet y se retorna la IP destino.
3. Se hace el actual request inicial solicitado por el cliente pero ahora ya con la "IP Publica" destino (63.121.32.59) resuelta junto con del nombre de dominio en el header llamado HOST, asi por ej:
> GET 63.121.32.59:80  
> Host guru.com
4. El request es recibido por el router de la red privada del destino, en este punto la "IP publica" ya se descarta ya que estamos dentro de la red privada y en este punto lo que si importa es el puerto definido en el request para que el router puede hacer el  'Port Forwarding' (NAT), que basicamente el router mantiene una tabla de mapping entre incoming_port y IP Privada:PORT. (Segun la imagen como no se especifica el puerto explicitamente por defecto es el puerto 80 para HTTP)
5. Nginx recibe el request y mediante la configuracion seteada en nginx.cong va a a enviar el request al server que se corresponda con el nombre de dominio solicitado en el header 'Host' del request. (en este caso guru.com:80 nginx va a enrutar el request al server 192.168.0.101:8080)

- Nota 1: los DNS solamente mapean domain_names a ip (sin puerto), es decir los DNS server o los DNS cache no manejan numeros de puertos, una vez resuelta la consulta al DNS para la obtencion de la IP destino, el cliente le hace un append del puerto que necesita contactarse al server a la IP destino para generar el actual request al server.  
- Nota 2: La IP privada del router de tu red privada se conoce tambien como 'Puerta de enlace' o 'Gateway' o 'eth0'
- Nota 3: El Port forwarding es un tipo de Network Address Translation (NAT). Es una técnica utilizada para redirigir el tráfico de entrada desde una dirección IP pública a una dirección IP privada en el interior de una red privada.

## Ejemplo real del Port Forwarding (NAT) hecho por router
![alt text](https://github.com/estebanbri/nginx/blob/master/Ejemplo-real-configuracion-port-forwarding-router.png)

Tutorial excelente de redes en español (Explica lo de Port Fordwarding y mucho mas): https://www.youtube.com/watch?v=kfUnTEOx7m8&list=PLOkfrWrF2MlnJCARuBJnbNnYdyQN2qMqZ

***Nota***: Por un lado acceder a tu red via comunicación directa a la IP Publica de tu router + Port Forwarding no es algo seguro, porque le estas dando a conocer la IP Pública de tu router a los demas y estas creando un agujero en tu red al mundo externo al mapear puertos con apps dentro de tu red. Por otro lado hay algunos router que no te permiten abrirle los puertos. Por ende aparecen utiles alternativas como:
- VPN's 
- 'Cloudflare Tunneling' el cual actua de intermediario entre el cliente de internet que hace el request y tu red privada sin pasar por tu router, es decir el cliente hace un request a la IP de cloudflare y cloudflare se comunica directamente con tu IP privada de manera segura y encriptada gracias a tunnel creado por Cloudflare.

## ¿Que sucede si no contraté una IP Publica estatica a mi ISP, es decir tengo una IP Publica Dinamica? Solución: ***DUCK DNS***
Es un servicio de DNS dinamico gratis, que basicamente como todo servicio DNS la funcion que cumple es asociar un "nombre de dominio" (http://{tu-sub-dominio}.duckdns.org) a la IP Publica de tu router pero la particularidad que tiene es que como los proveedores de internet generalmente te dan IP's Publicas dinamicas, es decir reinicias el router y te asigna otra IP Publica al router, DUCK DNS tiene la capacidad de asociar un nombre de dominio  a una IP Publica dinamica. El servicio de DuckDNS cada vez que cambia la IP Publica de tu router el mismo se encarga de asociar la nueva direccion IP Publica al nombre de dominio existente.

¿ Como lo haces ?
1) Ingresar a duckdns.com y registrar el dominio a la IP publica de tu router que tenes en ese momento (para saber cual es la ip publica en ese momento tenes web como cualesmiip.com).
2) Levantas un contenedor docker con el servicio de duckdns dinamico (tenes muchas imagenes ya fabricadas ej: linuxserver/duckdns). Dicho contenedor es el que se va a estar analizando tu IP Publica de tu router y si cambió el mismo se encarga de actualizar el registro de tu IP nueva al dominio "avisandole" al registro de DNS's que mantiene duckdns a nivel global.

## NGINX PROXY MANAGER
Es una UI web para gestionar nginx en caso de que lo necesites UNICAMENTE como PROXY REVERSO/LOAD BALANCER (y no como web server to serve static content) asi evitas el manejo de archivos de configuración. Te permite gestionar certificados SSL muy facilmente (tiene soporte especial para certificados letsencrypt que se autorenuevan out of the box). Ojo nada te impide de que agregues tanto un Nginx para servir static content y aparte tener el Nginx Proxy Manager que llame a dicho nginx.

## Tutorial para servir angular apps via Nginx
https://www.youtube.com/watch?v=hK0OS4E_xjM

## Tutorial configuracion SSL (Para cifrar comunicacion entre cliente y server)
https://www.youtube.com/watch?v=AqgClYuy1wM
