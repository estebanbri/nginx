# Reverse Proxy NGINX + Cache
Ejemplo simple para demostrar como funciona proxy reverso que llama al container docker que tiene corriendo el tomcat de docker-microservice y permitiendo cachear o no response en base al request.

### localhost/cached 
Dicha url localhost/nocached va a ser enrutado al microservicio http://rest-app:8080 y va a cachear el response
Nota: para ver si el request hizo un HIT o MISS en cache, fijate en el response nginx setea un header llamado X-Proxy-Cache (Esto fue configurado en el archivo default.config).

### localhost/nocached
Dicha url localhost/nocached va a ser enrutada al microservicio http://rest-app:8080 y NO va a cachear el response

# Load balancing
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

# Tambien podes ejecutar nginx sin un Dockerfile directamente usando la misma imagen nginx del registry de docker hub
Veamos las alternativas podes usar una o ambas dependiendo de tus necesidades:

### Alternativa 1: nginx como Reverse proxy (+ Load Balancing) (ubicacion del archivo default.conf: /etc/nginx/conf.d/):
Supone que almacenaste el archivo default.conf en tu ruta local D:\data\IdeaProjects\nginx entonces tu docker run:

> docker run --name myngnix --rm -d -v D:\data\IdeaProjects\nginx\default.conf:/etc/nginx/conf.d/default.conf nginx

### Alternativa 2: nginx para servir recursos estaticos (ubicacion de recursos static: /usr/share/nginx/html/):

> docker run --name myngnix --rm -d -v D:\data\IdeaProjects\nginx\index.html:/usr/share/nginx/html/index.html nginx


