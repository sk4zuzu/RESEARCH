SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

VAULT ?= http://vault.vault.svc

FQDN ?= asd.default.svc.cluster.local
BITS ?= 2048
DAYS ?= 2048

define STDIN1
PL
.
.
.
.
$(FQDN)
.
.
.
endef

define CSR_CNF
[req]
default_bits = $(BITS)
prompt = no
default_md = sha256
distinguished_name = dn
[dn]
C = PL
CN = $(FQDN)
endef

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

.PHONY: sign1

sign1: $(SELF)/.cache/$(FQDN).csr $(SELF)/.cache/$(FQDN).csr.json
	openssl req -text -noout -verify -in $(word 1,$^)
	curl \
	  --header "X-Vault-Token: root" \
	  --request POST \
	  --data "@$(word 2,$^)" \
	  $(VAULT)/v1/pki_int/sign/svc-dot-cluster-dot-local

$(SELF)/.cache/$(FQDN).csr.json: $(SELF)/.cache/$(FQDN).csr
	install -d $(SELF)/.cache/
	jq -n --arg csr "`cat $<`" '{"csr": $$csr}' | tee $@

$(SELF)/.cache/$(FQDN).csr: $(SELF)/.cache/$(FQDN).key $(SELF)/.cache/$(FQDN).csr.cnf
	install -d $(SELF)/.cache/
	openssl req -new -key $(word 1,$^) -config $(word 2,$^) -out $@ <<< "$$STDIN1"

$(SELF)/.cache/$(FQDN).key:
	install -d $(SELF)/.cache/
	openssl genrsa -out $@ 2048

$(SELF)/.cache/$(FQDN).csr.cnf:
	install -d $(SELF)/.cache/
	tee $@ <<< "$$CSR_CNF"
