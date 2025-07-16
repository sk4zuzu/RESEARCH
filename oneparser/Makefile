SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

export

.PHONY: all test

all: test

test:
	rspec $(SELF)/tests.rb
