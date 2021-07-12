SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

GOPATH := $(SELF)/.cache/go

export

.PHONY: all confirm

all: confirm apply

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

.PHONY: vk virtual-kubelet

vk virtual-kubelet: $(SELF)/stage0/virtual-kubelet

$(SELF)/.cache/virtual-kubelet/nomad/:
	install -d $@
	cd $@ && git clone --branch=master https://github.com/virtual-kubelet/nomad.git .

$(SELF)/stage0/virtual-kubelet: $(SELF)/.cache/virtual-kubelet/nomad/
	install -d $(GOPATH)/
	nix-shell --command "cd $< && exec make build"
	cp -f $</bin/$(notdir $@) $@
