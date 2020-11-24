SELF := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

export

.PHONY: all

all:
	cd $(SELF)/ && python3 main.py

.PHONY: poetry shell

poetry:
	pip3 --no-cache-dir install poetry

shell:
	cd $(SELF)/ && poetry shell
