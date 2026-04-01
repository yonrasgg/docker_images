FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring apt-utils autoconf automake build-essential git libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre++-dev libtool libxml2-dev libyajl-dev pkgconf wget zlib1g-dev

RUN curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list
RUN printf "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" > /etc/apt/preferences.d/99nginx
RUN apt-get update && apt-get install -y nginx

RUN git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity /opt/ModSecurity && \
    cd /opt/ModSecurity && \
    git submodule init && \
    git submodule update && \
    ./build.sh && \
    ./configure && \
    make && \
    make install

RUN git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git /opt/ModSecurity-nginx && \
    wget http://nginx.org/download/nginx-1.13.1.tar.gz -O /tmp/nginx-1.13.1.tar.gz && \
    tar zxvf /tmp/nginx-1.13.1.tar.gz -C /opt/ && \
    cd /opt/nginx-1.13.1 && \
    ./configure --with-compat --add-dynamic-module=/opt/ModSecurity-nginx && \
    make modules && \
    cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules/

# Download and unpack the headers-more-nginx-module
RUN git clone https://github.com/openresty/headers-more-nginx-module.git /opt/headers-more-nginx-module

# Build and install nginx with the headers-more-nginx-module
RUN wget 'http://nginx.org/download/nginx-1.17.8.tar.gz' -O /tmp/nginx-1.17.8.tar.gz && \
    tar -xzvf /tmp/nginx-1.17.8.tar.gz -C /opt/ && \
    cd /opt/nginx-1.17.8/ && \
    ./configure --prefix=/opt/nginx \
    --add-module=/opt/headers-more-nginx-module && \
    make && \
    make install

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
