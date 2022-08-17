SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

I         ?= $(SELF)/hosts.ini
INVENTORY ?= $(I)

ANSIBLE_STRATEGY_PLUGINS := $(HOME)/_git/mitogen/ansible_mitogen/plugins/strategy
ANSIBLE_STRATEGY         := mitogen_linear

export

.PHONY: all deploy market

all: deploy

deploy: $(INVENTORY) $(SELF)/deploy.yml
	cd $(SELF)/ && ansible-playbook -vv -i $^

market: $(INVENTORY) $(SELF)/market.yml
	cd $(SELF)/ && ansible-playbook -vv -i $^
