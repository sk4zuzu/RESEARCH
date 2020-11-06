TARGETS = install servers nodes nginx

.PHONY: all

all:
	ansible-playbook -vv main.yml

.PHONY: $(TARGETS)

$(TARGETS):
	ansible-playbook -vv main.yml --tags $@
