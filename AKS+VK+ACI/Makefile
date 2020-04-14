
SELF := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

include $(SELF)/Makefile.ENV

export

.PHONY: all

all:

.PHONY: binaries storage

binaries:
	make -f Makefile.BINARIES

storage:
	make -f Makefile.STORAGE

.PHONY: confirm yes

confirm: yes
yes:
	@: $(eval AUTO_APPROVE := --auto-approve)

.PHONY: apply-aks1

apply-aks1:
	cd $(SELF)/LIVE/aks1/ && rm -rf .terragrunt-cache/
	cd $(SELF)/LIVE/aks1/ && terragrunt apply $(AUTO_APPROVE)
	cd $(SELF)/LIVE/aks1/ && terragrunt output kubeconfig >kubeconfig.yml

.PHONY: destroy-aks1

destroy-aks1:
	cd $(SELF)/LIVE/aks1/ && rm -rf .terragrunt-cache/
	cd $(SELF)/LIVE/aks1/ && terragrunt destroy $(AUTO_APPROVE)
	cd $(SELF)/LIVE/aks1/ && rm -f kubeconfig.yml

.PHONY: kubeconfig-aks1

kubeconfig-aks1:
	@echo export KUBECONFIG=$(SELF)/LIVE/aks1/kubeconfig.yml

# vim:ts=4:sw=4:noet:syn=make:
