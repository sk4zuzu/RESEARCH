SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

RESTIC_VERSION := 0.14.0
RESTIC_URL     := https://github.com/restic/restic/releases/download/v$(RESTIC_VERSION)/restic_$(RESTIC_VERSION)_linux_amd64.bz2

RESTIC_REPOSITORY ?= sftp:ubuntu@10.2.11.30:/home/ubuntu/_git/asd/var/datastores/100/125/
RESTIC_PASSWORD   ?= asd

export

.PHONY: all

all: $(SELF)/.cache/restic diff23

$(SELF)/.cache/restic:
	@curl -fsSL $(RESTIC_URL) | bzcat | install -D -m a+x /dev/fd/0 $@

.PHONY: scenario1 scenario2 diff12 diff23

scenario1:
	ruby $(SELF)/scenario1.rb

scenario2:
	ruby $(SELF)/scenario2.rb

scenario3:
	ruby $(SELF)/scenario3.rb

diff12:
	diff <(ruby $(SELF)/scenario1.rb) \
	     <(ruby $(SELF)/scenario2.rb)

diff23:
	diff <(ruby $(SELF)/scenario2.rb) \
	     <(ruby $(SELF)/scenario3.rb)

.PHONY: sh

sh:
	env PATH=$(SELF)/.cache:$$PATH PS1='(\u) \w \$$ ' $(SHELL) --norc -i ||:
