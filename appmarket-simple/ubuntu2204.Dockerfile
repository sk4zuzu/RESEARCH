FROM docker.io/library/ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y \
 && apt-get install -y \
    mc \
    vim \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update -y \
 && apt-get install -y \
    gcc git \
    make \
    ruby-bundler ruby-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/marketplace/

RUN git clone https://github.com/OpenNebula/marketplace.git .

WORKDIR /tmp/appmarket-simple/

RUN git clone https://github.com/OpenNebula/appmarket-simple.git .

WORKDIR /tmp/appmarket-simple/src/

RUN ln -s ../../marketplace/ data \
 && ln -s ../data/logos public/logos

RUN (bundle update --bundler ||:) \
 && bundle update \
 && bundle add webrick

ENTRYPOINT []

CMD exec bundler exec rackup -o 0.0.0.0
