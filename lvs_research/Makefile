SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

ANSIBLE_STRATEGY_PLUGINS := $(HOME)/_git/mitogen/ansible_mitogen/plugins/strategy
ANSIBLE_STRATEGY         := mitogen_linear

SSH_OPTIONS := -o ForwardAgent=yes \
               -o StrictHostKeyChecking=no \
               -o GlobalKnownHostsFile=/dev/null \
               -o UserKnownHostsFile=/dev/null
export

.PHONY: all apply disk

all: c1-apply s1-apply s2-apply apply

apply: $(SELF)/hosts.ini $(SELF)/apply.yml
	cd $(SELF)/ && ansible-playbook -vv -i $^

disk:
	@cd $(SELF)/packer/ && make build

.PHONY: i1-apply i1-destroy

i1-apply: disk
	@cd $(SELF)/terraform/i1/ && terraform init && terraform apply --auto-approve

i1-destroy: d1-destroy
	@cd $(SELF)/terraform/i1/ && terraform init && terraform destroy --auto-approve

.PHONY: d1-apply d1-destroy

d1-apply: disk i1-apply
	@cd $(SELF)/terraform/d1/ && terraform init && terraform apply --auto-approve

d1-destroy: c1-destroy s1-destroy s2-destroy
	@cd $(SELF)/terraform/d1/ && terraform init && terraform destroy --auto-approve

.PHONY: c1-apply c1-destroy

c1-apply: disk d1-apply
	@cd $(SELF)/terraform/c1/ && terraform init && terraform apply --auto-approve

c1-destroy:
	@cd $(SELF)/terraform/c1/ && terraform init && terraform destroy --auto-approve

.PHONY: s1-apply s1-destroy

s1-apply: disk d1-apply
	@cd $(SELF)/terraform/s1/ && terraform init && terraform apply --auto-approve

s1-destroy:
	@cd $(SELF)/terraform/s1/ && terraform init && terraform destroy --auto-approve

.PHONY: s2-apply s2-destroy

s2-apply: disk d1-apply
	@cd $(SELF)/terraform/s2/ && terraform init && terraform apply --auto-approve

s2-destroy:
	@cd $(SELF)/terraform/s2/ && terraform init && terraform destroy --auto-approve

.PHONY: i1-ssh d1-ssh c1-ssh s1-ssh s2-ssh

i1-ssh:
	@ssh $(SSH_OPTIONS) alpine@10.11.12.13

d1-ssh:
	@ssh $(SSH_OPTIONS) alpine@10.11.12.13 -t ssh $(SSH_OPTIONS) alpine@172.16.1.10

c1-ssh:
	@ssh $(SSH_OPTIONS) alpine@10.11.12.13 -t ssh $(SSH_OPTIONS) alpine@172.16.1.11

s1-ssh:
	@ssh $(SSH_OPTIONS) alpine@10.11.12.13 -t ssh $(SSH_OPTIONS) alpine@172.16.1.12

s2-ssh:
	@ssh $(SSH_OPTIONS) alpine@10.11.12.13 -t ssh $(SSH_OPTIONS) alpine@172.16.1.13
