# iptables on Alpine Linux

This repository contains a Docker image of iptables running on Alpine Linux, making it suitable even for devices with limited resources such as Raspberry Pi.

## Image Download

You can download the iptables image on Alpine from Docker Hub using the following command:

```bash
docker pull ynrg13/iptables-alpine:latest
```

## Using the Image

### Basic Execution

To run iptables in a Docker container, use the following command:

```bash
docker run -d --cap-add=NET_ADMIN --name iptables ynrg13/iptables-alpine:latest
```

This command will run iptables in the background with the necessary privileges to modify the network configuration of the host.

### Customization

You can customize iptables rules using a custom script file when running the container. For example, to specify a custom script file:

```bash
docker run -d --cap-add=NET_ADMIN --name iptables -v /path/to/your/iptables.sh:/etc/iptables/iptables.sh ynrg13/iptables-alpine:latest
```

Make sure to mount the necessary directories or files for custom configurations:

```bash
docker run -d --cap-add=NET_ADMIN --name iptables -v /path/to/your/iptables.sh:/etc/iptables/iptables.sh ynrg13/iptables-alpine:latest
```

### Usage with Raspberry Pi

This image is especially useful on devices like Raspberry Pi due to its low resource consumption. You can run it on a Raspberry Pi as follows:

```bash
docker run -d --cap-add=NET_ADMIN --name iptables ynrg13/iptables-alpine:latest
```

## Contributions

Contributions and improvements are welcome! If you have any suggestions or encounter any issues, please create an issue or pull request in this repository.

## License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/yonrasgg/docker_images/blob/main/LICENSE) file for more details.

### [Docker Repo](https://hub.docker.com/repository/docker/ynrg13/iptables-alpine/general)

In this README, users are guided on how to download your iptables image from Docker Hub, run it on their machines (including Raspberry Pi), and how to customize iptables rules using a custom script. Similar to the Heimdall README, it also includes sections for contributions, licensing, and a link to the Docker repository.