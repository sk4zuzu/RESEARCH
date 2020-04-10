
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

.PHONY: apply-env1

apply-env1:
	cd $(SELF)/LIVE/env1/ && rm -rf .terragrunt-cache/
	cd $(SELF)/LIVE/env1/ && terragrunt apply $(AUTO_APPROVE)
	cd $(SELF)/LIVE/env1/ && terragrunt output kubeconfig >kubeconfig.yml

.PHONY: destroy-env1

destroy-env1:
	cd $(SELF)/LIVE/env1/ && rm -rf .terragrunt-cache/
	cd $(SELF)/LIVE/env1/ && terragrunt destroy $(AUTO_APPROVE)
	cd $(SELF)/LIVE/env1/ && rm -f kubeconfig.yml

.PHONY: kubeconfig-env1

kubeconfig-env1:
	@echo export KUBECONFIG=$(SELF)/LIVE/env1/kubeconfig.yml

# vim:ts=4:sw=4:noet:syn=make:
