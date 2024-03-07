FROM alpine:latest

# Install OpenSSH
RUN apk add --no-cache openssh bash shadow && \
    ssh-keygen -A

# Configure sftp user
RUN useradd -rm -d /home/admin_user -s /bin/sh -G wheel -u 10001 admin_user && \
    echo "admin_user:SFTPUSERPASSWORDHERE" | chpasswd

# Necessary SSHD file
RUN mkdir -p /var/run/sshd

# SSH login fix to keep session alive
RUN echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config && \
    echo "ClientAliveCountMax 120" >> /etc/ssh/sshd_config

# Setup directory for SFTP
RUN mkdir -p /var/sftp/uploads && \
    chown root:root /var/sftp && \
    chmod 755 /var/sftp && \
    chown admin_user:admin_user /var/sftp/uploads

# Update to only allow sftp and not ssh tunneling
RUN echo -e "\n\
Match User admin_user\n\
ForceCommand internal-sftp\n\
PasswordAuthentication yes\n\
ChrootDirectory /var/sftp\n\
PermitTunnel no\n\
AllowAgentForwarding no\n\
AllowTcpForwarding no\n\
X11Forwarding no" >> /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]