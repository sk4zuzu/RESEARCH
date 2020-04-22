
SELF   := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
PARENT := $(abspath $(SELF)/../)

include $(SELF)/../Makefile.ENV

NAME  ?= kubelo-azure
IMAGE ?= $(IMAGE_REGISTRY)/$(NAME)

define DOCKERFILE
FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -q update \
 && : INSTALL EXTRA APT PACKAGES \
 && apt-get install -y \
    htop \
    mc \
    vim \
 && : CLEANUP APT CACHE \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get -q update \
 && : INSTALL APT PACKAGES \
 && apt-get install -y \
    bash \
    curl \
    git \
    gzip \
    make \
    python3 \
    python3-pip \
	rsync \
    tar \
    unzip \
 && : CLEANUP APT CACHE \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /kubelo+Azure/

COPY Makefile.BINARIES /kubelo+Azure/

ENV _GOPATH_=/usr/local

RUN : INSTALL BINARY REQUIREMENTS \
 && make -f Makefile.BINARIES

COPY . /kubelo+Azure/

ENTRYPOINT []

CMD : RECONSTRUCT STATIC CONFIG \
 && make files \
 && : LOGIN TO AZURE \
 && make login \
 && : FETCH TERRAFORM CONFIG \
 && make config \
 && : EXECUTE PYTHON APPLICATION \
 && python/autoscaler.py
endef

export

.PHONY: all

all: build

.PHONY: no-cache build

no-cache:
	@: $(eval NO_CACHE := --no-cache)

build:
	docker build $(NO_CACHE) -t $(IMAGE) -f- $(PARENT) <<< "$$DOCKERFILE"

.PHONY: push

push:
	docker push $(IMAGE)

.PHONY: run

run:
	docker run --rm -it $(IMAGE) /bin/bash

# vim:ts=4:sw=4:noet:syn=make:
