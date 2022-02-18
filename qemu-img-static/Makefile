SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

QEMU_VERSION := 6.0.1

HOST_UID := $(shell id -u)
HOST_GID := $(shell id -g)

export

.PHONY: all build debug extract

all: extract

build: $(SELF)/Dockerfile
	docker build -t qemu-img-static \
	--build-arg QEMU_VERSION=$(QEMU_VERSION) \
	-f $< \
	.

debug: $(SELF)/Dockerfile build
	docker run --rm -it qemu-img-static

extract: $(SELF)/Dockerfile build
	docker run --rm \
	-v $(SELF)/.out:/.out/ \
	--rm -it qemu-img-static \
	install -m u=rwx,go=rx -o $(HOST_UID) -g $(HOST_GID) \
	/opt/qemu-$(QEMU_VERSION)/build/qemu-img \
	/.out/
