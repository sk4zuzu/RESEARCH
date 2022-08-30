SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

TF_VAR_plan     ?= c3.medium.x86
TF_VAR_quantity ?= 3

AMER := dc13 iad1 da11 dfw2 sv15 sv16 sjc1 sp4 ch3 ny5 ny7 ewr1 la4 tr2 se4 sea1
EMEA := am6 ams1 fr2 ld7 md2 pa4
APAC := sg1 sg4 sin3 sy4 syd2 hk2 hkg1 sl1 ty11 nrt1

define CAPACITY_TEST
$(1): $(wildcard $(SELF)/*.tf) $(wildcard/*.tfvars)
	terraform init &> /dev/null
	@-TF_VAR_facility='$(1)' terraform apply --auto-approve

endef

export

.PHONY: all amer emea apac $(AMER) $(EMEA) $(APAC)

all: amer emea apac

amer: $(AMER)

emea: $(EMEA)

apac: $(APAC)

$(eval \
	$(foreach facility,$(AMER),$(call CAPACITY_TEST,$(facility))))

$(eval \
	$(foreach facility,$(EMEA),$(call CAPACITY_TEST,$(facility))))

$(eval \
	$(foreach facility,$(APAC),$(call CAPACITY_TEST,$(facility))))
