SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

GOPATH := $(SELF)/go/

GOCA_GIT     := $(HOME)/one-ee/src/oca/go/src/goca
PROVIDER_GIT := $(HOME)/terraform-provider-opennebula/

LOCAL_PLUGINS  := $(SELF)/terraform.d/plugins/terraform.local/local/
LOCAL_PROVIDER := $(LOCAL_PLUGINS)/opennebula/0.0.1/linux_amd64/terraform-provider-opennebula_v0.0.1_x1

export

.PHONY: all

all:

.PHONY: build-provider

build-provider:
	cd $(PROVIDER_GIT)/ && go mod edit -replace github.com/OpenNebula/one/src/oca/go/src/goca=$(GOCA_GIT)
	cd $(PROVIDER_GIT)/ && go mod tidy
	cd $(PROVIDER_GIT)/ && make build
	install -m u=rwx,go= -D $(GOPATH)/bin/terraform-provider-opennebula $(LOCAL_PROVIDER)
	rm -f $(SELF)/.terraform.lock.hcl

.PHONY: init plan apply destroy

init plan:
	terraform $@

apply destroy: TF_LOG ?= INFO
apply destroy: init
	terraform $@ --auto-approve
