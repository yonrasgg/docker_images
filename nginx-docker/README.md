# Nginx + ModSecurity Docker Image

This repository houses a Docker image that amalgamates Nginx and ModSecurity on an Ubuntu base, aimed at delivering a robust Web Application Firewall (WAF) to shield your web applications from common threats and vulnerabilities.

- **Nginx** is configured using the official [Nginx Docker image](https://hub.docker.com/_/nginx/). During the build, Nginx source is fetched for module compilation.
- **ModSecurity** configuration follows the guide on [Compiling and Installing ModSecurity for Open Source NGINX](https://www.nginx.com/blog/compiling-and-installing-modsecurity-for-open-source-nginx/).
- The **OWASP ModSecurity Core Rule Set (CRS)** is sourced during build from [OWASP ModSecurity CRS GitHub](https://github.com/SpiderLabs/owasp-modsecurity-crs/).
- Additionally, the [Headers More Nginx module](https://github.com/openresty/headers-more-nginx-module) is installed, and the Server header is sanitized from the response.

## Image Build

Build the Nginx + ModSecurity image using the command below:

```bash
docker build -t nginx-modsecurity .
```

## Using the Image

### Basic Execution

Launch Nginx with ModSecurity in a Docker container:

```bash
docker run -d --name nginx-modsec nginx-modsecurity
```

This command runs Nginx with ModSecurity in the background.

### Customization

Mount your custom configuration files when launching the container for custom Nginx and ModSecurity configurations:

```bash
docker run -d --name nginx-modsec \
-v /path/to/your/nginx.conf:/etc/nginx/nginx.conf \
-v /path/to/your/modsec:/etc/nginx/modsec \
nginx-modsecurity
```

For more comprehensive custom configurations like SSL certificates, ModSecurity rules, and log directories, use:

```bash
docker run -d --name nginx-modsec \
-v /path/to/your/nginx.conf:/etc/nginx/nginx.conf \
-v /path/to/your/modsec:/etc/nginx/modsec \
-v /path/to/your/ssl:/etc/nginx/ssl \
-v /path/to/your/logs/nginx:/var/log/nginx \
nginx-modsecurity
```

## Setting up `libmodsecurity` in your Docker container

Post image pull, ensure `libmodsecurity` is correctly configured within your Docker container by following these steps:

1. **Create a Docker Volume for `libmodsecurity`**:
   ```bash
   docker volume create libmodsecurity
   ```

2. **Copy `libmodsecurity.so.3` to the Docker Volume**:
   ```bash
   sudo cp /path/to/your/libmodsecurity.so.3 /var/lib/docker/volumes/libmodsecurity/_data/
   ```

3. **Update Docker Run Command**:
   ```bash
   docker run -d -v libmodsecurity:/usr/local/modsecurity/lib --name nginx-modsec nginx-modsecurity
   ```

4. **Restart the Container**:
   ```bash
   docker restart nginx-modsec
   ```

5. **Verify the Configuration**:
   ```bash
   docker exec -it nginx-modsec nginx -t
   ```

6. **Inspect the NGINX Logs**:
   ```bash
   docker exec -it nginx-modsec cat /var/log/nginx/error.log
   ```

7. **Test the Setup**:
   ```bash
   curl http://localhost:80
   ```

## Example Use Cases and Commands

### Auditing and Testing

Audit ModSecurity for false positives before deployment. Run the container in audit mode to log HTTP traffic without blocking requests:

```bash
docker run -d --name nginx-modsec -e MODSEC_AUDIT_LOG=/var/log/modsec_audit.log nginx-modsecurity
```

Tail the audit log:

```bash
docker exec -it nginx-modsec tail -f /var/log/modsec_audit.log
```

Trigger a security rule using curl:

```bash
curl -I 'http://localhost/?param="><script>alert(1);</script>'
```

### Enabling ModSecurity

Post auditing, enable ModSecurity by updating the `modsecurity.conf` file and restarting the container:

```bash
docker exec -it nginx-modsec sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/modsecurity.d/modsecurity.conf
docker restart nginx-modsec
```

### Blocking Specific Attacks

Create custom rules to block particular attacks. For example, to block requests with a specific User-Agent:

```bash
echo 'SecRule REQUEST_HEADERS:User-Agent "BadBot" "id:1234,deny,status:403"' > custom_rules.conf
docker cp custom_rules.conf nginx-modsec:/etc/modsecurity.d/
docker restart nginx-modsec
```

## Contributions

We welcome contributions and enhancements. For suggestions or issues, create an issue or pull request in this repository.

## License

This project is under the MIT License. View the [LICENSE](https://github.com/your-repo/docker_images/blob/main/LICENSE) file for more details.

### [Docker Repo](https://github.com/yonrasgg/docker_images/blob/49fdb953ec2321a81841c05cb21c96402156c617/nginx-docker/README.md)

Inspired by the official Nginx images and ModSecurity, this image melds the powerful Nginx web server with the robust protection of ModSecurity, adhering to best practices for optimal performance and security.
