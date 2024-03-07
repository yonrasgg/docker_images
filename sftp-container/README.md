# SFTP Docker Image

This Dockerfile is used to create a Docker image for an SFTP server based on the latest version of Alpine Linux.

## Base Image

The base image for this Docker image is the latest version of Alpine Linux.

## Installation

The following packages are installed on the Alpine Linux image:
- OpenSSH
- Bash
- Shadow (for password management)

SSH keys are generated for the server.

## User Configuration

A new user named `admin_user` is created with the following settings:
- Home directory: `/home/admin_user`
- Shell: `/bin/sh`
- Primary group: `wheel`
- User ID: `10001`

The password for `admin_user` is set to `SFTPUSERPASSWORDHERE`.

## Directory Setup

The following directories are created:
- `/var/run/sshd` for the SSH daemon to run
- `/var/sftp/uploads` for SFTP file uploads

Permissions and ownership are set accordingly.

## SSH Server Configuration

The SSH server is configured with the following settings:
- Keep sessions alive by sending a message to the client every 60 seconds
- Allow a maximum of 120 missed messages before disconnecting the session
- Only allow SFTP for the `admin_user` user
- Disable SSH tunneling, agent forwarding, TCP forwarding, and X11 forwarding

## Network Port

The container listens on port 22, the default port for SSH.

## Container Startup

The SSH daemon is started when the container starts. The `-D` option is used to run SSHD in the foreground and prevent the container from exiting.

## Usage

To use this Docker image, follow these steps:
1. Build the image using the provided Dockerfile.
2. Run a container based on the built image.
3. Connect to the SFTP server using an SFTP client.

Please refer to the Docker documentation for more information on building and running Docker images.
