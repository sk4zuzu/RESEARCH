.PHONY: all

all: $(basename $(wildcard test*.yml))

test%:
	ansible-playbook -vv $@.yml
