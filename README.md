# Reverse Proxy NGINX + Cache
Ejemplo simple para demostrar como funciona proxy reverso que llama al container docker que tiene corriendo el tomcat de docker-microservice y permitiendo cachear o no response en base al request.

### localhost/cached 
Dicha url localhost/nocached va a ser enrutado al microservicio http://rest-app:8080 y va a cachear el response
Nota: para ver si el request hizo un HIT o MISS en cache, fijate en el response nginx setea un header llamado X-Proxy-Cache (Esto fue configurado en el archivo default.config).

### localhost/nocached
Dicha url localhost/nocached va a ser enrutada al microservicio http://rest-app:8080 y NO va a cachear el response