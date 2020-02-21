FROM alpine:latest

RUN set -xe \
    && apk add --no-cache strongswan sudo bash

COPY entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh

COPY ipsec-vti.sh /var/lib/strongswan/ipsec-vti.sh
RUN chmod 0755 /var/lib/strongswan/ipsec-vti.sh

RUN echo 'ipsec ALL=NOPASSWD:SETENV:/usr/sbin/ipsec,/sbin/ip,/sbin/sysctl' > /etc/sudoers.d/ipsec
RUN chmod 0440 /etc/sudoers.d/ipsec

EXPOSE 500/udp 4500/udp

ENTRYPOINT ["/entrypoint.sh"]