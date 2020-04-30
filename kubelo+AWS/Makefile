
SELF := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

include $(SELF)/Makefile.ENV

AWS_DEFAULT_REGION    ?= $(REGION)
AWS_ACCESS_KEY_ID     ?= $(ACCESS_KEY)
AWS_SECRET_ACCESS_KEY ?= $(SECRET_KEY)

TF_VAR_SG_ALLOWED_ADDRESS ?= $(strip $(shell curl -fs ifconfig.io))/32

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
