# Reverse Proxy NGINX + Cache
Ejemplo simple para demostrar como funciona proxy reverso que llama al container docker que tiene corriendo el tomcat de docker-microservice y permitiendo cachear o no response en base al request.

### localhost/cached
Va a cachear el response
Nota: para ver si el request hizo un HIT o MISS en cache, fijate en el response nginx setea un header llamado X-Proxy-Cache (Esto fue configurado en el archivo default.config).

### localhost/nocached
No va a cachear el response