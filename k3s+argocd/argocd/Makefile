SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

export

.PHONY: all confirm

all: confirm apply

confirm:
	@: $(eval AUTO_APPROVE := --auto-approve)

COMMAND = apply # default

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

.PHONY: clean

clean:
	-rm -rf $(SELF)/stage*/.terraform/
	-rm -f $(SELF)/stage*/terraform.tfstate*
