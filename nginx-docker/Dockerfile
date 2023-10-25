# Usar una imagen base de Alpine por su tamaño pequeño
FROM alpine:latest as builder

# Instalar las dependencias necesarias
RUN apk add --no-cache \
    git \
    g++ \
    autoconf \
    automake \
    build-base \
    curl \
    libcurl \
    pcre2-dev \
    libxml2-dev \
    libxslt-dev \
    linux-headers \
    geoip-dev \
    libtool \
    lmdb-dev \
    yajl-dev \
    zlib-dev

# Descargar y compilar el código fuente de ModSecurity
WORKDIR /opt
RUN git clone https://github.com/SpiderLabs/ModSecurity
WORKDIR /opt/ModSecurity
RUN git submodule init && \
    git submodule update && \
    sh build.sh && \
    ./configure --with-pcre2 && \
    make && \
    make install

# Descargar el conector NGINX para ModSecurity y compilarlo como un módulo dinámico
WORKDIR /opt
RUN git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
WORKDIR /opt/nginx
RUN wget http://nginx.org/download/nginx-1.21.5.tar.gz && \
    tar zxvf nginx-1.21.5.tar.gz
WORKDIR /opt/nginx/nginx-1.21.5
RUN ./configure --with-compat --add-dynamic-module=/opt/ModSecurity-nginx || (cat config.log && exit 1)
RUN make modules

# Crear una nueva imagen basada en NGINX 1.21.5
FROM nginx:1.21.5

# Copiar el módulo dinámico compilado y las configuraciones de ModSecurity
COPY --from=builder /opt/nginx/nginx-1.21.5/objs/ngx_http_modsecurity_module.so /etc/nginx/modules/
COPY --from=builder /opt/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
COPY --from=builder /opt/ModSecurity/unicode.mapping /etc/nginx/modsec/

# Habilitar y configurar ModSecurity
RUN sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf
RUN echo -e 'load_module modules/ngx_http_modsecurity_module.so;\n' | cat - /etc/nginx/nginx.conf > temp && mv temp /etc/nginx/nginx.conf
RUN echo -e '\nmodsecurity on;\nmodsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;\n' >> /etc/nginx/nginx.conf

# Exponer los puertos 80 y 443
EXPOSE 80 443

# Ejecutar NGINX en primer plano
CMD ["nginx", "-g", "daemon off;"]
