
SELF := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

export

.PHONY: all

all: server client

.PHONY: server client

server:
	ansible-playbook -v server.yml

client:
	ansible-playbook -v client.yml

# vim:ts=4:sw=4:noet:syn=make:
