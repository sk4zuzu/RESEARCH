SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

export

.PHONY: all confirm

all: confirm apply

confirm:
	@: $(eval AUTO_APPROVE := --auto-approve)

.PHONY: init plan apply destroy

init: COMMAND = init
init: stage0 stage1 stage2

plan: COMMAND = plan
plan: stage0 stage1 stage2

apply: COMMAND = apply
apply: stage0 stage1 stage2

destroy: COMMAND = destroy
destroy: stage2 stage1 stage0

.PHONY: stage0 stage1 stage2

stage0: $(SELF)/stage0/
	cd $< && terraform $(COMMAND) $(AUTO_APPROVE)

stage1: $(SELF)/stage1/
	cd $< && terraform $(COMMAND) $(AUTO_APPROVE)

stage2: $(SELF)/stage2/
	cd $< && terraform $(COMMAND) $(AUTO_APPROVE)

.PHONY: clean

clean:
	-rm -rf $(SELF)/stage*/.terraform/
	-rm -f $(SELF)/stage*/terraform.tfstate*

.PHONY: elastic-password

elastic-password:
	@kubectl -n eck get secret/elasticsearch-es-elastic-user -o jsonpath='{.data.elastic}' | base64 --decode && echo
