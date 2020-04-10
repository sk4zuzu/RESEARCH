
FROM golang:1.14-alpine3.11 as build

COPY . /self/

RUN cd /self/cmd/cpuhog/ && go build

FROM alpine:3.11

RUN apk --no-cache add curl htop

COPY --from=build /self/cmd/cpuhog/cpuhog /usr/local/bin/

CMD cpuhog

# vim:ts=2:sw=2:et:syn=dockerfile:
