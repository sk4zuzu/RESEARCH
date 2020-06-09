
SELF := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

export

.PHONY: all

all:
	python3 $(SELF)/main.py

# vim:ts=4:sw=4:noet:syn=make:
