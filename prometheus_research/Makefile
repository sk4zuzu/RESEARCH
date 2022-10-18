SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

include $(SELF)/.env

export

.PHONY: all

all: up

.PHONY: up

up: $(SELF)/docker-compose.yml
	docker-compose -f $< up --build

.PHONY: down

down: $(SELF)/docker-compose.yml
	-docker-compose -f $< down --volumes --remove-orphans

.PHONY: ps

ps: $(SELF)/docker-compose.yml
	docker-compose -f $< ps
