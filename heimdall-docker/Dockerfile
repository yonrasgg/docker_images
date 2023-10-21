FROM alpine:latest

RUN apk --no-cache add curl s6 && \
    curl -LO https://github.com/linuxserver/Heimdall/archive/refs/tags/v2.5.6.zip && \
    unzip v2.5.6.zip && \
    ls -al && \
    ls -al Heimdall-2.5.6 && \
    find / -name "Heimdall" -type d

CMD ["s6-svscan", "/etc/s6.d"]
