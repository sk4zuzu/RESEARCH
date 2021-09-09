SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

DRY_RUN ?= client # set it to "none" if you want to really update

export

.PHONY: all update check

all: update

update: $(SELF)/update-coredns-add-consul.sh
	$(SHELL) $<

check: $(wildcard $(SELF)/*.sh)
	shellcheck $^
