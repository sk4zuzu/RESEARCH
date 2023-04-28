SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

SUDO ?= doas

PROOT_URL  := https://gitlab.com/proot/proot/-/jobs/2370229665/artifacts/download?file_type=archive
UBUNTU_URL := https://cloud-images.ubuntu.com/minimal/releases/jammy/release-20230209/ubuntu-22.04-minimal-cloudimg-amd64-root.tar.xz

export

.PHONY: all

all: proot1

.PHONY: proot1

proot1: $(SELF)/.cache/proot $(SELF)/.cache/proot1/
	$(word 1,$^) -r $(word 2,$^) -w / /bin/uname -a

$(SELF)/.cache/proot:
	curl -fsSL '$(PROOT_URL)' | install -m u=rw,go= -D /dev/fd/0 $@.zip
	unzip -p $@.zip dist/proot | install -m u=rwx,go=rx -D /dev/fd/0 $@
	rm -f $@.zip

$(SELF)/.cache/proot1/: $(SELF)/.cache/ubuntu.tar.xz
	install -d $@
	$(SUDO) tar -xf $< -C $@

$(SELF)/.cache/ubuntu.tar.xz:
	curl -fsSL '$(UBUNTU_URL)' | install -m u=rw,go= -D /dev/fd/0 $@
