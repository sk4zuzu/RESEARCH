SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

export

.PHONY: all up down purge

all: up

up: $(SELF)/docker-compose.yml
	docker-compose -f $< up

down: $(SELF)/docker-compose.yml
	-docker-compose -f $< down --remove-orphans

purge: $(SELF)/docker-compose.yml
	-docker-compose -f $< down --remove-orphans --volumes
