FROM alpine:latest

RUN apk update && apk add iptables

COPY rc.iptables /etc/rc.d/rc.iptables

RUN chmod +x /etc/rc.d/rc.iptables

CMD ["tail", "-f", "/dev/null"]
