SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

VVV := -vv

export

.PHONY: all apply purge

all: apply

apply: $(SELF)/apply.yml
	cd $(SELF)/ && ansible-playbook $(VVV) $<

purge: $(SELF)/purge.yml
	cd $(SELF)/ && ansible-playbook $(VVV) $<

units:
	cd $(HOME)/ansible_collections/community/general/ && ansible-test units --docker default -v \
	tests/unit/plugins/module_utils/test_opennebula.py \
	tests/unit/plugins/modules/test_one_vm.py

units26:
	cd $(HOME)/ansible_collections/community/general/ && ansible-test units --docker default -v --python 2.6 \
	tests/unit/plugins/module_utils/test_opennebula.py \
	tests/unit/plugins/modules/test_one_vm.py

units38:
	cd $(HOME)/ansible_collections/community/general/ && ansible-test units --docker default -v --python 3.8 \
	tests/unit/plugins/module_utils/test_opennebula.py \
	tests/unit/plugins/modules/test_one_vm.py

sanity:
	cd $(HOME)/ansible_collections/community/general/ && ansible-test sanity --docker default -v

sanity26:
	cd $(HOME)/ansible_collections/community/general/ && ansible-test sanity --test compile --python 2.6

docs:
	cd $(HOME)/ansible_collections/community/general/ && ansible-test sanity --test validate-modules one_vm -v
