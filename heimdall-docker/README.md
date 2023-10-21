# Heimdall on Alpine Linux

![Heimdall Logo](https://camo.githubusercontent.com/17936a339a24134131b4c797d379adae8efe409157093d2a1e73d7930416f098/68747470733a2f2f692e696d6775722e636f6d2f697556387733792e706e67)

This repository contains a Docker image of Heimdall running on Alpine Linux, making it suitable even for devices with limited resources such as Raspberry Pi.

## Image Download

You can download the Heimdall image on Alpine from Docker Hub using the following command:

```bash
docker pull ynrg13/heimdall-alpine:latest
```

## Using the Image

### Basic Execution

To run Heimdall in a Docker container, use the following command:

```bash
docker run -d -p 80:80 --name heimdall ynrg13/heimdall-alpine:latest
```

This command will run Heimdall in the background and map port 80 of the container to port 80 on the host.

### Customization

You can customize Heimdall's configuration using environment variables when running the container. For example, to specify a custom configuration file:

```bash
docker run -d -p 80:80 --name heimdall -e HEIMDALL_CONFIG=/config/config.yml ynrg13/heimdall-alpine:latest
```

Make sure to mount the necessary directories for persistent storage, such as configuration and data directories:

```bash
docker run -d -p 80:80 --name heimdall -v /path/to/config:/config -v /path/to/data:/data ynrg13/heimdall-alpine:latest
```

### Usage with Raspberry Pi

This image is especially useful on devices like Raspberry Pi due to its low resource consumption. You can run it on a Raspberry Pi as follows:

```bash
docker run -d -p 80:80 --name heimdall ynrg13/heimdall-alpine:latest
```

## Contributions

Contributions and improvements are welcome! If you have any suggestions or encounter any issues, please create an issue or pull request in this repository.

## License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/yonrasgg/docker_images/blob/main/LICENSE) file for more details.
