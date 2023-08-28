FROM alpine:3.17

RUN apk --no-cache add \
    ruby \
    tini

RUN gem install \
    webrick

WORKDIR /var/tmp/

ENTRYPOINT ["/sbin/tini", "--"]

CMD hostname -f > index.html && exec ruby -run -e httpd . -p 8000
