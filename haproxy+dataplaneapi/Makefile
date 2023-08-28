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

.PHONY: exec_haproxy0

exec_haproxy0: $(COMPOSE_FILES)
	@$(call DC,$^) exec haproxy0 /bin/sh

.PHONY: test1 test2 test3

test1:
	curl -f -u admin:asd \
		-X GET \
		-H "Content-Type: application/json" \
		'http://$(SUBNET_PREFIX).8:5555/v2/services/haproxy/configuration/servers?backend=b1'
	curl -f -u admin:asd \
		-X POST \
		-H "Content-Type: application/json" \
		-d '{"name": "http1", "address": "$(SUBNET_PREFIX).2", "port": 8000, "check": "enabled"}' \
		'http://$(SUBNET_PREFIX).8:5555/v2/services/haproxy/configuration/servers?backend=b1&version=1'
	curl -f -u admin:asd \
		-X POST \
		-H "Content-Type: application/json" \
		-d '{"name": "http2", "address": "$(SUBNET_PREFIX).4", "port": 8000, "check": "enabled"}' \
		'http://$(SUBNET_PREFIX).8:5555/v2/services/haproxy/configuration/servers?backend=b1&version=2'
	curl -f -u admin:asd \
		-X GET \
		-H "Content-Type: application/json" \
		'http://$(SUBNET_PREFIX).8:5555/v2/services/haproxy/configuration/servers?backend=b1'

test2:
	curl -f -u admin:asd \
		-X GET \
		-H "Content-Type: application/json" \
		'http://$(SUBNET_PREFIX).8:5555/v2/services/haproxy/configuration/servers?backend=b2'
	curl -f -u admin:asd \
		-X POST \
		-H "Content-Type: application/json" \
		-d '{"name": "http1", "address": "$(SUBNET_PREFIX).2", "port": 8000, "check": "enabled"}' \
		'http://$(SUBNET_PREFIX).8:5555/v2/services/haproxy/configuration/servers?backend=b2&version=3'
	curl -f -u admin:asd \
		-X POST \
		-H "Content-Type: application/json" \
		-d '{"name": "http2", "address": "$(SUBNET_PREFIX).4", "port": 8000, "check": "enabled"}' \
		'http://$(SUBNET_PREFIX).8:5555/v2/services/haproxy/configuration/servers?backend=b2&version=4'
	curl -f -u admin:asd \
		-X GET \
		-H "Content-Type: application/json" \
		'http://$(SUBNET_PREFIX).8:5555/v2/services/haproxy/configuration/servers?backend=b2'

test3:
	for k in {1..4}; do sleep 1; curl -fsSL http://$(SUBNET_PREFIX).8:8686/; done

test4:
	for k in {1..4}; do sleep 1; curl -fsSL http://$(SUBNET_PREFIX).8:6969/; done
