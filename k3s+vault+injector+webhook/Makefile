SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

export

.PHONY: all confirm

all: confirm apply

confirm:
	@: $(eval AUTO_APPROVE := --auto-approve)

.PHONY: init plan apply destroy

init: COMMAND = init
init: stage0

plan: COMMAND = plan
plan: stage0

apply: COMMAND = apply
apply: stage0

destroy: COMMAND = destroy
destroy: stage0

.PHONY: stage0

stage0: $(SELF)/stage0/
	cd $< && terraform $(COMMAND) $(AUTO_APPROVE)
