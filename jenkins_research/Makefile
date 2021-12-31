SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

include $(SELF)/.env

export

.PHONY: all

all:

.PHONY: scenario1 scenario2

scenario1: $(SELF)/scenario1.yml $(SELF)/id_rsa.env
	docker-compose --env-file $(word 2,$^) -f $(word 1,$^) up --build

scenario2: $(SELF)/scenario2.yml $(SELF)/id_rsa.env
	docker-compose --env-file $(word 2,$^) -f $(word 1,$^) up --build

$(SELF)/id_rsa.env: $(SELF)/id_rsa.pub
	$(file >$@,JENKINS_AGENT_SSH_PUBKEY=$(file <$<))

$(SELF)/id_rsa.pub: $(SELF)/id_rsa

$(SELF)/id_rsa:
	ssh-keygen -t rsa -b 3072 -m PEM -f $@ -N ''

.PHONY: jenkins1 jenkins2 agent1 agent2

jenkins1 jenkins2 agent1 agent2: $(SELF)/scenario1.yml
	docker-compose -f $< exec -u root $@ /bin/sh

.PHONY: down1 down2

down1: $(SELF)/scenario1.yml
	-docker-compose -f $< down --volumes

down2: $(SELF)/scenario2.yml
	-docker-compose -f $< down --volumes

.PHONY: cli1 cli2

cli1: $(SELF)/jenkins-cli1.jar
	java -jar $< -s http://jenkins1.poc.svc:8080/ -auth jenkins:asd -webSocket groovysh

cli2: $(SELF)/jenkins-cli2.jar
	java -jar $< -s http://jenkins2.poc.svc:8080/ -auth jenkins:asd -webSocket groovysh

$(SELF)/jenkins-cli1.jar:
	curl -fsSLo $@ http://jenkins1.poc.svc:8080/jnlpJars/jenkins-cli.jar

$(SELF)/jenkins-cli2.jar:
	curl -fsSLo $@ http://jenkins2.poc.svc:8080/jnlpJars/jenkins-cli.jar
