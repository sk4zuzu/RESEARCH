
SELF  := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
SHELL := $(shell which bash)
CACHE := $(SELF)/.cache

IMAGES := \
haproxy:2.2.2-alpine \
webdevops/php-apache:7.4-alpine

ARCHIVES := $(patsubst %,%.tar,$(subst /,-,$(subst :,-,$(IMAGES))))
OUTPUTS  := $(patsubst %.tar,$(CACHE)/%.out,$(ARCHIVES))
EXPORTS  := $(patsubst %.out,%.exp,$(OUTPUTS))

define BASH_SAVE_IMAGES
set -o errexit -o nounset -o pipefail
for IMAGE in $(IMAGES); do
    docker pull $$IMAGE
	NAME1=$${IMAGE/:/-}
	NAME2=$${NAME1/\//-}
	docker tag $$IMAGE $$NAME2
done
endef

define BASH_DIFF_OUTPUTS
set -o errexit -o nounset -o pipefail
for OUTPUT in $(OUTPUTS); do
    diff --recursive --no-dereference "$${OUTPUT/.out/.exp}" "$$OUTPUT"
done
endef

export

.PHONY: all save test clean

all: save $(OUTPUTS) $(EXPORTS)

save:
	$(SHELL) -s <<< "$$BASH_SAVE_IMAGES"

test: save $(OUTPUTS) $(EXPORTS)
	$(SHELL) -s <<< "$$BASH_DIFF_OUTPUTS"

clean:
	rm -rf $(CACHE) $(ARCHIVES)

$(SELF)/%.tar:
	docker save $* --output $@

$(CACHE)/%.out: $(SELF)/%.tar
	make -f $(SELF)/Makefile.EXTRACT IMAGE_TAR="$<" all clean
	rm -rf  $@/.dockerenv $@/dev/* $@/etc/host{name,s} $@/etc/{mtab,resolv.conf}

$(CACHE)/%.exp:
	install -d $@/
	docker export `docker create $*` | tar xf - -C $@/
	rm -rf  $@/.dockerenv $@/dev/* $@/etc/host{name,s} $@/etc/{mtab,resolv.conf}

# vim:ts=4:sw=4:noet:syn=make:
