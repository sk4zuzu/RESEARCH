SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

include $(SELF)/.env

COMPOSE_FILES ?= docker-compose.yml

DC = docker-compose $(foreach item,$(1),--file $(item))

.PHONY: all

all: up

.PHONY: up_no_logs logs up down purge ps

up_no_logs: $(COMPOSE_FILES)
	@$(call DC,$^) up --build --detach

logs: $(COMPOSE_FILES)
	@$(call DC,$^) logs --follow

up: up_no_logs logs

down: $(COMPOSE_FILES)
	@$(call DC,$^) down

purge: $(COMPOSE_FILES)
	@$(call DC,$^) down --volumes

ps: $(COMPOSE_FILES)
	@$(call DC,$^) ps

.PHONY: exec_haproxy1 exec_haproxy2

exec_haproxy1: $(COMPOSE_FILES)
	@$(call DC,$^) exec haproxy1 /bin/sh

exec_haproxy2: $(COMPOSE_FILES)
	@$(call DC,$^) exec haproxy2 /bin/sh

.PHONY: socat_haproxy1 socat_haproxy2

socat_haproxy1: $(COMPOSE_FILES)
	@$(call DC,$^) exec haproxy1 \
	/bin/sh -c 'while :; do /usr/bin/socat - UNIX-CLIENT:/var/run/haproxy.sock; done'

socat_haproxy2: $(COMPOSE_FILES)
	@$(call DC,$^) exec haproxy2 \
	/bin/sh -c 'while :; do /usr/bin/socat - UNIX-CLIENT:/var/run/haproxy.sock; done'

.PHONY: client_haproxy1 client_haproxy2

client_haproxy1: $(COMPOSE_FILES)
	@$(call DC,$^) exec haproxy1 /usr/bin/ruby client.rb

client_haproxy2: $(COMPOSE_FILES)
	@$(call DC,$^) exec haproxy2 /usr/bin/ruby client.rb

.PHONY: test

test:
	for k in {1..12}; do sleep 1; curl -fsSL http://$(SUBNET_PREFIX).86:8686/; done
