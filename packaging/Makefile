SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

V ?= -vv

export

.PHONY: all alma8 ubuntu2204

all: alma8 ubuntu2004

alma8 ubuntu2004: $(SELF)/main.yml
	ansible-playbook $(V) --limit $@ $^
