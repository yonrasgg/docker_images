# Alpine FTP/FTPS Docker Image

This Docker image facilitates the deployment of an FTP (File Transfer Protocol) server with optional FTPS (FTP over SSL/TLS) support, using Alpine Linux for a lightweight and efficient setup. It streamlines the process of setting up and managing an FTP or FTPS server within a Dockerized environment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Building the Docker Image](#building-the-docker-image)
- [Running the Docker Container](#running-the-docker-container)
- [Connecting to the FTP Server](#connecting-to-the-ftp-server)
- [Customizing the Docker Image](#customizing-the-docker-image)
- [Environment Variables and Configuration](#environment-variables-and-configuration)
- [FTPS Setup](#ftps-setup)
- [Using Docker Compose](#using-docker-compose)
- [Contributing](#contributing)
- [License](#license)

## Prerequisites

Ensure Docker is installed and properly configured on your system. Visit the [official Docker documentation](https://docs.docker.com/get-docker/) for guidance on installation and setup.

## Building the Docker Image

To build the Docker image, execute these steps:

1. **Obtain the Source**: Clone or download the source repository containing the Dockerfile and associated scripts.
2. **Navigate to the Project Directory**: Switch to the directory housing the Dockerfile.
3. **Build the Image**: Run the following command to build the Docker image. Note that user configurations are managed at runtime via environment variables.

    ```bash
    docker build -t alpine-ftp-server .
    ```

## Running the Docker Container

Launch the Docker container with this command:

```bash
docker run -d \
    -p "21:21" \
    -p 21000-21010:21000-21010 \
    -e USERS="one|1234" \
    -e ADDRESS=ftp.site.domain \
    alpine-ftp-server
```

This command starts the container in detached mode, maps the necessary ports, and sets up an FTP user.

## Connecting to the FTP Server

Connect to the FTP server using any FTP client with the server address (`ftp://your_server_ip`), the username (e.g., `one`), and the password specified at runtime.

## Customizing the Docker Image

The Docker image can be customized by editing the Dockerfile or by adjusting runtime environment variables for user management and server configuration.

## Environment Variables and Configuration

- **USERS**: Configures FTP users in the format `name|password|[folder][|uid][|gid]`. Default: `alpineftp|alpineftp`.
- **ADDRESS**: External address for passive FTP connections. Optional but recommended for passive mode operation.
- **MIN_PORT**, **MAX_PORT**: Define the range for passive connection ports. Defaults to 21000-21010.

## FTPS Setup

For FTPS support, use a valid SSL/TLS certificate. Here’s how to configure the server for FTPS:

1. Generate a Let's Encrypt certificate for your domain.
2. Configure the container with the certificate paths and necessary environment variables:

```bash
docker run -d \
    --name ftps-server \
    -p "21:21" \
    -p 21000-21010:21000-21010 \
    -v "/etc/letsencrypt:/etc/letsencrypt:ro" \
    -e USERS="one|1234" \
    -e ADDRESS=ftp.site.domain \
    -e TLS_CERT="/etc/letsencrypt/live/ftp.site.domain/fullchain.pem" \
    -e TLS_KEY="/etc/letsencrypt/live/ftp.site.domain/privkey.pem" \
    alpine-ftp-server
```

## Using Docker Compose

When using Docker Compose, ensure port mappings are quoted to prevent YAML parsing errors:

```yaml
services:
  ftp-server:
    image: alpine-ftp-server
    ports:
      - "21:21"
      - "21000-21010:21000-21010"
    environment:
      - USERS=one|1234
      - ADDRESS=ftp.site.domain
```

## Contributing

Contributions to enhance the Docker image or documentation are welcome. Please submit pull requests for any improvements.

## License

This project is inspired by and adapted from [delfer/docker-alpine-ftp-server](https://github.com/delfer/docker-alpine-ftp-server), maintaining any original licensing terms.
