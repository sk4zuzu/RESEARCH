SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

#ANSIBLE_STRATEGY_PLUGINS := $(HOME)/_git/mitogen/ansible_mitogen/plugins/strategy
#ANSIBLE_STRATEGY         := mitogen_linear

export

.PHONY: all solo nspawn raft apache2

all: solo

solo: $(SELF)/hosts.ini $(SELF)/solo.yml $(SELF)/prometheus.yml #$(SELF)/onegate.yml
	cd $(SELF)/ && ansible-playbook -vv -i $^

nspawn: $(SELF)/nspawn.ini $(SELF)/solo.yml $(SELF)/apache2.yml $(SELF)/market.yml $(SELF)/dnsmasq.yml #$(SELF)/microenvs.yml
	cd $(SELF)/ && ansible-playbook -vv -i $^

restic: $(SELF)/nspawn.ini $(SELF)/restic.yml
	cd $(SELF)/ && ansible-playbook -vv -i $^

equinix: $(SELF)/equinix.ini $(SELF)/solo.yml $(SELF)/apache2.yml $(SELF)/market.yml
	cd $(SELF)/ && ansible-playbook -vv -i $^

raft: $(SELF)/hosts.ini $(SELF)/raft.yml
	cd $(SELF)/ && ansible-playbook -vv -i $^

apache2: $(SELF)/hosts.ini $(SELF)/apache2.yml
	cd $(SELF)/ && ansible-playbook -vv -i $^
