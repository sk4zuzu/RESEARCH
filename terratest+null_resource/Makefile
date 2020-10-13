SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

export

.PHONY: all

all: prereq test

.PHONY: prereq

prereq: needs-go \
        needs-terraform

needs-%:
	@which $*

.PHONY: test

test:
	@cd $(SELF)/ && go test -v
