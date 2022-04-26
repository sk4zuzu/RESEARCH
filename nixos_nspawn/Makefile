SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

ANSIBLE_STRATEGY_PLUGINS := $(HOME)/_git/mitogen/ansible_mitogen/plugins/strategy
ANSIBLE_STRATEGY         := mitogen_linear

export

.PHONY: all deploy

all: deploy

deploy: $(SELF)/hosts.ini $(SELF)/deploy.yml
	cd $(SELF)/ && ansible-playbook -vv -i $^
