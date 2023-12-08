SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

GOPATH := $(SELF)/go/

LOCAL_GIT      := $(SELF)/../../terraform-provider-opennebula/
LOCAL_VERSION  := 1.3.1
LOCAL_PLUGINS  := $(SELF)/terraform.d/plugins/terraform.local/local/
LOCAL_PROVIDER := $(LOCAL_PLUGINS)/opennebula/$(LOCAL_VERSION)/linux_amd64/terraform-provider-opennebula_v$(LOCAL_VERSION)_x1

export

.PHONY: all

all: apply

.PHONY: plan apply destroy init

init:
	terraform $@

plan apply destroy: init
	terraform $@

.PHONY: purge build

purge:
	-rm -r $(SELF)/.terraform/
	-rm $(SELF)/.terraform.lock.hcl

build: purge
	cd $(LOCAL_GIT)/ && make build
	install -m u=rwx,go= -D $(GOPATH)/bin/terraform-provider-opennebula $(LOCAL_PROVIDER)
