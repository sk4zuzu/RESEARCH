SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

export

.PHONY: all

all: apply

.PHONY: plan apply destroy init refresh

init:
	terraform $@

plan apply destroy: init
	terraform $@

.PHONY: ssh

ssh:
	$(shell terraform output _ssh)
