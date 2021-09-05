SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

KV_VERSION ?= v0.45.0
VC_VERSION ?= v0.45.0
CDI_VERSION ?= v1.40.0
CNAO_VERSION ?= v0.59.0

DOCKER_REGISTRY ?= sk4zuzu

PREREQ := \
$(SELF)/bin/virtctl

export

.PHONY: all confirm

all: $(PREREQ) confirm apply

confirm:
	@: $(eval AUTO_APPROVE := --auto-approve)

.PHONY: init plan apply destroy

COMMAND = apply # default

init: COMMAND = init
init: stage0 stage1 stage2 stage3

plan: COMMAND = plan
plan: stage0 stage1 stage2 stage3

apply: COMMAND = apply
apply: stage0 stage1 stage2 stage3

destroy: COMMAND = destroy
destroy: stage3 stage2 stage1 stage0

.PHONY: stage0 stage1 stage2 stage3

$(SELF)/stage0/manifests/kv/01-kubevirt-operator.yaml:
	install -d $(dir $@)
	curl -fsSLo $@ https://github.com/kubevirt/kubevirt/releases/download/$(KV_VERSION)/kubevirt-operator.yaml

$(SELF)/stage0/manifests/cdi/01-cdi-operator.yaml:
	install -d $(dir $@)
	curl -fsSLo $@ https://github.com/kubevirt/containerized-data-importer/releases/download/$(CDI_VERSION)/cdi-operator.yaml

$(SELF)/stage0/manifests/cnao/01-network-addons-config.crd.yaml:
	install -d $(dir $@)
	curl -fsSLo $@ https://github.com/kubevirt/cluster-network-addons-operator/releases/download/$(CNAO_VERSION)/network-addons-config.crd.yaml

$(SELF)/stage0/manifests/cnao/02-operator.yaml:
	install -d $(dir $@)
	curl -fsSLo $@ https://github.com/kubevirt/cluster-network-addons-operator/releases/download/$(CNAO_VERSION)/operator.yaml

stage0: $(SELF)/stage0/ \
        $(SELF)/stage0/manifests/kv/01-kubevirt-operator.yaml \
        $(SELF)/stage0/manifests/cdi/01-cdi-operator.yaml \
        $(SELF)/stage0/manifests/cnao/01-network-addons-config.crd.yaml \
        $(SELF)/stage0/manifests/cnao/02-operator.yaml
	cd $< && terraform $(COMMAND) $(AUTO_APPROVE)

$(SELF)/stage1/manifests/kv/01-kubevirt-cr.yaml:
	install -d $(dir $@)
	curl -fsSLo $@ https://github.com/kubevirt/kubevirt/releases/download/$(KV_VERSION)/kubevirt-cr.yaml

$(SELF)/stage1/manifests/cdi/01-cdi-cr.yaml:
	install -d $(dir $@)
	curl -fsSLo $@ https://github.com/kubevirt/containerized-data-importer/releases/download/$(CDI_VERSION)/cdi-cr.yaml

stage1: $(SELF)/stage1/ \
        $(SELF)/stage1/manifests/kv/01-kubevirt-cr.yaml \
        $(SELF)/stage1/manifests/cdi/01-cdi-cr.yaml
	cd $< && terraform $(COMMAND) $(AUTO_APPROVE)

stage2: $(SELF)/stage2/
	cd $< && terraform $(COMMAND) $(AUTO_APPROVE)

stage3: $(SELF)/stage3/
	cd $(SELF)/images/ && make
	cd $< && terraform $(COMMAND) $(AUTO_APPROVE)

.PHONY: images

images: $(SELF)/images/k3s-alpine.Dockerfile
	docker build -t $(DOCKER_REGISTRY)/k3s-alpine:latest -f $< $(dir $<)
	docker push $(DOCKER_REGISTRY)/k3s-alpine:latest

.PHONY: clean

clean:
	-rm -rf $(SELF)/stage*/.terraform/
	-rm -f $(SELF)/stage*/terraform.tfstate*

$(SELF)/bin/virtctl: $(SELF)/bin/virtctl-$(VC_VERSION)
	rm -f $@ && ln -s $< $@

$(SELF)/bin/virtctl-$(VC_VERSION):
	curl -fsSLo $@ https://github.com/kubevirt/kubevirt/releases/download/$(VC_VERSION)/virtctl-$(VC_VERSION)-linux-amd64
	chmod +x $@
