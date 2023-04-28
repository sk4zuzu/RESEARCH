SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

I         ?= $(SELF)/hosts.ini
INVENTORY ?= $(I)

export

.PHONY: all deploy market

all: deploy

deploy: $(INVENTORY) $(SELF)/deploy.yml
	cd $(SELF)/ && ansible-playbook -vv -i $^

market: $(INVENTORY) $(SELF)/market.yml
	cd $(SELF)/ && ansible-playbook -vv -i $^
