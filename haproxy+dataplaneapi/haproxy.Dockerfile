FROM alpine:3.17

RUN apk --no-cache add curl haproxy

ENV DATAPLANEAPI_VERSION=2.8.1

WORKDIR /tmp/

RUN curl -fsSL https://github.com/haproxytech/dataplaneapi/releases/download/v${DATAPLANEAPI_VERSION}/dataplaneapi_${DATAPLANEAPI_VERSION}_linux_x86_64.tar.gz \
  | tar -xzf- -C /usr/local/bin/ dataplaneapi

COPY /*.cfg /dataplaneapi.yml /etc/haproxy/

WORKDIR /

ENTRYPOINT []

CMD exec haproxy -f /etc/haproxy/haproxy.cfg
