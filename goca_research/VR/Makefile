SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

export

.PHONY: all run replace

all: run

run: $(SELF)/main.go
	@cd $(SELF)/ && go run $<

replace:
	@go mod edit -replace github.com/OpenNebula/one/src/oca/go/src/goca=$(HOME)/_git/one/src/oca/go/src/goca
