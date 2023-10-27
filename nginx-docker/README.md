# Nginx + ModSecurity docker image

This repository provides a Docker image incorporating Nginx and ModSecurity on an Ubuntu base. It is designed to offer a robust web application firewall (WAF) to safeguard your web applications against common threats and vulnerabilities.

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

## Contributions

Contributions and enhancements are warmly welcomed! For suggestions or issues, please create an issue or pull request in this repository.

## License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/your-repo/docker_images/blob/main/LICENSE) file for more details.

### [Docker Repo](https://github.com/yonrasgg/docker_images/blob/49fdb953ec2321a81841c05cb21c96402156c617/nginx-docker/README.md)

Inspired by official Nginx images and ModSecurity, this image integrates the powerful Nginx web server with the robust protection of ModSecurity. The setup adheres to best practices ensuring optimal performance and security.

---

## Example Use Cases and Commands

### Auditing and Testing

Before deploying, it's crucial to audit ModSecurity to ensure no false positives. Run the container in audit mode to log HTTP traffic without blocking any requests.

```bash
docker run -d --name nginx-modsec -e MODSEC_AUDIT_LOG=/var/log/modsec_audit.log nginx-modsecurity
```

Tail the audit log with:

```bash
docker exec -it nginx-modsec tail -f /var/log/modsec_audit.log
```

Trigger a security rule using curl to examine the behavior:

```bash
curl -I 'http://localhost/?param="><script>alert(1);</script>'
```

### Enabling ModSecurity

After auditing, enable ModSecurity by updating the `modsecurity.conf` file and restarting the container.

```bash
docker exec -it nginx-modsec sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/modsecurity.d/modsecurity.conf
docker restart nginx-modsec
```

### Blocking Specific Attacks

Create custom rules to block particular attacks. For instance, to block requests with a specific User-Agent:

```bash
echo 'SecRule REQUEST_HEADERS:User-Agent "BadBot" "id:1234,deny,status:403"' > custom_rules.conf
docker cp custom_rules.conf nginx-modsec:/etc/modsecurity.d/
docker restart nginx-modsec
```

Now, requests from `BadBot` will be blocked.

These examples illustrate how to utilize and customize the Nginx + ModSecurity image to effectively protect your web applications.