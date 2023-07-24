SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

I         ?= $(SELF)/inventory/hosts.yml
INVENTORY ?= $(I)

export

.PHONY: all deploy market

all: deploy

deploy: $(INVENTORY) $(SELF)/deploy.yml
	cd $(SELF)/ && ansible-playbook -vv -i $^

market: $(INVENTORY) $(SELF)/market.yml
	cd $(SELF)/ && ansible-playbook -vv -i $^

.PHONY: ssh

ssh: SSH_OPTS := -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
ssh: $(INVENTORY)
	cd $(SELF)/ && ssh $(SSH_OPTS) \
	-o User=$$(yq .all.vars.ansible_user $<) \
	$$(yq .ubuntu.hosts.ubuntu1.ansible_host $<)
