FROM docker.io/library/almalinux:8

RUN yum install -y \
    mc \
    vim \
 && yum clean -y all

RUN yum install -y \
    gcc git \
    make \
    redhat-rpm-config ruby-devel rubygem-bundler \
 && yum clean -y all

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
