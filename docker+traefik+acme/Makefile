.PHONY: all

all: scenario1

.PHONY: scenario1 traefik1

scenario1:
	docker-compose -f scenario1.yml up

traefik1:
	docker-compose -f scenario1.yml exec -u root traefik /bin/sh

.PHONY: down

down:
	-docker-compose -f scenario1.yml down -v
