SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

export

.PHONY: all

all: apply

.PHONY: plan apply destroy init refresh

init:
	terraform $@

plan apply destroy: init
	terraform $@

refresh: refresh-epiphany-offline refresh-epiphany apply

.PHONY: refresh-epiphany-offline refresh-epiphany

refresh-epiphany-offline:
	-terraform state rm 'null_resource.epicli-clone-epiphany-offline'

refresh-epiphany:
	-terraform state rm 'null_resource.epicli-clone-epiphany'

.PHONY: ssh

ssh:
	$(shell terraform output _ssh)
