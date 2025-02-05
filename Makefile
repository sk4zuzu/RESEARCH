SELF := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

.PHONY: all

all:
