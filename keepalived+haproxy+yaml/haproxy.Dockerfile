FROM alpine:3.15

RUN apk --no-cache add \
    ruby \
    tini

RUN apk --no-cache add \
    gettext \
    haproxy \
    keepalived

COPY /keepalived.conf.envsubst /tmp/

ARG SUBNET_PREFIX

RUN SUBNET_PREFIX=$SUBNET_PREFIX envsubst '$SUBNET_PREFIX' \
    < /tmp/keepalived.conf.envsubst \
    > /etc/keepalived/keepalived.conf \
 && cat /etc/keepalived/keepalived.conf

COPY /updater.rb /
COPY /haproxy.yml /etc/haproxy/

WORKDIR /

ENTRYPOINT ["/sbin/tini", "--"]

CMD keepalived -f /etc/keepalived/keepalived.conf --dont-fork --log-console \
  & haproxy -f /etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid \
  & ruby ./updater.rb \
  & exec sleep infinity
