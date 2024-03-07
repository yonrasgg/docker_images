# SFTP Docker Image

This Docker image facilitates the deployment of a Secure FTP (SFTP) server using Ubuntu 16.04, streamlining the process of setting up and managing an SFTP server within a Dockerized environment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Building the Docker Image](#building-the-docker-image)
- [Running the Docker Container](#running-the-docker-container)
- [Connecting to the SFTP Server](#connecting-to-the-sftp-server)
- [Customizing the Docker Image](#customizing-the-docker-image)
- [Contributing](#contributing)
- [License](#license)

## Prerequisites

Ensure Docker is installed and properly configured on your system prior to utilizing this Docker image. Refer to the [official Docker documentation](https://docs.docker.com/get-docker/) for installation guidelines.

## Building the Docker Image

Execute the following steps to construct the Docker image:

1. **Clone the Repository**: Obtain a copy of the source repository by cloning it to your local machine.

2. **Navigate to the Project Directory**: Change your directory to the one containing the Dockerfile.

3. **Build the Image**: Construct the Docker image using the command below. Substitute `your_password` with the desired password for the SFTP user account.

    ```bash
    docker build --build-arg PASSWORD_SFTP=your_password -t sftp-server .
    ```

## Running the Docker Container

Deploy the Docker container with the command provided below:

```bash
docker run -d -p 22:22 sftp-server
```

This operation initiates the Docker container in detached mode (`-d`), correlating port 22 on the container to port 22 on the host system.

## Connecting to the SFTP Server

To establish a connection with the SFTP server, utilize an SFTP client targeting `sftp://localhost`. Use the username `admin` and the password designated during the image building process.

## Customizing the Docker Image

Modifications to the Docker image can be made by adjusting the Dockerfile. Potential customizations include altering the base image, incorporating additional software packages, introducing further user accounts, or amending the SFTP server's configuration parameters.

## Contributing

Your contributions are highly appreciated! For enhancements or modifications, please initiate a pull request.

## License

This project is distributed under the MIT License. For more information, please refer to the LICENSE file included in the repository.
