# Nginx + ModSecurity docker image

This repository provides a Docker image incorporating Nginx and ModSecurity on an Ubuntu base. It's designed to offer a robust web application firewall (WAF) to safeguard your web applications against common threats and vulnerabilities.

The Nginx service is built from the official [Nginx Docker image](https://hub.docker.com/_/nginx/). During the build time, the Nginx source is downloaded due to the compilation of modules. ModSecurity is set via [Compiling and Installing ModSecurity for Open Source NGINX](https://www.nginx.com/blog/compiling-and-installing-modsecurity-for-open-source-nginx/). The OWASP ModSecurity Core Rule Set is set during build time from [OWASP ModSecurity CRS GitHub](https://github.com/SpiderLabs/owasp-modsecurity-crs/). Additionally, the [Headers More Nginx module](https://github.com/openresty/headers-more-nginx-module) is also set, and the Server header is cleaned from the response.

## Image Build

You can build the Nginx + ModSecurity image with the following command:

```bash
docker build -t nginx-modsecurity .
```

## Using the Image

### Basic Execution

Execute Nginx with ModSecurity in a Docker container using this command:

```bash
docker run -d --name nginx-modsec nginx-modsecurity
```

This will run Nginx with ModSecurity in the background.

### Customization

Customize Nginx and ModSecurity configurations by mounting your own configuration files when launching the container. For instance, to specify custom Nginx and ModSecurity configuration files:

```bash
docker run -d --name nginx-modsec \
-v /path/to/your/nginx.conf:/etc/nginx/nginx.conf \
-v /path/to/your/modsec:/etc/nginx/modsec \
nginx-modsecurity
```

Ensure you mount necessary directories or files for custom configurations, like SSL certificates, ModSecurity rules, and log directories:

```bash
docker run -d --name nginx-modsec \
-v /path/to/your/nginx.conf:/etc/nginx/nginx.conf \
-v /path/to/your/modsec:/etc/nginx/modsec \
-v /path/to/your/ssl:/etc/nginx/ssl \
-v /path/to/your/logs/nginx:/var/log/nginx \
nginx-modsecurity
```

... (and the rest of your README continues unchanged) ...

These alterations should accommodate your requirement to have references before the instruction sections while keeping everything in English and retaining the format.