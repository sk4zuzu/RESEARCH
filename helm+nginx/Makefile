
SELF := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

NAME ?= hello

export

.PHONY: all upgrade

all: upgrade

upgrade:
	helm upgrade --install $(NAME) $(SELF)/

# vim:ts=4:sw=4:noet:syn=make:
