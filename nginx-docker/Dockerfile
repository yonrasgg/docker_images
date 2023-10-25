# Use Alpine Linux as a base system
FROM alpine:latest

# Install the necessary dependencies
RUN apk add --no-cache nginx openssl curl ca-certificates

# Ensure the necessary directories exist
RUN mkdir -p /etc/modsecurity.d && \
    mkdir -p /etc/modsecurity/crs && \
    mkdir -p /etc/nginx/conf.d

# Download the ModSecurity configuration files from the repository
RUN wget -O /etc/modsecurity.d/modsecurity.conf https://raw.githubusercontent.com/janikvonrotz/nginx-modsecurity-crs/master/etc/modsecurity.d/modsecurity.conf && \
    wget -O /etc/modsecurity/crs/crs-setup.conf https://raw.githubusercontent.com/janikvonrotz/nginx-modsecurity-crs/master/etc/modsecurity/crs-setup.conf && \
    wget -O /etc/modsecurity/crs/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf https://raw.githubusercontent.com/janikvonrotz/nginx-modsecurity-crs/master/etc/modsecurity/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf

# Modify the nginx.conf file to include the ModSecurity configuration
RUN echo -e "load_module modules/ngx_http_modsecurity_module.so;\n$(cat /etc/nginx/nginx.conf)" > /etc/nginx/nginx.conf && \
    echo -e "server {\n listen 80;\n modsecurity on;\n modsecurity_rules_file /etc/modsecurity/crs/crs-setup.conf;\n location / {\n proxy_pass http://localhost:8085;\n proxy_set_header Host \$host;\n }\n}" > /etc/nginx/conf.d/proxy.conf

# Expose port 80 for HTTP traffic and port 443 for HTTPS traffic
EXPOSE 80 443

# Run Nginx in the foreground to keep the container running
CMD ["nginx", "-g", "daemon off;"]
