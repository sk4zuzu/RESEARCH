SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

SSH_OPTIONS := -o ForwardAgent=yes \
               -o StrictHostKeyChecking=no \
               -o GlobalKnownHostsFile=/dev/null \
               -o UserKnownHostsFile=/dev/null
export

.PHONY: all disk

all: apply

disk:
	@cd $(SELF)/packer/ && make build

.PHONY: apply destroy

apply: disk
	@cd $(SELF)/terraform/ && terraform init && terraform apply --auto-approve

destroy:
	@cd $(SELF)/terraform/ && terraform init && terraform destroy --auto-approve

.PHONY: ssh

ssh:
	@ssh $(SSH_OPTIONS) ubuntu@10.11.12.13
