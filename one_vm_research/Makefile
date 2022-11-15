SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

VVV := -vv

export

.PHONY: all apply purge

all: apply

apply: $(SELF)/apply.yml
	cd $(SELF)/ && ansible-playbook $(VVV) $<

purge: $(SELF)/purge.yml
	cd $(SELF)/ && ansible-playbook $(VVV) $<
