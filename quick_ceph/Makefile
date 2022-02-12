SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

BRANCH := stable-6.0
VVV    := -vv

export

.PHONY: all ceph setup

all: ceph setup

ceph: $(SELF)/ceph.ini ceph-ansible
	nix-shell --run 'cd $(SELF)/.cache/ceph-ansible/ && unset ANSIBLE_LIBRARY && ansible-playbook $(VVV) -i $< site.yml.sample'

setup: $(wildcard $(SELF)/*.ini)
	nix-shell --run 'cd $(SELF)/ && ansible-playbook $(VVV) $(foreach ini,$^,-i $(ini)) setup.yml'

.PHONY: ceph-ansible

ceph-ansible:
	install -d $(SELF)/.cache/ceph-ansible/
	cd $(SELF)/.cache/ceph-ansible/ && git clone --branch=$(BRANCH) https://github.com/ceph/ceph-ansible.git . || ( \
		git fetch origin $(BRANCH) \
		&& git clean -df \
		&& git checkout . \
		&& git checkout $(BRANCH) \
		&& git reset --hard $(BRANCH) \
	)

.PHONY: clean

clean:
	-rm -rf $(SELF)/.cache/
