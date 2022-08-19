SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

I         ?= $(SELF)/inventory.yml
INVENTORY ?= $(I)

ANSIBLE_STRATEGY_PLUGINS := $(realpath $(SELF)/../../mitogen/ansible_mitogen/plugins/strategy)
ANSIBLE_STRATEGY         := mitogen_linear

export

.PHONY: all

all: research

.PHONY: research

research: $(INVENTORY) $(SELF)/research.yml
	cd $(SELF)/ && ansible-playbook -vv -i $^
