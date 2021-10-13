SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

NAMESPACE := poc

export

.PHONY: all

all: serve

.PHONY: poetry

poetry:
	poetry install
	poetry export --no-interaction --format=requirements.txt --without-hashes --output=$(SELF)/requirements.txt

.PHONY: serve

serve: $(wildcard $(SELF)/*.py)
	python3 $(SELF)/main.py

.PHONY: test

test: $(wildcard $(SELF)/*.tavern.yml)
	tavern-ci --stdout $^

.PHONY: up down

up: $(SELF)/docker-compose.yml
	docker-compose -f $< $@ --build

down: $(SELF)/docker-compose.yml
	-docker-compose -f $< $@ -v

push: $(SELF)/docker-compose.yml
	docker-compose -f $< $@

.PHONY: s1 s2

s1: $(SELF)/docker-compose.yml
	@docker-compose -f $< exec $@ /bin/sh

s2: $(SELF)/docker-compose.yml
	@docker-compose -f $< exec $@ /bin/sh

.PHONY: deploy-now delete-now

deploy-now: $(SELF)/kubernetes.yml
	kubectl -n $(NAMESPACE) apply -f $<

delete-now: $(SELF)/kubernetes.yml
	kubectl -n $(NAMESPACE) delete -f $<
