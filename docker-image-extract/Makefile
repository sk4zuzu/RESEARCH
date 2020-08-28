
SELF  := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
SHELL := $(shell which bash)
CACHE := $(SELF)/.cache

IMAGES := \
haproxy:2.2.2-alpine \
webdevops/php-apache:7.4-alpine

ARCHIVES := $(patsubst %,%.tar,$(subst /,-,$(subst :,-,$(IMAGES))))
OUTPUTS  := $(patsubst %.tar,$(CACHE)/%.out,$(ARCHIVES))
EXPORTS  := $(patsubst %.out,%.exp,$(OUTPUTS))

define SAVE_IMAGES
set -o errexit -o nounset -o pipefail
for IMAGE in $(IMAGES); do
    docker pull $$IMAGE
	NAME1=$${IMAGE/:/-}
	NAME2=$${NAME1/\//-}
	docker tag $$IMAGE $$NAME2
done
endef

export

.PHONY: all save clean

all: save $(OUTPUTS) $(EXPORTS)

save:
	$(SHELL) -s <<< "$$SAVE_IMAGES"

clean:
	rm -rf $(CACHE) $(ARCHIVES)

$(SELF)/%.tar:
	docker save $* --output $@

$(CACHE)/%.out: $(SELF)/%.tar
	make -f $(SELF)/Makefile.EXTRACT IMAGE_TAR="$<" all clean

$(CACHE)/%.exp:
	install -d $@/
	docker export `docker create $*` | tar xf - -C $@/
	rm -rf $@/.dockerenv $@/dev/* $@/etc/resolv.conf

# vim:ts=4:sw=4:noet:syn=make:
