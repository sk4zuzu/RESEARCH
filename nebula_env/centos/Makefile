SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

ANSIBLE_STRATEGY_PLUGINS := $(HOME)/_git/mitogen/ansible_mitogen/plugins/strategy
ANSIBLE_STRATEGY         := mitogen_linear

export

.PHONY: all apply

all: apply

apply: $(SELF)/apply.yml $(SELF)/hosts.ini
	cd $(SELF)/ && ansible-playbook -vv $<
