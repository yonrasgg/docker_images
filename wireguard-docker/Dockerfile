FROM alpine:latest

RUN apk add -U wireguard-tools

COPY generate_config.sh /usr/local/bin/

CMD ["generate_config.sh", "wg-quick", "up", "wg0"]
