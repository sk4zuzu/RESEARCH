SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

include $(SELF)/.env

export

.PHONY: all

all:

.PHONY: scenario1 scenario2

scenario1: $(SELF)/docker-compose.yml $(SELF)/scenario1.yml $(SELF)/id_rsa.env
	docker-compose --env-file $(word 3,$^) -f $(word 1,$^) -f $(word 2,$^) up --build

scenario2: $(SELF)/docker-compose.yml $(SELF)/scenario2.yml $(SELF)/id_rsa.env
	docker-compose --env-file $(word 3,$^) -f $(word 1,$^) -f $(word 2,$^) up --build

$(SELF)/id_rsa.env: $(SELF)/id_rsa.pub
	$(file >$@,JENKINS_AGENT_SSH_PUBKEY=$(file <$<))

$(SELF)/id_rsa.pub: $(SELF)/id_rsa

$(SELF)/id_rsa:
	ssh-keygen -t rsa -b 3072 -m PEM -f $@ -N ''

.PHONY: jenkins agent1 agent2

jenkins agent1 agent2: $(SELF)/docker-compose.yml
	docker-compose -f $< exec -u root $@ /bin/sh

.PHONY: down

down: $(SELF)/docker-compose.yml
	-docker-compose -f $< down --volumes --remove-orphans

.PHONY: cli

cli: $(SELF)/jenkins-cli.jar
	java -jar $< -s http://jenkins.poc.svc:8080/ -auth jenkins:asd -webSocket groovysh

$(SELF)/jenkins-cli.jar:
	curl -fsSLo $@ http://jenkins.poc.svc:8080/jnlpJars/jenkins-cli.jar
