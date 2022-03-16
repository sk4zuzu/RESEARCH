SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

API_HOST    ?= delta
CREDENTIALS ?= oneadmin:asd

export

.PHONY: all

all: rubocop rspec

.PHONY: rspec rubocop ruby

rspec: $(SELF)/apply.rb
	$@ $<

rubocop: $(SELF)/apply.rb
	-$@ $<

ruby: $(SELF)/apply.rb
	$@ $< $(API_HOST) $(CREDENTIALS)
