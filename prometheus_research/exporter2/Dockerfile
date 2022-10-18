FROM ruby:3.1.2-alpine3.16

RUN apk --no-cache add \
    bash

RUN gem install --no-document \
    prometheus-client \
    sinatra \
    webrick

COPY /exporter2.rb /

ENTRYPOINT []

CMD exec ruby /exporter2.rb
