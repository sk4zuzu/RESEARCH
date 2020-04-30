
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

.PHONY: apply-asg1

apply-asg1:
	cd $(SELF)/LIVE/asg1/ && rm -rf .terragrunt-cache/
	cd $(SELF)/LIVE/asg1/ && terragrunt apply $(AUTO_APPROVE)

.PHONY: destroy-asg1

destroy-asg1:
	cd $(SELF)/LIVE/asg1/ && rm -rf .terragrunt-cache/
	cd $(SELF)/LIVE/asg1/ && terragrunt destroy $(AUTO_APPROVE)

# vim:ts=4:sw=4:noet:syn=make:
