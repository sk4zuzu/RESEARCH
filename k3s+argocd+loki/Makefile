SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

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

.PHONY: grafana-password

grafana-password:
	kubectl -n loki get secret loki-grafana -o jsonpath="{.data.admin-password}" | base64 --decode && echo
