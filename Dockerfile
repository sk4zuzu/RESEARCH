FROM alpine

RUN apk --no-cache add tini

ENTRYPOINT ["/sbin/tini", "--"]
