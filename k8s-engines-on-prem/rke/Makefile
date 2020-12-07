SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

RKE_VERSION    = v1.2.3
SKOPEO_VERSION = v1.2.0

TO_ARCHIVE = $(patsubst %,$(SELF)/files/%.tar,$(subst :,..,$(1)))
TO_IMAGE   = $(patsubst $(SELF)/files/%.tar,%,$(subst ..,:,$(1)))

K8S_VERSIONS      = v1.18.12-rancher1-1 v1.19.4-rancher1-1
K8S_SYSTEM_IMAGES = $(sort $(foreach v,$(K8S_VERSIONS),$(shell $(SELF)/files/rke --quiet config --system-images --version $(v))))

export

.PHONY: all prereq

all: prereq

prereq: $(SELF)/files/rke $(SELF)/files/skopeo

$(SELF)/files/rke:
	curl -fsSL -o $@ https://github.com/rancher/rke/releases/download/$(RKE_VERSION)/rke_linux-amd64
	chmod +x $@

$(SELF)/files/skopeo:
	curl -fsSL -o $@ https://github.com/alvistack/containers-skopeo/releases/download/$(SKOPEO_VERSION)/skopeo-$(SKOPEO_VERSION)-linux-amd64
	chmod +x $@

.PHONY: r1download r1 r1purge r1logs

r1download: $(call TO_ARCHIVE,$(K8S_SYSTEM_IMAGES)) prereq

$(call TO_ARCHIVE,$(K8S_SYSTEM_IMAGES)):
	install -d $(dir $@)
	$(SELF)/files/skopeo --quiet --insecure-policy copy docker://$(call TO_IMAGE,$@) docker-archive://$@

r1: r1download
	cd $(SELF)/ && docker-compose up --detach && docker-compose logs --follow

r1purge:
	cd $(SELF)/ && docker-compose down --volumes

r1logs:
	cd $(SELF)/ && docker-compose logs --follow

.PHONY: u1prereq u1 u1upgrade u1remove

u1prereq: $(SELF)/u1.ini
	cd $(SELF)/ && ansible-playbook -vv --inventory=$< prereq.yml

u1: $(SELF)/u1-v1.18.12-rancher1-1.yml prereq
	cd $(SELF)/ && tee $(SELF)/u1.yml <$< \
	            && ./files/rke up --config=$(SELF)/u1.yml

u1upgrade: $(SELF)/u1-v1.19.4-rancher1-1.yml prereq
	cd $(SELF)/ && tee $(SELF)/u1.yml <$< \
	            && ./files/rke up --config=$(SELF)/u1.yml

u1remove: $(SELF)/u1.yml prereq
	cd $(SELF)/ && ./files/rke remove --config=$< --force

.PHONY: c1prereq c1 c1upgrade c1remove

c1prereq: $(SELF)/c1.ini
	cd $(SELF)/ && ansible-playbook -vv --inventory=$< prereq.yml

c1: $(SELF)/c1-v1.18.12-rancher1-1.yml prereq
	cd $(SELF)/ && tee $(SELF)/c1.yml <$< \
	            && ./files/rke up --config=$(SELF)/c1.yml

c1upgrade: $(SELF)/c1-v1.19.4-rancher1-1.yml prereq
	cd $(SELF)/ && tee $(SELF)/c1.yml <$< \
	            && ./files/rke up --config=$(SELF)/c1.yml

c1remove: $(SELF)/c1.yml prereq
	cd $(SELF)/ && ./files/rke remove --config=$< --force

.PHONY: au1 au1upgrade au1remove

au1: $(SELF)/au1-v1.18.12-rancher1-1.yml prereq
	cd $(SELF)/ && tee $(SELF)/au1.yml <$< \
	            && ./files/rke up --config=$(SELF)/au1.yml

au1upgrade: $(SELF)/au1-v1.19.4-rancher1-1.yml prereq
	cd $(SELF)/ && tee $(SELF)/au1.yml <$< \
	            && ./files/rke up --config=$(SELF)/au1.yml

au1remove: $(SELF)/au1.yml prereq
	cd $(SELF)/ && ./files/rke remove --config=$< --force
