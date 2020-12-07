SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

KUBEONE_VERSION = 1.1.0

K8S_VERSIONS = 1.18.12 1.19.4

export

.PHONY: all prereq

all: prereq

prereq: $(SELF)/files/kubeone

$(SELF)/files/kubeone:
	curl -fsSL -o $@.zip https://github.com/kubermatic/kubeone/releases/download/v$(KUBEONE_VERSION)/kubeone_$(KUBEONE_VERSION)_linux_amd64.zip
	unzip -o -d $(dir $@) $@.zip $(notdir $@) hack/image-loader.sh
	chmod +x $@
	rm $@.zip

.PHONY: r1 r1purge r1logs

r1:
	cd $(SELF)/ && docker-compose up --detach && docker-compose logs --follow

r1purge:
	cd $(SELF)/ && docker-compose down --volumes

r1logs:
	cd $(SELF)/ && docker-compose logs --follow

.PHONY: u1 u1upgrade

u1: $(SELF)/u1-v1.18.12.yml prereq
	cd $(SELF)/ && ./files/kubeone install --manifest $<

u1upgrade: $(SELF)/u1-v1.19.4.yml prereq
	cd $(SELF)/ && ./files/kubeone upgrade --manifest $< --force

.PHONY: c1 c1upgrade

c1: $(SELF)/c1-v1.18.12.yml prereq
	cd $(SELF)/ && ./files/kubeone install --manifest $<

c1upgrade: $(SELF)/c1-v1.19.4.yml prereq
	cd $(SELF)/ && ./files/kubeone upgrade --manifest $< --force

.PHONY: au1 au1upgrade

au1: $(SELF)/au1-v1.18.12.yml prereq
	cd $(SELF)/ && ./files/kubeone install --manifest $<

au1upgrade: $(SELF)/au1-v1.19.4.yml prereq
	cd $(SELF)/ && ./files/kubeone upgrade --manifest $< --force
