SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

XML_RPC_URL ?= http://delta:2633/RPC2
CREDENTIALS ?= oneadmin:asd

export

.PHONY: all

all: rubocop rspec

.PHONY:	rspec rubocop ruby

rspec: $(SELF)/apply.rb
	$@ $<

rubocop: $(SELF)/apply.rb
	-$@ $<

ruby: $(SELF)/apply.rb
	$@ $< $(XML_RPC_URL) $(CREDENTIALS)
