# Nginx + ModSecurity CRS on Alpine Linux

This repository contains a Docker image with Nginx and ModSecurity Core Rule Set (CRS) running on Alpine Linux, making it suitable even for devices with limited resources such as Raspberry Pi. This setup provides a robust web application firewall (WAF) to protect your web applications from common threats and vulnerabilities.

## Image Download

You can download the Nginx + ModSecurity CRS image on Alpine from Docker Hub using the following command:

```bash
docker pull ynrg13/modsecurity-nginx:alpine
```

## Using the Image

### Basic Execution

To run Nginx with ModSecurity CRS in a Docker container, use the following command:

```bash
docker run -d --name nginx-modsec ynrg13/modsecurity-nginx:alpine
```

This command will run Nginx with ModSecurity CRS in the background.

### Customization

You can customize the Nginx and ModSecurity configurations by mounting your own configuration files when running the container. For example, to specify a custom Nginx configuration file and a custom ModSecurity CRS configuration file:

```bash
docker run -d --name nginx-modsec -v /path/to/your/nginx.conf:/etc/nginx/nginx.conf -v /path/to/your/modsec:/etc/nginx/modsec ynrg13/modsecurity-nginx:alpine
```

Make sure to mount the necessary directories or files for custom configurations, such as SSL certificates, ModSecurity rules, and log directories:

```bash
docker run -d --name nginx-modsec \
-v /path/to/your/nginx.conf:/etc/nginx/nginx.conf \
-v /path/to/your/modsec:/etc/nginx/modsec \
-v /path/to/your/ssl:/etc/nginx/ssl \
-v /path/to/your/logs/nginx:/var/log/nginx \
ynrg13/modsecurity-nginx:alpine
```

### Usage with Raspberry Pi

This image is especially useful on devices like Raspberry Pi due to its low resource consumption. You can run it on a Raspberry Pi as follows:

```bash
docker run -d --name nginx-modsec ynrg13/modsecurity-nginx:alpine
```

## Contributions

Contributions and improvements are welcome! If you have any suggestions or encounter any issues, please create an issue or pull request in this repository.

## License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/your-repo/docker_images/blob/main/LICENSE) file for more details.

### [Docker Repo](https://github.com/yonrasgg/docker_images/blob/49fdb953ec2321a81841c05cb21c96402156c617/nginx-docker/README.md)

The image builds and configurations are inspired by and built upon official Nginx images and the official ModSecurity Core Rule Set Docker images, combining the powerful Nginx web server with the robust protection of ModSecurity CRS. The image utilizes Alpine Linux to ensure a lightweight, secure, and performant service capable of protecting your web applications against a wide range of security threats.

This setup follows best practices from [Nginx WAF Admin Guide](https://docs.nginx.com/nginx-waf/admin-guide/nginx-plus-modsecurity-waf-owasp-crs/) and [Core Rule Set Docker Image Guidelines](https://github.com/coreruleset/modsecurity-crs-docker) to ensure optimal performance and security.
