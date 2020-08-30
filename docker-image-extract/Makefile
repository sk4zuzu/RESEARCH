
SELF  := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
SHELL := $(shell which bash)
CACHE := $(SELF)/.cache

IMAGES := \
haproxy:2.2.2-alpine \
webdevops/php-apache:7.4-alpine

NAMES := $(subst /,-,$(subst :,-,$(IMAGES)))
TESTS := $(patsubst %,test_%,$(NAMES))

define TARGETS

$(SELF)/$(1).tar:
	docker pull $(2)
	docker save $(2) -o $$@

$(CACHE)/$(1).out: $(SELF)/$(1).tar
	# make -f $(SELF)/Makefile.EXTRACT IMAGE_TAR="$$<" all clean
	$(SELF)/extract-docker-image-V1.sh "$$<"
	rm -rf $$@/.dockerenv $$@/dev/* $$@/etc/host{name,s} $$@/etc/{mtab,resolv.conf}

$(CACHE)/$(1).exp:
	install -d $$@/
	docker export `docker create $(2)` | tar xf - -C $$@/
	rm -rf $$@/.dockerenv $$@/dev/* $$@/etc/host{name,s} $$@/etc/{mtab,resolv.conf}

.PHONY: test_$(1)
test_$(1): $(CACHE)/$(1).exp $(CACHE)/$(1).out
	diff --recursive --no-dereference $$^

endef

NAME_IMAGE_TUPLES := $(join $(NAMES),$(patsubst %,;%,$(IMAGES)))

ALL_TARGETS := \
$(foreach ITEM,$(NAME_IMAGE_TUPLES),\
    $(call TARGETS,$(word 1,$(subst ;, ,$(ITEM))),$(word 2,$(subst ;, ,$(ITEM)))))

export

.PHONY: all test clean

all: test

test: $(TESTS)

clean:
	rm -rf $(CACHE)

$(eval $(ALL_TARGETS))

# vim:ts=4:sw=4:noet:syn=make:
