FROM alpine:3.16

RUN apk --no-cache add \
    bash \
    curl \
    gzip \
    tar

ARG MAILPIT_VER=1.2.5

RUN curl -fsSL https://github.com/axllent/mailpit/releases/download/$MAILPIT_VER/mailpit-linux-amd64.tar.gz \
  | tar -xz -f- -C /usr/local/bin/ mailpit

ENTRYPOINT []

CMD exec /usr/local/bin/mailpit
