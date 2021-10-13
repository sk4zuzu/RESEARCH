include .env

.PHONY: all

all: scenario1

.PHONY: scenario1 traefik1 traefik2

scenario1:
	docker-compose -f scenario1.yml up --build

traefik1:
	docker-compose -f scenario1.yml exec -u root traefik1 /bin/sh

traefik2:
	docker-compose -f scenario1.yml exec -u root traefik2 /bin/sh

.PHONY: down

down:
	-docker-compose -f scenario1.yml down -v

.PHONY: test-mtls

test-mtls:
	curl -fv http://$(SUBNET_PREFIX).4/prod.idrix.eu/secure/

.PHONY: test-cert-selection

test-cert-selection:
	curl -fv \
	--cacert ./traefik1/certs/poc.lh.cacert.pem \
	--cert ./traefik1/certs/c1.poc.lh.cert.pem \
	--key ./traefik1/certs/c1.poc.lh.key.pem \
	https://s1.poc.lh/

.PHONY: test-domain-fronting

test-domain-fronting:
	curl -fv \
	--cacert ./traefik1/certs/poc.svc.cacert.pem \
	--cert ./traefik1/certs/c1.poc.svc.cert.pem \
	--key ./traefik1/certs/c1.poc.svc.key.pem \
	https://s1.poc.svc/
