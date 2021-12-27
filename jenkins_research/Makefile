SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

include $(SELF)/.env

export

.PHONY: all

all: scenario1

.PHONY: scenario1

scenario1: $(SELF)/scenario1.yml $(SELF)/id_rsa.env
	docker-compose --env-file $(word 2,$^) -f $(word 1,$^) up --build

$(SELF)/id_rsa.env: $(SELF)/id_rsa.pub
	$(file >$@,JENKINS_AGENT_SSH_PUBKEY=$(file <$<))

$(SELF)/id_rsa.pub: $(SELF)/id_rsa

$(SELF)/id_rsa:
	ssh-keygen -t rsa -b 3072 -m PEM -f $@ -N ''

.PHONY: jenkins1 agent1 agent2

jenkins1 agent1 agent2: $(SELF)/scenario1.yml
	docker-compose -f $< exec -u root $@ /bin/sh

.PHONY: down

down: $(SELF)/scenario1.yml
	-docker-compose -f $< down --volumes
