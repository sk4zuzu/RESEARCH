
SELF := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

export

.PHONY: all

all: deploy

.PHONY: deploy

deploy: deploy-1.14.6

deploy-%:
	ansible-playbook --tags deploy -e KUBERNETES_VERSION=$* -vv deploy.yml

.PHONY: upgrade

upgrade:
	ansible-playbook --tags upgrade -vv upgrade.yml

.PHONY: prereq

prereq:
	ansible-playbook --tags prereq -vv deploy.yml upgrade.yml

.PHONY: example

example:
	ansible-playbook -vv example.yml

# vim:ts=4:sw=4:noet:syn=make:
