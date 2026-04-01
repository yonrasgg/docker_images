FROM alpine:latest

RUN apk --no-cache add curl s6

RUN curl -LO https://github.com/linuxserver/Heimdall/archive/refs/tags/v2.5.6.zip && \
    unzip v2.5.6.zip && \
    rm v2.5.6.zip

RUN mkdir -p /etc/s6.d/heimdall

COPY heimdall.run /etc/s6.d/heimdall/run
RUN chmod +x /etc/s6.d/heimdall/run

CMD ["s6-svscan", "/etc/s6.d"]
