
SELF := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

-include $(SELF)/Makefile.ENV

# terraform variables
ARM_SUBSCRIPTION_ID ?= $(SUBSCRIPTION_ID)
ARM_CLIENT_ID       ?= $(CLIENT_ID)
ARM_CLIENT_SECRET   ?= $(CLIENT_SECRET)
ARM_TENANT_ID       ?= $(TENANT_ID)

export

.PHONY: all

all:

.PHONY: files makefile_env id_rsa id_rsa_pub

files: makefile_env id_rsa id_rsa_pub

makefile_env:
	echo "$$MAKEFILE_ENV" | tee $(SELF)/Makefile.ENV

id_rsa:
	install -m u=rwx,go= -d $(HOME)/.ssh/
	echo "$$ID_RSA" | tee $(HOME)/.ssh/id_rsa
	chmod u=rw,go= $(HOME)/.ssh/id_rsa

id_rsa_pub:
	install -m u=rwx,go= -d $(HOME)/.ssh/
	echo "$$ID_RSA_PUB" | tee $(HOME)/.ssh/id_rsa.pub
	chmod u=rw,go= $(HOME)/.ssh/id_rsa.pub

.PHONY: login config

login:
	az login --service-principal --username $(CLIENT_ID) --password $(CLIENT_SECRET) --tenant $(TENANT_ID)

config:
	make -f Makefile.STORAGE download_config

.PHONY: binaries storage

binaries:
	make -f Makefile.BINARIES

storage:
	make -f Makefile.STORAGE

.PHONY: confirm yes

confirm: yes
yes:
	@: $(eval AUTO_APPROVE := --auto-approve)

.PHONY: kubelo-docker

kubelo-docker:
	cd $(SELF)/docker/ && make build push NAME=kubelo-azure

.PHONY: kubelo-disk

kubelo-disk:
	cd $(SELF)/packer/ && make build NAME=kubelo

.PHONY: apply-kub1

apply-kub1:
	cd $(SELF)/LIVE/kub1/ && rm -rf .terragrunt-cache/
	cd $(SELF)/LIVE/kub1/ && terragrunt apply $(AUTO_APPROVE)

.PHONY: destroy-kub1

destroy-kub1:
	cd $(SELF)/LIVE/kub1/ && rm -rf .terragrunt-cache/
	cd $(SELF)/LIVE/kub1/ && terragrunt destroy $(AUTO_APPROVE)

# vim:ts=4:sw=4:noet:syn=make:
