SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

VIRTCTL_VERSION ?= v0.43.0
KUBECTL_VERSION ?= v1.19.10

TARGETS := \
$(SELF)/bin/kubectl \
$(SELF)/bin/virtctl

define GITHUB_RELEASE_INSTALL
$(SELF)/bin/$(2): $(SELF)/bin/$(2)-$(3)
	rm -f $$@ && ln -s $$< $$@
$(SELF)/bin/$(2)-$(3):
	curl -fSL https://github.com/$(1)/$(1)/releases/download/$(3)/$(2)-$(3)-linux-amd64 \
	     -o $$@ \
	&& chmod +x $$@
endef

define KUBERNETES_RELEASE_INSTALL
$(SELF)/bin/$(1): $(SELF)/bin/$(1)-$(2)
	rm -f $$@ && ln -s $$< $$@
$(SELF)/bin/$(1)-$(2):
	curl -fSL https://storage.googleapis.com/kubernetes-release/release/$(2)/bin/linux/amd64/$(1) \
	     -o $$@ \
	&& chmod +x $$@
endef

export

.PHONY: all confirm

all: $(TARGETS) confirm apply

confirm:
	@: $(eval AUTO_APPROVE := --auto-approve)

.PHONY: init plan apply destroy

init: COMMAND = init
init: stage0 stage1

plan: COMMAND = plan
plan: stage0 stage1

apply: COMMAND = apply
apply: stage0 stage1

destroy: COMMAND = destroy
destroy: stage1 stage0

.PHONY: stage0 stage1

stage0: $(SELF)/stage0/
	cd $< && terraform $(COMMAND) $(AUTO_APPROVE)

stage1: $(SELF)/stage1/
	cd $< && terraform $(COMMAND) $(AUTO_APPROVE)

.PHONY: clean

clean:
	-rm -rf $(SELF)/stage*/.terraform/
	-rm -f $(SELF)/stage*/terraform.tfstate*

$(eval \
	$(call GITHUB_RELEASE_INSTALL,kubevirt,virtctl,$(VIRTCTL_VERSION)))

$(eval \
	$(call KUBERNETES_RELEASE_INSTALL,kubectl,$(KUBECTL_VERSION)))
