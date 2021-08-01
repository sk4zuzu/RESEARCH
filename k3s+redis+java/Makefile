SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

IMG_PFX   := redisjava
REDIS_VER := 14.8.3

export

.PHONY: all

all: build1

.PHONY: build1

build1: $(SELF)/test1/
	cd $< && docker build -t $(IMG_PFX)-$@ .

.PHONY: exec1

exec1: build1
	docker run --rm --net=host -it $(IMG_PFX)-$< /bin/sh

.PHONY: test1

test1: build1
	REDIS_IP4=`kubectl get svc/redis -o jsonpath='{.spec.clusterIP}'` \
	docker run --rm --net=host -e REDIS_IP4 -it $(IMG_PFX)-$< \
	java -jar /opt/$@/target/$@-1.0.0-SNAPSHOT-jar-with-dependencies.jar

.PHONY: upgrade delete

upgrade: $(SELF)/values.yaml
	helm $@ --install redis bitnami/redis --version $(REDIS_VER) --wait -f $<

delete:
	helm $@ redis
