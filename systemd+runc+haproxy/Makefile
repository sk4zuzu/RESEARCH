
SELF := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

export

.PHONY: all

all:
	ansible-playbook -v main.yml

# vim:ts=4:sw=4:noet:syn=make:
