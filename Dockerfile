FROM nginx:alpine-slim
RUN apk add --no-cache bash
WORKDIR /etc/nginx
COPY default.conf ./conf.d/default.conf


